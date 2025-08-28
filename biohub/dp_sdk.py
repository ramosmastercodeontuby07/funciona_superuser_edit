import subprocess, json, tempfile, os, base64, shlex
from typing import List, Dict

# TODO: Ajusta a los binarios/CLI reales que te entregue el SDK de HID (U.are.U 4500)
DP_CAPTURE = "/opt/hid-sdk/bin/dp_capture"   # captura -> escribe template.bin
DP_MATCH   = "/opt/hid-sdk/bin/dp_match"     # match 1:1 -> imprime score
DP_IDENT   = "/opt/hid-sdk/bin/dp_identify"  # identify 1:N -> imprime id/score

class DPSDKError(Exception): pass

def _run(cmd: str, timeout: int = 25) -> str:
    p = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout)
    out = (p.stdout or "") + (p.stderr or "")
    if p.returncode != 0:
        raise DPSDKError(out.strip())
    return out

def capture_template() -> bytes:
    with tempfile.TemporaryDirectory() as td:
        tpl = os.path.join(td, "template.bin")
        cmd = f"{shlex.quote(DP_CAPTURE)} --out {shlex.quote(tpl)}"
        _run(cmd)
        return open(tpl, "rb").read()

def match_1to1(probe: bytes, ref: bytes) -> float:
    with tempfile.TemporaryDirectory() as td:
        p1 = os.path.join(td, "probe.bin"); open(p1, "wb").write(probe)
        p2 = os.path.join(td, "ref.bin");   open(p2, "wb").write(ref)
        cmd = f"{shlex.quote(DP_MATCH)} --probe {shlex.quote(p1)} --ref {shlex.quote(p2)}"
        out = _run(cmd)
        for line in out.splitlines():
            if "SCORE:" in line.upper():
                return float(line.split(":")[-1].strip())
        raise DPSDKError("no score parsed")

def identify(probe: bytes, gallery: List[Dict], threshold: float = 70.0):
    """
    gallery: [{ "id": 123, "template_b64": "..." }, ...]
    return (id_mejor, score) si >= threshold, o (None, 0.0)
    """
    with tempfile.TemporaryDirectory() as td:
        p1 = os.path.join(td, "probe.bin"); open(p1, "wb").write(probe)
        items = []
        for i, item in enumerate(gallery):
            raw = base64.b64decode(item["template_b64"])
            path = os.path.join(td, f"g{i}.bin")
            open(path, "wb").write(raw)
            items.append({"id": item["id"], "path": path})
        galfile = os.path.join(td, "gallery.json")
        open(galfile, "w").write(json.dumps(items))

        cmd = f"{shlex.quote(DP_IDENT)} --probe {shlex.quote(p1)} --gallery {shlex.quote(galfile)}"
        out = _run(cmd)

        best_id, best_score = None, 0.0
        for line in out.splitlines():
            line = line.strip()
            if line.upper().startswith("MATCH"):
                # ejemplo: "MATCH id=123 score=88.1"
                try:
                    parts = dict(s.split("=",1) for s in line.split()[1:])
                    cid = int(parts.get("id","0"))
                    sc  = float(parts.get("score","0"))
                    if sc > best_score:
                        best_id, best_score = cid, sc
                except Exception:
                    continue
        if best_score >= threshold:
            return best_id, best_score
        return None, 0.0
