################################################################################
# Snake Game for PlayStation 2 - MIPS Assembly
# 
# Características principales:
# - Movimiento fluido de la culebra en un tablero 2D
# - Detección de colisiones (paredes y cuerpo)
# - Generación aleatoria de comida
# - Sistema de puntaje
# - Lógica principal implementada completamente en MIPS
# - Renderizado básico en PS2 mediante el Graphics Synthesizer
#
# Este proyecto está diseñado como referencia educativa para:
# - Programación de videojuegos retro en bajo nivel
# - Control directo del hardware PS2
################################################################################

.data
    # ============================================================================
    # Constantes del tablero de juego
    # ============================================================================
    .eqv BOARD_WIDTH    32          # Ancho del tablero (columnas)
    .eqv BOARD_HEIGHT   24          # Alto del tablero (filas)
    .eqv CELL_SIZE      16          # Tamaño de cada celda en píxeles
    .eqv MAX_SNAKE_LEN  256         # Longitud máxima de la serpiente
    
    # ============================================================================
    # Constantes de dirección
    # ============================================================================
    .eqv DIR_UP         0
    .eqv DIR_DOWN       1
    .eqv DIR_LEFT       2
    .eqv DIR_RIGHT      3
    
    # ============================================================================
    # Estados del juego
    # ============================================================================
    .eqv STATE_PLAYING  0
    .eqv STATE_GAMEOVER 1
    .eqv STATE_PAUSED   2
    
    # ============================================================================
    # Direcciones de memoria del PS2 Graphics Synthesizer (GS)
    # ============================================================================
    .eqv GS_PMODE       0x12000000  # Modo de video
    .eqv GS_DISPFB1     0x12000070  # Frame buffer 1
    .eqv GS_DISPLAY1    0x12000080  # Display 1
    .eqv GS_BGCOLOR     0x120000E0  # Color de fondo
    .eqv GS_CSR         0x12001000  # Control/Status Register
    
    # ============================================================================
    # Direcciones del controlador PS2 (SIO2)
    # ============================================================================
    .eqv PAD_BASE       0xBF808200  # Base del controlador
    .eqv PAD_UP         0x0010      # Bit para botón arriba
    .eqv PAD_DOWN       0x0040      # Bit para botón abajo
    .eqv PAD_LEFT       0x0080      # Bit para botón izquierda
    .eqv PAD_RIGHT      0x0020      # Bit para botón derecha
    .eqv PAD_START      0x0008      # Bit para botón start
    
    # ============================================================================
    # Variables del juego
    # ============================================================================
    
    # Posiciones de la serpiente (x, y para cada segmento)
    snake_x:        .space 1024     # 256 segmentos * 4 bytes
    snake_y:        .space 1024     # 256 segmentos * 4 bytes
    snake_length:   .word  3        # Longitud inicial de la serpiente
    snake_dir:      .word  3        # Dirección actual (DIR_RIGHT)
    
    # Posición de la comida
    food_x:         .word  15       # Coordenada X de la comida
    food_y:         .word  12       # Coordenada Y de la comida
    
    # Sistema de puntaje
    score:          .word  0        # Puntaje actual
    high_score:     .word  0        # Puntaje más alto
    
    # Estado del juego
    game_state:     .word  0        # Estado actual (STATE_PLAYING)
    
    # Semilla para números aleatorios (LFSR)
    random_seed:    .word  0xACE1   # Semilla inicial del generador
    
    # Frame counter para timing
    frame_count:    .word  0        # Contador de frames
    
    # Tablero del juego (para detección de colisiones rápida)
    board:          .space 3072     # 32 * 24 * 4 bytes
    
    # Buffer de video (simulado para desarrollo)
    video_buffer:   .space 196608   # 512 * 384 bytes (simplificado)

.text
.globl main

################################################################################
# PUNTO DE ENTRADA PRINCIPAL
################################################################################
main:
    # Inicializar stack pointer
    li      $sp, 0x80800000         # Stack en memoria alta
    
    # Inicializar el hardware PS2
    jal     init_hardware
    nop
    
    # Inicializar el estado del juego
    jal     init_game
    nop
    
    # Bucle principal del juego
