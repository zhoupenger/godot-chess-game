extends Sprite2D

const BOARD_SIZE = 8 # 8个格子
const CELL_WIDTH = 16 # 每个格子18px

const TEXTURE_HOLDER = preload("res://scenes/texture_holder.tscn")

var BLACK_BISHOP 
var BLACK_KING 
var BLACK_KNIGHT 
var BLACK_PAWN 
var BLACK_QUEEN
var BLACK_ROOK 

var WHITE_BISHOP 
var WHITE_KING 
var WHITE_KNIGHT 
var WHITE_PAWN
var WHITE_QUEEN
var WHITE_ROOK

const PIECE_MOVE = preload("res://assets/chess/Piece_move.png")

# 重要变量
# -6 = black king
# -5 = black queen
# -4 = black rook
# -3 = black bishop
# -2 = black knight
# -1 = black pawn
var could_play : bool = true
var board : Array # 存储棋盘的初始化位置
var white : bool = true # 是否为白棋的轮次
var state : bool = false # 是否选中，要先选中再考虑移动
var moves = [] # 存储被选择棋子所有可能的move
var selected_piece : Vector2
var board_sequence : Array = [] # board的临时位置
var true_board_sequence : Array = [] # board的真实位置
var ai_best_move : Dictionary 
var str_arr : String # 字符串格式的array，用于给python传参

var white_first_move = ["g1h3", "g1f3", "b1c3", "b1a3", "h2h3", "g2g3", "f2f3", "e2e3", "d2d3", "c2c3", "b2b3", "a2a3", "h2h4", "g2g4", "f2f4", "e2e4", "d2d4", "c2c4", "b2b4", "a2a4"]
# 当前状态下所有合法的moves
var legal_moves : Array = []

var flip : bool = false # 是否翻转
var change_board : bool = false
var first_move : bool = true # 是否是第一步

# AI
#var DIR = OS.get_executable_path().get_base_dir()
var interpreter_path : String
var script_path : String
var script_path_2 : String
var script_path_3 : String
var stockfish_path : String = ProjectSettings.globalize_path("res://PythonFiles/stockfish")

#var move_sequence : String

@onready var pieces = $Pieces # 棋子
@onready var dots = $Dots
@onready var gameboard = $"." # 棋盘
@onready var self_move_sound = $self_move_sound

func _ready():
	if !OS.has_feature("standalone"): # if NOT exported version
		interpreter_path = ProjectSettings.globalize_path("res://PythonFiles/venv/bin/python3.10")
		script_path = ProjectSettings.globalize_path("res://PythonFiles/chess_engine.py")
		script_path_2 = ProjectSettings.globalize_path("res://PythonFiles/legal_moves.py")
		script_path_3 =  ProjectSettings.globalize_path("res://PythonFiles/winorlose.py")
	
	# 翻转那么棋盘也要翻转
	if flip:
		gameboard.flip_h = !gameboard.flip_h
		gameboard.flip_v = !gameboard.flip_v
	
	# 换棋盘
	if change_board:
		cooler_board()
	else:
		ordinary_board()
	
	# 初始化棋子摆放
	# 即使翻转棋盘，board的构成也不能变，因为它会直接与象棋引擎通讯
	board.append([4, 2, 3, 5, 6, 3, 2, 4])
	board.append([1, 1, 1, 1, 1, 1, 1, 1])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([-1, -1, -1, -1, -1, -1, -1, -1])
	board.append([-4, -2, -3, -5, -6, -3, -2, -4])
	
	display_board()

