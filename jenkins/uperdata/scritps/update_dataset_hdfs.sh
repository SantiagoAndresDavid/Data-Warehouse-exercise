#!/bin/bash

set -e

DATA_DIR="jenkins/dataset"
HDFS_PATH="/raw"

echo "================================="
echo " Subiendo datasets"
echo "================================="

for file in ${DATA_DIR}/*.csv
do
    filename=$(basename "$file")
    echo "Procesando: $filename"

    docker cp "$file" namenode:/tmp/"$filename"

    docker exec namenode hdfs dfs -put -f /tmp/"$filename" ${HDFS_PATH}
done

echo ""
echo "================================="
echo " Archivos cargados"
echo "================================="

docker exec namenode \
hdfs dfs -ls ${HDFS_PATH}

echo ""
echo "Proceso completado"