game_loop:
    # Leer entrada del controlador
    jal     read_controller
    nop
    
    # Verificar estado del juego
    lw      $t0, game_state
    beq     $t0, STATE_GAMEOVER, handle_gameover
    nop
    beq     $t0, STATE_PAUSED, handle_paused
    nop
    
    # Control de velocidad (actualizar cada N frames)
    lw      $t0, frame_count
    addiu   $t0, $t0, 1
    sw      $t0, frame_count
    
    # Actualizar lógica cada 8 frames para movimiento fluido
    andi    $t1, $t0, 7
    bnez    $t1, skip_update
    nop
    
    # Actualizar posición de la serpiente
    jal     update_snake
    nop
    
    # Verificar colisiones
    jal     check_collisions
    nop
    
    # Verificar si comió comida
    jal     check_food
    nop

skip_update:
    # Renderizar el frame
    jal     render_frame
    nop
    
    # Esperar vsync para sincronización vertical
    jal     wait_vsync
    nop
    
    # Continuar bucle
    j       game_loop
    nop

handle_gameover:
    # Renderizar pantalla de game over
    jal     render_gameover
    nop
    
    # Esperar botón start para reiniciar
    jal     read_controller
    nop
    andi    $t0, $v0, PAD_START
    beqz    $t0, game_loop
    nop
    
    # Reiniciar juego
    jal     init_game
    nop
    j       game_loop
    nop

handle_paused:
    # Renderizar indicador de pausa
    jal     render_paused
    nop
    j       game_loop
    nop

################################################################################
# INICIALIZACIÓN DEL HARDWARE PS2
################################################################################
init_hardware:
    addiu   $sp, $sp, -8
    sw      $ra, 0($sp)
    
    # Configurar modo de video NTSC 640x448
    li      $t0, GS_PMODE
    li      $t1, 0x0065             # Modo NTSC interlaced
    sw      $t1, 0($t0)
    
    # Configurar frame buffer
    li      $t0, GS_DISPFB1
    li      $t1, 0x00000000         # Frame buffer en 0, 32-bit color
    sw      $t1, 0($t0)
    
    # Configurar display
    li      $t0, GS_DISPLAY1
    li      $t1, 0x0001BF9F         # 640x448 display
    sw      $t1, 0($t0)
    
    # Limpiar color de fondo a negro
    li      $t0, GS_BGCOLOR
    li      $t1, 0x00000000         # Negro
    sw      $t1, 0($t0)
    
    lw      $ra, 0($sp)
    addiu   $sp, $sp, 8
    jr      $ra
    nop

################################################################################
# INICIALIZACIÓN DEL JUEGO
################################################################################
init_game:
    addiu   $sp, $sp, -8
    sw      $ra, 0($sp)
    
    # Inicializar longitud de la serpiente
    li      $t0, 3
    sw      $t0, snake_length
    
    # Inicializar dirección (derecha)
    li      $t0, DIR_RIGHT
    sw      $t0, snake_dir
    
    # Inicializar posición de la serpiente (centro del tablero)
    la      $t0, snake_x
    la      $t1, snake_y
    
    # Cabeza en el centro
    li      $t2, 16                 # X = 16 (centro)
    sw      $t2, 0($t0)
    li      $t3, 12                 # Y = 12 (centro)
    sw      $t3, 0($t1)
    
    # Segundo segmento
    li      $t2, 15
    sw      $t2, 4($t0)
    sw      $t3, 4($t1)
    
    # Tercer segmento
    li      $t2, 14
    sw      $t2, 8($t0)
    sw      $t3, 8($t1)
    
    # Inicializar puntaje
    sw      $zero, score
    
    # Estado del juego
    li      $t0, STATE_PLAYING
    sw      $t0, game_state
    
    # Generar comida inicial
    jal     spawn_food
    nop
    
    # Limpiar tablero
    jal     clear_board
    nop
    
    lw      $ra, 0($sp)
    addiu   $sp, $sp, 8
    jr      $ra
    nop

################################################################################
# LIMPIAR TABLERO
################################################################################
clear_board:
    la      $t0, board
    li      $t1, 768                # 32 * 24 = 768 celdas
    