func _input(event):
	# 鼠标左击并且不是flip的情况
	if event is InputEventMouseButton && event.pressed && !flip && could_play:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if is_mouse_out(): return # 不在棋盘上
			# 如果点在棋盘上
			# var1是列，var2是行，从0开始
			var var1 = snapped(get_global_mouse_position().x, 0) / CELL_WIDTH
			var var2 = abs(snapped(get_global_mouse_position().y, 0)) / CELL_WIDTH
			
			if var1 > 7 || var2 > 7: return
						
			# 没有选中棋子，该白棋/黑棋走，选择的是合法棋子
			if (!state && (white && board[var2][var1] > 0)) || (!state && (!white && board[var2][var1] < 0)):

				selected_piece = Vector2(var2, var1)
				
				# 如果是第一次，合法行动是white_first_move
				if first_move:
					# 开始个小剧情
					#Dialogic.start("timeline")
					
					moves = find_legal_moves(white_first_move, selected_piece)
					
				else:
					# legal_moves是当前状态下所有合法moves,是由AI走后顺手生成的
					moves = find_legal_moves(legal_moves, selected_piece) # 由后台生成的合法行动
					
				# 只要选中棋子我们就记录
				var move = transform_pos_to_uci(var1, var2)
				board_sequence.append(move)
				
				# 根据得到的moves展示所选棋子的选择
				show_options()
				
				state = true # 棋子已经被选择
			
			elif state: # 如果棋子处于选中状态，并且点击了一个坐标
				
				set_move(var2, var1)
				state = false
				# set_move会返回一个str_arr代表行动路径，用于AI进行判断
				#set_ai_move(str_arr)
	
	elif event is InputEventMouseButton && event.pressed && flip && could_play:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if is_mouse_out(): return # 不在棋盘上
			var var1 = snapped(get_global_mouse_position().x, 0) / CELL_WIDTH
			var var2 = abs(snapped(get_global_mouse_position().y, 0)) / CELL_WIDTH
			var2 = 7 - var2 # 特殊处理
			var1 = 7 - var1 
			if var1 > 7 || var2 > 7: return
			
			if first_move:
				# 让AI先走
				set_ai_move("AI GO!") # 走完后顺便把legal moves返回
				first_move = false
						
			if (!state && (white && board[var2][var1] > 0)) || (!state && (!white && board[var2][var1] < 0)):
				selected_piece = Vector2(var2, var1)
				
				# legal_moves是当前状态下所有合法moves,是由AI走后顺手生成的
				moves = find_legal_moves(legal_moves, selected_piece) # 由后台生成的合法行动
						
				# 只要选中棋子我们就记录
				var move = transform_pos_to_uci(var1, var2)
				board_sequence.append(move)
				
				# 根据得到的moves展示所选棋子的选择
				show_options()
				
				state = true # 棋子已经被选择
			
			elif state: # 如果棋子处于选中状态，并且点击了一个坐标
				
				set_move(var2, var1)
				state = false


func set_move(var2: int, var1: int):
	# 先检查这个点击的这个坐标在不在合法路径中
	for i in moves:
		# 该坐标位于合法行动集合里
		if i.x == var2 && i.y == var1:
			# 已经不是第一次走了
			first_move = false
			# 选中棋子并且走的合法，记录在board_sequence里面
			delete_dots()
			var move = transform_pos_to_uci(var1, var2)
			board_sequence.append(move)
			
			# 这时候把最后两个元素组合在一起，就是真实的行动
			var last_element = board_sequence[board_sequence.size()-1]
			var second_last_element = board_sequence[board_sequence.size()-2]
			true_board_sequence.append(second_last_element + last_element)
			board_sequence = []
			#print(true_board_sequence)
			
			# 异常的走子方式我们需要更新下board
			var is_king_move : bool = check_king_rook(var2, var1, selected_piece)
			var is_promotion : bool = check_promotion(var2, var1, selected_piece)
			
			# 如果这两个都没触发
			if !is_king_move && !is_promotion:

				#board该坐标棋子更新为selected_piece，原来的位置更新为空白0
				board[var2][var1] = board[selected_piece.x][selected_piece.y]
				board[selected_piece.x][selected_piece.y] = 0
				white = !white
			
			# 到这里是把move_sequence更新到board数组里
			
			# 如果升变了，要指定变成什么，比如说b7b8q
			if is_promotion:
				true_board_sequence[-1] = true_board_sequence[-1] + 'q'
			
			print(true_board_sequence)
			
			# 使用map()函数将数组中的每个元素转化为带有引号的字符串
			var new_arr = true_board_sequence.map(func(e): return "'" + e + "'")
			# 使用join()函数将新的数组转化为一个字符串
			str_arr = "[" + ", ".join(new_arr) + "]"
			
			display_board()
			self_move_sound.play()
			
			# 在这里休息1s
			await get_tree().create_timer(1).timeout
			
			is_game_over(str_arr)
			
			if could_play:
				set_ai_move(str_arr) # 现在可以让AI决策了		
			
			break
		
		else:
			# 如果坐标无效 
			delete_dots()
	
		
