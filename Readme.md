# Data Warehouse Exercise

## Docker Compose

Lanza cada entorno con los siguientes comandos desde la raíz del proyecto:

### Jenkins

```bash
docker compose -f docker/docker-compose.jenkins.yml up -d
```

Para detenerlo:

```bash
docker compose -f docker/docker-compose.jenkins.yml down
```

### Spark + Hadoop + PostgreSQL + Metabase

```bash
docker compose -f docker/docker-compose.spark.yml up -d
```

Para detenerlo:

```bash
docker compose -f docker/docker-compose.spark.yml down
```

### Servicios principales

- Jenkins: http://localhost:8080
- Hadoop Namenode: http://localhost:9870
- Metabase: http://localhost:3000
- PostgreSQL: localhost:5432
- Spark Master: http://localhost:8080

## Descripción general del ejercicio

Este repositorio es un ejercicio práctico para aprender a construir un flujo sencillo de Data Warehouse usando datos de ejemplo, contenedores Docker (Hadoop/HDFS, Spark, PostgreSQL, Metabase) y automatización con Jenkins. El objetivo es llevar datasets CSV desde el workspace local al HDFS (`/raw`), validar y procesar datos con jobs de Spark, y finalmente exponer resultados en una base de datos y en Metabase.

Objetivos de aprendizaje:

- Entender cómo montar un stack local de big data con Docker Compose (HDFS, Spark, Postgres, Metabase).
- Practicar la importación y validación de datasets en HDFS.
- Implementar trabajos de limpieza y transformación en Spark (raw -> bronze/gold).
- Integrar el proceso en pipelines de CI con Jenkins.
- Familiarizarse con la orquestación de archivos, scripts y parámetros para entornos reproducibles.

## Arquitectura y flujo de datos

Diagrama simplificado (ASCII):

```
Local Workspace (dataset/*.csv)
		|
		| (docker cp)
		v
	HDFS Namenode (/raw)  <-- raw zone
		|
		| (Spark jobs: validate_raw.py, clean_orders.py, clean_customers.py)
		v
	HDFS Bronze/Gold paths (procesado)
		|
		| (Escritura a Postgres / export)
		v
	PostgreSQL (tablas finales)
		|
		v
	Metabase (visualización)

Jenkins pipelines orchestrate: upload -> validate -> spark jobs -> promote to gold -> export
```

Zonas de datos sugeridas:

- Raw: `/raw` — archivos CSV tal cual, sin transformación.
- Bronze: `/bronze` — resultados de limpieza mínima (tipos, eliminaciones básicas).
- Gold: `/gold` — datos listos para consumo analítico y carga en Postgres.

## Carpetas y scripts principales

- `dataset/` : CSVs de ejemplo (clientes, órdenes, productos, etc.).
- `docker/docker-compose.spark.yml` : Stack para Hadoop/HDFS, Spark, Postgres y Metabase.
- `docker/docker-compose.jenkins.yml` : Stack para Jenkins.
- `docker/spark-jobs/validate_bigdata_stack.ps1` : Script PowerShell para validar que el stack está arriba.

### Validaciones dentro de Docker

Las comprobaciones y scripts de validación están pensadas para ejecutarse dentro de los contenedores del stack (no sólo en la máquina host). Por ejemplo:

- `docker exec namenode ...` se usa para ejecutar comandos HDFS dentro del contenedor `namenode`.
- `docker exec spark-master ...` o `docker exec spark-worker ...` se usan para ejecutar comprobaciones o jobs Spark dentro de los contenedores Spark.

El script `docker/spark-jobs/validate_bigdata_stack.ps1` realiza checks desde el host pero asume que los servicios están disponibles dentro de Docker; en pipelines de Jenkins lo normal es ejecutar validaciones con `docker exec` para comprobar conectividad HDFS, disponibilidad del Namenode/Datanode y la capacidad de ejecutar `spark-submit`.