clear_loop:
    sw      $zero, 0($t0)
    addiu   $t0, $t0, 4
    addiu   $t1, $t1, -1
    bnez    $t1, clear_loop
    nop
    
    jr      $ra
    nop

################################################################################
# LEER CONTROLADOR PS2
################################################################################
read_controller:
    addiu   $sp, $sp, -8
    sw      $ra, 0($sp)
    
    # Leer estado del controlador
    li      $t0, PAD_BASE
    lw      $v0, 0($t0)
    
    # Invertir bits (botones presionados son 0)
    not     $v0, $v0
    
    # Guardar estado actual de la serpiente
    lw      $t1, snake_dir
    
    # Verificar botones de dirección
    # No permitir dirección opuesta (no puede ir hacia atrás)
    
check_up:
    andi    $t2, $v0, PAD_UP
    beqz    $t2, check_down
    nop
    # No puede ir arriba si va abajo
    li      $t3, DIR_DOWN
    beq     $t1, $t3, check_down
    nop
    li      $t4, DIR_UP
    sw      $t4, snake_dir
    j       dir_done
    nop
    
check_down:
    andi    $t2, $v0, PAD_DOWN
    beqz    $t2, check_left
    nop
    # No puede ir abajo si va arriba
    li      $t3, DIR_UP
    beq     $t1, $t3, check_left
    nop
    li      $t4, DIR_DOWN
    sw      $t4, snake_dir
    j       dir_done
    nop
    
check_left:
    andi    $t2, $v0, PAD_LEFT
    beqz    $t2, check_right
    nop
    # No puede ir izquierda si va derecha
    li      $t3, DIR_RIGHT
    beq     $t1, $t3, check_right
    nop
    li      $t4, DIR_LEFT
    sw      $t4, snake_dir
    j       dir_done
    nop
    
check_right:
    andi    $t2, $v0, PAD_RIGHT
    beqz    $t2, check_pause
    nop
    # No puede ir derecha si va izquierda
    li      $t3, DIR_LEFT
    beq     $t1, $t3, check_pause
    nop
    li      $t4, DIR_RIGHT
    sw      $t4, snake_dir
    j       dir_done
    nop

check_pause:
    andi    $t2, $v0, PAD_START
    beqz    $t2, dir_done
    nop
    # Toggle pausa
    lw      $t3, game_state
    li      $t4, STATE_PLAYING
    beq     $t3, $t4, set_paused
    nop
    li      $t4, STATE_PAUSED
    bne     $t3, $t4, dir_done
    nop
    li      $t5, STATE_PLAYING
    sw      $t5, game_state
    j       dir_done
    nop
set_paused:
    li      $t5, STATE_PAUSED
    sw      $t5, game_state

dir_done:
    lw      $ra, 0($sp)
    addiu   $sp, $sp, 8
    jr      $ra
    nop

################################################################################
# ACTUALIZAR POSICIÓN DE LA SERPIENTE
################################################################################
update_snake:
    addiu   $sp, $sp, -16
    sw      $ra, 0($sp)
    sw      $s0, 4($sp)
    sw      $s1, 8($sp)
    
    # Cargar posición de la cabeza
    la      $t0, snake_x
    la      $t1, snake_y
    lw      $s0, 0($t0)             # head_x
    lw      $s1, 0($t1)             # head_y
    
    # Calcular nueva posición basada en dirección
    lw      $t2, snake_dir
    
    # Switch según dirección
    li      $t3, DIR_UP
    beq     $t2, $t3, move_up
    nop
    li      $t3, DIR_DOWN
    beq     $t2, $t3, move_down
    nop
    li      $t3, DIR_LEFT
    beq     $t2, $t3, move_left
    nop
    j       move_right
    nop
    
move_up:
    addiu   $s1, $s1, -1            # Y -= 1
    j       move_done
    nop
    
move_down:
    addiu   $s1, $s1, 1             # Y += 1
    j       move_done
    nop
    
move_left:
    addiu   $s0, $s0, -1            # X -= 1
    j       move_done
    nop
    
move_right:
    addiu   $s0, $s0, 1             # X += 1

move_done:
    # Mover cada segmento hacia la posición del anterior
    lw      $t4, snake_length
    addiu   $t4, $t4, -1            # Empezar desde el último segmento
    
    la      $t0, snake_x
    la      $t1, snake_y
    
