from stockfish import Stockfish
import json
import sys

def main():
    args = sys.argv

    path = args[1]
    #parameters = json.loads(args[2]) 
    #move_sequence = json.loads(args[2]) 
    #move_sequence = list(json.loads(args[2]))
    move_sequence = eval(args[2])

    #print(move_sequence)

    best_move = ai_move_decision(path, move_sequence)

    print(best_move)

    return best_move

def ai_move_decision(stockfish_path, move_sequence):
    paras = {"Threads": 1, "Minimum Thinking Time": 30, "UCI_Elo": 600}
    #move_sequence = ["e2e4", "e7e5", "g1f3", "b8c6", "f1c4"]

    stockfish = Stockfish(path=stockfish_path, depth=5, parameters=paras)
    stockfish.set_position(move_sequence)
    best_move = stockfish.get_best_move()

    #print(str(best_move))

    return str(best_move)

if __name__ == "__main__":
    main()