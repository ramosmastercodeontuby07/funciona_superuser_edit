from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import httpx, os, base64
from pydantic import BaseModel
from dotenv import load_dotenv
from hmac_sign import sign
import dp_sdk

load_dotenv()

RAILS_BASE = os.getenv("RAILS_BASE_URL", "http://127.0.0.1:3000")
API_KEY    = os.getenv("RAILS_API_KEY", "")
SECRET     = os.getenv("FINGER_SECRET", "")
ALLOWED    = [o.strip() for o in os.getenv("ALLOWED_ORIGINS","http://localhost:3000").split(",")]

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED,
    allow_methods=["GET","POST","OPTIONS"],
    allow_headers=["*"],
)

class EnrollReq(BaseModel):
    kind: str     # "user" | "member"
    subject_id: int

@app.get("/health")
def health():
    return {"ok": True}

@app.get("/capture_identify")
async def capture_identify(kind: str = "member"):
    if kind not in ("member", "user"):
        raise HTTPException(400, "bad kind")
    try:
        probe = dp_sdk.capture_template()
    except Exception as e:
        raise HTTPException(500, f"capture error: {e}")

    url = f"{RAILS_BASE}/api/fp/gallery/{'users' if kind=='user' else 'members'}"
    headers = {"Authorization": f"Bearer {API_KEY}"}
    async with httpx.AsyncClient(timeout=30.0) as client:
        r = await client.get(url, headers=headers)
    if r.status_code != 200:
        raise HTTPException(502, f"gallery error: {r.text}")
    gallery = r.json().get("items", [])
    if not gallery:
        return {"ok": False, "error": "empty gallery"}

    try:
        matched_id, score = dp_sdk.identify(probe, gallery, threshold=70.0)
    except Exception as e:
        raise HTTPException(500, f"identify error: {e}")

    if not matched_id:
        return {"ok": False, "matched_id": None, "score": 0.0}

    token = sign({"kind": kind, "subject_id": matched_id, "score": score}, SECRET)
    return {"ok": True, "matched_id": matched_id, "score": score, "token": token}

@app.post("/enroll")
async def enroll(req: EnrollReq):
    if req.kind not in ("member", "user"):
        raise HTTPException(400, "bad kind")
    try:
        tpl = dp_sdk.capture_template()
    except Exception as e:
        raise HTTPException(500, f"capture error: {e}")
    tpl_b64 = base64.b64encode(tpl).decode()

    url = f"{RAILS_BASE}/api/fp/save"
    headers = {"Authorization": f"Bearer {API_KEY}"}
    payload = {
        "kind": req.kind,
        "subject_id": req.subject_id,
        "template_b64": tpl_b64,
        "algo": "HID-DP",
        "finger": "auto"
    }
    async with httpx.AsyncClient(timeout=30.0) as client:
        r = await client.post(url, headers=headers, json=payload)
    if r.status_code != 200:
        raise HTTPException(502, f"save error: {r.text}")
    return {"ok": True}
