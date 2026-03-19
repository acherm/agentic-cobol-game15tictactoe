       IDENTIFICATION DIVISION.
       PROGRAM-ID. GAME015.
      *
      * Computes all possible games in the Game of 0.15.
      * Two players alternate picking numbers 0.01-0.09 (no repeats).
      * A player wins when three of their numbers sum to 0.15.
      * If all 9 numbers are used with no winner, it is a draw.
      *
      * Mathematically equivalent to the Game of 15 (scaled by 1/100).
      * Internal representation uses integers 1-9 for efficiency.
      *
      * Usage: ./game015 [--unique]
      *   --unique  Also count games modulo board symmetry
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *
      * Command-line argument
       01  CMD-ARG            PIC X(20) VALUE SPACES.
       01  UNIQUE-MODE        PIC 9 VALUE 0.
      *
      * Owner of each number: 0=available, 1=Player1, 2=Player2
       01  OWNER-TABLE.
           05  OWNER          PIC 9 OCCURS 9 TIMES.
      *
      * Current depth in search tree (1 = first move, 9 = last)
       01  DEPTH              PIC 99.
      *
      * Next number to try at each depth level
       01  NEXT-TRY-TABLE.
           05  NEXT-TRY       PIC 99 OCCURS 9 TIMES.
      *
      * The number chosen at each depth level
       01  MOVE-TABLE.
           05  CHOSEN          PIC 9 OCCURS 9 TIMES.
      *
      * Working variables
       01  CUR-PLAYER         PIC 9.
       01  CUR-NUM            PIC 99.
       01  WIN-FOUND          PIC 9.
       01  IDX                PIC 99.
       01  QUOT               PIC 99.
       01  RMDR               PIC 99.
       01  DONE-FLAG          PIC 9 VALUE 0.
      *
      * Game outcome counters (all games)
       01  P1-WINS            PIC 9(8) VALUE ZEROS.
       01  P2-WINS            PIC 9(8) VALUE ZEROS.
       01  DRAWS              PIC 9(8) VALUE ZEROS.
       01  TOTAL-GAMES        PIC 9(8) VALUE ZEROS.
      *
      * Unique game counters (modulo symmetry)
       01  U-P1-WINS          PIC 9(8) VALUE ZEROS.
       01  U-P2-WINS          PIC 9(8) VALUE ZEROS.
       01  U-DRAWS            PIC 9(8) VALUE ZEROS.
       01  U-TOTAL            PIC 9(8) VALUE ZEROS.
      *
      * Variables for canonical check
       01  IS-CANONICAL       PIC 9.
       01  SYM-IDX            PIC 99.
       01  CMP-IDX            PIC 99.
       01  TEMP-NUM           PIC 9.
       01  TRANS-NUM          PIC 9.
       01  SYM-CMP            PIC 9.
       01  GAME-LEN           PIC 99.
      *
      * Display field (suppress leading zeros)
       01  DISPLAY-NUM        PIC Z(7)9.
      *
      * All 8 triples of {1..9} that sum to 15 (i.e., {0.01..0.09}
      * that sum to 0.15):
      * 0.01+0.05+0.09, 0.01+0.06+0.08, 0.02+0.04+0.09,
      * 0.02+0.05+0.08, 0.02+0.06+0.07, 0.03+0.04+0.08,
      * 0.03+0.05+0.07, 0.04+0.05+0.06
       01  WIN-TRIPLES.
           05  TRIPLE-DATA    PIC X(24)
               VALUE "159168249258267348357456".
           05  TRIPLE-ARRAY REDEFINES TRIPLE-DATA.
               10  TRIPLE     OCCURS 8 TIMES.
                   15  T1     PIC 9.
                   15  T2     PIC 9.
                   15  T3     PIC 9.
      *
      * 8 symmetries of the magic square (dihedral group D4).
      * Magic square:  2 7 6 / 9 5 1 / 4 3 8
      * (or: 0.02 0.07 0.06 / 0.09 0.05 0.01 / 0.04 0.03 0.08)
       01  SYM-TABLE.
           05  FILLER  PIC X(9) VALUE "123456789".
           05  FILLER  PIC X(9) VALUE "369258147".
           05  FILLER  PIC X(9) VALUE "987654321".
           05  FILLER  PIC X(9) VALUE "741852963".
           05  FILLER  PIC X(9) VALUE "963852741".
           05  FILLER  PIC X(9) VALUE "147258369".
           05  FILLER  PIC X(9) VALUE "321654987".
           05  FILLER  PIC X(9) VALUE "789456123".
       01  SYM-TABLE-R REDEFINES SYM-TABLE.
           05  SYM-ROW        OCCURS 8 TIMES.
               10  SYM-MAP    PIC 9 OCCURS 9 TIMES.
      *
       PROCEDURE DIVISION.
       MAIN-PROGRAM.
           ACCEPT CMD-ARG FROM COMMAND-LINE
           IF CMD-ARG = "--unique"
               MOVE 1 TO UNIQUE-MODE
           END-IF
      *
           INITIALIZE OWNER-TABLE
           MOVE 1 TO DEPTH
           MOVE 1 TO NEXT-TRY(1)
           MOVE 0 TO DONE-FLAG
      *
           PERFORM DFS-STEP UNTIL DONE-FLAG = 1
      *
           ADD P1-WINS P2-WINS DRAWS GIVING TOTAL-GAMES
      *
           DISPLAY "Game of 0.15 - Possible Games"
           DISPLAY "============================="
           MOVE P1-WINS TO DISPLAY-NUM
           DISPLAY "Player 1 wins: " DISPLAY-NUM
           MOVE P2-WINS TO DISPLAY-NUM
           DISPLAY "Player 2 wins: " DISPLAY-NUM
           MOVE DRAWS TO DISPLAY-NUM
           DISPLAY "Draws:         " DISPLAY-NUM
           MOVE TOTAL-GAMES TO DISPLAY-NUM
           DISPLAY "Total games:   " DISPLAY-NUM
      *
           IF UNIQUE-MODE = 1
               ADD U-P1-WINS U-P2-WINS U-DRAWS
                   GIVING U-TOTAL
               DISPLAY " "
               DISPLAY "Unique games (modulo symmetry)"
               DISPLAY "=============================="
               MOVE U-P1-WINS TO DISPLAY-NUM
               DISPLAY "Player 1 wins: " DISPLAY-NUM
               MOVE U-P2-WINS TO DISPLAY-NUM
               DISPLAY "Player 2 wins: " DISPLAY-NUM
               MOVE U-DRAWS TO DISPLAY-NUM
               DISPLAY "Draws:         " DISPLAY-NUM
               MOVE U-TOTAL TO DISPLAY-NUM
               DISPLAY "Total games:   " DISPLAY-NUM
           END-IF
      *
           STOP RUN
           .
      *
       DFS-STEP.
           IF NEXT-TRY(DEPTH) > 9
               IF DEPTH = 1
                   MOVE 1 TO DONE-FLAG
               ELSE
                   SUBTRACT 1 FROM DEPTH
                   MOVE 0 TO OWNER(CHOSEN(DEPTH))
                   ADD 1 TO NEXT-TRY(DEPTH)
               END-IF
           ELSE
               MOVE NEXT-TRY(DEPTH) TO CUR-NUM
               IF OWNER(CUR-NUM) NOT = 0
                   ADD 1 TO NEXT-TRY(DEPTH)
               ELSE
                   DIVIDE DEPTH BY 2
                       GIVING QUOT REMAINDER RMDR
                   IF RMDR = 1
                       MOVE 1 TO CUR-PLAYER
                   ELSE
                       MOVE 2 TO CUR-PLAYER
                   END-IF
                   MOVE CUR-NUM TO CHOSEN(DEPTH)
                   MOVE CUR-PLAYER TO OWNER(CUR-NUM)
                   PERFORM CHECK-WIN
                   IF WIN-FOUND = 1
                       IF CUR-PLAYER = 1
                           ADD 1 TO P1-WINS
                       ELSE
                           ADD 1 TO P2-WINS
                       END-IF
                       IF UNIQUE-MODE = 1
                           MOVE DEPTH TO GAME-LEN
                           PERFORM CHECK-CANONICAL
                           IF IS-CANONICAL = 1
                               IF CUR-PLAYER = 1
                                   ADD 1 TO U-P1-WINS
                               ELSE
                                   ADD 1 TO U-P2-WINS
                               END-IF
                           END-IF
                       END-IF
                       MOVE 0 TO OWNER(CUR-NUM)
                       ADD 1 TO NEXT-TRY(DEPTH)
                   ELSE
                       IF DEPTH = 9
                           ADD 1 TO DRAWS
                           IF UNIQUE-MODE = 1
                               MOVE 9 TO GAME-LEN
                               PERFORM CHECK-CANONICAL
                               IF IS-CANONICAL = 1
                                   ADD 1 TO U-DRAWS
                               END-IF
                           END-IF
                           MOVE 0 TO OWNER(CUR-NUM)
                           ADD 1 TO NEXT-TRY(DEPTH)
                       ELSE
                           ADD 1 TO DEPTH
                           MOVE 1 TO NEXT-TRY(DEPTH)
                       END-IF
                   END-IF
               END-IF
           END-IF
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
      *
       CHECK-CANONICAL.
           MOVE 1 TO IS-CANONICAL
           PERFORM VARYING SYM-IDX FROM 2 BY 1
               UNTIL SYM-IDX > 8 OR IS-CANONICAL = 0
               MOVE 0 TO SYM-CMP
               PERFORM VARYING CMP-IDX FROM 1 BY 1
                   UNTIL CMP-IDX > GAME-LEN
                   OR SYM-CMP NOT = 0
                   MOVE CHOSEN(CMP-IDX) TO TEMP-NUM
                   MOVE SYM-MAP(SYM-IDX, TEMP-NUM)
                       TO TRANS-NUM
                   IF TRANS-NUM < CHOSEN(CMP-IDX)
                       MOVE 1 TO SYM-CMP
                       MOVE 0 TO IS-CANONICAL
                   ELSE IF TRANS-NUM > CHOSEN(CMP-IDX)
                       MOVE 2 TO SYM-CMP
                   END-IF END-IF
               END-PERFORM
           END-PERFORM
           .
