# Diagrama y contratos de archivos

## Diagrama del pipeline

```text
          programa.mini
                |
                v
  +--------------------------------+
  | ETAPA 1, JAVA                  |
  | Lexer con expresiones regulares|
  | Parser descendente recursivo   |
  | Analisis semantico             |
  | Jerarquia de Instruccion       |
  +---------------+----------------+
                  |  programa.ir, solo si el programa es valido
                  v
  +--------------------------------+
  | ETAPA 2, PYTHON                |
  | Validacion del contrato        |
  | filter, map y reduce           |
  +---------------+----------------+
                  |  resultado.txt, con traza, RESULT y OPS
                  v
  +--------------------------------+
  | ETAPA 3, MIPS                  |
  | Lectura de RESULT y OPS        |
  | Checksum con mul, xor y suma   |
  +---------------+----------------+
                  |
                  v
              firma.txt
```

Cada etapa termina con código 1 si falla. `run.sh` revisa ese código y detiene el pipeline, así ninguna etapa procesa un archivo que la anterior no generó.

## Contrato 1, programa.mini

Es la entrada del pipeline y el único archivo escrito a mano. Sigue la gramática del enunciado.

```text
<programa>   ::= <data> <operacion> { <operacion> } "PRINT"
<data>       ::= "DATA" <numero> { <numero> }
<operacion>  ::= <filter> | <map> | <reduce>
<filter>     ::= "FILTER" <comparador> <numero>
<map>        ::= "MAP" <aritmetico> <numero>
<reduce>     ::= "REDUCE" ("SUM" | "MAX" | "MIN")
<comparador> ::= ">" | "<" | ">=" | "<=" | "=="
<aritmetico> ::= "+" | "-" | "*"
<numero>     ::= entero no negativo
```

Decisiones léxicas

- Las palabras clave solo se aceptan en mayúscula.
- Los espacios, tabulaciones y saltos de línea solo separan tokens. La gramática no exige una instrucción por línea, aunque los casos se escriben así.
- Los números son enteros no negativos. `-5` se lee como el operador `-` seguido de `5`, y en DATA produce un error sintáctico.
- Los símbolos de dos caracteres (`>=`, `<=`, `==`) se reconocen antes que los de uno, para tomar siempre la coincidencia más larga.

## Contrato 2, programa.ir (de Java a Python)

Una instrucción por línea, con los campos separados por `|`.

```text
Formato                    Ejemplo
DATA|n1,n2,...             DATA|3,8,5,10,12
FILTER|comparador|n        FILTER|>|5
MAP|operador|n             MAP|*|2
REDUCE|SUM, MAX o MIN      REDUCE|SUM
PRINT                      PRINT
```

- La primera línea es DATA y la última es PRINT.
- Entre ellas hay al menos una operación, y REDUCE solo puede ser la última.
- Java lo genera solo si el programa pasa las fases léxica, sintáctica y semántica. Si hay error, borra cualquier `programa.ir` anterior.
- Python vuelve a validar el formato antes de ejecutar y no confía ciegamente en el archivo.

## Contrato 3, resultado.txt (de Python a MIPS)

```text
FILTER > 5 => [8, 10, 12]
MAP * 2 => [16, 20, 24]
REDUCE SUM => 60
RESULT=60
OPS=3
```

- Las líneas de traza son para lectura humana y MIPS las ignora.
- `RESULT=` lleva un número si el programa tiene REDUCE, una secuencia separada por comas si no lo tiene (`RESULT=16,20,24`) y queda vacío si la lista final está vacía y no hubo REDUCE.
- `OPS=` es la cantidad de operaciones ejecutadas. Solo cuentan FILTER, MAP y REDUCE, no DATA ni PRINT.
- Python lo genera solo si la ejecución termina bien. Si falla, borra cualquier `resultado.txt` anterior.

## Contrato 4, firma.txt (salida de MIPS)

```text
FIRMA=80
```

```text
checksum = 0
por cada numero n de RESULT, checksum = checksum * 31 + n
checksum = checksum XOR ops
checksum = checksum + 17
```

Con un solo resultado equivale a la fórmula del enunciado, `(resultado XOR ops) + 17`. Con una secuencia, multiplicar por 31 hace que la firma cambie si cambia el orden de los elementos.

## Decisiones de diseño

| Situación | Decisión | Etapa |
|---|---|---|
| FILTER, MAP o REDUCE después de REDUCE | Error semántico, el valor ya no es una lista | Java |
| REDUCE SUM sobre lista vacía | Devuelve 0, su elemento neutro | Python |
| REDUCE MAX o MIN sobre lista vacía | Error de ejecución, no tienen elemento neutro | Python |
| Programa sin REDUCE | RESULT es una secuencia | Python y MIPS |
| Resultados negativos | Se permiten y MIPS reconoce el signo | Python y MIPS |
| Archivos de una ejecución anterior | `run.sh` los borra al iniciar y cada etapa borra su salida si falla | Todas |

## Manejo de errores

| Etapa | Tipo de error | Ejemplo | Caso |
|---|---|---|---|
| Java | Léxico | Símbolo `%` no reconocido | 02 |
| Java | Sintáctico | Falta DATA o falta PRINT | 03 y 10 |
| Java | Semántico | MAP después de REDUCE | 07 |
| Python | Contrato | `programa.ir` con formato inválido | Solo si se edita a mano |
| Python | Ejecución | REDUCE MAX sobre lista vacía | 08 |
| MIPS | Contrato | Falta `RESULT=` u `OPS=` en `resultado.txt` | Solo si se edita a mano |
| MIPS | Tamaño | `resultado.txt` de 4095 bytes o más no cabe en el buffer | Programa con cientos de datos y sin REDUCE |
