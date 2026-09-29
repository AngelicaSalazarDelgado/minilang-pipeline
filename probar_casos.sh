#!/usr/bin/env bash
# Ejecuta el pipeline con cada caso de prueba y guarda la evidencia en evidencias/
# Uso: ./probar_casos.sh

cd "$(dirname "$0")"
mkdir -p evidencias

for caso in casos/*.mini; do
    nombre=$(basename "$caso" .mini)
    destino="evidencias/$nombre"
    rm -rf "$destino"
    mkdir -p "$destino"

    ./run.sh "$caso" > "$destino/ejecucion.log" 2>&1
    codigo=$?   # codigo de salida de run.sh, 0 si el pipeline termino completo

    # Copiar los archivos que el pipeline alcanzo a generar
    cp salida/programa.ir salida/resultado.txt salida/firma.txt "$destino/" 2>/dev/null

    if [ $codigo -eq 0 ]; then
        echo "$nombre  COMPLETO  $(cat salida/firma.txt)"
    else
        echo "$nombre  DETENIDO  $(grep -m1 '^Error' "$destino/ejecucion.log")"
    fi
done

# Dejar en salida/ los archivos de la ejecucion principal
./run.sh > /dev/null 2>&1
echo ""
echo "salida/ contiene la ejecucion de programa.mini"
