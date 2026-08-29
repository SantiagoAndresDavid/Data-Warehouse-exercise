#!/bin/bash

DATA_DIR="jenkins/uperdata/data"
HDFS_PATH="/raw"

echo "================================="
echo " Creando directorio HDFS"
echo "================================="

docker exec namenode hdfs dfs -p ${HDFS_PATH}

echo ""
echo "Proceso completado"