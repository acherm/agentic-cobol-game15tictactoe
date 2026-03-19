       IDENTIFICATION DIVISION.
       PROGRAM-ID. GAMEN.
      *
      * Generator for "Game of N" variants.
      * Given a target sum and number range, defines a game where
      * two players alternate picking numbers; first to collect
      * three numbers summing to the target wins.
      *
      * Usage: ./gameN <target-sum> [<max-number>]
      *   target-sum   Integer sum needed to win (e.g. 15)
      *   max-number   Highest pickable number (default: auto)
      *
      * Examples:
      *   ./gameN 15 9     (classic Game of 15)
      *   ./gameN 12 8     (Game of 12 with numbers 1-8)
      *   ./gameN 10       (Game of 10, auto range)
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *
      * Command-line parsing
       01  CMD-LINE           PIC X(80) VALUE SPACES.
       01  ARG1               PIC X(20) VALUE SPACES.
       01  ARG2               PIC X(20) VALUE SPACES.
       01  TARGET-SUM         PIC 99 VALUE 0.
       01  MAX-NUM            PIC 99 VALUE 0.
      *
      * Triple generation
       01  NUM-TRIPLES        PIC 99 VALUE 0.
       01  GEN-A              PIC 99.
       01  GEN-B              PIC 99.
       01  GEN-C              PIC 99.
       01  GEN-SUM            PIC 999.
       01  TRIPLE-TABLE.
           05  GEN-TRIPLE     OCCURS 84 TIMES.
               10  GT1        PIC 99.
               10  GT2        PIC 99.
               10  GT3        PIC 99.
      *
      * Owner of each number: 0=available, 1=Player1, 2=Player2
       01  OWNER-TABLE.
           05  OWNER          PIC 9 OCCURS 15 TIMES.
      *
      * DFS state
       01  DEPTH              PIC 99.
       01  NEXT-TRY-TABLE.
           05  NEXT-TRY       PIC 99 OCCURS 15 TIMES.
       01  MOVE-TABLE.
           05  CHOSEN         PIC 99 OCCURS 15 TIMES.
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
      * Game outcome counters
       01  P1-WINS            PIC 9(10) VALUE ZEROS.
       01  P2-WINS            PIC 9(10) VALUE ZEROS.
       01  DRAWS              PIC 9(10) VALUE ZEROS.
       01  TOTAL-GAMES        PIC 9(10) VALUE ZEROS.
      *
      * Display fields
       01  DISPLAY-NUM        PIC Z(9)9.
       01  DISP2              PIC Z9.
       01  DT1                PIC Z9.
       01  DT2                PIC Z9.
       01  DT3                PIC Z9.
      *
      * Summary of all numbers
       01  ALL-NUMS-SUM       PIC 999 VALUE 0.
       01  RATIO-DISPLAY      PIC X(30).
      *
       PROCEDURE DIVISION.
       MAIN-PROGRAM.
           PERFORM PARSE-ARGS
           PERFORM GENERATE-TRIPLES
           PERFORM DISPLAY-RULES
      *
           IF MAX-NUM <= 9
               DISPLAY "Enumerating all possible games..."
               DISPLAY " "
               INITIALIZE OWNER-TABLE
               MOVE 1 TO DEPTH
               MOVE 1 TO NEXT-TRY(1)
               MOVE 0 TO DONE-FLAG
               MOVE 0 TO P1-WINS
               MOVE 0 TO P2-WINS
               MOVE 0 TO DRAWS
               PERFORM DFS-STEP UNTIL DONE-FLAG = 1
               ADD P1-WINS P2-WINS DRAWS
                   GIVING TOTAL-GAMES
               DISPLAY "Results:"
               DISPLAY "========"
               MOVE P1-WINS TO DISPLAY-NUM
               DISPLAY "  Player 1 wins: " DISPLAY-NUM
               MOVE P2-WINS TO DISPLAY-NUM
               DISPLAY "  Player 2 wins: " DISPLAY-NUM
               MOVE DRAWS TO DISPLAY-NUM
               DISPLAY "  Draws:         " DISPLAY-NUM
               MOVE TOTAL-GAMES TO DISPLAY-NUM
               DISPLAY "  Total games:   " DISPLAY-NUM
           ELSE
               DISPLAY "(Too many numbers to enumerate"
               DISPLAY " all games. Use max <= 9.)"
           END-IF
      *
           DISPLAY " "
           STOP RUN
           .
      *
       PARSE-ARGS.
           ACCEPT CMD-LINE FROM COMMAND-LINE
           IF CMD-LINE = SPACES
               DISPLAY "Usage: ./gameN <target> "
                   "[<max-number>]"
               DISPLAY " "
               DISPLAY "  target      integer sum to win"
               DISPLAY "  max-number  highest pickable "
                   "number (default: auto)"
               DISPLAY " "
               DISPLAY "Examples:"
               DISPLAY "  ./gameN 15 9   classic Game of"
                   " 15"
               DISPLAY "  ./gameN 12 8   Game of 12,"
                   " numbers 1-8"
               DISPLAY "  ./gameN 10     Game of 10,"
                   " auto range"
               STOP RUN
           END-IF
      *
           UNSTRING CMD-LINE DELIMITED BY ALL SPACES
               INTO ARG1 ARG2
           END-UNSTRING
      *
           COMPUTE TARGET-SUM =
               FUNCTION NUMVAL(ARG1)
      *
           IF ARG2 NOT = SPACES
               COMPUTE MAX-NUM =
                   FUNCTION NUMVAL(ARG2)
           ELSE
      *        Auto: K = T - 3, capped at 15, min 3
               COMPUTE MAX-NUM = TARGET-SUM - 3
               IF MAX-NUM > 15
                   MOVE 15 TO MAX-NUM
               END-IF
               IF MAX-NUM < 3
                   MOVE 3 TO MAX-NUM
               END-IF
           END-IF
      *
           IF MAX-NUM > 15
               DISPLAY "Error: max-number cannot "
                   "exceed 15."
               STOP RUN
           END-IF
           IF MAX-NUM < 3
               DISPLAY "Error: need at least 3 "
                   "numbers."
               STOP RUN
           END-IF
           IF TARGET-SUM < 6
               DISPLAY "Error: target must be >= 6 "
                   "(min triple is 1+2+3)."
               STOP RUN
           END-IF
           .
      *
       GENERATE-TRIPLES.
           MOVE 0 TO NUM-TRIPLES
           PERFORM VARYING GEN-A FROM 1 BY 1
               UNTIL GEN-A > MAX-NUM
               PERFORM VARYING GEN-B FROM 1 BY 1
                   UNTIL GEN-B > MAX-NUM
                   IF GEN-B > GEN-A
                       COMPUTE GEN-C =
                           TARGET-SUM - GEN-A - GEN-B
                       IF GEN-C > GEN-B
                           AND GEN-C <= MAX-NUM
                           ADD 1 TO NUM-TRIPLES
                           MOVE GEN-A
                               TO GT1(NUM-TRIPLES)
                           MOVE GEN-B
                               TO GT2(NUM-TRIPLES)
                           MOVE GEN-C
                               TO GT3(NUM-TRIPLES)
                       END-IF
                   END-IF
               END-PERFORM
           END-PERFORM
           .
      *
       DISPLAY-RULES.
           DISPLAY " "
           DISPLAY "==============================="
               "=========="
           MOVE TARGET-SUM TO DISP2
           DISPLAY "  The Game of "
               FUNCTION TRIM(DISP2)
           DISPLAY "==============================="
               "=========="
           DISPLAY " "
           DISPLAY "Rules:"
           MOVE MAX-NUM TO DISP2
           DISPLAY "  - Two players alternate "
               "picking a number"
           DISPLAY "    from {1, 2, ..., "
               FUNCTION TRIM(DISP2)
               "}. No repeats."
           MOVE TARGET-SUM TO DISP2
           DISPLAY "  - A player wins when any "
               "three of their"
           DISPLAY "    chosen numbers sum to "
               FUNCTION TRIM(DISP2) "."
           DISPLAY "  - If all numbers are used "
               "with no winner,"
           DISPLAY "    the game is a draw."
           DISPLAY " "
      *
      *    Compute sum of all numbers 1..K
           COMPUTE ALL-NUMS-SUM =
               MAX-NUM * (MAX-NUM + 1) / 2
           MOVE MAX-NUM TO DISP2
           DISPLAY "Number pool: 1 to "
               FUNCTION TRIM(DISP2)
               " (" FUNCTION TRIM(DISP2)
               " numbers)"
           MOVE ALL-NUMS-SUM TO DT1
           DISPLAY "Sum of all numbers: "
               FUNCTION TRIM(DT1)
           DISPLAY " "
      *
           MOVE NUM-TRIPLES TO DISP2
           IF NUM-TRIPLES = 0
               DISPLAY "No winning triples exist!"
               DISPLAY "This game always ends in "
                   "a draw."
           ELSE
               DISPLAY "Winning triples ("
                   FUNCTION TRIM(DISP2) "):"
               PERFORM VARYING IDX FROM 1 BY 1
                   UNTIL IDX > NUM-TRIPLES
                   MOVE GT1(IDX) TO DT1
                   MOVE GT2(IDX) TO DT2
                   MOVE GT3(IDX) TO DT3
                   DISPLAY "  {"
                       FUNCTION TRIM(DT1) ", "
                       FUNCTION TRIM(DT2) ", "
                       FUNCTION TRIM(DT3) "}"
               END-PERFORM
           END-IF
           DISPLAY " "
      *
      *    Compare to classic Game of 15
           IF TARGET-SUM = 15 AND MAX-NUM = 9
               DISPLAY "Note: This is the classic "
                   "Game of 15,"
               DISPLAY "isomorphic to Tic-Tac-Toe "
                   "via the 3x3 magic square."
               DISPLAY " "
           END-IF
      *
           IF NUM-TRIPLES = 0
               DISPLAY "With no winning triples, "
                   "every game is a draw."
               DISPLAY "Not very exciting!"
               DISPLAY " "
           ELSE IF NUM-TRIPLES < 4
               DISPLAY "Few winning triples: "
                   "games tend to end in draws."
               DISPLAY " "
           ELSE IF NUM-TRIPLES >= 8
               DISPLAY "Many winning triples: "
                   "games tend to end quickly."
               DISPLAY " "
           END-IF END-IF END-IF
           .
      *
       DFS-STEP.
           IF NEXT-TRY(DEPTH) > MAX-NUM
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
                       MOVE 0 TO OWNER(CUR-NUM)
                       ADD 1 TO NEXT-TRY(DEPTH)
                   ELSE
                       IF DEPTH = MAX-NUM
                           ADD 1 TO DRAWS
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
               UNTIL IDX > NUM-TRIPLES OR WIN-FOUND = 1
               IF OWNER(GT1(IDX)) = CUR-PLAYER
                   AND OWNER(GT2(IDX)) = CUR-PLAYER
                   AND OWNER(GT3(IDX)) = CUR-PLAYER
                   MOVE 1 TO WIN-FOUND
               END-IF
           END-PERFORM
           .
