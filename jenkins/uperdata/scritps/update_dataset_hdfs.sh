#!/bin/bash
set -uo pipefail

WORKSPACE_DIR="${WORKSPACE:-$(pwd)}"
DATA_DIR="${WORKSPACE_DIR}/dataset"
HDFS_PATH="/raw"

 echo "================================="
 echo " DIAGNÓSTICO: importación de datasets a HDFS"
 echo "================================="
 echo "WORKSPACE_DIR = $WORKSPACE_DIR"
 echo "DATA_DIR      = $DATA_DIR"
 echo "HDFS_PATH     = $HDFS_PATH"
 echo ""

if [ ! -d "$DATA_DIR" ]; then
    echo "ERROR: no existe el directorio $DATA_DIR en el workspace del pipeline."
    ls -la "$WORKSPACE_DIR" || true
    exit 1
fi

ls -la "$DATA_DIR"

shopt -s nullglob
CSV_FILES=("$DATA_DIR"/*.csv)

echo "CSV encontrados: ${#CSV_FILES[@]}"
for f in "${CSV_FILES[@]}"; do
    echo "- $f"
done

if [ ${#CSV_FILES[@]} -eq 0 ]; then
    echo "ERROR: no se encontraron archivos CSV en $DATA_DIR"
    exit 1
fi

echo ""
echo "Validando acceso a Docker..."
docker ps --format '{{.Names}}' || true

echo ""
echo "Creando directorio HDFS $HDFS_PATH..."
docker exec namenode hdfs dfs -mkdir -p "$HDFS_PATH"
status=$?
if [ $status -ne 0 ]; then
    echo "ERROR: no se pudo crear $HDFS_PATH en HDFS"
    exit $status
fi

echo ""
for file in "${CSV_FILES[@]}"
do
    filename=$(basename "$file")
    echo "================================="
    echo "Procesando: $filename"
    echo "Origen local: $file"
    echo "Destino temporal: /tmp/$filename"

    ls -l "$file" || { echo "ERROR: no existe el archivo $file"; exit 1; }

    docker cp "$file" namenode:/tmp/"$filename"
    status=$?
    if [ $status -ne 0 ]; then
        echo "ERROR: docker cp falló para $file"
        exit $status
    fi

    echo "Subiendo a HDFS..."
    docker exec namenode hdfs dfs -put -f "/tmp/$filename" "$HDFS_PATH"
    status=$?
    if [ $status -ne 0 ]; then
        echo "ERROR: hdfs dfs -put falló para $filename"
        exit $status
    fi

    echo "Validando que exista en HDFS..."
    docker exec namenode hdfs dfs -test -f "$HDFS_PATH/$filename"
    status=$?
    if [ $status -ne 0 ]; then
        echo "ERROR: $filename no quedó en HDFS en $HDFS_PATH"
        exit $status
    fi

    echo "OK: $filename cargado correctamente"
done

echo ""
echo "================================="
echo " Archivos cargados"
echo "================================="

docker exec namenode hdfs dfs -ls "$HDFS_PATH"
status=$?
if [ $status -ne 0 ]; then
    echo "ERROR: no se pudo listar $HDFS_PATH"
    exit $status
fi

echo ""
echo "Proceso completado"