       IDENTIFICATION DIVISION.
       PROGRAM-ID. GAME15TREE.
      *
      * Displays the optimal play tree for the Game of 15.
      * Pass 1: Minimax with memoization (base-3 position key).
      * Pass 2: Print ASCII tree of optimal moves only.
      *
      * Usage: ./game15tree [--depth N]
      *   --depth N  Limit tree display to N plies (default: 9)
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *
      * Command-line parsing
       01  CMD-LINE           PIC X(80) VALUE SPACES.
       01  WS-TOK1            PIC X(20) VALUE SPACES.
       01  WS-TOK2            PIC X(20) VALUE SPACES.
       01  MAX-DEPTH          PIC 99 VALUE 9.
      *
      * Owner of each number: 0=free, 1=Player1, 2=Player2
       01  OWNER-TABLE.
           05  OWNER          PIC 9 OCCURS 9 TIMES.
      *
      * Search depth
       01  DEPTH              PIC 99.
      *
      * Next number to try at each depth (pass 1)
       01  NEXT-TRY-TABLE.
           05  NEXT-TRY       PIC 99 OCCURS 9 TIMES.
      *
      * Number chosen at each depth
       01  MOVE-TABLE.
           05  CHOSEN         PIC 9 OCCURS 9 TIMES.
      *
      * Working variables
       01  CUR-PLAYER         PIC 9.
       01  CUR-NUM            PIC 99.
       01  WIN-FOUND          PIC 9.
       01  IDX                PIC 99.
       01  QUOT               PIC 99.
       01  RMDR               PIC 99.
      *
      * Minimax encoded values:
      *   0 = not computed, 1 = P2 wins, 2 = Draw, 3 = P1 wins
      *
      * Memoization table (3^9 = 19683 positions)
       01  MEMO-TABLE.
           05  MEMO-VAL       PIC 9 OCCURS 19683 TIMES.
      *
      * Position key computation
       01  POS-KEY            PIC 9(5).
       01  POW3               PIC 9(5).
       01  KEY-I              PIC 99.
      *
      * Minimax DFS variables
       01  BEST-VAL-TABLE.
           05  BEST-VAL       PIC 9 OCCURS 9 TIMES.
       01  CHILD-VAL          PIC 9.
       01  MM-DONE            PIC 9 VALUE 0.
      *
      * Tree printing variables
       01  TREE-DONE          PIC 9 VALUE 0.
       01  IS-TERMINAL        PIC 9.
       01  DEPTH-LIMITED      PIC 9.
       01  NODE-VAL           PIC 9.
       01  PARENT-VAL         PIC 9.
      *
      * Optimal moves at each depth
       01  OPT-TABLE.
           05  OPT-LEVEL      OCCURS 9 TIMES.
               10  OPT-COUNT  PIC 99.
               10  OPT-INDEX  PIC 99.
               10  OPT-NUMS   PIC 9 OCCURS 9 TIMES.
      *
      * Bad (losing) moves at each depth
       01  BAD-TABLE.
           05  BAD-LEVEL      OCCURS 9 TIMES.
               10  BAD-COUNT  PIC 99.
               10  BAD-NUMS   PIC 9 OCCURS 9 TIMES.
      *
      * Prefix tracking for tree connectors
       01  IS-LAST-TABLE.
           05  IS-LAST        PIC 9 OCCURS 9 TIMES.
      *
      * Output line assembly
       01  OUTPUT-LINE        PIC X(200) VALUE SPACES.
       01  LINE-POS           PIC 999.
       01  LP                 PIC 99.
      *
      * Single-digit display helper
       01  DISP-DIGIT         PIC 9.
      *
      * Trial move for COLLECT-OPTIMAL
       01  TRIAL-NUM          PIC 99.
       01  TRIAL-VAL          PIC 9.
      *
      * Winning triples
       01  WIN-TRIPLES.
           05  TRIPLE-DATA    PIC X(24)
               VALUE "159168249258267348357456".
           05  TRIPLE-ARRAY REDEFINES TRIPLE-DATA.
               10  TRIPLE     OCCURS 8 TIMES.
                   15  T1     PIC 9.
                   15  T2     PIC 9.
                   15  T3     PIC 9.
      *
      * Root value for display
       01  ROOT-VAL           PIC 9.
      *
       PROCEDURE DIVISION.
       MAIN-PROGRAM.
           PERFORM PARSE-ARGS
      *
      * === Pass 1: Minimax ===
           INITIALIZE MEMO-TABLE
           INITIALIZE OWNER-TABLE
           MOVE 1 TO DEPTH
           MOVE 1 TO NEXT-TRY(1)
           MOVE 1 TO BEST-VAL(1)
           MOVE 0 TO MM-DONE
      *
           PERFORM MINIMAX-STEP UNTIL MM-DONE = 1
      *
      * Store root value
           PERFORM COMPUTE-POS-KEY
           ADD 1 TO POS-KEY
           MOVE MEMO-VAL(POS-KEY) TO ROOT-VAL
      *
      * === Pass 2: Print tree ===
           INITIALIZE OWNER-TABLE
           MOVE 1 TO DEPTH
      *
      * Print header
           MOVE SPACES TO OUTPUT-LINE
           MOVE "Game of 15 - Optimal Play Tree" TO
               OUTPUT-LINE(1:30)
           IF ROOT-VAL = 3
               MOVE " [P1 wins]" TO OUTPUT-LINE(31:10)
           ELSE IF ROOT-VAL = 2
               MOVE " [Draw]" TO OUTPUT-LINE(31:7)
           ELSE
               MOVE " [P2 wins]" TO OUTPUT-LINE(31:10)
           END-IF END-IF
           DISPLAY FUNCTION TRIM(OUTPUT-LINE TRAILING)
      *
      * Collect optimal moves at depth 1
           PERFORM COLLECT-OPTIMAL
           IF BAD-COUNT(1) > 0
               PERFORM PRINT-AVOID
           END-IF
           MOVE 1 TO OPT-INDEX(1)
           MOVE 0 TO TREE-DONE
      *
           IF OPT-COUNT(1) = 0
               MOVE 1 TO TREE-DONE
           END-IF
      *
           PERFORM TREE-STEP UNTIL TREE-DONE = 1
      *
           STOP RUN
           .
      *
       PARSE-ARGS.
           ACCEPT CMD-LINE FROM COMMAND-LINE
           MOVE 9 TO MAX-DEPTH
           IF CMD-LINE NOT = SPACES
               UNSTRING CMD-LINE DELIMITED BY ALL SPACES
                   INTO WS-TOK1 WS-TOK2
               END-UNSTRING
               IF WS-TOK1 = "--depth"
                   COMPUTE MAX-DEPTH =
                       FUNCTION NUMVAL(WS-TOK2)
                   IF MAX-DEPTH < 1
                       MOVE 1 TO MAX-DEPTH
                   END-IF
                   IF MAX-DEPTH > 9
                       MOVE 9 TO MAX-DEPTH
                   END-IF
               END-IF
           END-IF
           .
      *
      * ============================================================
      * Pass 1: Minimax with memoization
      * ============================================================
      *
       MINIMAX-STEP.
           IF NEXT-TRY(DEPTH) > 9
      *        All children exhausted - store result and backtrack
               IF DEPTH = 1
      *            Store root position value
                   PERFORM COMPUTE-POS-KEY
                   ADD 1 TO POS-KEY
                   MOVE BEST-VAL(1) TO MEMO-VAL(POS-KEY)
                   MOVE 1 TO MM-DONE
               ELSE
      *            Store current position value in memo
                   PERFORM COMPUTE-POS-KEY
                   ADD 1 TO POS-KEY
                   MOVE BEST-VAL(DEPTH)
                       TO MEMO-VAL(POS-KEY)
      *            Save child value for parent
                   MOVE BEST-VAL(DEPTH) TO CHILD-VAL
      *            Backtrack
                   SUBTRACT 1 FROM DEPTH
                   MOVE 0 TO OWNER(CHOSEN(DEPTH))
                   PERFORM UPDATE-BEST
                   ADD 1 TO NEXT-TRY(DEPTH)
               END-IF
           ELSE
               MOVE NEXT-TRY(DEPTH) TO CUR-NUM
               IF OWNER(CUR-NUM) NOT = 0
                   ADD 1 TO NEXT-TRY(DEPTH)
               ELSE
      *            Determine player
                   DIVIDE DEPTH BY 2
                       GIVING QUOT REMAINDER RMDR
                   IF RMDR = 1
                       MOVE 1 TO CUR-PLAYER
                   ELSE
                       MOVE 2 TO CUR-PLAYER
                   END-IF
      *            Make move
                   MOVE CUR-NUM TO CHOSEN(DEPTH)
                   MOVE CUR-PLAYER TO OWNER(CUR-NUM)
      *            Check for win
                   PERFORM CHECK-WIN
                   IF WIN-FOUND = 1
      *                Terminal: win
                       IF CUR-PLAYER = 1
                           MOVE 3 TO CHILD-VAL
                       ELSE
                           MOVE 1 TO CHILD-VAL
                       END-IF
                       MOVE 0 TO OWNER(CUR-NUM)
                       PERFORM UPDATE-BEST
                       ADD 1 TO NEXT-TRY(DEPTH)
                   ELSE IF DEPTH = 9
      *                Terminal: draw
                       MOVE 2 TO CHILD-VAL
                       MOVE 0 TO OWNER(CUR-NUM)
                       PERFORM UPDATE-BEST
                       ADD 1 TO NEXT-TRY(DEPTH)
                   ELSE
      *                Non-terminal: check memo
                       PERFORM COMPUTE-POS-KEY
                       ADD 1 TO POS-KEY
                       IF MEMO-VAL(POS-KEY) NOT = 0
      *                    Already computed
                           MOVE MEMO-VAL(POS-KEY)
                               TO CHILD-VAL
                           MOVE 0 TO OWNER(CUR-NUM)
                           PERFORM UPDATE-BEST
                           ADD 1 TO NEXT-TRY(DEPTH)
                       ELSE
      *                    Go deeper
                           ADD 1 TO DEPTH
                           MOVE 1 TO NEXT-TRY(DEPTH)
      *                    Init best for new depth
                           DIVIDE DEPTH BY 2
                               GIVING QUOT REMAINDER RMDR
                           IF RMDR = 1
                               MOVE 1 TO BEST-VAL(DEPTH)
                           ELSE
                               MOVE 3 TO BEST-VAL(DEPTH)
                           END-IF
                       END-IF
                   END-IF END-IF
               END-IF
           END-IF
           .
      *
       UPDATE-BEST.
      *    P1 (odd depth) maximizes, P2 (even depth) minimizes
           DIVIDE DEPTH BY 2
               GIVING QUOT REMAINDER RMDR
           IF RMDR = 1
               IF CHILD-VAL > BEST-VAL(DEPTH)
                   MOVE CHILD-VAL TO BEST-VAL(DEPTH)
               END-IF
           ELSE
               IF CHILD-VAL < BEST-VAL(DEPTH)
                   MOVE CHILD-VAL TO BEST-VAL(DEPTH)
               END-IF
           END-IF
           .
      *
       COMPUTE-POS-KEY.
           MOVE 0 TO POS-KEY
           MOVE 1 TO POW3
           PERFORM VARYING KEY-I FROM 1 BY 1
               UNTIL KEY-I > 9
               COMPUTE POS-KEY =
                   POS-KEY + OWNER(KEY-I) * POW3
               MULTIPLY 3 BY POW3
           END-PERFORM
           .
      *
      * ============================================================
      * Pass 2: Print optimal play tree
      * ============================================================
      *
       TREE-STEP.
           IF OPT-INDEX(DEPTH) > OPT-COUNT(DEPTH)
      *        All optimal moves exhausted at this depth
               IF DEPTH = 1
                   MOVE 1 TO TREE-DONE
               ELSE
                   SUBTRACT 1 FROM DEPTH
                   MOVE 0 TO OWNER(CHOSEN(DEPTH))
                   ADD 1 TO OPT-INDEX(DEPTH)
               END-IF
           ELSE
      *        Pick the next optimal move
               MOVE OPT-NUMS(DEPTH, OPT-INDEX(DEPTH))
                   TO CUR-NUM
      *        Set IS-LAST flag for tree connectors
               IF OPT-INDEX(DEPTH) = OPT-COUNT(DEPTH)
                   MOVE 1 TO IS-LAST(DEPTH)
               ELSE
                   MOVE 0 TO IS-LAST(DEPTH)
               END-IF
      *        Determine player
               DIVIDE DEPTH BY 2
                   GIVING QUOT REMAINDER RMDR
               IF RMDR = 1
                   MOVE 1 TO CUR-PLAYER
               ELSE
                   MOVE 2 TO CUR-PLAYER
               END-IF
      *        Make move
               MOVE CUR-NUM TO CHOSEN(DEPTH)
               MOVE CUR-PLAYER TO OWNER(CUR-NUM)
      *        Evaluate node
               PERFORM CHECK-WIN
               IF WIN-FOUND = 1
                   IF CUR-PLAYER = 1
                       MOVE 3 TO NODE-VAL
                   ELSE
                       MOVE 1 TO NODE-VAL
                   END-IF
                   MOVE 1 TO IS-TERMINAL
                   MOVE 0 TO DEPTH-LIMITED
               ELSE IF DEPTH = 9
                   MOVE 2 TO NODE-VAL
                   MOVE 1 TO IS-TERMINAL
                   MOVE 0 TO DEPTH-LIMITED
               ELSE
                   PERFORM COMPUTE-POS-KEY
                   ADD 1 TO POS-KEY
                   MOVE MEMO-VAL(POS-KEY) TO NODE-VAL
                   MOVE 0 TO IS-TERMINAL
                   IF DEPTH >= MAX-DEPTH
                       MOVE 1 TO DEPTH-LIMITED
                   ELSE
                       MOVE 0 TO DEPTH-LIMITED
                   END-IF
               END-IF END-IF
      *
               PERFORM PRINT-NODE
      *
               IF IS-TERMINAL = 1
                   OR DEPTH-LIMITED = 1
      *            Depth-limited: show avoid before stopping
                   IF DEPTH-LIMITED = 1
                       ADD 1 TO DEPTH
                       PERFORM COLLECT-OPTIMAL
                       IF BAD-COUNT(DEPTH) > 0
                           PERFORM PRINT-AVOID
                       END-IF
                       SUBTRACT 1 FROM DEPTH
                   END-IF
      *            Leaf or depth-limited: undo and advance
                   MOVE 0 TO OWNER(CHOSEN(DEPTH))
                   ADD 1 TO OPT-INDEX(DEPTH)
               ELSE
      *            Go deeper
                   ADD 1 TO DEPTH
                   PERFORM COLLECT-OPTIMAL
                   IF BAD-COUNT(DEPTH) > 0
                       PERFORM PRINT-AVOID
                   END-IF
                   MOVE 1 TO OPT-INDEX(DEPTH)
               END-IF
           END-IF
           .
      *
       COLLECT-OPTIMAL.
      *    Find all moves at DEPTH whose value equals the parent
      *    position's minimax value.
      *    Determine player
           DIVIDE DEPTH BY 2
               GIVING QUOT REMAINDER RMDR
           IF RMDR = 1
               MOVE 1 TO CUR-PLAYER
           ELSE
               MOVE 2 TO CUR-PLAYER
           END-IF
      *    Get parent position value
           PERFORM COMPUTE-POS-KEY
           ADD 1 TO POS-KEY
           MOVE MEMO-VAL(POS-KEY) TO PARENT-VAL
      *
           MOVE 0 TO OPT-COUNT(DEPTH)
           MOVE 0 TO BAD-COUNT(DEPTH)
           PERFORM VARYING TRIAL-NUM FROM 1 BY 1
               UNTIL TRIAL-NUM > 9
               IF OWNER(TRIAL-NUM) = 0
      *            Trial move
                   MOVE CUR-PLAYER TO OWNER(TRIAL-NUM)
                   MOVE TRIAL-NUM TO CUR-NUM
                   PERFORM CHECK-WIN
                   IF WIN-FOUND = 1
                       IF CUR-PLAYER = 1
                           MOVE 3 TO TRIAL-VAL
                       ELSE
                           MOVE 1 TO TRIAL-VAL
                       END-IF
                   ELSE IF DEPTH = 9
                       MOVE 2 TO TRIAL-VAL
                   ELSE
                       PERFORM COMPUTE-POS-KEY
                       ADD 1 TO POS-KEY
                       MOVE MEMO-VAL(POS-KEY)
                           TO TRIAL-VAL
                   END-IF END-IF
      *            Undo trial
                   MOVE 0 TO OWNER(TRIAL-NUM)
      *            Classify: optimal or losing
                   IF TRIAL-VAL = PARENT-VAL
                       ADD 1 TO OPT-COUNT(DEPTH)
                       MOVE TRIAL-NUM TO
                           OPT-NUMS(DEPTH,
                           OPT-COUNT(DEPTH))
                   ELSE
                       ADD 1 TO BAD-COUNT(DEPTH)
                       MOVE TRIAL-NUM TO
                           BAD-NUMS(DEPTH,
                           BAD-COUNT(DEPTH))
                   END-IF
               END-IF
           END-PERFORM
           .
      *
       PRINT-NODE.
           MOVE SPACES TO OUTPUT-LINE
           MOVE 1 TO LINE-POS
      *    Build prefix from depth 1 to DEPTH-1
           PERFORM VARYING LP FROM 1 BY 1
               UNTIL LP >= DEPTH
               IF IS-LAST(LP) = 1
                   MOVE "    " TO
                       OUTPUT-LINE(LINE-POS:4)
               ELSE
                   MOVE "|   " TO
                       OUTPUT-LINE(LINE-POS:4)
               END-IF
               ADD 4 TO LINE-POS
           END-PERFORM
      *    Connector for current node
           IF IS-LAST(DEPTH) = 1
               MOVE "+-- " TO
                   OUTPUT-LINE(LINE-POS:4)
           ELSE
               MOVE "|-- " TO
                   OUTPUT-LINE(LINE-POS:4)
           END-IF
           ADD 4 TO LINE-POS
      *    Player label
           IF CUR-PLAYER = 1
               MOVE "P1:" TO OUTPUT-LINE(LINE-POS:3)
           ELSE
               MOVE "P2:" TO OUTPUT-LINE(LINE-POS:3)
           END-IF
           ADD 3 TO LINE-POS
      *    Move number
           MOVE CUR-NUM TO DISP-DIGIT
           MOVE DISP-DIGIT TO OUTPUT-LINE(LINE-POS:1)
           ADD 1 TO LINE-POS
      *    Value annotation
           MOVE " [" TO OUTPUT-LINE(LINE-POS:2)
           ADD 2 TO LINE-POS
           EVALUATE NODE-VAL
               WHEN 3
                   MOVE "P1 wins" TO
                       OUTPUT-LINE(LINE-POS:7)
                   ADD 7 TO LINE-POS
               WHEN 2
                   MOVE "Draw" TO
                       OUTPUT-LINE(LINE-POS:4)
                   ADD 4 TO LINE-POS
               WHEN 1
                   MOVE "P2 wins" TO
                       OUTPUT-LINE(LINE-POS:7)
                   ADD 7 TO LINE-POS
           END-EVALUATE
           MOVE "]" TO OUTPUT-LINE(LINE-POS:1)
           ADD 1 TO LINE-POS
      *    Terminal marker
           IF IS-TERMINAL = 1
               MOVE " *" TO OUTPUT-LINE(LINE-POS:2)
               ADD 2 TO LINE-POS
           END-IF
      *    Depth-limited marker
           IF DEPTH-LIMITED = 1
               MOVE " ..." TO OUTPUT-LINE(LINE-POS:4)
               ADD 4 TO LINE-POS
           END-IF
      *
           DISPLAY FUNCTION TRIM(OUTPUT-LINE TRAILING)
           .
      *
       PRINT-AVOID.
           MOVE SPACES TO OUTPUT-LINE
           MOVE 1 TO LINE-POS
      *    Build prefix from depth 1 to DEPTH-1
           PERFORM VARYING LP FROM 1 BY 1
               UNTIL LP >= DEPTH
               IF IS-LAST(LP) = 1
                   MOVE "    " TO
                       OUTPUT-LINE(LINE-POS:4)
               ELSE
                   MOVE "|   " TO
                       OUTPUT-LINE(LINE-POS:4)
               END-IF
               ADD 4 TO LINE-POS
           END-PERFORM
      *    Print "avoid:" followed by bad move numbers
           MOVE "avoid:" TO OUTPUT-LINE(LINE-POS:6)
           ADD 6 TO LINE-POS
           PERFORM VARYING IDX FROM 1 BY 1
               UNTIL IDX > BAD-COUNT(DEPTH)
               IF IDX > 1
                   MOVE "," TO OUTPUT-LINE(LINE-POS:1)
                   ADD 1 TO LINE-POS
               END-IF
               MOVE " " TO OUTPUT-LINE(LINE-POS:1)
               ADD 1 TO LINE-POS
               MOVE BAD-NUMS(DEPTH, IDX) TO DISP-DIGIT
               MOVE DISP-DIGIT TO
                   OUTPUT-LINE(LINE-POS:1)
               ADD 1 TO LINE-POS
           END-PERFORM
           DISPLAY FUNCTION TRIM(OUTPUT-LINE TRAILING)
           .
      *
       CHECK-WIN.
           MOVE 0 TO WIN-FOUND
           PERFORM VARYING IDX FROM 1 BY 1
               UNTIL IDX > 8 OR WIN-FOUND = 1
               IF OWNER(T1(IDX)) = CUR-PLAYER
                   AND OWNER(T2(IDX)) = CUR-PLAYER
                   AND OWNER(T3(IDX)) = CUR-PLAYER
                   MOVE 1 TO WIN-FOUND
               END-IF
           END-PERFORM
           .
