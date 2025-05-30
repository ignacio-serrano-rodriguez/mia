import math

# --- Constantes y Clases Fundamentales ---

PLAYER_X = 'X'  # Define la marca para el jugador X
PLAYER_O = 'O'  # Define la marca para el jugador O

class State:
    # Define los posibles estados del juego
    DRAW    = "DRAW"    # Estado de empate
    OVER    = "OVER"    # Estado de juego terminado (alguien ganó)
    PLAYING = "PLAYING" # Estado de juego en curso

class TicTacBoard:
    # Representa el tablero y la lógica del juego Tres en Raya para un tablero de n x n
    def __init__(self, n=3):
        if n < 3:
            raise ValueError("El tamaño del tablero (n) debe ser al menos 3.")
        self.n = n
        # Inicializa el tablero como una cuadrícula de n x n vacía
        self.board = [[' ' for _ in range(n)] for _ in range(n)]
        self.winner = None  # Almacena quién ganó (PLAYER_X o PLAYER_O), o None si nadie ha ganado aún
        self.moves_history = [] # Guarda el historial de movimientos (coordenadas)

    def print_board(self):
        # Imprime el estado actual del tablero en la consola
        print("\nTablero actual")
        header = "   " + " ".join([str(i+1) for i in range(self.n)])
        print(header)
        print("  +" + "--"*self.n + "-+")
        for i, row in enumerate(self.board):
            print(f"{i+1} | " + " ".join(row) + " |")
        print("  +" + "--"*self.n + "-+")


    def get_possible_moves(self):
        # Devuelve una lista de todos los movimientos válidos (casillas vacías)
        moves = []
        for r in range(self.n): # Itera sobre las filas
            for c in range(self.n): # Itera sobre las columnas
                if self.board[r][c] == ' ': # Si la casilla está vacía
                    moves.append((r, c)) # Agrega la coordenada (fila, columna) a la lista de movimientos
        return moves

    def make_move(self, move, mark): # Realiza un movimiento en el tablero
        # move: una tupla (fila, columna)
        # mark: la marca del jugador (PLAYER_X o PLAYER_O)
        r, c = move
        if 0 <= r < self.n and 0 <= c < self.n and self.board[r][c] == ' ': # Si la casilla está vacía y dentro de los límites
            self.board[r][c] = mark # Coloca la marca del jugador
            self.moves_history.append(move) # Registra el movimiento
            self._check_win() # Verifica si este movimiento resultó en una victoria
        else:
            # Este error no debería ocurrir si se usa get_possible_moves() correctamente
            # y la validación de entrada del usuario es correcta.
            print(f"´\nError: Movimiento inválido en {move} para el tablero {self.n}x{self.n}")


    def undo(self):
        # Deshace el último movimiento realizado
        if not self.moves_history: # Si no hay movimientos para deshacer
            return
        last_move = self.moves_history.pop() # Obtiene y elimina el último movimiento del historial
        r, c = last_move
        self.board[r][c] = ' ' # Limpia la casilla en el tablero
        self.winner = None # Anula cualquier ganador, ya que el estado del juego cambió

    def _check_win(self):
        # Método privado para verificar si hay un ganador después de un movimiento
        
        # Comprobar filas
        for r in range(self.n):
            if self.board[r][0] != ' ' and all(self.board[r][c] == self.board[r][0] for c in range(self.n)):
                self.winner = self.board[r][0]
                return

        # Comprobar columnas
        for c in range(self.n):
            if self.board[0][c] != ' ' and all(self.board[r][c] == self.board[0][c] for r in range(self.n)):
                self.winner = self.board[0][c]
                return

        # Comprobar diagonal principal (top-left to bottom-right)
        if self.board[0][0] != ' ' and all(self.board[i][i] == self.board[0][0] for i in range(self.n)):
            self.winner = self.board[0][0]
            return

        # Comprobar diagonal secundaria (top-right to bottom-left)
        if self.board[0][self.n - 1] != ' ' and all(self.board[i][self.n - 1 - i] == self.board[0][self.n - 1] for i in range(self.n)):
            self.winner = self.board[0][self.n - 1]
            return
        
        # Si no se encontró ninguna línea ganadora, self.winner permanece None

    def get_winner(self):
        # Devuelve la marca del jugador ganador, o None si no hay ganador
        return self.winner

    def get_state(self):
        # Devuelve el estado actual del juego
        if self.winner: # Si hay un ganador
            return State.OVER # El juego terminó
        if not self.get_possible_moves(): # Si no hay ganador Y no quedan movimientos posibles
            return State.DRAW # Es un empate
        return State.PLAYING # De lo contrario, el juego sigue en curso

# --- Función de Evaluación Separada ---
def evaluate_board(board, maximizer_mark):
    """
    Evalúa el estado final del tablero y devuelve una puntuación.
    +1 si el maximizador gana.
    -1 si el minimizador (oponente) gana.
    0 si es un empate.
    """
    current_state = board.get_state()
    if current_state == State.DRAW:
        return 0
    if current_state == State.OVER:
        winner = board.get_winner()
        if winner == maximizer_mark:
            return 1  # Maximizador gana
        else:
            return -1 # Minimizador (oponente) gana
    # Esta función solo debería ser llamada para estados terminales en este contexto.
    return None # Opcionalmente, lanzar un error si se llama inesperadamente.

