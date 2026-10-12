"""Encode exact Blender production samples without nearest-frame retiming."""
import json
import math
import subprocess
from pathlib import Path
from intro_timing import LANDING, SPECIAL_BOOST, TIMELINES

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'build/gacha-art/intro'
OUT = ROOT / 'assets/gacha/film'
OUT.mkdir(parents=True, exist_ok=True)
track = json.loads((SOURCE/'track.json').read_text())
FPS = track['fps']

track['specialBoost'] = SPECIAL_BOOST
track['landing'] = LANDING
manifest = json.loads((SOURCE/'production/manifest.json').read_text())
if manifest['specialBoost'] != SPECIAL_BOOST or manifest.get('landing') != LANDING:
    raise ValueError('Rerender production frames: production timing changed')
track['production'] = manifest['tracks']

for name, bounds in TIMELINES.items():
    concat = SOURCE/f'{name}.ffconcat'
    lines = ['ffconcat version 1.0']
    files = manifest['files'][name]
    expected = math.ceil(bounds[-1]*FPS/1000)+1
    if len(files) != expected or manifest['tracks'][name]['bounds'] != bounds:
        raise ValueError(f'Rerender production frames for {name}: timing changed')
    for filename in files:
        frame = SOURCE / filename
        if not frame.is_file():
            raise FileNotFoundError(frame)
        lines.extend([f"file '{frame}'", f'option framerate {FPS}', f'duration {1/FPS:.9f}'])
    concat.write_text('\n'.join(lines)+'\n')
    subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-safe', '0',
        '-i', str(concat), '-r', str(FPS), '-c:v', 'libx264', '-preset', 'slow',
        '-crf', '19', '-pix_fmt', 'yuv420p', '-movflags', '+faststart',
        str(OUT/f'{name}.mp4')], check=True)
(OUT/'track.json').write_text(json.dumps(track, separators=(',', ':')))
for name, frame in [('poster', 0), ('opened', round(track['bounds'][-1]*FPS/1000))]:
    subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y',
        '-i', str(SOURCE/f'frames/frame_{frame:04d}.png'), '-frames:v', '1', '-q:v', '2',
        str(OUT/f'{name}.jpg')], check=True)
print('Packaged three local videos, camera track and stills:', OUT)
