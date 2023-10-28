#!/bin/bash

# Ścieżka do lokalnego pliku z logami
LOG_FILE="logfile.log"

# Utwórz przykładowy plik konfiguracyjny dla Filebeat
cat <<EOF > filebeat-config.yml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/app/*.log

output:
  http:
    hosts: ["http://victorialogs-host:8420/api/v1/write"]
EOF

# Kopiuj plik z logami do katalogu, który będzie dostępny dla kontenera Filebeat
mkdir -p /var/log/app
cp "$LOG_FILE" /var/log/app/app.log

# Uruchom kontener z VictoriaLogs
podman run -d --name victorialogs-container -p 8420:8420 victorialogs/victorialogs

# Oczekaj chwilę na uruchomienie kontenera VictoriaLogs
sleep 10

# Uruchom kontener z Filebeat
podman run -d --name filebeat-container docker.elastic.co/beats/filebeat:latest filebeat -e -strict.perms=false -E filebeat.config.inputs.path=filebeat-config.yml

# Oczekaj chwilę na uruchomienie kontenera Filebeat
sleep 10

# Benchmark zbierania logów za pomocą Filebeat
echo "Benchmark zbierania logów za pomocą Filebeat"
time filebeat -e -strict.perms=false

# Oczekaj chwilę, aż Filebeat rozpocznie zbieranie logów
sleep 10

# Benchmark przetwarzania logów w VictoriaLogs
echo "Benchmark przetwarzania logów w VictoriaLogs"
time curl -X POST -H "Content-Type: application/json" --data-binary @- "http://localhost:8420/api/v1/query" <<EOF
{
  "sql": "SELECT COUNT(*) FROM my_logs"
}
EOF

# Zatrzymaj i usuń kontenery
podman stop filebeat-container
podman stop victorialogs-container
podman rm filebeat-container
podman rm victorialogs-container

