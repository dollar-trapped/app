"""Retime a shared Blender plate to the three production timelines; encode H.264."""
import json
import math
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'build/gacha-art/intro'
OUT = ROOT / 'assets/gacha/film'
OUT.mkdir(parents=True, exist_ok=True)
track = json.loads((SOURCE/'track.json').read_text())
FPS = track['fps']
# Shared with Flutter via track.json: accelerate the plate and projected heads
# together, then rejoin the unchanged stillness/contact timeline.
track['specialBoost'] = {
    'startMs': 2850, 'endMs': 3650, 'gain': 1.6,
    'trailMs': 320, 'trailStretch': .9,
}
timelines = {
    'common': [0, 550, 2350, 2700, 2880, 3250, 3800],
    'rare': [0, 550, 3650, 4000, 4180, 4550, 5270],
    'special': [0, 550, 3650, 4070, 4260, 4790, 5750],
}
def source_time(ms, bounds, name):
    boost = track['specialBoost']
    if name == 'special' and boost['startMs'] < ms < boost['endMs']:
        span = boost['endMs']-boost['startMs']
        u = (ms-boost['startMs'])/span
        ms += span*boost['gain']*u*(1-u)**2
    for i in range(len(bounds)-1):
        if ms <= bounds[i+1]:
            f = max(0, (ms-bounds[i])/(bounds[i+1]-bounds[i]))
            return track['bounds'][i]+f*(track['bounds'][i+1]-track['bounds'][i])
    return track['bounds'][-1]

for name, bounds in timelines.items():
    concat = SOURCE/f'{name}.ffconcat'
    lines = ['ffconcat version 1.0']
    for i in range(math.ceil(bounds[-1]*FPS/1000)+1):
        source = round(source_time(i*1000/FPS, bounds, name)*FPS/1000)
        frame = SOURCE/f'frames/frame_{source:04d}.png'
        if not frame.is_file():
            raise FileNotFoundError(frame)
        lines.extend([f"file '{frame}'", f'duration {1/FPS:.9f}'])
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
