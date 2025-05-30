import math

# Constantes
PLAYER_X = 'X'  # Define la marca para el jugador X
PLAYER_O = 'O'  # Define la marca para el jugador O

# Define los posibles estados del juego
class State:
    DRAW    = "DRAW"    # Estado de empate
    OVER    = "OVER"    # Estado de juego terminado (alguien ganó)
    PLAYING = "PLAYING" # Estado de juego en curso

# Representa el tablero y la lógica del juego Tres en Raya
class TicTacBoard:
    def __init__(self):
        # Inicializa el tablero como una cuadrícula de 3x3 vacía
        self.board = [[' ' for _ in range(3)] for _ in range(3)]
        self.winner = None  # Almacena quién ganó (PLAYER_X o PLAYER_O), o None si nadie ha ganado aún
        self.moves_history = [] # Guarda el historial de movimientos (coordenadas)

    def print_board(self):
        # Imprime el estado actual del tablero en la consola
        print("\nTablero actual")
        for row in self.board:
            print("|" + "|".join(row) + "|") # Une las celdas de cada fila con "|"

    def get_possible_moves(self):
        # Devuelve una lista de todos los movimientos válidos (casillas vacías)
        moves = []
        for r in range(3): # Itera sobre las filas
            for c in range(3): # Itera sobre las columnas
                if self.board[r][c] == ' ': # Si la casilla está vacía
                    moves.append((r, c)) # Agrega la coordenada (fila, columna) a la lista de movimientos
        return moves

    def make_move(self, move, mark): # Realiza un movimiento en el tablero
        # move: una tupla (fila, columna)
        # mark: la marca del jugador (PLAYER_X o PLAYER_O)
        r, c = move
        if self.board[r][c] == ' ': # Si la casilla está vacía
            self.board[r][c] = mark # Coloca la marca del jugador
            self.moves_history.append(move) # Registra el movimiento
            self._check_win() # Verifica si este movimiento resultó en una victoria
        else:
            # Este error no debería ocurrir si se usa get_possible_moves() correctamente
            print(f"´\nError: Movimiento inválido en {move}")


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
        for r in range(3):
            if self.board[r][0] == self.board[r][1] == self.board[r][2] and self.board[r][0] != ' ':
                self.winner = self.board[r][0] # El ganador es la marca en esa fila
                return

        # Comprobar columnas
        for c in range(3):
            if self.board[0][c] == self.board[1][c] == self.board[2][c] and self.board[0][c] != ' ':
                self.winner = self.board[0][c] # El ganador es la marca en esa columna
                return

        # Comprobar diagonales
        if self.board[0][0] == self.board[1][1] == self.board[2][2] and self.board[0][0] != ' ':
            self.winner = self.board[0][0] # El ganador es la marca en la diagonal principal
            return
        if self.board[0][2] == self.board[1][1] == self.board[2][0] and self.board[0][2] != ' ':
            self.winner = self.board[0][2] # El ganador es la marca en la diagonal secundaria
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

"""
    Función de Evaluación
    Evalúa el estado final del tablero y devuelve una puntuación.
    +1 si el maximizador gana.
    -1 si el minimizador (oponente) gana.
    0 si es un empate.
    """
