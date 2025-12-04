# Snake-MIPS-PS2

Este proyecto es una versión clásica del juego Snake, desarrollada para la PlayStation 2 utilizando ensamblador MIPS. El juego corre directamente sobre el hardware de la PS2, sin librerías externas, demostrando control total sobre la lógica, entrada y renderizado en bajo nivel.

## Características principales

- **Movimiento fluido de la culebra** en un tablero 2D de 32x24 celdas
- **Detección de colisiones** con paredes y cuerpo de la serpiente
- **Generación aleatoria de comida** usando un algoritmo LFSR
- **Sistema de puntaje** con seguimiento de puntuación máxima
- **Lógica principal** implementada completamente en MIPS
- **Renderizado básico** en PS2 mediante el Graphics Synthesizer

## Estructura del proyecto

```
Snake-MIPS-PS2/
├── snake.asm          # Código fuente principal del juego
└── README.md          # Documentación del proyecto
```

## Arquitectura del código

### Módulos principales

1. **Inicialización del hardware (`init_hardware`)**
   - Configura el modo de video NTSC
   - Inicializa el frame buffer del Graphics Synthesizer
   - Establece el color de fondo

2. **Lógica del juego (`init_game`, `update_snake`, `check_collisions`, `check_food`)**
   - Maneja el estado del juego (jugando, pausado, game over)
   - Actualiza la posición de cada segmento de la serpiente
   - Detecta colisiones con paredes y el propio cuerpo
   - Verifica si la serpiente come la comida

3. **Sistema de entrada (`read_controller`)**
   - Lee el estado del controlador PS2
   - Procesa direcciones (arriba, abajo, izquierda, derecha)
   - Maneja pausa con el botón START
   - Previene direcciones opuestas (no puede retroceder)

4. **Renderizado (`render_frame`, `draw_cell`, `draw_border`)**
   - Limpia la pantalla cada frame
   - Dibuja el borde del tablero
   - Renderiza la serpiente con diferenciación de cabeza/cuerpo
   - Muestra la comida

5. **Generación aleatoria (`random`, `spawn_food`)**
   - Implementa un LFSR de 16 bits para números pseudo-aleatorios
   - Genera posiciones válidas para la comida

## Requisitos

### Para desarrollo
- Un ensamblador MIPS compatible con PS2 (por ejemplo, `mips-elf-as` del PS2DEV SDK)
- Opcional: PCSX2 para emulación y pruebas

### Para ejecución real
- PlayStation 2 con capacidad de ejecutar homebrew
- Memory card formateada con Free McBoot o similar

## Compilación

### Usando PS2DEV SDK

```bash
# Configurar entorno PS2DEV
export PS2DEV=/usr/local/ps2dev
export PATH=$PATH:$PS2DEV/bin

# Ensamblar el código
mips-elf-as -o snake.o snake.asm

# Enlazar
mips-elf-ld -o snake.elf snake.o -T ps2.ld

# Crear imagen ISO (opcional)
mkisofs -o snake.iso snake.elf
```

## Controles

| Botón | Acción |
|-------|--------|
| D-Pad Arriba | Mover serpiente hacia arriba |
| D-Pad Abajo | Mover serpiente hacia abajo |
| D-Pad Izquierda | Mover serpiente hacia la izquierda |
| D-Pad Derecha | Mover serpiente hacia la derecha |
| START | Pausar/Reanudar juego |

## Constantes configurables

El código incluye varias constantes que pueden modificarse:

```assembly
.eqv BOARD_WIDTH    32      # Ancho del tablero
.eqv BOARD_HEIGHT   24      # Alto del tablero
.eqv CELL_SIZE      16      # Tamaño de celda en píxeles
.eqv MAX_SNAKE_LEN  256     # Longitud máxima de la serpiente
```

## Registros de hardware PS2 utilizados

### Graphics Synthesizer (GS)
- `GS_PMODE (0x12000000)` - Modo de video
- `GS_DISPFB1 (0x12000070)` - Frame buffer 1
- `GS_DISPLAY1 (0x12000080)` - Configuración de display
- `GS_BGCOLOR (0x120000E0)` - Color de fondo
- `GS_CSR (0x12001000)` - Control/Status Register

### Controlador (SIO2)
- `PAD_BASE (0xBF808200)` - Base del controlador

## Propósito educativo

Este proyecto está diseñado como una referencia educativa para quienes deseen aprender:

- **Programación de videojuegos retro en bajo nivel**: Entender cómo funcionaban los juegos antes de los motores modernos
- **Arquitectura MIPS**: Dominar un conjunto de instrucciones RISC fundamental
- **Control directo del hardware PS2**: Interactuar con el Graphics Synthesizer y controladores sin abstracción
- **Gestión de memoria**: Trabajar con buffers de video y estructuras de datos en ensamblador
- **Algoritmos de juego**: Implementar lógica de colisiones, movimiento y generación aleatoria

## Referencias

- [PS2DEV Wiki](https://www.ps2-home.com/forum/viewtopic.php?t=1248) - Documentación de desarrollo PS2
- [MIPS Architecture](https://en.wikipedia.org/wiki/MIPS_architecture) - Referencia de la arquitectura MIPS
- [EE Users Manual](https://psi-rockin.github.io/ps2tek/) - Manual técnico del Emotion Engine

## Licencia

Este proyecto es de código abierto y está disponible para uso educativo.
