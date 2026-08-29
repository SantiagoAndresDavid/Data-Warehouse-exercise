#!/bin/bash
set -e

HDFS_PATH="/raw"

echo "================================="
echo " Subiendo datasets"
echo "================================="

docker exec namenode hdfs dfs -mkdir -p "$HDFS_PATH"

for file in /dataset/*.csv
do
    [ -e "$file" ] || continue

    filename=$(basename "$file")
    echo "Procesando: $filename"

    docker exec namenode hdfs dfs -put -f "$file" "$HDFS_PATH"

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