func set_ai_move(str_arr: String):
	
	var from_position : Vector2
	var to_position : Vector2
	
	if flip && first_move: 
		# AI先走并且第一步
		from_position = Vector2(1, 4)
		to_position = Vector2(3, 4)
	else:
		# AI调用python考虑下一步怎么走
		var best_move_uci = ai_move_decision(stockfish_path, str_arr)
		ai_best_move = transform_uci_to_pos(best_move_uci)
		from_position = ai_best_move['from_position']
		to_position = ai_best_move['to_position']

	# 把AI的行动添加到true_board_sequence里
	var second_last_element = transform_pos_to_uci(from_position.y, from_position.x)
	var last_element = transform_pos_to_uci(to_position.y, to_position.x)
	true_board_sequence.append(second_last_element + last_element)
	
	# 更新board
	#异常的走子方式我们需要更新下board
	var is_king_move : bool = check_king_rook(to_position.x, to_position.y, from_position)
	var is_promotion : bool = check_promotion(to_position.x, to_position.y, from_position)
	
	# 如果AI升变了
	if is_promotion:
		true_board_sequence[-1] = true_board_sequence[-1] + 'q'
		
	print(true_board_sequence)

	# 如果这两个都没触发
	if !is_king_move && !is_promotion:

		#board该坐标棋子更新为selected_piece，原来的位置更新为空白0
		board[to_position.x][to_position.y] = board[from_position.x][from_position.y]
		board[from_position.x][from_position.y] = 0
		white = !white
	
	display_board()
	self_move_sound.play()
	
	# 使用map()函数将数组中的每个元素转化为带有引号的字符串
	var new_arr = true_board_sequence.map(func(e): return "'" + e + "'")
	# 使用join()函数将新的数组转化为一个字符串
	str_arr = "[" + ", ".join(new_arr) + "]"
	
	is_game_over(str_arr)
	
	if could_play:
	# AI行动完后要把当前局面拿去生成legal_moves以便下一步人使用
		generate_legal_moves_array(str_arr)


# ----- 渲染函数 -----
func show_options():
	# 如果选中棋子没有可行的move
	if moves == []:
		state = false # 棋子不能正常选中
		return
	show_dots()

func show_dots():
	if !flip:
		for i in moves:
			var holder = TEXTURE_HOLDER.instantiate()
			dots.add_child(holder)
			holder.texture = PIECE_MOVE
			holder.z_index = 2
			holder.global_position = Vector2(i.y * CELL_WIDTH + (CELL_WIDTH/2), -i.x * CELL_WIDTH - (CELL_WIDTH/2))
	
	else:
		for i in moves:
			var holder = TEXTURE_HOLDER.instantiate()
			dots.add_child(holder)
			holder.texture = PIECE_MOVE
			holder.z_index = 2
			holder.global_position = Vector2((7-i.y) * CELL_WIDTH + (CELL_WIDTH/2), -(7-i.x) * CELL_WIDTH - (CELL_WIDTH/2))



func delete_dots():
	for child in dots.get_children():
		child.queue_free()

func display_board():
	
	# 每次更新棋盘都要把原先实例化的棋子释放掉
	for child in pieces.get_children():
		child.queue_free()
		
	if !flip:
		#for i in BOARD_SIZE:
		for i in range(BOARD_SIZE - 1, -1, -1): # # 从最后一行开始到第一行
			for j in BOARD_SIZE:
				var holder = TEXTURE_HOLDER.instantiate() # 实例化纹理场景
				pieces.add_child(holder)  # 作为 pieces 的子节点
				# 根据 flip 的值来调整棋子的坐标
				var pos_x = j * CELL_WIDTH + (CELL_WIDTH / 2)
				var pos_y = -i * CELL_WIDTH - (CELL_WIDTH)
				holder.global_position = Vector2(pos_x, pos_y)
				
				# 渲染棋子
				# 根据棋子类型来设置 z-index 和 texture
				match board[i][j]:
					-6, 6:  # 国王和其他大棋
						holder.z_index = 1
						holder.texture = BLACK_KING if board[i][j] == -6 else WHITE_KING
					-5, 5:  # 王后和其他大棋
						holder.z_index = 1
						holder.texture = BLACK_QUEEN if board[i][j] == -5 else WHITE_QUEEN
					-4, 4:
						holder.z_index = 1
						holder.texture = BLACK_ROOK if board[i][j] == -4 else WHITE_ROOK
					-3, 3:
						holder.z_index = 1
						holder.texture = BLACK_BISHOP if board[i][j] == -3 else WHITE_BISHOP
					-2, 2:
						holder.z_index = 1
						holder.texture = BLACK_KNIGHT if board[i][j] == -2 else WHITE_KNIGHT
					-1, 1:  # 兵
						holder.z_index = 0  # 确保兵在大棋下方
						holder.texture = BLACK_PAWN if board[i][j] == -1 else WHITE_PAWN
					0:
						holder.texture = null	
	
	else: #如果选择翻转:
		#for i in BOARD_SIZE: # 对于翻转，我们需要从棋盘的下方开始遍历
		for i in range(BOARD_SIZE - 1, -1, -1):
			for j in BOARD_SIZE:
				var holder = TEXTURE_HOLDER.instantiate() # 实例化纹理场景
				pieces.add_child(holder)  # 将其作为 pieces 的子节点
				# 对于翻转的处理，我们需要调整 pos_x 和 pos_y 来翻转棋盘。使用7-i和7-j来计算正确的位置
				var pos_x = j * CELL_WIDTH + (CELL_WIDTH / 2)
				var pos_y = -i * CELL_WIDTH - (CELL_WIDTH)
				holder.global_position = Vector2(pos_x, pos_y)
				# 渲染棋子
				# 渲染逻辑保持不变
				match board[7-i][7-j]: # 注意这里的 index 变化
					-6, 6:
						holder.z_index = 1
						holder.texture = BLACK_KING if board[7-i][7-j] == -6 else WHITE_KING
					-5, 5:
						holder.z_index = 1
						holder.texture = BLACK_QUEEN if board[7-i][7-j] == -5 else WHITE_QUEEN
					-4, 4:
						holder.z_index = 1
						holder.texture = BLACK_ROOK if board[7-i][7-j] == -4 else WHITE_ROOK
					-3, 3:
						holder.z_index = 1
						holder.texture = BLACK_BISHOP if board[7-i][7-j] == -3 else WHITE_BISHOP
					-2, 2:
						holder.z_index = 1
						holder.texture = BLACK_KNIGHT if board[7-i][7-j] == -2 else WHITE_KNIGHT
					-1, 1:
						holder.z_index = 0
						holder.texture = BLACK_PAWN if board[7-i][7-j] == -1 else WHITE_PAWN
					0:
						holder.texture = null
	
	

