<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>我真的特别爱你</title>
    <link rel="stylesheet" href="https://pyscript.net/releases/2024.10.1/core.css">
    <style>
        *{margin:0;padding:0;box-sizing:border-box}
        body{background:#000;color:#fff;font-family:Consolas,Monaco,monospace;min-height:100vh;display:flex;flex-direction:column;align-items:center;justify-content:center;overflow:hidden}
        #term{white-space:pre;font-size:12px;line-height:1.1}
    </style>
</head>
<body>
<div id="term"></div>
<audio id="bgm" loop autoplay>

<script type="py" src="https://pyscript.net/releases/2024.10.1/core.js" config="pyscript.toml"></script>
<py-config>
packages = ["pillow"]
[[fetch]]
files = [
# ========== 修改这里为你的在线资源地址 ==========
# 示例："https://xxx.com/smiling_penguin1.gif",
# 示例："https://xxx.com/music.mp3"
]
</py-config>

<py-script>
import asyncio
from PIL import Image, ImageSequence
import js

# -------------------------- 配置区 --------------------------
GIF_URL = "smiling_penguin1.gif"   # 修改为你的gif网络地址
MUSIC_URL = "music.mp3"            # 修改为你的mp3网络地址
MESSAGE = "我真的特别爱你"
SCALE = 0.85
ALPHA_THRESHOLD = 200
# ------------------------------------------------------------

term_dom = js.document.getElementById("term")
bgm_dom = js.document.getElementById("bgm")
bgm_dom.src = MUSIC_URL

def render_half_block(img:Image.Image):
    rgba = img.convert("RGBA")
    w,h = rgba.size
    px = rgba.load()
    lines = []
    for y in range(0, h, 2):
        buf = []
        for x in range(w):
            t = px[x,y]
            b = px[x,y+1] if (y+1 < h) else (0,0,0,0)
            t_ok = t[3] >= 128
            b_ok = b[3] >=128
            if t_ok and b_ok:
                fg = f"rgb({t[0]},{t[1]},{t[2]})"
                bg = f"rgb({b[0]},{b[1]},{b[2]})"
                ch = "▀"
                buf.append(f'<span style="color:{fg};background:{bg}">{ch}</span>')
            elif t_ok:
                fg = f"rgb({t[0]},{t[1]},{t[2]})"
                buf.append(f'<span style="color:{fg}">▀</span>')
            elif b_ok:
                fg = f"rgb({b[0]},{b[1]},{b[2]})"
                buf.append(f'<span style="color:{fg}">▄</span>')
            else:
                buf.append(" ")
        lines.append("".join(buf))
    return lines

async def main():
    # 下载GIF
    resp = await js.fetch(GIF_URL)
    ab = await resp.arrayBuffer()
    data = bytearray(js.Uint8Array.new(ab))
    frames_raw = []
    with Image.open(io.BytesIO(data)) as im:
        for frame in ImageSequence.Iterator(im):
            dur = max(frame.info.get("duration",100)/1000, 0.02)
            frm = frame.convert("RGBA").copy()
            frames_raw.append((frm, dur))

    # 裁剪透明边框
    boxes = [f[0].getchannel("A").getbbox() for f in frames_raw]
    boxes = [b for b in boxes if b is not None]
    if boxes:
        l = min(b[0] for b in boxes)
        t = min(b[1] for b in boxes)
        r = max(b[2] for b in boxes)
        bot = max(b[3] for b in boxes)
        frames_raw = [(im.crop((l,t,r,bot)),d) for im,d in frames_raw]

    # 缩放
    base_w,base_h = frames_raw[0][0].size
    target_w = int(base_w * SCALE)
    target_h = int(base_h * SCALE)
    frames = []
    for im,dur in frames_raw:
        im2 = im.resize((target_w, target_h), Image.Resampling.NEAREST)
        frames.append((im2, dur))

    idx = 0
    while True:
        img, delay = frames[idx]
        text_lines = render_half_block(img)
        html_body = "<br>".join(text_lines) + f"<br><br>{MESSAGE}"
        term_dom.innerHTML = html_body
        idx = (idx+1) % len(frames)
        await asyncio.sleep(delay)

import io
asyncio.create_task(main())
</py-script>
</body>
</html>
