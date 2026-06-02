; ==============================================================================
; ARCHIVO: matriz_traspuesta.asm
; DESCRIPCION: Captura una matriz 3x3 de un solo digito por celda,
;              calcula su traspuesta y muestra los resultados.
; COMPILAR: nasm -f elf64 matriz_traspuesta.asm -o matriz_traspuesta.o
; ENLAZAR: ld matriz_traspuesta.o -o matriz_traspuesta
; EJECUTAR: ./matriz_traspuesta
; ==============================================================================

; ------------------------------------------------------------------------------
; MACROS
; ------------------------------------------------------------------------------
; Macro para imprimir cadenas en la salida estandar (stdout)
; Recibe dos parametros:
;   %1 = direccion de la cadena a imprimir
;   %2 = longitud de la cadena en bytes
%macro print_string 2
    mov rax, 1          ; syscall: sys_write (numero 1 en el registro rax)
    mov rdi, 1          ; file descriptor: stdout (1 = pantalla/terminal)
    mov rsi, %1         ; puntero a la cadena (primer parametro: direccion del texto)
    mov rdx, %2         ; longitud de la cadena (segundo parametro: cantidad de bytes)
    syscall             ; invoca al kernel de Linux para ejecutar la syscall
%endmacro

; Macro para leer la entrada estandar (stdin)
; Recibe dos parametros:
;   %1 = direccion del buffer donde se almacenara lo leido
;   %2 = cantidad maxima de bytes a leer
%macro read_input 2
    mov rax, 0          ; syscall: sys_read (numero 0 en el registro rax)
    mov rdi, 0          ; file descriptor: stdin (0 = teclado/entrada)
    mov rsi, %1         ; puntero al buffer (primer parametro: donde guardar los datos)
    mov rdx, %2         ; bytes a leer (segundo parametro: cantidad maxima de caracteres)
    syscall             ; invoca al kernel para ejecutar la lectura
%endmacro

; ------------------------------------------------------------------------------
; SECCION DE DATOS - Variables inicializadas
; ------------------------------------------------------------------------------
section .data
    ; Mensaje de titulo que se muestra al iniciar el programa
    ; Los valores 10 y 0 al final son: 10 = salto de linea (LF), 0 = terminador nulo
    msg_titulo    db "--- MATRIZ 3x3 Y SU TRASPUESTA ---", 10, 0
    ; Calcula la longitud del mensaje usando la posicion actual ($) menos la etiqueta
    len_titulo    equ $ - msg_titulo

    ; Mensaje que se muestra para solicitar un digito al usuario
    msg_prompt    db "Ingrese un digito (0-9) para la matriz: ", 0
    len_prompt    equ $ - msg_prompt

    ; Mensaje de error cuando el usuario ingresa un caracter no valido
    ; Incluye salto de linea (10) y terminador nulo (0)
    msg_error     db "ERROR: Caracter invalido. Ingrese solo un digito (0-9).", 10, 0
    len_error     equ $ - msg_error

    ; Encabezado para la seccion de la matriz original
    msg_original  db 10, "--- MATRIZ ORIGINAL ---", 10, 0
    len_original  equ $ - msg_original

    ; Encabezado para la seccion de la matriz traspuesta
    msg_tras      db 10, "--- MATRIZ TRASPUESTA ---", 10, 0
    len_tras      equ $ - msg_tras

    ; Cadena con un espacio en blanco, usado como separador entre numeros
    espacio       db " ", 0
    ; Cadena con un salto de linea, usado para pasar a la siguiente fila
    salto_linea   db 10, 0

; ------------------------------------------------------------------------------
; SECCION BSS - Variables no inicializadas
; ------------------------------------------------------------------------------
section .bss
    ; Reserva 9 bytes contiguos para almacenar la matriz 3x3 original
    ; Cada byte almacenara el codigo ASCII de un digito (0-9)
    matriz        resb 9  ; Reserva 9 bytes para la matriz 3x3 original

    ; Reserva 9 bytes contiguos para almacenar la matriz traspuesta
    ; Los datos se colocaran aqui despues del calculo
    traspuesta    resb 9  ; Reserva 9 bytes para la matriz traspuesta

    ; Buffer de 1 byte para leer un solo caracter del teclado
    buffer_in     resb 1  ; Buffer de 1 byte para lectura de teclado

; ------------------------------------------------------------------------------
; SECCION DE TEXTO - Codigo ejecutable
; ------------------------------------------------------------------------------
section .text
    global _start       ; Hace visible la etiqueta _start para el enlazador (linker)

; ==============================================================================
; PUNTO DE ENTRADA PRINCIPAL
; ==============================================================================
_start:
    ; Imprime el mensaje de bienvenida/titulo en pantalla
    print_string msg_titulo, len_titulo

    ; Inicializacion del contador de elementos capturados
    ; Se usa la instruccion XOR sobre si mismo para poner r12 en cero
    ; Esto es mas eficiente que mov r12, 0
    xor r12, r12        ; r12 = 0 (Contador de elementos: 0 a 8)

