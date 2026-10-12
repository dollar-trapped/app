"""Blender background plate + projected reward anchors, no baked reward colors.

blender --background --python tool/gacha_art/render_intro.py -- --preview
blender --background --python tool/gacha_art/render_intro.py
python3 tool/gacha_art/package_intro.py
"""
import json
import math
import random
import runpy
import sys
from pathlib import Path

import bpy
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'build/gacha-art/intro'
OUT.mkdir(parents=True, exist_ok=True)
FPS, WIDTH, HEIGHT = 30, 720, 1600
BOUNDS = [0, 550, 3650, 4070, 4260, 4790, 5750]
END = 5800
FORMATION_END_MS = 1850
START_HEIGHTS = (4.2, 5.3, 4.4, 5.0, 4.1, 5.2, 4.3, 4.9, 4.6, 4.15)
START_JITTER = (-.08, .06, -.10, .08, -.04, .09, -.05, .05, -.09, .04)
preview = '--preview' in sys.argv
if preview:
    sys.argv.remove('--preview')
sys.argv.append('--save-only')
model = runpy.run_path(str(Path(__file__).with_name('render_case.py')))
scene, camera, lid = model['scene'], model['camera'], model['lid']
box, material = model['box'], model['material']
case = bpy.data.objects.new('Case grounded root', None)
bpy.context.collection.objects.link(case)
for obj in list(scene.objects):
    if obj.type not in {'LIGHT', 'CAMERA'} and obj != case and obj.parent is None:
        obj.parent = case

def clamp(x): return max(0., min(1., x))
def phase(t, a, b): return clamp((t-a)/(b-a))
def smooth(x): return x*x*(3-2*x)
def emission(name, color, strength):
    mat = material(name, color)
    bsdf = mat.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Emission Color'].default_value = (*color, 1)
    bsdf.inputs['Emission Strength'].default_value = strength
    return mat

floor = material('Obsidian landing apron', (.019, .028, .037), .4, .32)
nodes = floor.node_tree.nodes
noise = nodes.new('ShaderNodeTexNoise')
noise.inputs['Scale'].default_value = 34
bump = nodes.new('ShaderNodeBump')
bump.inputs['Strength'].default_value = .23
bump.inputs['Distance'].default_value = .025
floor.node_tree.links.new(noise.outputs['Fac'], bump.inputs['Height'])
floor.node_tree.links.new(bump.outputs['Normal'], nodes.get('Principled BSDF').inputs['Normal'])
box('Endless dark ground', (0, 5, -.18), (160, 160, .2), floor, .02)
pad = material('Brushed circular landing pad', (.045, .065, .077), .7, .36)
bpy.ops.mesh.primitive_cylinder_add(vertices=128, radius=3.65, depth=.10, location=(0, 0, -.04))
bpy.context.object.data.materials.append(pad)
bevel = bpy.context.object.modifiers.new('Pad edge', 'BEVEL')
bevel.width, bevel.segments = .06, 3
line = emission('Dim white-blue landing lights', (.28, .40, .47), 1.5)
for radius in (3.45, 3.58):
    bpy.ops.mesh.primitive_torus_add(major_radius=radius, minor_radius=.012, major_segments=128,
                                  minor_segments=6, location=(0, 0, .022))
    bpy.context.object.data.materials.append(line)
for i in range(16):
    angle = i*math.tau/16
    ob = box('Radial pad tick', (3.2*math.cos(angle), 3.2*math.sin(angle), .015),
             (.16, .035, .013), line, .005)
    ob.rotation_euler.z = angle