'''
    --- Algoritmo Minimax ---
    Este algoritmo ayuda a la IA a decidir cuál es el mejor movimiento.
    Funciona explorando todos los posibles movimientos futuros y eligiendo el que
    maximiza su puntuación (si es el turno de la IA) o minimiza la puntuación del oponente.
    Ahora también devuelve el movimiento que lleva a esa puntuación desde el nivel actual.
    Nota: Para tableros más grandes (n > 3 o 4), el algoritmo Minimax puede volverse muy lento 
    debido al crecimiento exponencial del árbol de búsqueda. Se requerirían optimizaciones
    como la poda Alfa-Beta o limitar la profundidad de búsqueda para tableros grandes.
'''
def minimax(board, is_maximizing_turn, maximizer_mark, depth):
    # board: el estado actual del tablero
    # is_maximizing_turn: True si es el turno del jugador que quiere maximizar la puntuación (IA), False si es el turno del minimizador (oponente)
    # maximizer_mark: la marca del jugador que intenta maximizar (la IA)
    # depth: la profundidad actual en el árbol de búsqueda (no se usa para limitar en esta versión)

    current_state = board.get_state()

    # Casos base de la recursión: usan la función de evaluación separada
    if current_state == State.DRAW or current_state == State.OVER:
        score = evaluate_board(board, maximizer_mark)
        return score, None  # Puntuación, Movimiento

    opponent_mark = PLAYER_O if maximizer_mark == PLAYER_X else PLAYER_X
    
    best_move_at_this_level = None

    if is_maximizing_turn: # Turno de la IA (quiere la puntuación más alta)
        best_score = -math.inf
        possible_moves = board.get_possible_moves()

        for move in possible_moves:
            board.make_move(move, maximizer_mark)
            score_of_resulting_state, _ = minimax(board, False, maximizer_mark, depth + 1)
            board.undo()
            
            if score_of_resulting_state > best_score:
                best_score = score_of_resulting_state
                best_move_at_this_level = move
        return best_score, best_move_at_this_level
    
    else: # Turno del oponente (quiere la puntuación más baja para la IA)
        best_score = math.inf
        possible_moves = board.get_possible_moves()

        for move in possible_moves:
            board.make_move(move, opponent_mark)
            score_of_resulting_state, _ = minimax(board, True, maximizer_mark, depth + 1)
            board.undo()

            if score_of_resulting_state < best_score:
                best_score = score_of_resulting_state
                best_move_at_this_level = move
        return best_score, best_move_at_this_level

def get_best_move(board, ai_mark):
    # Encuentra el mejor movimiento para la IA en el estado actual del tablero
    # ai_mark: la marca de la IA
    _, best_move = minimax(board, True, ai_mark, 0)
    return best_move

# --- Lógica Principal del Juego ---
def play_game():
    board_size = 0
    while True:
        try:
            board_size_input = input("Introduce el tamaño del tablero (e.g., 3 para 3x3, 4 para 4x4, mínimo 3): ")
            board_size = int(board_size_input)
            if board_size >= 3:
                break
            else:
                print("El tamaño del tablero debe ser al menos 3.")
        except ValueError:
            print("Entrada inválida. Por favor, introduce un número entero.")

    game_board = TicTacBoard(n=board_size)
    human_player = PLAYER_X
    ai_player = PLAYER_O
    current_player = human_player # El humano empieza

    print(f"\nTres en Raya (Tic Tac Toe) {board_size}x{board_size} con Minimax")
    game_board.print_board()

    while game_board.get_state() == State.PLAYING:
        if current_player == human_player:
            print(f"\nTurno del Humano ({human_player})")
            try:
                row_input = int(input(f"Elige fila (1-{board_size}): "))
                col_input = int(input(f"Elige columna (1-{board_size}): "))

                move = (row_input - 1, col_input - 1) # Convertir a coordenadas 0-indexadas

                if 0 <= move[0] < board_size and 0 <= move[1] < board_size and move in game_board.get_possible_moves():
                    game_board.make_move(move, human_player)
                    current_player = ai_player
                else:
                    print(f"\nMovimiento inválido. Asegúrate de elegir una casilla vacía y usar los números 1-{board_size}. Intenta de nuevo.")
            except ValueError:
                print("Entrada inválida. Ingresa números.")
        else: # Turno de la IA
            print(f"\nTurno de la IA ({ai_player})")
            print("Calculando movimiento...") # Añadido para feedback en tableros grandes
            move = get_best_move(game_board, ai_player)
            if move:
                print(f"Fila elegida por IA: {move[0] + 1}, Columna elegida por IA: {move[1] + 1}")
                game_board.make_move(move, ai_player)
                current_player = human_player
            else:
                # Esto no debería ocurrir si hay movimientos posibles y el juego no ha terminado.
                # Podría ocurrir si minimax no encuentra un movimiento válido, lo cual sería un error.
                print(f"Error: IA ({ai_player}) no pudo encontrar un movimiento.")
                break 
        
        game_board.print_board()
        
        final_state = game_board.get_state()
        if final_state != State.PLAYING:
            if final_state == State.DRAW:
                print("\n¡Es un empate!")
            else: # State.OVER, alguien ganó
                winner = game_board.get_winner()
                if winner == human_player:
                    print(f"¡Felicidades! ¡El jugador Humano ({winner}) ha ganado!")
                else:
                    print(f"\n¡La IA ({winner}) ha ganado!")
            break

if __name__ == "__main__":
    play_game()
