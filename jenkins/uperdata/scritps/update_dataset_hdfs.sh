#!/bin/bash
set -euo pipefail

HDFS_PATH="/raw"
DATA_DIR="/dataset"

echo "================================="
echo " Subiendo datasets"
echo "================================="

if [ ! -d "$DATA_DIR" ]; then
    echo "ERROR: no existe el directorio $DATA_DIR dentro del contenedor Jenkins/namenode."
    exit 1
fi

shopt -s nullglob
CSV_FILES=("$DATA_DIR"/*.csv)

if [ ${#CSV_FILES[@]} -eq 0 ]; then
    echo "ERROR: no se encontraron archivos CSV en $DATA_DIR"
    exit 1
fi

docker exec namenode hdfs dfs -mkdir -p "$HDFS_PATH"

for file in "${CSV_FILES[@]}"
do
    filename=$(basename "$file")
    echo "Procesando: $filename"

    docker cp "$file" namenode:/tmp/"$filename"
    docker exec namenode hdfs dfs -put -f "/tmp/$filename" "$HDFS_PATH"

    if ! docker exec namenode hdfs dfs -test -f "$HDFS_PATH/$filename"; then
        echo "ERROR: $filename no se cargó correctamente en HDFS"
        exit 1
    fi
done

echo ""
echo "================================="
echo " Archivos cargados"
echo "================================="

docker exec namenode hdfs dfs -ls "$HDFS_PATH"

echo ""
echo "Proceso completado"