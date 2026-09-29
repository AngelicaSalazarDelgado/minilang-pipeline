# MiniLang Pipeline

Examen parcial, Parte B. EIF400 Paradigmas de Programación, II Ciclo 2026.
Universidad Nacional, Sede Regional Brunca, Campus Coto.
Angélica Salazar Delgado.

Pipeline políglota que analiza un pequeño lenguaje de transformación de datos en Java, lo ejecuta con estilo funcional en Python y genera una firma de verificación en MIPS. Las etapas se comunican solo mediante archivos. El diagrama y los contratos están en `docs/CONTRATOS.md`.

## Requisitos

- Linux o WSL con bash
- JDK 11 o superior (`javac` y `java`)
- Python 3.8 o superior
- MARS 4.5, incluido en `mips/Mars4_5.jar`

## Estructura

```text
minilang-pipeline/
  programa.mini          programa principal de prueba
  run.sh                 ejecuta el pipeline completo
  probar_casos.sh        ejecuta todos los casos y guarda evidencias
  demo.sh                demostracion guiada que se uso para grabar el video
  java/src/minilang/     etapa 1, lexer, parser, analisis semantico y jerarquia de instrucciones
  python/ejecutor.py     etapa 2, ejecucion con filter, map y reduce
  mips/firma.asm         etapa 3, checksum de verificacion
  mips/Mars4_5.jar       simulador MARS usado para ejecutar la etapa 3
  casos/                 casos de prueba .mini
  salida/                programa.ir, resultado.txt y firma.txt de la ejecucion principal
  evidencias/            log y archivos generados por cada caso
  docs/                  contratos, diagrama y documento de decisiones
```

## Ejecución

Todos los comandos se ejecutan desde la carpeta raíz del proyecto.

```bash
./run.sh                                       # ejecuta programa.mini
./run.sh casos/caso02_operador_invalido.mini   # ejecuta otro programa
./probar_casos.sh                              # ejecuta todos los casos y guarda evidencias
./demo.sh                                      # demostracion guiada con explicaciones en pantalla
```

Si los scripts no tienen permiso de ejecución, se habilita con `chmod +x run.sh probar_casos.sh demo.sh`.

`run.sh` borra las salidas de la ejecución anterior, compila Java y ejecuta las tres etapas en orden. Si una etapa falla, muestra el error, indica en qué etapa se detuvo y no ejecuta las siguientes.

### Ejecución manual por etapa

```bash
javac -d java/out java/src/minilang/*.java
java -cp java/out minilang.Main programa.mini salida/programa.ir
python3 python/ejecutor.py salida/programa.ir salida/resultado.txt
java -jar mips/Mars4_5.jar nc ae1 se1 mips/firma.asm
```

El programa MIPS usa las rutas relativas `salida/resultado.txt` y `salida/firma.txt`, por eso debe ejecutarse desde la carpeta raíz.

## Códigos de salida

| Código | Significado |
|---|---|
| 0 | La etapa terminó correctamente |
| 1 | Error de análisis, de contrato o de ejecución |
| 2 | Error de uso o de lectura de archivos |

## Casos de prueba

Los casos 01 a 06 corresponden a las seis pruebas obligatorias del enunciado, en el mismo orden. Los casos 07 a 11 son adicionales.

| Caso | Propósito | Resultado |
|---|---|---|
| 01 | Programa válido con FILTER, MAP, REDUCE y PRINT | RESULT=60, OPS=3, FIRMA=80 |
| 02 | Operador inválido | Error léxico en línea 3, se detiene en Java |
| 03 | Programa sin DATA | Error sintáctico en línea 1, se detiene en Java |
| 04 | REDUCE MAX | RESULT=15, OPS=2, FIRMA=30 |
| 05 | FILTER deja la lista vacía | RESULT=0, OPS=2, FIRMA=19 |
| 06 | MAP y FILTER consecutivos | RESULT=63, OPS=4, FIRMA=76 |
| 07 | MAP después de REDUCE | Error semántico en línea 3, se detiene en Java |
| 08 | REDUCE MAX sobre lista vacía | Error de ejecución, se detiene en Python |
| 09 | Programa sin REDUCE | RESULT=16,20,24, OPS=2, FIRMA=16039 |
| 10 | Programa sin PRINT | Error sintáctico en línea 2, se detiene en Java |
| 11 | MAP que produce negativos | RESULT=-3, OPS=2, FIRMA=16 |

La evidencia de cada caso está en `evidencias/<caso>/`, con el log de la ejecución y los archivos que el pipeline alcanzó a generar.

## Video de demostración

El video muestra una ejecución completa y un caso de error.

[Ver el video de demostración](AGREGAR_ENLACE_DEL_VIDEO)

## Referencias

- Oracle. Java SE API, clases `java.util.regex.Pattern` y `java.util.regex.Matcher`. https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/regex/Pattern.html
- Python Software Foundation. Módulo `functools`, función `reduce`. https://docs.python.org/3/library/functools.html
- Python Software Foundation. Módulo `operator`. https://docs.python.org/3/library/operator.html
- Vollmar, K. y Sanderson, P. MARS 4.5, ayuda integrada del simulador, secciones de syscalls y opciones de línea de comandos.