shift_loop:
    beqz    $t4, shift_done
    nop
    
    # Calcular offsets
    sll     $t5, $t4, 2             # offset actual = i * 4
    addiu   $t6, $t4, -1
    sll     $t6, $t6, 2             # offset anterior = (i-1) * 4
    
    # Copiar posición del segmento anterior
    add     $t7, $t0, $t6           # &snake_x[i-1]
    lw      $t8, 0($t7)
    add     $t7, $t0, $t5           # &snake_x[i]
    sw      $t8, 0($t7)
    
    add     $t7, $t1, $t6           # &snake_y[i-1]
    lw      $t8, 0($t7)
    add     $t7, $t1, $t5           # &snake_y[i]
    sw      $t8, 0($t7)
    
    addiu   $t4, $t4, -1
    j       shift_loop
    nop
    
shift_done:
    # Actualizar posición de la cabeza
    sw      $s0, 0($t0)
    sw      $s1, 0($t1)
    
    lw      $s1, 8($sp)
    lw      $s0, 4($sp)
    lw      $ra, 0($sp)
    addiu   $sp, $sp, 16
    jr      $ra
    nop

################################################################################
# VERIFICAR COLISIONES (PAREDES Y CUERPO)
################################################################################
check_collisions:
    addiu   $sp, $sp, -8
    sw      $ra, 0($sp)
    
    # Obtener posición de la cabeza
    la      $t0, snake_x
    la      $t1, snake_y
    lw      $t2, 0($t0)             # head_x
    lw      $t3, 0($t1)             # head_y
    
    # ========================================
    # Verificar colisión con paredes
    # ========================================
    
    # Pared izquierda (x < 0)
    bltz    $t2, collision_detected
    nop
    
    # Pared derecha (x >= BOARD_WIDTH)
    li      $t4, BOARD_WIDTH
    bge     $t2, $t4, collision_detected
    nop
    
    # Pared superior (y < 0)
    bltz    $t3, collision_detected
    nop
    
    # Pared inferior (y >= BOARD_HEIGHT)
    li      $t4, BOARD_HEIGHT
    bge     $t3, $t4, collision_detected
    nop
    
    # ========================================
    # Verificar colisión con el cuerpo
    # ========================================
    lw      $t5, snake_length
    li      $t6, 1                  # Empezar desde segmento 1 (no la cabeza)
    
body_check_loop:
    bge     $t6, $t5, no_collision
    nop
    
    # Calcular offset
    sll     $t7, $t6, 2             # offset = i * 4
    
    # Obtener posición del segmento
    add     $t8, $t0, $t7
    lw      $t8, 0($t8)             # segment_x
    add     $t9, $t1, $t7
    lw      $t9, 0($t9)             # segment_y
    
    # Comparar con la cabeza
    bne     $t2, $t8, next_segment
    nop
    bne     $t3, $t9, next_segment
    nop
    
    # Colisión con el cuerpo detectada
    j       collision_detected
    nop
    
next_segment:
    addiu   $t6, $t6, 1
    j       body_check_loop
    nop
    
collision_detected:
    # Game over - establecer estado
    li      $t0, STATE_GAMEOVER
    sw      $t0, game_state
    
    # Actualizar high score si es necesario
    lw      $t1, score
    lw      $t2, high_score
    ble     $t1, $t2, no_collision
    nop
    sw      $t1, high_score
    
no_collision:
    lw      $ra, 0($sp)
    addiu   $sp, $sp, 8
    jr      $ra
    nop

################################################################################
# VERIFICAR SI LA SERPIENTE COMIÓ COMIDA
################################################################################
check_food:
    addiu   $sp, $sp, -8
    sw      $ra, 0($sp)
    
    # Obtener posición de la cabeza
    la      $t0, snake_x
    la      $t1, snake_y
    lw      $t2, 0($t0)             # head_x
    lw      $t3, 0($t1)             # head_y
    
    # Obtener posición de la comida
    lw      $t4, food_x
    lw      $t5, food_y
    
    # Comparar posiciones
    bne     $t2, $t4, no_food
    nop
    bne     $t3, $t5, no_food
    nop
    
    # ¡Comió la comida!
    
    # Incrementar puntaje
    lw      $t6, score
    addiu   $t6, $t6, 10
    sw      $t6, score
    
    # Incrementar longitud de la serpiente
    lw      $t6, snake_length
    li      $t7, MAX_SNAKE_LEN
    bge     $t6, $t7, skip_grow    # No crecer si está al máximo
    nop
    addiu   $t6, $t6, 1
    sw      $t6, snake_length
    
