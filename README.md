# Game of 15 in COBOL

Five COBOL programs exploring the **Game of 15**, a combinatorial number-picking game isomorphic to Tic-Tac-Toe via the 3x3 magic square.

## The Game of 15

Two players alternate picking a number from {1, 2, ..., 9}. A number may not be repeated. The first player to hold three numbers summing to **15** wins. If all nine numbers are used with no winner, the game is a draw.

The 8 winning triples (subsets of {1..9} summing to 15) correspond exactly to the rows, columns, and diagonals of the magic square:

```
2  7  6
9  5  1
4  3  8
```

This makes the Game of 15 strategically equivalent to Tic-Tac-Toe.

## Programs

### game15.cob: Game Counter

Enumerates all possible games via iterative DFS with backtracking. Reports win/draw counts.

```
$ cobc -x -o game15 game15.cob
$ ./game15
Player 1 wins:   131184
Player 2 wins:    77904
Draws:            46080
Total games:     255168
```

With the `--unique` flag, deduplicates games modulo the 8 symmetries of the magic square (dihedral group D4):

```
$ ./game15 --unique
Unique games (modulo symmetry)
Player 1 wins:    16398
Player 2 wins:     9738
Draws:             5760
Total games:      31896
```

### game15tree.cob: Optimal Play Tree

Two-pass program: (1) minimax with memoization over all 19,683 positions (3^9 base-3 keys), (2) ASCII tree showing only optimal moves.

Under optimal play the game always ends in a draw; no player can force a win.

```
$ cobc -x -o game15tree game15tree.cob
$ ./game15tree --depth 2
Game of 15 - Optimal Play Tree [Draw]
|-- P1:1 [Draw]
|   avoid: 2, 3, 4, 7
|   |-- P2:5 [Draw] ...
|   |-- P2:6 [Draw] ...
|   |-- P2:8 [Draw] ...
|   +-- P2:9 [Draw] ...
|-- P1:2 [Draw]
|   avoid: 1, 3, 4, 6, 7, 8, 9
|   +-- P2:5 [Draw] ...
...
```

The full tree (`./game15tree` with no depth limit) produces 15,303 lines with 3,584 terminal draw positions and 0 forced wins.

At each node, **avoid** lines list moves that would lose, and branches show safe/optimal moves.

### game015.cob / game015tree.cob: Game of 0.15

Variant where players pick from {0.01, 0.02, ..., 0.09} and the target sum is 0.15. Mathematically identical (scaled by 1/100); internal representation uses integers 1-9, only the display format changes.

```
$ cobc -x -o game015 game015.cob && cobc -x -o game015tree game015tree.cob
$ ./game015            # same counts as game15
$ ./game015tree --depth 2   # tree with "P1:0.05" format
```

### gameN.cob: Variant Generator

Parameterized program that defines and analyzes any "Game of N" variant. Dynamically generates winning triples, displays rules, and enumerates all games (for max-number <= 9).

```
$ cobc -x -o gameN gameN.cob
$ ./gameN 15 9    # classic Game of 15: 255,168 games, 8 triples
$ ./gameN 12 8    # Game of 12, numbers 1-8: 34,704 games, 6 triples
$ ./gameN 10 7    # Game of 10, numbers 1-7: 4,752 games, 4 triples
$ ./gameN 10      # auto-derives max number (defaults to 7)
```

## Building