# Layered volumetric banks give actual depth as the camera descends through them.
def mist_material(name, density, tint):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    n, links = mat.node_tree.nodes, mat.node_tree.links
    n.clear()
    output = n.new('ShaderNodeOutputMaterial')
    vol = n.new('ShaderNodeVolumePrincipled')
    vol.inputs['Color'].default_value = (*tint, 1)
    vol.inputs['Anisotropy'].default_value = .25
    tex = n.new('ShaderNodeTexNoise')
    tex.inputs['Scale'].default_value = 3.8
    tex.inputs['Detail'].default_value = 3
    ramp = n.new('ShaderNodeValToRGB')
    ramp.color_ramp.elements[0].position = .40
    ramp.color_ramp.elements[1].position = .76
    gain = n.new('ShaderNodeMath')
    gain.operation = 'MULTIPLY'
    gain.inputs[1].default_value = density
    links.new(tex.outputs['Fac'], ramp.inputs[0])
    coords = n.new('ShaderNodeTexCoord')
    distance = n.new('ShaderNodeVectorMath')
    distance.operation = 'DISTANCE'
    distance.inputs[1].default_value = (.5, .5, .5)
    edge = n.new('ShaderNodeMapRange')
    edge.interpolation_type = 'SMOOTHSTEP'
    edge.inputs['From Min'].default_value = .18
    edge.inputs['From Max'].default_value = .5
    edge.inputs['To Min'].default_value = 1
    edge.inputs['To Max'].default_value = 0
    fade = n.new('ShaderNodeMath')
    fade.operation = 'MULTIPLY'
    links.new(coords.outputs['Generated'], distance.inputs[0])
    links.new(distance.outputs['Value'], edge.inputs['Value'])
    links.new(edge.outputs[0], fade.inputs[0])
    links.new(ramp.outputs[0], fade.inputs[1])
    links.new(fade.outputs[0], gain.inputs[0])
    links.new(gain.outputs[0], vol.inputs['Density'])
    links.new(vol.outputs['Volume'], output.inputs['Volume'])
    return mat, gain

rng = random.Random(74)
cloudmat, _ = mist_material('Night cloud vapor', .65, (.12, .21, .29))
for i in range(15):
    side = -1 if i % 2 else 1
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8,
        location=(side*rng.uniform(2.5, 5), rng.uniform(1, 6), rng.uniform(5, 40)))
    obj = bpy.context.object
    obj.name = 'Passing cloud bank'
    obj.scale = (rng.uniform(3, 6), 3, rng.uniform(.6, 1.6))
    obj.data.materials.append(cloudmat)

# Stars are geometry in the distant sky; the opening flash remains result-neutral.
stars = emission('Cold distant stars', (.49, .69, .86), 3)
for i in range(500):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=rng.uniform(.009, .027),
        location=(rng.uniform(-12, 12), rng.uniform(16, 28), rng.uniform(7, 85)))
    bpy.context.object.data.materials.append(stars)

smoke, smoke_gain = mist_material('Contact dust billows', 0, (.31, .38, .43))
billows = []
for i in range(12):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8)
    obj = bpy.context.object
    obj.name = 'Impact dust'
    obj.data.materials.append(smoke)
    billows.append((obj, i*math.tau/12, rng.uniform(.85, 1.2)))

for obj in scene.objects:
    if obj.type == 'LIGHT':
        obj.data.energy *= .55
# Light traversing the clouds is neutral; Flutter supplies the actual reward hue.
bpy.ops.object.light_add(type='POINT', location=(0, 0, 40))
falllight = bpy.context.object
falllight.data.energy = 700
falllight.data.color = (.42, .62, .85)
falllight.data.shadow_soft_size = 1.5
bpy.ops.object.light_add(type='AREA', location=(0, 0, .55))
inside = bpy.context.object
inside.rotation_euler.x = math.pi
inside.data.shape, inside.data.size = 'RECTANGLE', 3.0
inside.data.size_y = 1.5
inside.data.color = (.72, .86, 1)

