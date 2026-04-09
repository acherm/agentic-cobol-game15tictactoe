# Replay Prompts

Reusable prompts for reproducing the Game of 15 COBOL project step by step. Each prompt is self-contained enough to copy-paste into a coding agent session. They specify **what** to build (behavior, inputs, outputs, verification), not **how** (no algorithm names, no data structure prescriptions, no COBOL-specific idioms).

Use them sequentially: each step builds on the previous one.

For reference on what was actually built (algorithms chosen, bugs encountered, autonomous decisions), see [SPECIFICATION_BACKLOG.md](SPECIFICATION_BACKLOG.md).

---

## Step 1: Game Counter

> Write a COBOL program (GnuCOBOL) for the "Game of 15".
>
> Rules: Two players alternate picking a number from {1, 2, ..., 9}. A number cannot be picked twice. A player wins when any three of their chosen numbers sum to exactly 15. If all nine numbers are picked and no player has won, the game is a draw.
>
> The program should enumerate every possible game (every legal sequence of moves to completion) and report:
> - Player 1 wins (player who picks first)
> - Player 2 wins
> - Draws
> - Total games
>
> Expected output for verification:
> ```
> Player 1 wins:   131184
> Player 2 wins:    77904
> Draws:            46080
> Total games:     255168
> ```

---

## Step 2: Symmetry Deduplication

> Add a `--unique` command-line flag to the game counter.
>
> The Game of 15 is isomorphic to Tic-Tac-Toe. The numbers 1-9 can be arranged in a 3x3 magic square where rows, columns, and diagonals each sum to 15:
>
> ```
> 2  7  6
> 9  5  1
> 4  3  8
> ```
>
> This means the Game of 15 inherits the same board symmetries as Tic-Tac-Toe: rotations and reflections of the square (8 symmetries total). Two games that are identical up to such a symmetry should be counted as one.
>
> When `--unique` is passed, additionally report the number of games after removing symmetric duplicates. Keep reporting the original (non-deduplicated) totals as well.
>
> Expected output for verification:
> ```
> Unique games (modulo symmetry)
> Player 1 wins:    16398
> Player 2 wins:     9738
> Draws:             5760
> Total games:      31896
> ```

---

## Step 3: Optimal Play Tree

> Write a new COBOL program that displays the Game of 15 optimal play tree as ASCII art.
>
> "Optimal play" means both players play to maximize their own outcome: Player 1 tries to win (or at least draw), Player 2 tries to win (or at least draw). Under optimal play, the Game of 15 always ends in a draw (since it is equivalent to Tic-Tac-Toe).
>
> The tree should show only optimal moves (moves that do not worsen the position). Each node displays the move (e.g., "P1:5") and the outcome under optimal play from that position ("[Draw]", "[P1 wins]", or "[P2 wins]"). Use tree connectors for readability (`|--` for siblings, `+--` for the last child).
>
> Support a `--depth N` flag to limit how deep the tree is displayed. Nodes beyond the depth limit should be shown with `...` to indicate continuation. Without the flag, display the full tree.
>
> Example (depth 2):
> ```
> Game of 15 - Optimal Play Tree [Draw]
> |-- P1:1 [Draw]
> |   |-- P2:5 [Draw] ...
> |   +-- P2:6 [Draw] ...
> |-- P1:2 [Draw]
> |   +-- P2:5 [Draw] ...
> ...
> ```
>
> Verification: the full tree (no depth limit) should have 3,584 terminal draw positions and 0 forced wins.

---

## Step 4: Avoid Annotations

> Enhance the optimal play tree: at each decision point, before listing the optimal (safe) moves, show which available moves would be mistakes.
>
> For each position, classify every available move as either:
> 1. **Safe/optimal**: playing it does not worsen the outcome (the position stays at the same value under optimal play)
> 2. **Bad**: playing it lets the opponent reach a better outcome than they could otherwise
>
> Before the branches for safe moves, print an `avoid:` line listing all bad moves (comma-separated). If there are no bad moves, omit the line.
>
> Example:
> ```
> |-- P1:1 [Draw]
> |   avoid: 2, 3, 4, 7
> |   |-- P2:5 [Draw] ...
> |   |-- P2:6 [Draw] ...
> |   |-- P2:8 [Draw] ...
> |   +-- P2:9 [Draw] ...
> ```
>
> This means after P1 picks 1, picking 2, 3, 4, or 7 would be mistakes for P2 (they would allow P1 to win), while 5, 6, 8, 9 are safe responses.

---

## Step 5: Game of 0.15 Variant

> The "Game of 0.15" is defined as follows: two players alternate picking a number among {0.01, 0.02, ..., 0.09}. A number cannot be repeated. A player wins when three of their numbers sum to 0.15. If all numbers are used with no winner, the game is a draw.
>
> This is mathematically identical to the Game of 15 (every number is simply divided by 100), so the game counts and optimal play tree are the same.
>
> Create two programs:
> - `game015.cob`: game counter (same logic as Step 1+2, but displays numbers as "0.01" through "0.09" and the target as "0.15")
> - `game015tree.cob`: optimal play tree with avoid annotations (same logic as Step 3+4, but displays moves as "P1:0.05" instead of "P1:5")
>
> The game counts should be identical to the Game of 15. Only the display format changes.

---

## Step 6: Parameterized Variant Generator

> Write a COBOL program that generalizes the game to any target sum and number range.
>
> Usage: `./gameN <target-sum> [<max-number>]`
>
> The "Game of N" is played with numbers {1, 2, ..., max-number}. Two players alternate picking; a player wins when three of their numbers sum to exactly target-sum. If all numbers are used with no winner, it is a draw.
>
> The program should:
> 1. Find all "winning triples": sets of three distinct numbers from the pool that sum to the target
> 2. Display the rules, the number pool, and all winning triples
> 3. If max-number is small enough (9 or fewer), enumerate all possible games and report win/draw counts
> 4. If max-number is not provided, choose a reasonable default based on the target sum
>
> Include input validation and a usage message when run without arguments.
>
> Test cases:
> ```
> ./gameN 15 9    -> 255,168 total games, 8 winning triples (classic Game of 15)
> ./gameN 12 8    -> 34,704 total games, 6 winning triples
> ./gameN 10 7    -> 4,752 total games, 4 winning triples
> ```
