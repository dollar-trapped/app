"""Encode frames emitted by gacha_sky_scene_test.dart; requires ffmpeg/ffprobe."""
import argparse
import json
import shutil
import subprocess
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--frames', type=Path, default=Path('/private/tmp/gacha-procedural'))
parser.add_argument('--output', type=Path, default=Path('docs/qa/gacha-presentation-2026-10-11/procedural'))
args = parser.parse_args()
if not shutil.which('ffmpeg') or not shutil.which('ffprobe'):
    parser.error('Install ffmpeg (including ffprobe) first')
args.output.mkdir(parents=True, exist_ok=True)
metadata = {}
for grade in ('common', 'rare', 'special'):
    for count in (1, 10):
        for quality in ('high', 'low'):
            name = f'{grade}_{count}_{quality}'
            frames = args.frames / name
            if not (frames / 'frame_0000.png').is_file():
                parser.error(f'Missing frames: {frames}')
            output = args.output / f'{name}.mp4'
            subprocess.run([
                'ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-framerate', '15',
                '-i', str(frames / 'frame_%04d.png'), '-c:v', 'libx264', '-crf', '18',
                '-pix_fmt', 'yuv420p', '-movflags', '+faststart', str(output),
            ], check=True)
            metadata[name] = json.loads(subprocess.check_output([
                'ffprobe', '-v', 'quiet', '-print_format', 'json', '-show_streams',
                '-show_format', str(output),
            ]))
(args.output / 'video-metadata.json').write_text(json.dumps(metadata, indent=2) + '\n')
print(f'Encoded {len(metadata)} videos into {args.output}')