scene.world.use_nodes = True
scene.world.node_tree.nodes['Background'].inputs[0].default_value = (.028, .07, .13, 1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value = .7
scene.render.engine = 'BLENDER_EEVEE'
scene.cycles.samples = 8 if preview else 16
scene.cycles.use_denoising = True
# Keep rendering reproducible on headless hosts without a Metal context.
scene.cycles.device = 'CPU'
scene.eevee.use_raytracing = True
if '--cycles' in sys.argv:
    scene.render.engine = 'CYCLES'
scene.render.film_transparent = False
scene.render.resolution_x, scene.render.resolution_y = WIDTH, HEIGHT
scene.render.resolution_percentage = 50 if preview else 100
scene.render.image_settings.color_mode = 'RGB'
scene.render.fps = FPS
camera.data.ortho_scale = 5.5 * HEIGHT / WIDTH
camera.data.shift_y = .16
scene.view_settings.exposure = .25

def travel(ms):
    if ms < 3650:
        return .84 * phase(ms, 550, 3650)**2
    if ms < 3910:
        return .84 + .05*(1-(1-phase(ms, 3650, 3910))**3)
    return .89 + .11*phase(ms, 3910, 4070)**3

def point(ms, index, count):
    # Ten persistent sources: scattered overhead -> horizontal formation ->
    # accelerated camera-following descent. Delay only the final lid contacts,
    # so the row does not become a diagonal staircase during the shared fall.
    stagger = index*14*smooth(phase(ms, 3650, 3910))
    t = travel(ms-stagger)
    formation = smooth(phase(ms, BOUNDS[1], FORMATION_END_MS))
    lane = index-(count-1)/2
    aim = smooth(phase(t, .76, 1))
    u = .5 if count == 1 else index/(count-1)
    target = Vector((-1.55+3.1*u, 0, .915))
    height = 4.7 if count == 1 else START_HEIGHTS[index]
    jitter = 0 if count == 1 else START_JITTER[index]
    sky = Vector((lane*.42+jitter*(1-formation), 0,
                  .915+38*(1-t)+height*(1-formation)))
    # Horizontal convergence only: every light keeps a separate surface target.
    sky.x = sky.x*(1-aim)+target.x*aim
    sky.y = target.y*aim
    return sky

def project(point):
    p = world_to_camera_view(scene, camera, Vector(point))
    return [round(p.x, 6), round(1-p.y, 6)]

def pose(ms):
    t = travel(ms)
    elevation = max(0, 38*(1-t)-2.8)
    # Continuous descent, then a grounded close-up with no diagonal yaw.
    camera.location = (0, -10, 6.3+elevation)
    camera.rotation_euler = (Vector((0, 0, 1+elevation))-camera.location).to_track_quat('-Z', 'Y').to_euler()
    age = max(0, (ms-4070)/1000)
    recoil = math.exp(-age*10) if ms >= 4070 else 0
    case.scale.z = 1-.035*recoil*math.cos(age*29)
    case.rotation_euler.y = math.sin(age*31)*.013*recoil
    opening = smooth(phase(ms, 4790, 5750))
    lid.rotation_euler.x = -math.radians(102)*opening
    inside.data.energy = 350*opening
    falllight.location = point(ms, 0, 1)
    falllight.data.energy = 700*(1-phase(ms, 4070, 4300))
    density = (1-math.exp(-age*24))*math.exp(-age*2.8) if ms >= 4070 else 0
    smoke_gain.inputs[1].default_value = density*2.4
    for obj, angle, variation in billows:
        radius = 1.7+3.0*(1-math.exp(-age*2))
        obj.location = (math.cos(angle)*radius, math.sin(angle)*radius, .10+age*.35)
        obj.scale = (variation*(.45+age*.75), variation*(.4+age*.6), .22+age*.45)
    bpy.context.view_layer.update()
    return {'one': [project(point(ms, 0, 1))],
            'ten': [project(point(ms, i, 10)) for i in range(10)],
            'case': project((0, 0, .7)),
            'rim': [project(case.matrix_world @ Vector(p)) for p in
                    [(-1.9, -1.08, .72), (1.9, -1.08, .72), (1.9, 1.08, .72), (-1.9, 1.08, .72)]]}

count = round(END/1000*FPS)+1
scene.frame_start, scene.frame_end = 1, count
track = []
for i in range(count):
    ms = i*1000/FPS
    scene.frame_set(i+1)
    track.append(pose(ms))
    # Preserve an editable, scrub-able Blender timeline, not only rendered PNGs.
    for obj, paths in [(camera, ('location', 'rotation_euler')),
                       (case, ('scale', 'rotation_euler')),
                       (lid, ('rotation_euler',)), (falllight, ('location',))]:
        for path in paths:
            obj.keyframe_insert(data_path=path, frame=i+1)
    for lamp in (inside, falllight):
        lamp.data.keyframe_insert(data_path='energy', frame=i+1)
    smoke_gain.inputs[1].keyframe_insert(data_path='default_value', frame=i+1)
    for obj, _, _ in billows:
        obj.keyframe_insert(data_path='location', frame=i+1)
        obj.keyframe_insert(data_path='scale', frame=i+1)
    if '--save-scene-only' not in sys.argv and (not preview or i in (0, 30, 75, 111, 122, 132, 159, 174)):
        directory = OUT / ('preview' if preview else 'frames')
        directory.mkdir(parents=True, exist_ok=True)
        scene.render.filepath = str(directory/f'frame_{i:04d}.png')
        bpy.ops.render.render(write_still=True)
(OUT/'track.json').write_text(json.dumps({'fps': FPS, 'width': WIDTH, 'height': HEIGHT,
    'bounds': BOUNDS, 'frames': track}, separators=(',', ':')))
pose(5750)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'intro.blend'))
