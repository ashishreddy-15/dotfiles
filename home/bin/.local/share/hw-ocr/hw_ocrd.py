#!/usr/bin/env python3
"""hw-ocr daemon: local handwriting recognition over a Unix socket (see docs/system.md, "Handwriting recognition service").

Protocol (newline-delimited, one request per connection line, handled serially):
  warm              -> {"ok":true}            (loads the model)
  /abs/path.png     -> {"text":"...","ms":N}  or {"error":"..."}
Started by systemd socket activation (LISTEN_FDS) or, when run by hand, binds $XDG_RUNTIME_DIR/hw-ocr.sock itself.
Exits after HW_IDLE seconds (default 600) without a request; the model is loaded lazily.
Env: HW_MODEL, HW_THREADS (default 8), HW_IDLE, HW_SOCK, HW_CHUNK (0 disables splitting of very wide lines).
"""
import json, os, socket, sys, time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from hw_post import clean

MODEL = os.environ.get("HW_MODEL", os.path.expanduser("~/handwriting/models/trocr-small-ft"))
THREADS = int(os.environ.get("HW_THREADS", "8"))
IDLE = float(os.environ.get("HW_IDLE", "600"))
SOCK = os.environ.get("HW_SOCK") or os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "hw-ocr.sock")
CHUNK = os.environ.get("HW_CHUNK", "1") != "0"
MAX_BYTES = 32 * 1024 * 1024

_m = {}


def log(*a):
    print(*a, file=sys.stderr, flush=True)


def load():
    if _m:
        return
    t = time.time()
    import torch
    from transformers import TrOCRProcessor, VisionEncoderDecoderModel
    torch.set_num_threads(THREADS)
    _m["proc"] = TrOCRProcessor.from_pretrained(MODEL)
    m = VisionEncoderDecoderModel.from_pretrained(MODEL).eval()
    # The stock checkpoint emits [2, text, 2] with no leading <s>: the start token must be set explicitly.
    m.config.decoder_start_token_id = 2
    m.config.pad_token_id = 1
    m.config.eos_token_id = 2
    _m["model"] = m
    _m["torch"] = torch
    recognise_image_rgb_blank()
    log(f"model loaded in {time.time() - t:.1f}s")


def recognise_image_rgb_blank():
    from PIL import Image
    _recognise([Image.new("RGB", (400, 60), "white")])


def _recognise(imgs):
    torch, proc, model = _m["torch"], _m["proc"], _m["model"]
    px = proc(images=imgs, return_tensors="pt").pixel_values
    with torch.inference_mode():
        out = model.generate(px, max_new_tokens=64, num_beams=1)
    return proc.batch_decode(out, skip_special_tokens=True)


def open_rgb(path):
    from PIL import Image
    im = Image.open(path)
    im.load()
    if im.mode in ("RGBA", "LA", "PA") or "transparency" in im.info:
        im = im.convert("RGBA")
        bg = Image.new("RGB", im.size, "white")
        bg.paste(im, mask=im.getchannel("A"))
        return bg
    return im.convert("RGB")


def recognise_file(path):
    from hw_chunk import split_wide
    load()
    img = open_rgb(path)
    parts = split_wide(img) if CHUNK else [img]
    texts = _recognise(parts)
    return clean(" ".join(t.strip() for t in texts))


def handle(line):
    t0 = time.time()
    if line == "warm":
        load()
        return {"ok": True}
    if not os.path.isabs(line):
        return {"error": "expected 'warm' or an absolute path to a PNG"}
    try:
        if os.path.getsize(line) > MAX_BYTES:
            return {"error": "file too large"}
        text = recognise_file(line)
    except Exception as e:  # report, keep serving
        return {"error": f"{type(e).__name__}: {e}"}
    return {"text": text, "ms": int((time.time() - t0) * 1000)}


def listener():
    if os.environ.get("LISTEN_PID") == str(os.getpid()) and int(os.environ.get("LISTEN_FDS", "0")) >= 1:
        return socket.socket(fileno=3), False
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        os.unlink(SOCK)
    except FileNotFoundError:
        pass
    s.bind(SOCK)
    os.chmod(SOCK, 0o600)
    s.listen(8)
    return s, True


def serve(conn):
    conn.settimeout(10)
    buf = b""
    while b"\n" not in buf and len(buf) < 8192:
        d = conn.recv(4096)
        if not d:
            break
        buf += d
    line = buf.split(b"\n", 1)[0].decode("utf-8", "replace").strip()
    if not line:
        return
    conn.sendall((json.dumps(handle(line), ensure_ascii=False) + "\n").encode())


def main():
    srv, own = listener()
    last = time.time()
    try:
        while True:
            left = IDLE - (time.time() - last)
            if left <= 0:
                log("idle, exiting")
                break
            srv.settimeout(left)
            try:
                conn, _ = srv.accept()
            except socket.timeout:
                continue
            with conn:
                try:
                    serve(conn)
                except (OSError, socket.timeout) as e:
                    log("connection error:", e)
            last = time.time()
    finally:
        if own:
            try:
                os.unlink(SOCK)
            except OSError:
                pass


if __name__ == "__main__":
    main()
