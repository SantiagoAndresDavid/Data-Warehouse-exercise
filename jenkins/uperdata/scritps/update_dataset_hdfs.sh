#!/bin/bash
set -e

DATA_DIR="/dataset"
HDFS_PATH="/raw"

echo "================================="
echo " Subiendo datasets"
echo "================================="

# Crear la carpeta en HDFS si no existe
docker exec namenode hdfs dfs -mkdir -p "$HDFS_PATH"

for file in "$DATA_DIR"/*.csv
do
    [ -e "$file" ] || continue

    filename=$(basename "$file")
    echo "Procesando: $filename"

    docker cp "$file" namenode:/tmp/"$filename"
    docker exec namenode hdfs dfs -put -f /tmp/"$filename" "$HDFS_PATH"

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