; Etiqueta principal de captura de datos
; Este ciclo se ejecuta 9 veces, una por cada celda de la matriz 3x3
.ciclo_captura:
    ; Compara el contador r12 con 9 para saber si ya se capturaron todos
    cmp r12, 9          ; Verifica si ya tenemos 9 elementos
    jge .calcular_trasp ; Si r12 >= 9, pasa a calcular la traspuesta

    ; Solicita al usuario que ingrese un digito para la matriz
    print_string msg_prompt, len_prompt

; Etiqueta para leer un caracter del teclado
.leer_caracter:
    ; Llama a la macro read_input para leer 1 byte del teclado
    ; El resultado se almacena en buffer_in
    read_input buffer_in, 1
    ; Mueve el caracter leido (el byte) al registro AL para poder manipularlo
    mov al, byte [buffer_in]

    ; Validar si el usuario solo presiono ENTER sin datos previos
    ; El codigo ASCII del ENTER (salto de linea) es 10 (0x0A)
    cmp al, 10
    je .leer_caracter   ; Si era ENTER, lo ignora y vuelve a leer

    ; --- VALIDACION DE RANGO [0-9] ---
    ; Verifica que el caracter sea un digito entre '0' y '9'
    ; Los digitos '0' a '9' en ASCII tienen los valores 0x30 a 0x39 (48 a 57)
    cmp al, '0'         ; Compara con ASCII '0' (0x30) - limite inferior
    jl .entrada_invalida; Si es menor que '0', el caracter no es valido
    cmp al, '9'         ; Compara con ASCII '9' (0x39) - limite superior
    jg .entrada_invalida; Si es mayor que '9', el caracter no es valido

    ; Si el caracter paso ambas validaciones, es un digito valido
    ; Se guarda en la posicion [matriz + r12] de la matriz original
    ; r12 actua como indice (0 a 8) para recorrer las 9 celdas
    mov byte [matriz + r12], al
    inc r12             ; Incrementa el contador de elementos capturados

    ; --- LIMPIEZA DE BUFER (FLUSH) ---
    ; Evita que si el usuario escribe "123", el "23" corrompa la matriz
    ; Se leen caracteres hasta encontrar un salto de linea (ENTER)
.limpiar_buffer_exito:
    read_input buffer_in, 1         ; Lee un byte del buffer de entrada
    cmp byte [buffer_in], 10        ; Compara con el codigo ASCII de ENTER
    jne .limpiar_buffer_exito       ; Si no es ENTER, sigue leyendo y descartando

    ; Regresa al inicio del ciclo para capturar el siguiente elemento
    jmp .ciclo_captura

; Etiqueta para manejar errores de entrada
; Se ejecuta cuando el usuario ingresa un caracter que no esta entre '0' y '9'
.entrada_invalida:
    ; Muestra el mensaje de error en pantalla
    print_string msg_error, len_error

    ; Limpiar todo lo que el usuario haya escrito en la misma linea
    ; Esto evita que caracteres residuales afecten futuras lecturas
.limpiar_buffer_error:
    cmp al, 10          ; Si el caracter invalido era el ENTER, ya limpiamos
    je .ciclo_captura   ; Salta directamente a pedir el numero de nuevo
    read_input buffer_in, 1         ; Lee un byte del buffer
    mov al, byte [buffer_in]        ; Lo mueve a AL para la comparacion
    cmp al, 10          ; Compara con ENTER
    jne .limpiar_buffer_error       ; Si no es ENTER, sigue descartando caracteres

    ; Regresa al ciclo de captura SIN incrementar r12, para que el usuario
    ; pueda intentar de nuevo con el mismo elemento
    jmp .ciclo_captura  ; Regresa a solicitar el numero sin incrementar el contador

; ------------------------------------------------------------------------------
; RUTINA: Calcular Traspuesta
; ------------------------------------------------------------------------------
; Convierte la matriz original M[3][3] en su traspuesta T[3][3]
; La formula de traspuesta es: T[j][i] = M[i][j] para todo i,j en {0,1,2}
; ------------------------------------------------------------------------------
.calcular_trasp:
    xor r8, r8          ; r8 = 0 (Fila i, contador de filas: 0 a 2)
.ciclo_filas:
    cmp r8, 3           ; Verifica si ya procesamos las 3 filas (i = 0,1,2)
    jge .mostrar_resultados  ; Si ya terminamos, pasamos a mostrar resultados
    xor r9, r9          ; r9 = 0 (Columna j, contador de columnas: 0 a 2)

