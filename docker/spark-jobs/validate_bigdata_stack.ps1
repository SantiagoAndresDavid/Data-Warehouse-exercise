Write-Host ""
Write-Host "========================================="
Write-Host " BIG DATA PLATFORM HEALTH CHECK"
Write-Host "========================================="
Write-Host ""

# --------------------------------------------------
# Docker
# --------------------------------------------------

Write-Host "[1/7] Docker"

docker version *> $null

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Docker no disponible" -ForegroundColor Red
    exit 1
}

Write-Host "OK Docker" -ForegroundColor Green

# --------------------------------------------------
# Containers
# --------------------------------------------------

Write-Host ""
Write-Host "[2/7] Contenedores"

$containers = @(
    "namenode",
    "datanode",
    "spark-master",
    "spark-worker",
    "postgres",
    "metabase",
    "jenkins-data-warehouse"
)

foreach ($container in $containers) {

    $status = docker inspect `
        --format "{{.State.Running}}" `
        $container 2>$null

    if ($status -eq "true") {
        Write-Host "OK $container" -ForegroundColor Green
    }
    else {
        Write-Host "ERROR $container" -ForegroundColor Red
    }
}

# --------------------------------------------------
# Docker Network
# --------------------------------------------------

Write-Host ""
Write-Host "[3/7] Red Docker"

docker network inspect bigdata *> $null

if ($LASTEXITCODE -eq 0) {
    Write-Host "OK network bigdata" -ForegroundColor Green
}
else {
    Write-Host "ERROR network bigdata" -ForegroundColor Red
}

# --------------------------------------------------
# Hadoop NameNode
# --------------------------------------------------

Write-Host ""
Write-Host "[4/7] Hadoop NameNode"

docker exec namenode jps 2>$null |
Select-String NameNode

if ($LASTEXITCODE -eq 0) {
    Write-Host "OK NameNode activo" -ForegroundColor Green
}
else {
    Write-Host "ERROR NameNode inactivo" -ForegroundColor Red
}

# --------------------------------------------------
# Hadoop DataNode
# --------------------------------------------------

Write-Host ""
Write-Host "[5/7] Hadoop Cluster"

$report = docker exec namenode hdfs dfsadmin -report 2>$null

if ($report -match "Live datanodes \(1\)") {

    Write-Host "OK DataNode registrado" -ForegroundColor Green
}
else {

    Write-Host "ERROR No hay DataNodes registrados" -ForegroundColor Red
}

# --------------------------------------------------
# Spark
# --------------------------------------------------

Write-Host ""
Write-Host "[6/7] Spark"

docker exec spark-master bash -c "jps" 2>$null

if ($LASTEXITCODE -eq 0) {
    Write-Host "OK Spark Master" -ForegroundColor Green
}
else {
    Write-Host "ERROR Spark Master" -ForegroundColor Red
}

# --------------------------------------------------
# PostgreSQL
# --------------------------------------------------

Write-Host ""
Write-Host "[7/7] PostgreSQL"

docker exec postgres `
pg_isready `
-U admin `
-d dwh *> $null

if ($LASTEXITCODE -eq 0) {

    Write-Host "OK PostgreSQL" -ForegroundColor Green
}
else {

    Write-Host "ERROR PostgreSQL" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================="
Write-Host " RESUMEN"
Write-Host "========================================="
Write-Host ""

docker ps --format "table {{.Names}}\t{{.Status}}"