skip_grow:
    # Generar nueva comida
    jal     spawn_food
    nop
    
no_food:
    lw      $ra, 0($sp)
    addiu   $sp, $sp, 8
    jr      $ra
    nop

################################################################################
# GENERAR COMIDA EN POSICIÓN ALEATORIA
################################################################################
spawn_food:
    addiu   $sp, $sp, -16
    sw      $ra, 0($sp)
    sw      $s0, 4($sp)
    sw      $s1, 8($sp)
    
spawn_retry:
    # Generar X aleatorio (0 a BOARD_WIDTH-1)
    jal     random
    nop
    li      $t0, BOARD_WIDTH
    div     $v0, $t0
    mfhi    $s0                     # food_x = random % BOARD_WIDTH
    
    # Generar Y aleatorio (0 a BOARD_HEIGHT-1)
    jal     random
    nop
    li      $t0, BOARD_HEIGHT
    div     $v0, $t0
    mfhi    $s1                     # food_y = random % BOARD_HEIGHT
    
    # Verificar que la comida no esté sobre la serpiente
    lw      $t2, snake_length
    li      $t3, 0
    la      $t0, snake_x
    la      $t1, snake_y
    
check_food_position:
    bge     $t3, $t2, food_position_ok
    nop
    
    sll     $t4, $t3, 2
    add     $t5, $t0, $t4
    lw      $t5, 0($t5)
    add     $t6, $t1, $t4
    lw      $t6, 0($t6)
    
    # Comparar con posición de comida propuesta
    bne     $s0, $t5, next_check
    nop
    bne     $s1, $t6, next_check
    nop
    
    # Colisión - reintentar
    j       spawn_retry
    nop
    
next_check:
    addiu   $t3, $t3, 1
    j       check_food_position
    nop
    
food_position_ok:
    # Guardar posición de la comida
    sw      $s0, food_x
    sw      $s1, food_y
    
    lw      $s1, 8($sp)
    lw      $s0, 4($sp)
    lw      $ra, 0($sp)
    addiu   $sp, $sp, 16
    jr      $ra
    nop

################################################################################
# GENERADOR DE NÚMEROS ALEATORIOS (LFSR - Linear Feedback Shift Register)
################################################################################
random:
    # Cargar semilla actual
    lw      $v0, random_seed
    
    # LFSR de 16 bits con taps en 16, 14, 13, 11
    # bit = (seed >> 0) ^ (seed >> 2) ^ (seed >> 3) ^ (seed >> 5)
    srl     $t0, $v0, 0
    andi    $t0, $t0, 1
    srl     $t1, $v0, 2
    andi    $t1, $t1, 1
    xor     $t0, $t0, $t1
    srl     $t1, $v0, 3
    andi    $t1, $t1, 1
    xor     $t0, $t0, $t1
    srl     $t1, $v0, 5
    andi    $t1, $t1, 1
    xor     $t0, $t0, $t1
    
    # Shift y agregar nuevo bit
    sll     $v0, $v0, 1
    andi    $v0, $v0, 0xFFFF
    or      $v0, $v0, $t0
    
    # Guardar nueva semilla
    sw      $v0, random_seed
    
    jr      $ra
    nop

################################################################################
# RENDERIZAR FRAME COMPLETO
################################################################################
render_frame:
    addiu   $sp, $sp, -16
    sw      $ra, 0($sp)
    sw      $s0, 4($sp)
    sw      $s1, 8($sp)
    
    # Limpiar pantalla (fondo negro)
    jal     clear_screen
    nop
    
    # Dibujar borde del tablero
    jal     draw_border
    nop
    
    # Dibujar la comida (color rojo)
    lw      $a0, food_x
    lw      $a1, food_y
    li      $a2, 0xFF0000           # Rojo
    jal     draw_cell
    nop
    
    # Dibujar la serpiente
    lw      $s0, snake_length
    li      $s1, 0                  # Índice
    la      $t0, snake_x
    la      $t1, snake_y
    