def evaluate_board(board, maximizer_mark):
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
'''
def minimax(board, is_maximizing_turn, maximizer_mark, opponent_mark, depth, eval_func):
    # board: el estado actual del tablero
    # is_maximizing_turn: True si es el turno del jugador que quiere maximizar la puntuación (IA), False si es el turno del minimizador (oponente)
    # maximizer_mark: la marca del jugador que intenta maximizar (la IA)
    # opponent_mark: la marca del jugador oponente
    # depth: la profundidad actual en el árbol de búsqueda
    # eval_func: la función para evaluar el tablero

    current_state = board.get_state()

    # Casos base de la recursión: usan la función de evaluación separada
    if current_state == State.DRAW or current_state == State.OVER:
        score = eval_func(board, maximizer_mark)
        return score, None  # Puntuación, Movimiento

    # opponent_mark se pasa ahora como argumento
    
    # Este será el mejor movimiento encontrado EN ESTE NIVEL de la recursión
    best_move_at_this_level = None

    if is_maximizing_turn: # Turno de la IA (quiere la puntuación más alta)
        best_score = -math.inf
        possible_moves = board.get_possible_moves()
        # No es necesario verificar 'if not possible_moves:' aquí, 
        # porque los casos base DRAW/OVER ya cubren situaciones sin movimientos.
        # Si llegamos aquí, siempre hay movimientos posibles o el juego ya terminó.

        for move in possible_moves:
            board.make_move(move, maximizer_mark)
            # La llamada recursiva devuelve (puntuación_del_estado_resultante, movimiento_desde_ese_estado_resultante)
            # Solo nos interesa la puntuación_del_estado_resultante para la decisión actual.
            score_of_resulting_state, _ = minimax(board, False, maximizer_mark, opponent_mark, depth + 1, eval_func)
            board.undo()
            
            if score_of_resulting_state > best_score:
                best_score = score_of_resulting_state
                best_move_at_this_level = move # Este 'move' es el que se está probando en el bucle actual
        return best_score, best_move_at_this_level
    
    else: # Turno del oponente (quiere la puntuación más baja para la IA)
        best_score = math.inf
        possible_moves = board.get_possible_moves()

        for move in possible_moves:
            board.make_move(move, opponent_mark)
            score_of_resulting_state, _ = minimax(board, True, maximizer_mark, opponent_mark, depth + 1, eval_func)
            board.undo()

            if score_of_resulting_state < best_score:
                best_score = score_of_resulting_state
                best_move_at_this_level = move

        return best_score, best_move_at_this_level

def get_best_move(board, ai_mark, opponent_mark, eval_func):
    # Encuentra el mejor movimiento para la IA en el estado actual del tablero
    # ai_mark: la marca de la IA
    # opponent_mark: la marca del oponente
    # eval_func: la función para evaluar el tablero

    # La primera llamada a minimax es para el turno de la IA (is_maximizing_turn = True), en profundidad 0.
    # minimax ahora devuelve (puntuación, movimiento_que_lleva_a_esa_puntuación_desde_este_nivel).
    # Desempaquetar la puntuación y el movimiento. Solo necesitamos el movimiento.
    _, best_move = minimax(board, True, ai_mark, opponent_mark, 0, eval_func)
        
    return best_move

def play_game():
    # Función principal que maneja el flujo de una partida
    game_board = TicTacBoard() # Crea una instancia del tablero
    human_player = PLAYER_X # El humano será X
    ai_player = PLAYER_O    # La IA será O
    current_player = human_player # El humano empieza

    print("\nTres en Raya (Tic Tac Toe) con Minimax")
    game_board.print_board() # Muestra el tablero inicial

    # Bucle principal del juego: continúa mientras el juego esté en estado "PLAYING"
    while game_board.get_state() == State.PLAYING:
        if current_player == human_player: # Si es el turno del humano
            print(f"\nTurno del Humano ({human_player})")
            try:
                # Pide al humano que ingrese su movimiento (usando 1,2,3)
                row_input = int(input("Elige fila (1, 2, 3): "))
                col_input = int(input("Elige columna (1, 2, 3): "))

                # Convertir a coordenadas internas (0,1,2)
                move = (row_input - 1, col_input - 1)

                if 0 <= move[0] <= 2 and 0 <= move[1] <= 2 and move in game_board.get_possible_moves(): # Verifica si el movimiento es válido
                    game_board.make_move(move, human_player) # Realiza el movimiento
                    current_player = ai_player # Cambia el turno a la IA
                else:
                    print("\nMovimiento inválido. Asegúrate de elegir una casilla vacía y usar los números 1, 2 o 3. Intenta de nuevo.")
            except ValueError: # Si el usuario no ingresa números
                print("Entrada inválida. Ingresa números (1, 2 o 3).")
        else: # Turno de la IA
            print(f"\\nTurno de la IA ({ai_player})")
            move = get_best_move(game_board, ai_player, human_player, evaluate_board) # La IA calcula su mejor movimiento
            if move: # Si la IA encontró un movimiento
                print(f"Fila elegida: {move[0] + 1}\\nColumna elegida: {move[1] + 1}")
                game_board.make_move(move, ai_player) # Realiza el movimiento
                current_player = human_player # Cambia el turno al humano
            else: # Esto no debería ocurrir si hay movimientos posibles
                print(f"Error: IA ({ai_player}) no pudo encontrar un movimiento.")
                break # Termina el juego si hay un error
        
        game_board.print_board() # Muestra el tablero después de cada jugada
        
        # Pequeña pausa para poder seguir el juego si es IA vs IA, o para que el humano vea el movimiento de la IA
        # Si se desea que solo pause en IA vs IA, se puede condicionar.
        # input("Presiona Enter para continuar con el siguiente turno...") 

        final_state = game_board.get_state() # Obtiene el estado del juego
        if final_state != State.PLAYING: # Si el juego ya no está en "PLAYING"
            if final_state == State.DRAW: # Si es empate
                print("\n¡Es un empate!")
            else: # State.OVER, alguien ganó
                winner = game_board.get_winner()
                if winner == human_player:
                    print(f"¡Felicidades! ¡El jugador Humano ({winner}) ha ganado!")
                else:
                    print(f"\n¡La IA ({winner}) ha ganado!")
            break # Termina el bucle del juego

if __name__ == "__main__":
    # Este bloque se ejecuta solo si el script se corre directamente (no si se importa como módulo)
    play_game() # Inicia el juego
