#!/usr/bin/env bash
# Pipeline MiniLang. Ejecuta Java, Python y MIPS sobre un programa .mini
# Uso: ./run.sh [archivo.mini]   (por defecto programa.mini)

# set -u detiene el script si se usa una variable que no existe
set -u
# Trabajar siempre desde la carpeta del proyecto, sin importar desde donde se llame
cd "$(dirname "$0")"

ENTRADA="${1:-programa.mini}"
IR="salida/programa.ir"
RESULTADO="salida/resultado.txt"
FIRMA="salida/firma.txt"
MARS="mips/Mars4_5.jar"

# Muestra en que etapa fallo y termina con codigo 1
detener() {
    echo ""
    echo "PIPELINE DETENIDO en la etapa $1"
    exit 1
}

if [ ! -f "$ENTRADA" ]; then
    echo "No existe el archivo $ENTRADA"
    exit 2
fi

mkdir -p salida java/out

# Borrar salidas de una ejecucion anterior para no procesar archivos viejos
# Si un comando falla, || llama a detener y el script termina antes de la siguiente etapa
rm -f "$IR" "$RESULTADO" "$FIRMA"

echo "== Compilando Java"
javac -d java/out java/src/minilang/*.java || detener "de compilacion"

echo "== Etapa 1, Java, analisis y traduccion de $ENTRADA"
java -cp java/out minilang.Main "$ENTRADA" "$IR" || detener "1 (Java)"

echo "== Etapa 2, Python, ejecucion funcional"
python3 python/ejecutor.py "$IR" "$RESULTADO" || detener "2 (Python)"

echo "== Etapa 3, MIPS, firma de verificacion"
java -jar "$MARS" nc ae1 se1 mips/firma.asm || detener "3 (MIPS)"
# Revision extra, MARS debe haber creado firma.txt
[ -f "$FIRMA" ] || detener "3 (MIPS), no se genero $FIRMA"

echo ""
echo "PIPELINE COMPLETO"
echo "  $IR"
echo "  $RESULTADO"
echo "  $FIRMA"