- `jenkins/cleandata/` y `jenkins/uperdata/` : pipelines y scripts asociados a cada pipeline en Jenkins.
  - `jenkins/uperdata/scritps/update_dataset_hdfs.sh` : script que copia los CSV desde el workspace al HDFS (`/raw`).
    - Comportamiento clave:
	 - Detecta `WORKSPACE` o usa `pwd` como base.
	 - Lista CSV en `dataset/` y muestra conteo.
	 - Crea el path HDFS (`hdfs dfs -mkdir -p ")` y sube los archivos con `hdfs dfs -put -f`.
	 - Valida existencia en HDFS con `hdfs dfs -test -f`.
	 - Al final lista el contenido de la ruta HDFS.
    - Recomendaciones: parametrizar `WORKSPACE` y `HDFS_PATH`, limpiar `/tmp` en el contenedor, añadir `--help` y comprobaciones previas de `docker` y `docker exec`.

## Rol de Hadoop (HDFS) y Spark en el proceso

- Hadoop/HDFS: actúa como la zona de almacenamiento distribuido. Los CSV crudos se colocan en la zona `raw` (ej. `/raw`) para mantener un registro inmutable de los datos originales. HDFS permite a Spark leer los datos de forma distribuida y escalable.
- Spark: se encarga de la validación, limpieza y transformación de los datos. Los jobs Spark (por ejemplo `validate_raw.py`, `clean_orders.py`) realizan:
	- Validaciones de consistencia y esquema.
	- Transformaciones y limpieza (convertir tipos, normalizar, quitar duplicados).
	- Escritura de resultados en zonas `bronze`/`gold` en HDFS y/o exportación a PostgreSQL para consumo analítico.

Flujo típico con Docker:

1. `update_dataset_hdfs.sh` copia los CSV al contenedor `namenode` y los pone en HDFS (`/raw`).
2. Se ejecuta un job de validación dentro de un contenedor Spark (ej. `docker exec spark-worker spark-submit ... validate_raw.py`) que lee desde HDFS.
3. Si la validación pasa, se ejecutan jobs de limpieza/transformación que escriben en `/bronze` y luego `/gold`.
4. Los resultados finales pueden exportarse a PostgreSQL y visualizarse en Metabase.

  - `jenkins/cleandata/spark-jobs/clean_customers.py`, `clean_orders.py`, `gold_orders.py` : jobs Spark para limpieza y promoción a gold.
  - `jenkins/uperdata/scritps/create_directories_hdfs.sh` y `update_dataset_hdfs.sh` : helpers para preparar HDFS y subir datos.

## Cómo usar (pasos rápidos)

1. Levantar stack (desde la raíz del repo):

```bash
docker compose -f docker/docker-compose.spark.yml up -d
docker compose -f docker/docker-compose.jenkins.yml up -d
```

2. Verificar servicios (opcional):

```bash
# Namenode
curl -s http://localhost:9870 | head -n 20
# Jenkins
curl -s http://localhost:8080 | head -n 20
```

3. Subir datasets a HDFS (ejecutar desde la raíz del repo o usando `WORKSPACE`):

```bash
# desde la raíz (usa dataset/)
jenkins/uperdata/scritps/update_dataset_hdfs.sh

# o explícitamente
WORKSPACE=$(pwd) jenkins/uperdata/scritps/update_dataset_hdfs.sh
```

4. Ejecutar validaciones y jobs Spark (ejemplos):

```bash
# Validar stack
docker exec spark-worker /bin/bash -c "python3 /jobs/validate_raw.py"

# Ejecutar job de limpieza (localmente o vía Jenkins)
docker exec spark-master /bin/bash -c "spark-submit --master local /jobs/clean_orders.py"
```

5. Consultar resultados en Postgres / Metabase.

## Buenas prácticas y mejoras sugeridas

- Parametrizar rutas y contenedores (`--namenode-name`, `HDFS_PATH`) mediante variables de entorno o flags `--help`.
- Añadir logging estructurado y niveles (`INFO/ERROR`).
- Limpiar archivos temporales dentro del contenedor tras la carga.
- Añadir validaciones de esquema (por ejemplo con `pandera` o validaciones en Spark) antes de promover datos a bronze/gold.
- Añadir un README por pipeline en `jenkins/` con pasos específicos de ejecución y ejemplos de `Jenkinsfile`.

## Contribuir

Si quieres que actualice los scripts para seguir las recomendaciones (parametrización, help, limpieza `/tmp`, corrección de `scritps` → `scripts`), dime y aplico los cambios. También puedo crear diagramas más visuales (PNG/SVG) si lo prefieres.
