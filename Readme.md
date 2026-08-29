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