draw_snake_loop:
    bge     $s1, $s0, draw_snake_done
    nop
    
    # Calcular offset
    sll     $t2, $s1, 2
    add     $t3, $t0, $t2
    lw      $a0, 0($t3)             # x
    add     $t3, $t1, $t2
    lw      $a1, 0($t3)             # y
    
    # Color: cabeza verde claro, cuerpo verde oscuro
    beqz    $s1, draw_head
    nop
    li      $a2, 0x008800           # Verde oscuro (cuerpo)
    j       draw_segment
    nop
    
draw_head:
    li      $a2, 0x00FF00           # Verde claro (cabeza)
    
draw_segment:
    jal     draw_cell
    nop
    
    addiu   $s1, $s1, 1
    j       draw_snake_loop
    nop
    
draw_snake_done:
    # Dibujar puntaje
    jal     draw_score
    nop
    
    lw      $s1, 8($sp)
    lw      $s0, 4($sp)
    lw      $ra, 0($sp)
    addiu   $sp, $sp, 16
    jr      $ra
    nop

################################################################################
# LIMPIAR PANTALLA
################################################################################
clear_screen:
    # Acceder al buffer de video y limpiar
    la      $t0, video_buffer
    li      $t1, 49152              # 512 * 384 / 4 palabras
    
clear_screen_loop:
    sw      $zero, 0($t0)
    addiu   $t0, $t0, 4
    addiu   $t1, $t1, -1
    bnez    $t1, clear_screen_loop
    nop
    
    jr      $ra
    nop

################################################################################
# DIBUJAR BORDE DEL TABLERO
################################################################################
draw_border:
    addiu   $sp, $sp, -16
    sw      $ra, 0($sp)
    sw      $s0, 4($sp)
    
    li      $a2, 0x404040           # Color gris para el borde
    
    # Borde superior
    li      $s0, 0
border_top:
    li      $t0, BOARD_WIDTH
    bge     $s0, $t0, border_bottom_init
    nop
    move    $a0, $s0
    li      $a1, -1
    jal     draw_cell
    nop
    addiu   $s0, $s0, 1
    j       border_top
    nop
    
border_bottom_init:
    li      $s0, 0
border_bottom:
    li      $t0, BOARD_WIDTH
    bge     $s0, $t0, border_left_init
    nop
    move    $a0, $s0
    li      $a1, BOARD_HEIGHT
    jal     draw_cell
    nop
    addiu   $s0, $s0, 1
    j       border_bottom
    nop
    
border_left_init:
    li      $s0, 0
border_left:
    li      $t0, BOARD_HEIGHT
    bge     $s0, $t0, border_right_init
    nop
    li      $a0, -1
    move    $a1, $s0
    jal     draw_cell
    nop
    addiu   $s0, $s0, 1
    j       border_left
    nop
    
border_right_init:
    li      $s0, 0
border_right:
    li      $t0, BOARD_HEIGHT
    bge     $s0, $t0, border_done
    nop
    li      $a0, BOARD_WIDTH
    move    $a1, $s0
    jal     draw_cell
    nop
    addiu   $s0, $s0, 1
    j       border_right
    nop
    
border_done:
    lw      $s0, 4($sp)
    lw      $ra, 0($sp)
    addiu   $sp, $sp, 16
    jr      $ra
    nop

################################################################################
# DIBUJAR UNA CELDA EN EL TABLERO
# Argumentos: $a0 = x, $a1 = y, $a2 = color (RGB)
################################################################################
draw_cell:
    # Calcular posición en píxeles
    # pixel_x = (x + 1) * CELL_SIZE (offset de 1 por el borde)
    # pixel_y = (y + 1) * CELL_SIZE
    
    addiu   $t0, $a0, 1
    sll     $t0, $t0, 4             # * 16 (CELL_SIZE)
    
    addiu   $t1, $a1, 1
    sll     $t1, $t1, 4             # * 16 (CELL_SIZE)
    
    # Calcular dirección base en el buffer de video
    # address = video_buffer + (y * 512 + x) * 4
    la      $t2, video_buffer
    sll     $t3, $t1, 9             # y * 512
    add     $t3, $t3, $t0
    sll     $t3, $t3, 2             # * 4 (bytes por pixel)
    add     $t2, $t2, $t3
    
    # Dibujar cuadrado de CELL_SIZE x CELL_SIZE
    li      $t4, CELL_SIZE          # filas
    
