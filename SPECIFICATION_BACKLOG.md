# Specification Backlog (Agent-Implemented Features)

This backlog documents what the agent actually built, step by step, at the level of individual technical capabilities. It complements the [README feature backlog](README.md#feature-backlog-ex-post), which is organized by user requests. Here the perspective is: what decisions did the agent make, what sub-features were introduced (including ones not explicitly requested), and in what order.

Features are numbered F-01, F-02, ... in implementation order. Each feature notes whether it was **explicitly requested** by the user or **agent-decided** (an implementation choice the agent made autonomously).

## Step 1: Game Counter (`game15.cob` v1)

User request: *"Write a COBOL program that computes the number of possible games in the Game of 15."*

| ID | Feature | Origin | Code Reference |
|----|---------|--------|---------------|
| F-01 | **Iterative DFS with backtracking** (non-recursive, stack-free). Uses DEPTH counter + NEXT-TRY array to simulate call stack. Chosen because COBOL lacks recursion support in standard usage. | Agent-decided | `game15.cob:144-215` (DFS-STEP) |
| F-02 | **Ownership model**. OWNER-TABLE array (9 entries, values 0/1/2) tracks which player holds each number. Serves as both game state and win-check input. | Agent-decided | `game15.cob:22-23` |
| F-03 | **Player alternation via depth parity**. `DIVIDE DEPTH BY 2 GIVING QUOT REMAINDER RMDR`; odd depth = P1, even = P2. Avoids storing a separate turn variable. | Agent-decided | `game15.cob:161-167` |
| F-04 | **Win detection via hardcoded triples**. All 8 winning triples encoded as a 24-char string `"159168249258267348357456"` with REDEFINES overlay for structured access (T1/T2/T3 per triple). | Agent-decided | `game15.cob:71-78` (data), `game15.cob:217-227` (CHECK-WIN) |
| F-05 | **Formatted result display**. Leading-zero suppression via `PIC Z(7)9`. Separate counters for P1 wins, P2 wins, draws. | Agent-decided | `game15.cob:46-49, 66-67, 114-123` |

## Step 2: Symmetry Deduplication (`game15.cob` v2)

User request: *"Add a flag to compute numbers without duplicates."*

The user said "duplicates"; the agent interpreted this as board-symmetry equivalence via the tic-tac-toe isomorphism (not mere move-order permutations). This was a non-trivial interpretation.

| ID | Feature | Origin | Code Reference |
|----|---------|--------|---------------|
| F-06 | **Command-line flag parsing**. `ACCEPT CMD-ARG FROM COMMAND-LINE`; compares against `"--unique"` to set UNIQUE-MODE flag. | Agent-decided (flag name + mechanism) | `game15.cob:18-19, 100-103` |
| F-07 | **D4 symmetry table (magic square permutations)**. 8 rows of 9 digits each, stored as FILLER PIC X(9) values with REDEFINES for indexed access. Each row maps number N to its image under one of the 8 symmetries (identity, 90CW, 180, 270CW, flipH, flipV, main diagonal, anti-diagonal). | Agent-decided | `game15.cob:80-96` |
| F-08 | **Canonical form checking**. For each completed game, compares the move sequence against all 8 symmetric images lexicographically. Counts the game only if it is the smallest (canonical) representative of its equivalence class. Early termination on first smaller image found. | Agent-decided | `game15.cob:232-251` (CHECK-CANONICAL) |
| F-09 | **Dual counter system**. Separate U-P1-WINS, U-P2-WINS, U-DRAWS counters for unique games, alongside the original total counters. Both are always computed; unique results displayed only when `--unique` is active. | Agent-decided | `game15.cob:52-55, 125-139, 180-190` |

## Step 3: Optimal Play Tree (`game15tree.cob`)

User request: *"Depict a tree (in ASCII format) of all possible moves and the outcome (under optimal play)."*

| ID | Feature | Origin | Code Reference |
|----|---------|--------|---------------|
| F-10 | **Two-pass program architecture**. Pass 1 computes minimax values for all positions; Pass 2 traverses and prints the tree. Separation allows the tree printer to query precomputed values without re-solving. | Agent-decided | `game15tree.cob:114-128` (pass 1), `game15tree.cob:130-158` (pass 2) |
| F-11 | **Iterative minimax algorithm**. P1 (odd depth) maximizes, P2 (even depth) minimizes. Values: 1=P2 wins, 2=Draw, 3=P1 wins. Best-value tracking per depth level via BEST-VAL array. | Agent-decided | `game15tree.cob:187-271` (MINIMAX-STEP), `game15tree.cob:273-286` (UPDATE-BEST) |
| F-12 | **Position memoization via base-3 hashing**. Each board state maps to a unique key in [0, 19682] using `sum(OWNER(i) * 3^(i-1))`. MEMO-TABLE stores the minimax value for each position. Avoids re-evaluating transpositions. | Agent-decided | `game15tree.cob:46-53, 288-297` (COMPUTE-POS-KEY) |
| F-13 | **Optimal move filtering (COLLECT-OPTIMAL)**. At each node, tries all available moves, evaluates each via memo lookup or direct win/draw check, and partitions into optimal (value = parent value) vs. suboptimal. | Agent-decided | `game15tree.cob:388-443` |
| F-14 | **ASCII tree rendering with proper connectors**. `\|--` for intermediate siblings, `+--` for last sibling. IS-LAST array tracks per-depth whether the current node is the last child, controlling prefix continuation lines (`\|   ` vs. `    `). Line assembled character-by-character into OUTPUT-LINE PIC X(200). | Agent-decided | `game15tree.cob:81-88, 445-511` (PRINT-NODE) |
| F-15 | **Depth-limited display**. `--depth N` flag parsed via UNSTRING into two tokens. Nodes beyond MAX-DEPTH are printed with `...` marker instead of expanding children. | Agent-decided (mechanism); explicitly requested (concept) | `game15tree.cob:15-18, 163-181` (PARSE-ARGS), `game15tree.cob:353-357, 504-508` |
| F-16 | **Node value annotations**. Each node labeled `[Draw]`, `[P1 wins]`, or `[P2 wins]`. Terminal nodes marked with `*`. | Agent-decided | `game15tree.cob:480-508` |

## Step 4: Avoid Annotations (`game15tree.cob` enhancement)

User request: *"Given a sequence of moves/choices, there are (1) follow-up choice to NOT perform (otherwise you lose); (2) follow-up choice you can make."*

| ID | Feature | Origin | Code Reference |
|----|---------|--------|---------------|
| F-17 | **Move classification (optimal vs. bad)**. COLLECT-OPTIMAL extended to partition available moves into two lists: OPT-NUMS (safe/optimal) and BAD-NUMS (lead to worse position). | Explicitly requested (concept); agent-decided (mechanism) | `game15tree.cob:75-79` (BAD-TABLE), `game15tree.cob:429-440` |
| F-18 | **Avoid line rendering**. PRINT-AVOID paragraph builds `avoid: 1, 3, 7, 9` lines with proper tree-prefix alignment. Displayed before the optimal move branches at each decision point. | Agent-decided (format) | `game15tree.cob:513-545` (PRINT-AVOID), called at `game15tree.cob:148-150, 368-370, 380-382` |

## Step 5: Bug Fixes (during Steps 3 and 4)

Both bugs were detected by the agent during testing and fixed within the same session. No bugs remain in the shipped code.

| ID | Feature | Origin | Code Reference |
|----|---------|--------|---------------|
| F-19 | **DISP-DIGIT intermediary for safe numeric display**. CUR-NUM (PIC 99, two digits) cannot be directly moved to a single-character output field without truncation to the wrong digit. DISP-DIGIT (PIC 9) is a dedicated one-digit variable: CUR-NUM is moved to DISP-DIGIT (numeric truncation keeps the units digit), then DISP-DIGIT is moved to the output line. | Agent-decided (fix for self-detected bug) | `game15tree.cob:91, 477-478` |
| F-20 | **CHOSEN(DEPTH)-based undo instead of CUR-NUM**. COLLECT-OPTIMAL's inner loop overwrites CUR-NUM (needed because CHECK-WIN reads it). The calling paragraph's undo operation must not use CUR-NUM after COLLECT-OPTIMAL returns. Fix: use `OWNER(CHOSEN(DEPTH))` which stores the actual chosen move and is never overwritten by inner loops. | Agent-decided (fix for self-detected bug) | `game15tree.cob:310, 374` |

## Step 6: Game of 0.15 Adaptation (`game015.cob`, `game015tree.cob`)

User request: *"The game of 0.15 [...] Please adapt your program to count the number of games, as well as the tree."*

| ID | Feature | Origin | Code Reference |
|----|---------|--------|---------------|
| F-21 | **Display-layer adaptation without logic change**. Internal representation stays as integers 1-9 for computational efficiency. Output formatting changed to show `"0.0X"` (e.g., `"P1:0.05"`) by inserting a fixed `"0.0"` prefix before the digit. | Agent-decided (approach) | `game015tree.cob:449-453` |
| F-22 | **Wider tree indentation for longer labels**. Tree connectors use 5-char spacing (`\|    `, `+--- `) instead of 4-char, accommodating the wider `"0.0X"` move labels. | Agent-decided | `game015tree.cob:425-441` |

## Step 7: Variant Generator (`gameN.cob`)

User request: *"Provide a generator that 'invents' a variant of the game of N=15 by changing N and thus the possible numbers users can choose. Please recap the rules of the game of N after."*

| ID | Feature | Origin | Code Reference |
|----|---------|--------|---------------|
| F-23 | **Two-argument CLI with UNSTRING parsing**. First argument = target sum, second (optional) = max number. UNSTRING splits by spaces into ARG1/ARG2, converted via FUNCTION NUMVAL. | Agent-decided (mechanism) | `gameN.cob:115-154` (PARSE-ARGS) |
| F-24 | **Dynamic winning triple generation**. Nested loops over all pairs (a, b) where a < b, computes c = target - a - b, checks c > b and c <= max. Stores in TRIPLE-TABLE (up to 84 entries). | Agent-decided | `gameN.cob:173-195` (GENERATE-TRIPLES) |
| F-25 | **Parameterized DFS engine**. OWNER-TABLE, NEXT-TRY-TABLE, and MOVE-TABLE all sized to 15 (max allowed). DFS-STEP uses MAX-NUM instead of hardcoded 9. CHECK-WIN iterates over NUM-TRIPLES (dynamic) instead of hardcoded 8. | Agent-decided (generalization) | `gameN.cob:42-49, 283-327` (DFS-STEP), `gameN.cob:329-339` (CHECK-WIN) |
| F-26 | **Auto-derivation of max-number**. When second argument is omitted, computes `MAX-NUM = TARGET-SUM - 3`, capped to [3, 15]. Heuristic ensures the number pool is large enough for meaningful play. | Agent-decided | `gameN.cob:146-154` |
| F-27 | **Input validation with error messages**. Three checks: max-number > 15 (array bounds), max-number < 3 (too few numbers), target-sum < 6 (minimum triple is 1+2+3=6). Each prints an error and does STOP RUN. | Agent-decided | `gameN.cob:156-171` |
| F-28 | **Usage message**. Displayed when no arguments given. Shows syntax, parameter descriptions, and three examples. | Agent-decided | `gameN.cob:117-133` |
| F-29 | **Rules display with game character commentary**. After listing winning triples, prints qualitative observations: "No winning triples exist!" / "Few winning triples: games tend to end in draws" / "Many winning triples: games tend to end quickly." | Agent-decided | `gameN.cob:197-281` (DISPLAY-RULES), commentary at `gameN.cob:267-280` |
| F-30 | **Classic Game of 15 detection**. When TARGET-SUM=15 and MAX-NUM=9, prints a note about the tic-tac-toe isomorphism via the magic square. | Agent-decided | `gameN.cob:259-265` |
| F-31 | **Enumeration guard for large games**. If MAX-NUM > 9, skips DFS (too many permutations) and prints a message instead of hanging. | Agent-decided | `gameN.cob:83, 106-109` |

## Summary

| Category | Count | Example IDs |
|----------|-------|-------------|
| Total features implemented | 31 | F-01 to F-31 |
| Explicitly requested by user | 5 | F-01 (counter), F-06 (--unique flag), F-10 (tree), F-17 (avoid concept), F-21 (0.15 adaptation) |
| Agent-decided (implementation choices) | 26 | F-02 to F-05, F-07 to F-09, F-11 to F-16, F-18 to F-20, F-22 to F-31 |
| Bug fixes (self-detected) | 2 | F-19, F-20 |

The user made 6 feature requests that resulted in 31 implemented capabilities. The agent autonomously decided the algorithms (iterative DFS, minimax, base-3 memoization), data representations (OWNER-TABLE, SYM-TABLE, TRIPLE-TABLE), display mechanisms (ASCII tree connectors, avoid lines), and defensive features (input validation, usage messages, enumeration guards).
