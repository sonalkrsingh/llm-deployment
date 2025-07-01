import requests
import time
import numpy as np
import socket
from concurrent.futures import ThreadPoolExecutor
from urllib.parse import urljoin

socket.setdefaulttimeout(120) 

# Configuration
BASE_URL = "http://a9b8f8e24ec314f6e907f74634b8e859-171634566.ap-south-1.elb.amazonaws.com"  # Use LLM Router LB
ENDPOINT = "/api/generate"  
MODEL = "llama3.1:8b"  
PROMPT = "Explain quantum computing in one sentence."
NUM_REQUESTS = 100
CONCURRENCY = 10
# Headers
HEADERS = {
    "Content-Type": "application/json",
    #"X-Model": MODEL  
}

def check_health():
    try:
        response = requests.get(f"{BASE_URL}/healthz", timeout=5)
        return response.status_code == 200
    except:
        return False

def send_request(session, request_id):
    session = requests.Session()
    adapter = requests.adapters.HTTPAdapter(
        pool_connections=20,
        pool_maxsize=20,
        max_retries=3
    )
    session.mount('http://', adapter)
    session.mount('https://', adapter)
    
    payload = {
        "model": MODEL,
        "prompt": PROMPT,
        "stream": False  # Disable streaming for simpler testing
    }
    start_time = time.time()
    try:
        response = session.post(
            urljoin(BASE_URL, ENDPOINT),
            headers=HEADERS,
            json=payload,
            timeout=30
        )
        latency_ms = (time.time() - start_time) * 1000
        if response.status_code == 200:
            return (True, latency_ms, response.json().get("response", ""))
        else:
            return (False, latency_ms, f"HTTP {response.status_code}")
    except Exception as e:
        error_msg = str(e)
        print(f"Request {request_id+1} error: {error_msg}")  
        return (False, (time.time() - start_time) * 1000, error_msg)

def run_test():
    latencies = []
    successes = 0
    session = requests.Session()

    with ThreadPoolExecutor(max_workers=CONCURRENCY) as executor:
        futures = [executor.submit(send_request, session, i) for i in range(NUM_REQUESTS)]
        for i, future in enumerate(futures):
            success, latency, response = future.result()
            latencies.append(latency)
            if success:
                successes += 1
            print(f"Request {i+1}/{NUM_REQUESTS}: {'✅' if success else '❌'} {latency:.2f}ms")

    # Calculate metrics
    success_rate = (successes / NUM_REQUESTS) * 100
    p50 = np.percentile(latencies, 50)
    p90 = np.percentile(latencies, 90)
    p99 = np.percentile(latencies, 99)

    print(f"\n📊 Results (N={NUM_REQUESTS}):")
    print(f"✅ Success Rate: {success_rate:.1f}%")
    print(f"⏱️ Latency (ms):")
    print(f"  - Avg: {np.mean(latencies):.2f}")
    print(f"  - P50: {p50:.2f}")
    print(f"  - P90: {p90:.2f}")
    print(f"  - P99: {p99:.2f}")
    print(f"  - Max: {max(latencies):.2f}")

if __name__ == "__main__":
    if not check_health():
        print("❌ Service is not healthy")
        exit(1)
    run_test()