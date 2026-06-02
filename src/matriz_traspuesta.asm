; ==============================================================================
; ARCHIVO: matriz_traspuesta.asm
; DESCRIPCIoN: Captura una matriz 3x3 de un solo digito por celda, 
;              calcula su traspuesta y muestra los resultados.
; COMPILAR: nasm -f elf64 matriz_traspuesta.asm -o matriz_traspuesta.o
; ENLAZAR: ld matriz_traspuesta.o -o matriz_traspuesta
; EJECUTAR: ./matriz_traspuesta
; ==============================================================================

; ------------------------------------------------------------------------------
; MACROS
; ------------------------------------------------------------------------------
; Macro para imprimir cadenas en la salida estandar (stdout)
%macro print_string 2
    mov rax, 1          ; syscall: sys_write
    mov rdi, 1          ; file descriptor: stdout
    mov rsi, %1         ; puntero a la cadena
    mov rdx, %2         ; longitud de la cadena
    syscall
%endmacro

; Macro para leer la entrada estandar (stdin)
%macro read_input 2
    mov rax, 0          ; syscall: sys_read
    mov rdi, 0          ; file descriptor: stdin
    mov rsi, %1         ; puntero al buffer
    mov rdx, %2         ; bytes a leer
    syscall
%endmacro

; ------------------------------------------------------------------------------
; SECCION DE DATOS - Variables inicializadas
; ------------------------------------------------------------------------------
section .data
    msg_titulo    db "--- MATRIZ 3x3 Y SU TRASPUESTA ---", 10, 0
    len_titulo    equ $ - msg_titulo

    msg_prompt    db "Ingrese un digito (0-9) para la matriz: ", 0
    len_prompt    equ $ - msg_prompt

    msg_error     db "ERROR: Caracter invalido. Ingrese solo un digito (0-9).", 10, 0
    len_error     equ $ - msg_error

    msg_original  db 10, "--- MATRIZ ORIGINAL ---", 10, 0
    len_original  equ $ - msg_original

    msg_tras      db 10, "--- MATRIZ TRASPUESTA ---", 10, 0
    len_tras      equ $ - msg_tras

    espacio       db " ", 0
    salto_linea   db 10, 0

; ------------------------------------------------------------------------------
; SECCION BSS - Variables no inicializadas
; ------------------------------------------------------------------------------
section .bss
    matriz        resb 9  ; Reserva 9 bytes para la matriz 3x3 original
    traspuesta    resb 9  ; Reserva 9 bytes para la matriz traspuesta
    buffer_in     resb 1  ; Buffer de 1 byte para lectura de teclado

; ------------------------------------------------------------------------------
; SECCION DE TEXTO - Codigo ejecutable
; ------------------------------------------------------------------------------
section .text
    global _start

_start:
    print_string msg_titulo, len_titulo
    
    ; Inicializacion del contador de elementos capturados
    xor r12, r12        ; r12 = 0 (Contador de elementos: 0 a 8)

; Etiqueta principal de captura de datos
.ciclo_captura:
    cmp r12, 9          ; Verifica si ya tenemos 9 elementos
    jge .calcular_trasp ; Si r12 >= 9, pasa a calcular la traspuesta

    print_string msg_prompt, len_prompt

.leer_caracter:
    read_input buffer_in, 1
    mov al, byte [buffer_in]

    ; Validar si el usuario solo presiono ENTER sin datos previos
    cmp al, 10
    je .leer_caracter   ; Ignora ENTER solitarios o residuales

    ; --- VALIDACION DE RANGO [0-9] ---
    cmp al, '0'         ; Compara con ASCII '0' (0x30)
    jl .entrada_invalida
    cmp al, '9'         ; Compara con ASCII '9' (0x39)
    jg .entrada_invalida

    ; Si es valido, guardar en la matriz en la posicion actual
    mov byte [matriz + r12], al
    inc r12             ; Incrementar contador de elementos

    ; --- LIMPIEZA DE BUFER (FLUSH) ---
    ; Evita que si el usuario escribe "123", el "23" corrompa la matriz
.limpiar_buffer_exito:
    read_input buffer_in, 1
    cmp byte [buffer_in], 10    ; Lee hasta encontrar un salto de linea (ENTER)
    jne .limpiar_buffer_exito
    
    jmp .ciclo_captura

; Etiqueta para manejar errores
.entrada_invalida:
    print_string msg_error, len_error
    
    ; Limpiar todo lo que el usuario haya escrito en la misma linea
.limpiar_buffer_error:
    cmp al, 10          ; Si el caracter invalido era el ENTER, ya limpiamos
    je .ciclo_captura
    read_input buffer_in, 1
    mov al, byte [buffer_in]
    cmp al, 10
    jne .limpiar_buffer_error
    
    jmp .ciclo_captura  ; Regresa a solicitar el numero sin incrementar el contador

; ------------------------------------------------------------------------------
; RUTINA: Calcular Traspuesta
; ------------------------------------------------------------------------------
.calcular_trasp:
    xor r8, r8          ; r8 = Fila i (0 a 2)
.ciclo_filas:
    cmp r8, 3
    jge .mostrar_resultados
    xor r9, r9          ; r9 = Columna j (0 a 2)

.ciclo_columnas:
    cmp r9, 3
    jge .siguiente_fila

    ; Calcular indice de Matriz Original: (i * 3) + j
    mov rax, r8
    imul rax, 3
    add rax, r9
    mov cl, byte [matriz + rax] ; Extrae el valor de M[i][j]

    ; Calcular indice de Matriz Traspuesta: (j * 3) + i
    mov rax, r9
    imul rax, 3
    add rax, r8
    mov byte [traspuesta + rax], cl ; Guarda en T[j][i]

    inc r9
    jmp .ciclo_columnas

.siguiente_fila:
    inc r8
    jmp .ciclo_filas

; ------------------------------------------------------------------------------
; RUTINA: Mostrar Resultados
; ------------------------------------------------------------------------------
.mostrar_resultados:
    ; Mostrar Matriz Original
    print_string msg_original, len_original
    mov r10, matriz     ; Puntero a la matriz original
    call .imprimir_matriz

    ; Mostrar Matriz Traspuesta
    print_string msg_tras, len_tras
    mov r10, traspuesta ; Puntero a la matriz traspuesta
    call .imprimir_matriz

; ------------------------------------------------------------------------------
; RUTINA: Salir del sistema
; ------------------------------------------------------------------------------
.salir:
    mov rax, 60         ; syscall: sys_exit
    xor rdi, rdi        ; codigo de salida: 0 (éxito)
    syscall

; ------------------------------------------------------------------------------
; SUBRUTINA: Imprimir Matriz
; Parametro: r10 (Debe contener la direccion base de la matriz a imprimir)
; ------------------------------------------------------------------------------
.imprimir_matriz:
    xor r13, r13        ; r13 = contador global (0 a 8)
.loop_impresion:
    cmp r13, 9
    jge .fin_impresion

    ; Imprimir el digito actual
    mov rax, 1
    mov rdi, 1
    lea rsi, [r10 + r13] ; Calcula la direccion del byte actual
    mov rdx, 1
    syscall

    ; Imprimir espacio en blanco
    print_string espacio, 1

    inc r13

    ; Verificar si necesitamos salto de linea (cada 3 elementos)
    ; (r13) mod 3 == 0
    mov rax, r13
    xor rdx, rdx
    mov rbx, 3
    div rbx             ; rax = cociente, rdx = residuo
    cmp rdx, 0
    jne .loop_impresion

    ; Imprimir salto de linea
    print_string salto_linea, 1
    jmp .loop_impresion

.fin_impresion:
    ret