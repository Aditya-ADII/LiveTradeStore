# ingest.py
# Usage:
# 1) activate your venv
# 2) pip install -r requirements.txt
# 3) python ingest.py
import csv
import random
import time
from datetime import datetime, timedelta
from pathlib import Path
import os
import sys

# Try importing DB driver and dotenv, provide clear error if missing
try:
    import psycopg2
except Exception as e:
    print("ERROR: psycopg2 is not installed in this environment.")
    print("Run: pip install psycopg2-binary")
    sys.exit(1)

# optional: load .env
try:
    from dotenv import load_dotenv
    load_dotenv()
except Exception:
    # python-dotenv is optional, but recommended
    pass

# Config - read from env with defaults
DB_NAME = os.getenv("DB_NAME", "livetrade")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASS = os.getenv("DB_PASS", "postgres")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")

OUT = Path("sample_trades.csv")
# Lower default for quick dev runs; set to 100000 when you want bigger test
N = int(os.getenv("INGEST_ROWS", "20000"))
SYMBOLS = ["AAPL","TSLA","RELIANCE","TCS","INFY","GOOG","MSFT","AMZN"]

def gen_row(ts):
    symbol = random.choice(SYMBOLS)
    price = round(random.uniform(50, 3500), 4)
    qty = random.choice([1,5,10,50,100,200])
    side = random.choice([0,1])
    exchange = random.choice(["NSE","BSE","NASDAQ"])
    return [symbol, ts.isoformat(), price, qty, side, exchange]

def write_csv(n=N):
    start = datetime.utcnow() - timedelta(days=random.randint(0,6))
    with OUT.open("w", newline="") as f:
        writer = csv.writer(f)
        for i in range(n):
            ts = start + timedelta(seconds=(i % (24*3600)))
            writer.writerow(gen_row(ts))

def copy_to_db():
    try:
        conn = psycopg2.connect(dbname=DB_NAME, user=DB_USER, password=DB_PASS, host=DB_HOST, port=DB_PORT)
    except Exception as e:
        print("ERROR: Could not connect to Postgres with given credentials.")
        print(f"Details: {e}")
        print("Check .env values or your Postgres server. Example .env:")
        print("DB_NAME=livetrade\nDB_USER=postgres\nDB_PASS=postgres\nDB_HOST=localhost\nDB_PORT=5432")
        sys.exit(1)

    cur = conn.cursor()
    with OUT.open("r") as f:
        try:
            cur.copy_expert("COPY trades(symbol, trade_ts, price, qty, side, exchange) FROM STDIN WITH (FORMAT csv)", f)
            conn.commit()
        except Exception as e:
            conn.rollback()
            print("ERROR during COPY:", e)
            cur.close()
            conn.close()
            sys.exit(1)
    cur.close()
    conn.close()

if __name__ == "__main__":
    print(f"Using DB: {DB_USER}@{DB_HOST}:{DB_PORT}/{DB_NAME}")
    t0 = time.time()
    print("Generating CSV with", N, "rows...")
    write_csv(N)
    print("CSV generated:", OUT, " time:", round(time.time()-t0,2), "s")
    t1 = time.time()
    print("Copying to DB...")
    copy_to_db()
    print("Ingest completed in:", round(time.time()-t1,2), "s")
    print("Done.")
