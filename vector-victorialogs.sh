#!/bin/bash

# Ścieżka do lokalnego pliku z logami
LOG_FILE="/ścieżka/do/twojego/przykładowego/logfile.log"

# Utwórz przykładowy plik konfiguracyjny dla Vector
cat <<EOF > vector-config.toml
[sources.my_source]
  type = "file"
  include = ["/var/log/vector/*.log"]

[sinks.my_sink]
  type = "http"
  inputs = ["my_source"]
  target = "http://victorialogs-host:8420/api/v1/write"
EOF

# Kopiuj plik z logami do katalogu, który będzie dostępny dla kontenera Vector
mkdir -p /var/log/vector
cp "$LOG_FILE" /var/log/vector/

# Uruchom kontener z VictoriaLogs
podman run -d --name victorialogs-container -p 8420:8420 victorialogs/victorialogs

# Oczekaj chwilę na uruchomienie kontenera VictoriaLogs
sleep 10

# Uruchom kontener z Vector
podman run -d --name vector-container -v vector-config.toml:/etc/vector/vector.toml -v /var/log/vector:/var/log/vector timberio/vector:latest vector --config /etc/vector/vector.toml

# Oczekaj chwilę na uruchomienie kontenera Vector
sleep 10

# Benchmark zbierania logów
echo "Benchmark zbierania logów z Vector do VictoriaLogs"
time vector

# Oczekaj chwilę, aż Vector rozpocznie zbieranie logów
sleep 10

# Benchmark przetwarzania logów w VictoriaLogs
echo "Benchmark przetwarzania logów w VictoriaLogs"
time curl -X POST -H "Content-Type: application/json" --data-binary @- "http://localhost:8420/api/v1/query" <<EOF
{
  "sql": "SELECT COUNT(*) FROM my_logs"
}
EOF

# Zatrzymaj i usuń kontenery
podman stop vector-container
podman stop victorialogs-container
podman rm vector-container
podman rm victorialogs-container

