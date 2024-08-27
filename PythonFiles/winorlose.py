import chess
import re
import json
import sys

def main():
    args = sys.argv

    move_sequence = eval(args[1])

    is_over = is_game_over(move_sequence)

    print(is_over)

    return is_over

def is_game_over(sequence):
    board = chess.Board()
    for i in range(len(sequence)):
        board.push(chess.Move.from_uci(str(sequence[i])))
        
    # 游戏结束: 0
    is_checkmate = board.is_checkmate()

    # 平局结束: 1
    is_stalemate = board.is_stalemate()
    is_insufficient_material = board.is_insufficient_material()

    # 宣布平局: 2
    is_seventyfive_moves = board.is_seventyfive_moves()
    is_fivefold_repetition = board.is_fivefold_repetition()
    is_claim_draw = board.can_claim_draw()

    if is_checkmate: return 0 #checkmate
    elif is_stalemate or is_insufficient_material or is_seventyfive_moves or is_fivefold_repetition or is_claim_draw: return 1 #draw
    else: return 2 #continue

if __name__ == "__main__":
    main()

        