# ----- 工具函数 -----
# 检查是否在棋盘外
func is_mouse_out():
	# 检查sprite2D是否被点击
	if get_rect().has_point(to_local(get_global_mouse_position())): return false
	return true

# 查找点击棋子的legal moves
func find_legal_moves(legal_list : Array, touch_pos : Vector2):
	if !flip or flip:
		var piece_legal_moves : Array = []
		for i in range(len(legal_list)):
			var item : String = legal_list[i] 
			var could_move_pos = transform_uci_to_pos(item)
		
			if could_move_pos['from_position'] == touch_pos:
				piece_legal_moves.append(could_move_pos['to_position'])

		return piece_legal_moves

# 把uci码转化为pos: e4 -> pos1 = 3, pos2 = 4
func transform_uci_to_pos(uci: String):

	var letters = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h']
	# 把a-h的字母替换成0-7
	var pos1 = letters.find(uci[0])
	var pos2 = int(uci[1]) - 1
	var pos3 = letters.find(uci[2])
	var pos4 = int(uci[3]) - 1
	
	return {"from_position": Vector2(pos2, pos1), "to_position": Vector2(pos4, pos3)}

# 把pos转化为uci: pos1 = 3, pos2 = 4 -> e4
func transform_pos_to_uci(pos1: int, pos2: int) -> String:

	var letters = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h']
	# 把0-7的数字替换成a-h
	var new_pos1 = letters[pos1]

	var uci_form = str(new_pos1) + str(pos2 + 1)

	return uci_form


# ----- 游戏判定函数 -----
func check_king_rook(var2: int, var1: int, select: Vector2):
	
	if white && select.x == 0 && select.y == 4 && board[select.x][select.y] == 6 && var2 == 0 && var1 == 6:			
		board[0][6] = board[select.x][select.y]
		board[0][5] = 4
		board[select.x][select.y] = 0
		board[0][7] = 0 
		white = !white
		return true
	elif white && select.x == 0 && select.y == 4 && board[select.x][select.y] == 6 && var2 == 0 && var1 == 2:			
		board[0][2] = board[select.x][select.y]
		board[0][3] = 4
		board[select.x][select.y] = 0
		board[0][0] = 0 
		white = !white
		return true
	elif !white && select.x == 7 && select.y == 4 && board[select.x][select.y] == -6 && var2 == 7 && var1 == 2:			
		board[7][2] = board[select.x][select.y]
		board[7][3] = -4
		board[select.x][select.y] = 0
		board[7][0] = 0 
		white = !white
		return true
	elif !white && select.x == 7 && select.y == 4 && board[select.x][select.y] == -6 && var2 == 7 && var1 == 6:			
		board[7][6] = board[select.x][select.y]
		board[7][5] = -4
		board[select.x][select.y] = 0
		board[7][7] = 0 
		white = !white
		return true
	return false

