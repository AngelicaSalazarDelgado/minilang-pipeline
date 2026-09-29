#!/usr/bin/env bash
# Demostracion del pipeline MiniLang para grabar el video.
# Antes de cada paso muestra una explicacion en pantalla y hace una pausa
# para que se alcance a leer. No necesita narracion.
#
# Uso
#   ./demo.sh                 automatico, pensado para grabar
#   MANUAL=1 ./demo.sh        avanza cada pausa con Enter
#   VELOCIDAD=2 ./demo.sh     cambia la duracion de las pausas, por defecto 1.5
#                             (con 1.5 el video dura cerca de 5 minutos)

cd "$(dirname "$0")"
VELOCIDAD="${VELOCIDAD:-1.5}"
MANUAL="${MANUAL:-0}"

TITULO=$'\e[1;36m'
TEXTO=$'\e[0;37m'
CMD=$'\e[1;33m'
FIN=$'\e[0m'

# Espera N segundos, escalados por VELOCIDAD. En modo manual espera Enter.
pausa() {
    if [ "$MANUAL" = "1" ]; then
        read -r -s
    else
        sleep "$(awk "BEGIN { print $1 * $VELOCIDAD }")"
    fi
}

# Imprime un texto letra por letra, como si se estuviera escribiendo
escribir() {
    local texto="$1" i
    printf '%s' "$TEXTO"
    for ((i = 0; i < ${#texto}; i++)); do
        printf '%s' "${texto:i:1}"
        sleep 0.012
    done
    printf '%s\n' "$FIN"
}

# Limpia la pantalla y muestra el titulo de una seccion
seccion() {
    clear
    printf '%s' "$TITULO"
    printf '==================================================================\n'
    printf '  %s\n' "$1"
    printf '==================================================================\n'
    printf '%s\n' "$FIN"
}

# Muestra un comando, espera un momento y lo ejecuta
comando() {
    echo ""
    printf '%s$ %s%s\n' "$CMD" "$1" "$FIN"
    sleep 1
    eval "$1"
    echo ""
}

# Portada
seccion "MiniLang Pipeline"
escribir "Examen parcial, Parte B. EIF400 Paradigmas de Programación, II Ciclo 2026."
escribir "Angélica Salazar Delgado. Universidad Nacional, Sede Regional Brunca, Campus Coto."
echo ""
pausa 3
escribir "Este video muestra un pipeline de tres etapas, cada una en un lenguaje y un paradigma distinto."
escribir "Java analiza el programa, Python lo ejecuta con estilo funcional y MIPS calcula una firma de verificación."
escribir "Las etapas solo se comunican mediante archivos."
pausa 8

# 1. Estructura
seccion "1. Estructura del proyecto"
escribir "Cada carpeta contiene una etapa del pipeline o una parte de la entrega."
comando "ls"
escribir "Estos son los archivos de código de las tres etapas."
comando "ls java/src/minilang python mips"
pausa 9

# 2. Entrada
seccion "2. El programa de entrada"
escribir "programa.mini está escrito en el mini lenguaje. Empieza con DATA, aplica operaciones y termina con PRINT."
comando "cat programa.mini"
escribir "El resultado esperado se calcula así."
escribir "  FILTER > 5    conserva los mayores que 5    [8, 10, 12]"
escribir "  MAP * 2       multiplica cada elemento      [16, 20, 24]"
escribir "  REDUCE SUM    suma todos los elementos      60"
pausa 9

# 3. Ejecucion completa
seccion "3. Ejecución completa del pipeline"
escribir "run.sh borra las salidas anteriores, compila Java y ejecuta las tres etapas en orden."
escribir "Cada etapa solo avanza si la anterior terminó sin errores."
pausa 3
comando "./run.sh"
escribir "Las tres etapas terminaron y se generaron programa.ir, resultado.txt y firma.txt."
pausa 8

# 4. Java
seccion "4. Etapa 1, Java y programa.ir"
escribir "Java revisa el programa en tres fases, léxica, sintáctica y semántica."
escribir "Si es válido, traduce cada instrucción a una línea de la representación intermedia."
comando "cat salida/programa.ir"
pausa 3
escribir "Cada instrucción es una clase. FILTER, MAP y REDUCE heredan de Operacion, que hereda de Instruccion."
comando "grep -n 'extends' java/src/minilang/Operacion.java java/src/minilang/*Instr.java"
pausa 3
escribir "La traducción usa polimorfismo. El ciclo llama a toIR() sin preguntar el tipo de cada instrucción."
comando "grep -n -B1 -A1 'i.toIR()' java/src/minilang/Main.java"
pausa 9

# 5. Python
seccion "5. Etapa 2, Python y resultado.txt"
escribir "Python valida programa.ir y ejecuta cada operación con filter, map y reduce, sin ciclos for ni while."
comando "grep -n -A4 -E 'def ejecutar_(filter|map)' python/ejecutor.py"
pausa 3
escribir "Toda la secuencia de operaciones también es un reduce, que pasa el estado de una operación a la siguiente."
comando "grep -n 'return reduce(aplicar' python/ejecutor.py"
pausa 3
escribir "El resultado incluye una traza de cada operación, el resultado final y la cantidad de operaciones."
comando "cat salida/resultado.txt"
pausa 9

# 6. MIPS
seccion "6. Etapa 3, MIPS y firma.txt"
escribir "MIPS lee RESULT y OPS de resultado.txt, convierte el texto a números carácter por carácter"
escribir "y calcula la firma con una multiplicación, una operación lógica XOR y una suma."
comando "grep -n -E '^ +(mul|xor|addiu) +.s4' mips/firma.asm"
pausa 3
escribir "Con los valores de esta ejecución."
escribir "  60 XOR 3 = 63"
escribir "  63 + 17  = 80"
comando "cat salida/firma.txt"
pausa 9

# 7. Error lexico
seccion "7. Caso de error, operador inválido"
escribir "El caso 2 usa el operador %, que no existe en el lenguaje."
comando "cat casos/caso02_operador_invalido.mini"
pausa 3
comando "./run.sh casos/caso02_operador_invalido.mini"
escribir "Java reporta un error léxico con su número de línea y el pipeline se detiene en la etapa 1."
escribir "La carpeta salida queda vacía, así ninguna etapa procesa archivos de una ejecución anterior."
comando "ls -l salida/"
pausa 9

# 8. Otros errores
seccion "8. Otros tipos de error"
escribir "Caso 3, el programa no empieza con DATA. Es un error sintáctico."
comando "./run.sh casos/caso03_sin_data.mini"
pausa 5
escribir "Caso 7, MAP después de REDUCE. La gramática lo permite, pero no tiene sentido. Es un error semántico."
comando "./run.sh casos/caso07_error_semantico.mini"
pausa 5
escribir "Caso 8, REDUCE MAX sobre una lista vacía. Java lo acepta, pero Python lo detiene al ejecutar."
comando "./run.sh casos/caso08_max_lista_vacia.mini"
pausa 9

# 9. Todos los casos
seccion "9. Todos los casos de prueba"
escribir "probar_casos.sh ejecuta los 11 casos y guarda la evidencia de cada uno en la carpeta evidencias."
escribir "Los casos 1 a 6 son los obligatorios del enunciado y los casos 7 a 11 son adicionales."
comando "./probar_casos.sh"
pausa 12

# Cierre
seccion "Resumen"
escribir "Java modela el lenguaje con herencia y polimorfismo."
escribir "Python transforma los datos con estilo funcional."
escribir "MIPS verifica el resultado con operaciones de bajo nivel."
escribir "Los contratos de archivos permiten que las tres etapas colaboren sin conocerse."
echo ""
pausa 6
escribir "Fin de la demostración."
echo ""