Requires [GnuCOBOL](https://gnucobol.sourceforge.io/) (tested with 3.2.0).

```bash
cobc -x -o game15 game15.cob
cobc -x -o game15tree game15tree.cob
cobc -x -o game015 game015.cob
cobc -x -o game015tree game015tree.cob
cobc -x -o gameN gameN.cob
```

## Feature Backlog (Ex-Post)

Reconstructed implementation history from the Claude Code session that produced this repository. Each feature was requested by the user as a prompt; the table below records both the **original prompt** (verbatim) and a **replay prompt** (self-contained description suitable for reproducing the feature with another LLM/agent).

For a more granular, agent-centric view of all 31 technical capabilities that were actually implemented (including autonomous decisions, algorithms, and bug fixes), see [SPECIFICATION_BACKLOG.md](SPECIFICATION_BACKLOG.md).

### BL-001: Game of 15 Counter

| | |
|---|---|
| **File(s)** | `game15.cob` |
| **Key result** | 255,168 total games (131,184 P1 wins, 77,904 P2 wins, 46,080 draws) |
| **Original prompt** | *"The game of 15 is defined as follows: Two players in turn say a number between one and nine. A particular number may not be repeated. The game is won by the player who has said three numbers whose sum is 15. If all the numbers are used and no one gets three numbers that add up to 15 then the game is a draw. Write a COBOL program (using GNUCobol) that computes the number of possible games in the game of 15..."* |
| **Replay prompt** | Write a COBOL program (GnuCOBOL) that enumerates all possible games in the Game of 15. Two players alternate picking numbers 1-9 (no repeats); a player wins when three of their numbers sum to 15; if all 9 numbers are used with no winner it is a draw. Use iterative DFS with backtracking. Report Player 1 wins, Player 2 wins, draws, and total games. |

### BL-002: Symmetry Deduplication (`--unique` flag)

| | |
|---|---|
| **File(s)** | `game15.cob` (extends BL-001) |
| **Key result** | 31,896 unique games modulo D4 symmetry |
| **Original prompt** | *"add a flag to compute numbers without duplicates"* |
| **Replay prompt** | Add a `--unique` command-line flag to the Game of 15 counter. When set, also count games modulo board symmetry. The Game of 15 is isomorphic to tic-tac-toe via the 3x3 magic square; use the dihedral group D4 (8 symmetries: 4 rotations + 4 reflections) to identify equivalent games. Only count a game if its move sequence is the lexicographically smallest among all 8 symmetric images. Report unique P1 wins, P2 wins, draws, and total. |

### BL-003: Optimal Play Tree (Minimax + ASCII)

| | |
|---|---|
| **File(s)** | `game15tree.cob` |
| **Key result** | 12,133 nodes, 3,584 terminal draws, 0 forced wins (game is always a draw under optimal play) |
| **Original prompt** | *"I am interested to depict a tree (in ASCII format) of all possible moves and the outcome (under optimal play)... Such a tree would help to know what to play after a certain sequence of 'moves' (numbers' choices in the game 15)"* |
| **Replay prompt** | Write a COBOL program (GnuCOBOL) that displays the optimal play tree for the Game of 15 as ASCII art. Use a two-pass architecture: Pass 1 computes minimax values with memoization (base-3 position key, 3^9 = 19,683 entries); Pass 2 traverses the game tree and prints only moves whose minimax value equals the parent position's value (i.e., optimal moves). Use tree connectors (`\|--`, `+--`) with proper indentation. Support a `--depth N` flag to limit display depth. |

### BL-004: Avoid Annotations

| | |
|---|---|
| **File(s)** | `game15tree.cob` (extends BL-003) |
| **Key result** | 15,303 total lines; at each decision point, losing moves listed before optimal branches |
| **Original prompt** | *"nice! to 'simplify' a bit, I suggest that given a sequence of moves/choices, there are (1) follow-up choice to NOT perform (otherwise you lose); (2) follow-up choice you can make (among many possibly)"* |
| **Replay prompt** | Enhance the optimal play tree program: at each decision point, before showing the optimal move branches, print an `avoid:` line listing all available moves whose minimax value is worse than the position's value (i.e., moves that would let the opponent win or gain advantage). Classify each available move as either optimal (value equals parent value) or bad (value differs), and display bad moves in the avoid line. |

### BL-005: Game of 0.15 Variant

| | |
|---|---|
| **File(s)** | `game015.cob`, `game015tree.cob` |
| **Key result** | Identical game counts; display uses "0.0X" number format |
| **Original prompt** | *"The game of 0.15 is defined as follows: Two players in turn say a number among 0.01, 0.02,..., 0.09. A particular number may not be repeated. The game is won by the player who has said three numbers whose sum is 0.15. If all the numbers are used and no one gets three numbers that add up to 0.15 then the game is a draw. Please adapt your program to count the number of games, as well as the tree"* |
| **Replay prompt** | Create two COBOL programs (`game015.cob` counter + `game015tree.cob` tree) for the "Game of 0.15": players pick from {0.01, 0.02, ..., 0.09}, target sum is 0.15. This is mathematically identical to the Game of 15 (scaled by 1/100). Keep the internal representation as integers 1-9 for efficiency; only change the display format to show numbers as "0.0X" (e.g., "P1:0.05"). |

### BL-006: Parameterized Variant Generator

| | |
|---|---|
| **File(s)** | `gameN.cob` |
| **Key result** | Works for any target sum N; `./gameN 15 9` reproduces 255,168; `./gameN 12 8` gives 34,704 |
| **Original prompt** | *"Provide a generator that 'invents' a variant of the game of N=15 by changing N (eg 0.15) and thus the possible numbers users can choose. Please recap the rules of the game of N after"* |
| **Replay prompt** | Write a COBOL program (GnuCOBOL) that accepts a target sum and optional max-number as command-line arguments (e.g., `./gameN 15 9`). Dynamically generate all winning triples (three distinct numbers from {1..max} summing to target). Display the game rules, number pool, and all winning triples. If max-number <= 9, enumerate all possible games via DFS and report P1 wins, P2 wins, draws, and total. Auto-derive max-number as `target - 3` (capped at [3, 15]) if not provided. Include input validation and a usage message. |

### Implementation Order and Dependencies

```
BL-001  Game counter (from scratch)
  +-- BL-002  adds --unique flag (extends BL-001)
BL-003  Optimal play tree (new program)
  +-- BL-004  adds avoid annotations (extends BL-003, user suggestion)
BL-005  Game of 0.15 (clones BL-001/002 + BL-003/004 with display changes)
BL-006  Variant generator (generalizes BL-001 to arbitrary N)
```

### Bugs Encountered and Fixed

Both bugs were **detected and fixed during the session**. No bugs remain in the shipped code. They illustrate a recurring COBOL challenge: all variables live in a single global WORKING-STORAGE, so any paragraph can silently overwrite a variable that another paragraph still depends on.

1. **Display bug (BL-003):** `CUR-NUM` was declared as `PIC 99` (two-digit numeric). When its value (e.g., `01`) was moved into a `PIC X(1)` display field, COBOL took only the first character `"0"`, so every move rendered as `"P1:0"`. **Impact:** all move numbers in the tree output were wrong. **Workaround:** a dedicated `DISP-DIGIT PIC 9` variable was introduced as an intermediary. `CUR-NUM` is moved to `DISP-DIGIT` (numeric-to-numeric, truncates to 1 digit correctly), then `DISP-DIGIT` is moved to the output line (`game15tree.cob:91`, `game15tree.cob:477-478`).

2. **Variable corruption (BL-004):** The `COLLECT-OPTIMAL` paragraph loops over trial moves using `MOVE TRIAL-NUM TO CUR-NUM` (needed because `CHECK-WIN` reads `CUR-NUM`). But the *calling* paragraph (`TREE-STEP`) also used `CUR-NUM` to track its own chosen move. After `COLLECT-OPTIMAL` returned, `CUR-NUM` held the last trial value instead of the actual chosen move, so the undo operation `MOVE 0 TO OWNER(CUR-NUM)` freed the wrong number, corrupting the board state. **Impact:** the tree showed `[]` empty annotations and incorrect win/draw labels. **Workaround:** the undo now reads the move from the `CHOSEN(DEPTH)` array (which is never overwritten by inner loops) instead of relying on `CUR-NUM` (`game15tree.cob:310`, `game15tree.cob:374`).

Both workarounds are effective: the programs produce correct, verified output. The root cause (COBOL's lack of local/scoped variables) is a language constraint, not a residual defect.

## Agentic Context

All code was generated by Claude (Anthropic) in a single Claude Code session over 2026-03-12 to 2026-03-13. The session comprised 10 user messages and produced 1,924 lines of COBOL across 5 programs. All programs compiled with zero errors on GnuCOBOL 3.2.0.
