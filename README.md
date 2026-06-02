# Calculadora de Matriz Traspuesta en NASM

Este programa esta escrito en ensamblador NASM y funciona en sistemas Linux de 64 bits. Su proposito es pedir al usuario que ingrese los nueve digitos de una matriz de 3 filas por 3 columnas, calcular la traspuesta de esa matriz y mostrar ambos resultados en pantalla.

## Entorno de Ejecucion

- **Arquitectura:** x86_64
- **Sistema operativo:** Linux
- **Ensamblador:** NASM
- **Enlazador:** GNU `ld`

## Instrucciones de Compilacion y Ejecucion

Para compilar y ejecutar el programa en una terminal Linux:

```bash
# Compilar el codigo fuente a un archivo objeto
nasm -f elf64 matriz_traspuesta.asm -o matriz_traspuesta.o

# Enlazar el archivo objeto para generar el ejecutable
ld matriz_traspuesta.o -o matriz_traspuesta

# Ejecutar el programa
./matriz_traspuesta
```

Una vez en ejecucion, el programa guiara al usuario paso a paso para ingresar los nueve digitos y finalmente mostrara tanto la matriz original como su traspuesta.

## Como se Organiza la Memoria para la Matriz

En los lenguajes de alto nivel como C o Python, una matriz se representa naturalmente como una cuadricula de filas y columnas. Pero en el hardware de una computadora, la memoria RAM no es mas que una larga y continua secuencia de bytes, cada uno con su propia direccion. No existen las filas ni las columnas a nivel de memoria; solo posiciones consecutivas numeradas desde cero en adelante.

Para representar una matriz de 3x3 en este esquema lineal, se reservan 9 bytes contiguos. Si se piensa en la matriz como una cuadricula de 3 filas y 3 columnas, la posicion del elemento que esta en la fila i y la columna j se calcula con la formula `i * 3 + j`. Por ejemplo, el elemento de la fila 1, columna 2 estaria en la posicion `1 * 3 + 2 = 5`, es decir, el sexto byte del bloque (contando desde cero). Este mapeo de coordenadas bidimensionales a un indice lineal es la clave para poder trabajar con matrices en ensamblador.

Como el programa reserva los 9 bytes de forma consecutiva en la seccion BSS del codigo, acceder a cada elemento de la matriz se reduce a tomar la direccion base del bloque y sumarle el desplazamiento calculado con la formula anterior. Esto es exactamente lo que hace el procesador cuando ejecuta instrucciones como `mov byte [matriz + rax], al`: suma el valor del registro rax (el indice lineal) a la direccion base de `matriz` y accede a ese byte en memoria.

## Captura de los Digitos

Al iniciar, el programa muestra un mensaje de bienvenida y comienza a pedir al usuario que ingrese un digito del 0 al 9. Esto lo hace nueve veces, una por cada celda de la matriz.

Cada caracter que el usuario escribe pasa por una validacion: si no esta entre el 0 y el 9, se muestra un mensaje de error y se vuelve a pedir el mismo digito sin avanzar al siguiente. Si el usuario presiona Enter sin haber escrito nada, simplemente se ignora y se espera un caracter valido.

Una situacion particular que debe manejarse con cuidado ocurre cuando el usuario escribe varios caracteres seguidos, por ejemplo "1A3", y luego presiona Enter. El sistema operativo entrega todo lo que se escribio en el buffer de entrada, pero el programa necesita un digito a la vez. Para evitar que los caracteres sobrantes interfieran con las lecturas siguientes, despues de cada digito valido el programa lee y descarta todos los caracteres que encuentre en el buffer hasta llegar al Enter. Asi se asegura que cada nueva solicitud comience con el buffer limpio.

Si el primer caracter que escribe el usuario no es valido, el programa muestra el error correspondiente y tambien vacia el buffer de entrada antes de pedir el digito nuevamente, de modo que las lecturas posteriores no se vean afectadas por caracteres residuales.

## Calculo de la Matriz Traspuesta

Una vez capturados los nueve digitos, el programa procede a calcular la matriz traspuesta. La traspuesta de una matriz consiste en intercambiar filas por columnas: el elemento que esta en la fila i y columna j de la matriz original debe colocarse en la fila j y columna i de la nueva matriz.

Para lograr esto, el programa recorre la matriz original con dos ciclos anidados. El ciclo exterior recorre las filas (i de 0 a 2) y el ciclo interior recorre las columnas (j de 0 a 2). En cada iteracion se realizan dos operaciones:

1. Se calcula el indice lineal del elemento en la matriz original usando la formula `i * 3 + j` y se extrae el valor de ese byte.
2. Se calcula el indice lineal donde debe guardarse ese valor en la matriz traspuesta usando la formula inversa `j * 3 + i`, y se almacena el byte alli.

Al terminar los dos ciclos, la matriz traspuesta contiene los valores originales pero con filas y columnas intercambiadas, lista para ser mostrada al usuario.

## Visualizacion de los Resultados

El programa muestra primero la matriz original y luego la matriz traspuesta. Para imprimir cada matriz, recorre sus nueve bytes uno por uno. Despues de cada digito imprime un espacio en blanco como separador. Cada vez que se han impreso tres digitos, en lugar de un espacio se imprime un salto de linea, de manera que la matriz se vea en pantalla con su forma cuadrada de 3 filas y 3 columnas.

Para detectar el momento exacto en que debe saltar de linea, el programa divide la posicion actual entre 3. Si el residuo de la division es cero, significa que acaba de imprimirse el tercer elemento de la fila y es momento de pasar a la siguiente linea.