func check_promotion(var2: int, var1: int, select: Vector2):
	# 这里检查一下升变
	if white && board[select.x][select.y] == 1 && var2 == 7: # 白兵升变
		board[var2][var1] = 5
		board[select.x][select.y] = 0 
		white = !white
		return true
			
	elif !white && board[select.x][select.y] == -1 && var2 == 0: # 黑兵升变
		board[var2][var1] = -5
		board[select.x][select.y] = 0 
		white = !white
		return true
	return false

# ----- python接口函数 -----
func ai_move_decision(stockfish_path, move_sequence):
	var output = []
	var sequence_string = String(move_sequence)

	var err = OS.execute(interpreter_path, [script_path, stockfish_path, sequence_string], output)
	var best_move = output[0]
	print("Best_Move:", best_move)
	
	return str(best_move)

func generate_legal_moves(board_sequence):
	var output = []
	var sequence_string = String(board_sequence)
	
	var err = OS.execute(interpreter_path, [script_path_2, sequence_string], output)
	var legal_moves = output[0]
	print("Legal_Moves:", legal_moves)
	
	return legal_moves
	

func generate_legal_moves_array(str_arr : String):
	var str_moves = generate_legal_moves(str_arr)
	str_moves = str_moves.replace("'", "\"")
	# 更新全局变量legal_moves
	legal_moves = str_to_var(str_moves)
	
func is_game_over(board_sequence):
	var output = []
	var sequence_string = String(board_sequence)
	
	var err = OS.execute(interpreter_path, [script_path_3, sequence_string], output)
	var is_game_over = output[0]
	is_game_over = int(is_game_over)
	
	#print("Is_game_end:", is_game_over)
	
	if is_game_over == 0:
		print("CHECKMATE")
		could_play = false
	elif is_game_over == 1:
		print("DRAW")
		could_play = false
	elif is_game_over == 2:
		print("CONTINUE")
	
	return is_game_over


# ----- 一些特别功能的实现 -----
func cooler_board():
	BLACK_BISHOP = preload("res://assets/16x32 pieces/cooler_chesses/black_bishop.png")
	BLACK_KING = preload("res://assets/16x32 pieces/cooler_chesses/black_king.png")
	BLACK_KNIGHT = preload("res://assets/16x32 pieces/cooler_chesses/black_knight.png")
	BLACK_PAWN = preload("res://assets/16x32 pieces/cooler_chesses/black_pawn.png")
	BLACK_QUEEN = preload("res://assets/16x32 pieces/cooler_chesses/black_queen.png")
	BLACK_ROOK = preload("res://assets/16x32 pieces/cooler_chesses/black_rook.png")

	WHITE_BISHOP = preload("res://assets/16x32 pieces/cooler_chesses/white_bishop.png")
	WHITE_KING = preload("res://assets/16x32 pieces/cooler_chesses/white_king.png")
	WHITE_KNIGHT = preload("res://assets/16x32 pieces/cooler_chesses/white_knight.png")
	WHITE_PAWN = preload("res://assets/16x32 pieces/cooler_chesses/white_pawn.png")
	WHITE_QUEEN = preload("res://assets/16x32 pieces/cooler_chesses/white_queen.png")
	WHITE_ROOK = preload("res://assets/16x32 pieces/cooler_chesses/white_rook.png")
	
	var new_texture = load("res://assets/boards/board_plain_04.png")
	gameboard.texture = new_texture

func ordinary_board():
	BLACK_BISHOP = preload("res://assets/16x32 pieces/chesses/black_bishop.png")
	BLACK_KING = preload("res://assets/16x32 pieces/chesses/black_king.png")
	BLACK_KNIGHT = preload("res://assets/16x32 pieces/chesses/black_knight.png")
	BLACK_PAWN = preload("res://assets/16x32 pieces/chesses/black_pawn.png")
	BLACK_QUEEN = preload("res://assets/16x32 pieces/chesses/black_queen.png")
	BLACK_ROOK = preload("res://assets/16x32 pieces/chesses/black_rook.png")

	WHITE_BISHOP = preload("res://assets/16x32 pieces/chesses/white_bishop.png")
	WHITE_KING = preload("res://assets/16x32 pieces/chesses/white_king.png")
	WHITE_KNIGHT = preload("res://assets/16x32 pieces/chesses/white_knight.png")
	WHITE_PAWN = preload("res://assets/16x32 pieces/chesses/white_pawn.png")
	WHITE_QUEEN = preload("res://assets/16x32 pieces/chesses/white_queen.png")
	WHITE_ROOK = preload("res://assets/16x32 pieces/chesses/white_rook.png")
