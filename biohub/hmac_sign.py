import hmac, hashlib, base64, json, time

def b64u(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()

def sign(payload: dict, secret: str, ttl: int = 20) -> str:
    payload = dict(payload)
    payload["ts"] = int(time.time())
    data = json.dumps(payload, separators=(",", ":"), sort_keys=True).encode()
    sig  = hmac.new(secret.encode(), data, hashlib.sha256).digest()
    return f"{b64u(data)}.{b64u(sig)}"
