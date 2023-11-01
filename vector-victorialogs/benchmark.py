import time
import requests
import json

# Replace with the IP address of your Vector instance
vector_url = "http://localhost:8686"

# Replace with the IP address of your VictoriaLogs instance
victorialogs_url = "http://localhost:9428"

# Number of logs to send
num_logs = 10000

# Start time
start_time = time.time()

# Send logs to Vector
for i in range(num_logs):
   log = {"message": f"Log message {i}", "timestamp": time.time()}
   requests.post(vector_url, data=json.dumps(log))

# End time
end_time = time.time()

# Print the time taken to send logs
print(f"Time taken to send logs: {end_time - start_time} seconds")

# Start time
start_time = time.time()

# Query logs from VictoriaLogs
response = requests.get(f"{victorialogs_url}/api/v1/query?query=LogsQL query")
logs = response.json()

# End time
end_time = time.time()

# Print the time taken to query logs
print(f"Time taken to query logs: {end_time - start_time} seconds")