.ciclo_columnas:
    cmp r9, 3           ; Verifica si ya procesamos las 3 columnas (j = 0,1,2)
    jge .siguiente_fila ; Si ya terminamos las columnas, pasamos a la siguiente fila

    ; Calcular indice de Matriz Original: (i * 3) + j
    ; Para acceder a M[i][j] en un arreglo unidimensional de 9 elementos
    mov rax, r8         ; Copia el valor de la fila i a rax
    imul rax, 3         ; Multiplica rax por 3 (desplazamiento de fila)
    add rax, r9         ; Suma la columna j para obtener el indice final
    mov cl, byte [matriz + rax] ; Extrae el valor de M[i][j] (1 byte)

    ; Calcular indice de Matriz Traspuesta: (j * 3) + i
    ; La traspuesta intercambia filas por columnas: T[j][i] = M[i][j]
    mov rax, r9         ; Copia el valor de la columna j a rax
    imul rax, 3         ; Multiplica rax por 3 (desplazamiento de fila en T)
    add rax, r8         ; Suma la fila i para obtener el indice en T
    mov byte [traspuesta + rax], cl ; Guarda el valor en T[j][i] (1 byte)

    inc r9              ; Incrementa el contador de columnas (j++)
    jmp .ciclo_columnas ; Repite el ciclo para la siguiente columna

.siguiente_fila:
    inc r8              ; Incrementa el contador de filas (i++)
    jmp .ciclo_filas    ; Repite el ciclo para la siguiente fila

; ------------------------------------------------------------------------------
; RUTINA: Mostrar Resultados
; ------------------------------------------------------------------------------
; Imprime en pantalla la matriz original y la matriz traspuesta
; ------------------------------------------------------------------------------
.mostrar_resultados:
    ; Mostrar Matriz Original
    print_string msg_original, len_original    ; Imprime el encabezado
    mov r10, matriz     ; Carga en r10 la direccion base de la matriz original
    call .imprimir_matriz  ; Llama a la subrutina que imprime la matriz

    ; Mostrar Matriz Traspuesta
    print_string msg_tras, len_tras            ; Imprime el encabezado
    mov r10, traspuesta ; Carga en r10 la direccion base de la matriz traspuesta
    call .imprimir_matriz  ; Llama a la subrutina que imprime la matriz

; ------------------------------------------------------------------------------
; RUTINA: Salir del sistema
; ------------------------------------------------------------------------------
; Finaliza el programa y devuelve el control al sistema operativo
; ------------------------------------------------------------------------------
.salir:
    mov rax, 60         ; syscall: sys_exit (numero 60 en rax)
    xor rdi, rdi        ; codigo de salida: 0 (exito)
    syscall             ; invoca al kernel para terminar el programa

; ------------------------------------------------------------------------------
; SUBRUTINA: Imprimir Matriz
; Parametro: r10 (Debe contener la direccion base de la matriz a imprimir)
; ------------------------------------------------------------------------------
; Imprime una matriz 3x3 almacenada en memoria como un arreglo lineal de 9 bytes
; Los elementos se muestran separados por espacios, con saltos de linea cada 3
; elementos para formar visualmente las filas de la matriz
; ------------------------------------------------------------------------------
.imprimir_matriz:
    xor r13, r13        ; r13 = 0 (contador global, recorre los 9 elementos: 0 a 8)
.loop_impresion:
    cmp r13, 9          ; Verifica si ya imprimimos los 9 elementos
    jge .fin_impresion  ; Si ya terminamos, sale del ciclo

    ; Imprimir el digito actual
    ; Usa la syscall sys_write (rax=1) para escribir a stdout (rdi=1)
    mov rax, 1          ; syscall: sys_write
    mov rdi, 1          ; file descriptor: stdout
    lea rsi, [r10 + r13] ; Carga la direccion efectiva del byte actual: base + indice
    mov rdx, 1          ; Longitud: 1 byte (un solo caracter)
    syscall             ; Ejecuta la escritura

    ; Imprimir espacio en blanco despues de cada digito
    print_string espacio, 1

    inc r13             ; Incrementa el contador de elementos (r13++)

    ; Verificar si necesitamos salto de linea (cada 3 elementos)
    ; Se calcula (r13) mod 3 usando la instruccion DIV
    ; Si el residuo (rdx) es 0, significa que completamos una fila de 3 elementos
    mov rax, r13        ; Copia el contador a rax (dividendo)
    xor rdx, rdx        ; Limpia rdx antes de la division (rdx guardara el residuo)
    mov rbx, 3          ; Divisor: 3
    div rbx             ; rax = cociente (r13 / 3), rdx = residuo (r13 % 3)
    cmp rdx, 0          ; Compara el residuo con 0
    jne .loop_impresion ; Si el residuo NO es 0, continua sin salto de linea

    ; Imprimir salto de linea (cuando residuo == 0, es decir, cada 3 elementos)
    print_string salto_linea, 1
    jmp .loop_impresion ; Continua con el siguiente elemento

.fin_impresion:
    ret                 ; Retorna al punto desde donde se llamo a la subrutina
    