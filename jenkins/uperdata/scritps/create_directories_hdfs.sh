#!/bin/bash

set -e

DATA_DIR="jenkins/uperdata/data"
HDFS_PATH="/raw"

echo "================================="
echo " Creando directorio HDFS"
echo "================================="

# Crear el directorio en HDFS si no existe
if docker exec namenode hdfs dfs -test -d "$HDFS_PATH"; then
  echo "El directorio HDFS $HDFS_PATH ya existe."
else
  docker exec namenode hdfs dfs -mkdir -p "$HDFS_PATH"
  echo "Se creó el directorio HDFS $HDFS_PATH."
fi

# Verificar si el directorio HDFS creado existe
if docker exec namenode hdfs dfs -test -d "$HDFS_PATH"; then
  echo "El directorio HDFS $HDFS_PATH existe y fue validado correctamente."
else
  echo "ERROR: El directorio HDFS $HDFS_PATH no existe."
fi

echo ""
echo "Proceso completado"