draw_cell_row:
    beqz    $t4, draw_cell_done
    nop
    
    li      $t5, CELL_SIZE          # columnas
    move    $t6, $t2
    
draw_cell_col:
    beqz    $t5, draw_cell_next_row
    nop
    
    sw      $a2, 0($t6)             # Escribir color
    addiu   $t6, $t6, 4
    addiu   $t5, $t5, -1
    j       draw_cell_col
    nop
    
draw_cell_next_row:
    addiu   $t2, $t2, 2048          # 512 * 4 (siguiente fila)
    addiu   $t4, $t4, -1
    j       draw_cell_row
    nop
    
draw_cell_done:
    jr      $ra
    nop

################################################################################
# DIBUJAR PUNTAJE
################################################################################
draw_score:
    # En una implementación real, esto dibujaría el puntaje en pantalla
    # usando sprites de dígitos. Aquí solo se reserva la funcionalidad.
    
    # Cargar puntaje actual
    lw      $t0, score
    
    # TODO: Implementar renderizado de texto/números
    # Esto requeriría sprites de fuente y lógica adicional
    
    jr      $ra
    nop

################################################################################
# RENDERIZAR PANTALLA DE GAME OVER
################################################################################
render_gameover:
    addiu   $sp, $sp, -8
    sw      $ra, 0($sp)
    
    # Limpiar pantalla
    jal     clear_screen
    nop
    
    # En implementación real: mostrar "GAME OVER" y puntaje final
    # Dibujar un indicador visual simple (cuadrado rojo en el centro)
    li      $a0, 14
    li      $a1, 10
    li      $a2, 0xFF0000
    jal     draw_cell
    nop
    
    li      $a0, 15
    li      $a1, 10
    li      $a2, 0xFF0000
    jal     draw_cell
    nop
    
    li      $a0, 16
    li      $a1, 10
    li      $a2, 0xFF0000
    jal     draw_cell
    nop
    
    li      $a0, 17
    li      $a1, 10
    li      $a2, 0xFF0000
    jal     draw_cell
    nop
    
    lw      $ra, 0($sp)
    addiu   $sp, $sp, 8
    jr      $ra
    nop

################################################################################
# RENDERIZAR INDICADOR DE PAUSA
################################################################################
render_paused:
    addiu   $sp, $sp, -8
    sw      $ra, 0($sp)
    
    # Dibujar frame normal
    jal     render_frame
    nop
    
    # Superponer indicador de pausa (dos barras verticales)
    li      $a2, 0xFFFFFF           # Blanco
    
    # Barra izquierda
    li      $a0, 14
    li      $a1, 10
    jal     draw_cell
    nop
    li      $a0, 14
    li      $a1, 11
    jal     draw_cell
    nop
    li      $a0, 14
    li      $a1, 12
    jal     draw_cell
    nop
    
    # Barra derecha
    li      $a0, 17
    li      $a1, 10
    jal     draw_cell
    nop
    li      $a0, 17
    li      $a1, 11
    jal     draw_cell
    nop
    li      $a0, 17
    li      $a1, 12
    jal     draw_cell
    nop
    
    lw      $ra, 0($sp)
    addiu   $sp, $sp, 8
    jr      $ra
    nop

################################################################################
# ESPERAR SINCRONIZACIÓN VERTICAL (VSYNC)
################################################################################
wait_vsync:
    # Leer el registro CSR del Graphics Synthesizer
    li      $t0, GS_CSR
    
vsync_wait_loop:
    lw      $t1, 0($t0)
    andi    $t1, $t1, 0x8           # Bit VSINT
    beqz    $t1, vsync_wait_loop
    nop
    
    # Limpiar el bit VSINT escribiendo 1
    li      $t1, 0x8
    sw      $t1, 0($t0)
    
    jr      $ra
    nop

################################################################################
# FIN DEL PROGRAMA
################################################################################
