"""Decode bundled plates, render Flutter overlays, and encode local previews.

Run from any directory: python3 tool/gacha_art/export_preview.py
Requires local ffmpeg and flutter executables. No Blender render is needed.
Outputs build/gacha-art/previews/{special,rare}-10.mp4 (offline, silent, 30fps).
"""
import argparse
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / "build/gacha-art/source-movie"
GRADES = ("special", "rare")
FPS = 30
DURATION = 6.5
FRAME_COUNT = round(FPS * DURATION)


def run(*command):
    subprocess.run(command, cwd=ROOT, check=True, timeout=600)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path,
                        default=ROOT / "build/gacha-art/previews")
    args = parser.parse_args()
    for executable in ("ffmpeg", "flutter"):
        if not shutil.which(executable):
            parser.error(f"Required executable is missing: {executable}")

    output = args.output_dir.resolve()
    output.mkdir(parents=True, exist_ok=True)
    for grade in GRADES:
        plate = WORK / grade / "plate"
        plate.mkdir(parents=True, exist_ok=True)
        run("ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
            "-i", str(ROOT / f"assets/gacha/film/{grade}.mp4"),
            "-vf", f"fps={FPS},tpad=stop_mode=clone:stop_duration=2",
            "-frames:v", str(FRAME_COUNT), str(plate / "%04d.png"))

    run("flutter", "test", "test/gacha_film_export_test.dart",
        "--dart-define=EXPORT_FILM_INTRO=true", "--reporter", "expanded")

    for grade in GRADES:
        movie = output / f"{grade}-10.mp4"
        run("ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
            "-framerate", str(FPS),
            "-i", str(WORK / grade / "composite/%04d.png"),
            "-frames:v", str(FRAME_COUNT), "-c:v", "libx264", "-crf", "18",
            "-pix_fmt", "yuv420p", "-movflags", "+faststart", str(movie))
        print(f"Preview: {movie}", flush=True)


if __name__ == "__main__":
    main()
