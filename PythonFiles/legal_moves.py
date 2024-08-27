import chess
import re
import json
import sys

def main():
    args = sys.argv

    move_sequence = eval(args[1])

    legal_moves = generate_legal_moves(move_sequence)

    print(legal_moves)

    return legal_moves

def generate_legal_moves(sequence):
    board = chess.Board()
    for i in range(len(sequence)):
        board.push(chess.Move.from_uci(str(sequence[i])))
        
    legal_moves = list(board.legal_moves)
    s = str(legal_moves)

    matches = re.findall(r"Move\.from_uci\('(.+?)'\)", s)
    moves = list(matches)
        
    return moves 

if __name__ == "__main__":
    main()