# run_all.ps1 - run from project root (D:\LiveTradeStore)
# Usage: Activate your venv, then: .\run_all.ps1

set -e

Write-Host "Starting Docker Compose..."
docker-compose up -d

# find container id
$container = docker-compose ps -q db
if (-not $container) {
    Write-Error "Could not find postgres container. Is docker-compose up running?"
    exit 1
}

# wait for pg_isready inside container
Write-Host "Waiting for Postgres to become healthy..."
$maxTries = 30
$try = 0
while ($try -lt $maxTries) {
    $try++
    $status = docker exec $container sh -c "pg_isready -U postgres" 2>$null
    if ($status -and $status -match "accepting connections") {
        Write-Host "Postgres is ready."
        break
    }
    Start-Sleep -Seconds 2
    Write-Host -NoNewline "."
}
if ($try -ge $maxTries) {
    Write-Error "Postgres did not become ready in time."
    docker logs $container --tail 100
    exit 1
}

# copy schema.sql into container and run it
Write-Host "`nApplying schema..."
docker cp .\schema.sql $container:/tmp/schema.sql
docker exec -i $container psql -U postgres -d livetrade -f /tmp/schema.sql

# optional: list partitions / tables
Write-Host "Listing top-level tables:"
docker exec -i $container psql -U postgres -d livetrade -c "\dt"

# Run ingest using local python (this will connect to localhost:5432)
Write-Host "`nRunning ingest.py (this uses your local python environment)..."
# Ensure you run this script with venv active. If not, it still runs the system python.
python .\ingest.py
if ($LASTEXITCODE -ne 0) {
    Write-Error "ingest.py failed. Check the script output."
    exit 1
}

# Run bench.sql inside container and capture EXPLAIN output to file inside container
Write-Host "`nRunning benchmarks (bench.sql) inside container..."
docker cp .\bench.sql $container:/tmp/bench.sql
docker exec -i $container bash -c "psql -U postgres -d livetrade -f /tmp/bench.sql" > explain_output.txt

Write-Host "`nBenchmark output saved to explain_output.txt"

Write-Host "`nDone. Check explain_output.txt and sample_trades.csv in project folder."
