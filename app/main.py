from fastapi import FastAPI
import os
import psycopg2
import redis
import socket

app = FastAPI()

# Database Connection
def get_db_connection():
    conn = psycopg2.connect(
        host=os.environ.get('DB_HOST', 'localhost'),
        database=os.environ.get('DB_NAME', 'fintech'),
        user=os.environ.get('DB_USER', 'fintechadmin'),
        password=os.environ.get('DB_PASSWORD', 'password123')
    )
    return conn

# Redis Connection
# Note: Redis with TLS requires ssl=True and usually a password
r = redis.Redis(
    host=os.environ.get('REDIS_HOST', 'localhost'),
    port=6379,
    password=os.environ.get('REDIS_AUTH_TOKEN', None),
    ssl=True,
    ssl_cert_reqs=None # In lab environments certificates might be self-signed
)

@app.get("/")
def read_root():
    return {"message": "Welcome to FinTech Global Platform", "hostname": socket.gethostname()}

@app.get("/health")
def health_check():
    status = {"status": "healthy", "components": {}}
    
    # Check DB
    try:
        conn = get_db_connection()
        conn.close()
        status["components"]["database"] = "reachable"
    except Exception as e:
        status["components"]["database"] = f"unreachable: {str(e)}"
        status["status"] = "degraded"
        
    # Check Redis
    try:
        r.ping()
        status["components"]["cache"] = "reachable"
    except Exception as e:
        status["components"]["cache"] = f"unreachable: {str(e)}"
        status["status"] = "degraded"
        
    return status
