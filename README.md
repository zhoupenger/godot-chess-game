# godot-chess-game

## Overview
I have implemented functionalities related to chess, including:
- Move validation
- Castling
- Pawn promotion
- Outcome determination for wins or draws in various situations

(I haven't implemented en passant captures, although I still considered it for judgments.)

Additionally, I have implemented features related to the game:
- AI battles - stockfish
- Different AI levels - by parameters in python
- Flipping the chessboard
- Changing the styles of the chessboard and pieces
- A simple dialogue system

It should be noted that for chess-related judgments, I have used two very convenient third-party Python libraries, python-chess and python-stockfish. With the help of these two libraries, we can implement these complex judgment functions in the background, therefore my code in GDScript will be relatively clear and concise.

## Implement
By adjusting several boolean variables in board.gd, we can switch modes.
```gdscript
var flip : bool = false # flip or not
var change_board : bool = false # change board or not

Dialogic.start("timeline") # start a demo dialog
```

## Visualization
No you could take a look

