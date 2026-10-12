"""Original case model. Run with Blender --background --python this_file.

Outputs 24 transparent 768px frames with one camera/light rig and a reproducible
source .blend. No external artwork, textures or fonts are required.
"""
import math
import sys
from pathlib import Path
import bpy
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/gacha/case'
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

def material(name, color, metal=0, rough=.4):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    shader = m.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value = (*color, 1)
    shader.inputs['Metallic'].default_value = metal
    shader.inputs['Roughness'].default_value = rough
    return m

aluminium = material('Satin anodized aluminium', (.33, .39, .41), .93, .28)
rubber = material('Charcoal rubber', (.022, .029, .030), .05, .65)
steel = material('Machined steel', (.65, .69, .70), 1, .18)
inner = material('Interior graphite velvet', (.016, .025, .023), 0, .9)
badge = material('Embossed pale gold', (.60, .52, .32), .8, .3)

# Fine unidirectional micro-scratches; they follow the same mesh across frames.
nodes, links = aluminium.node_tree.nodes, aluminium.node_tree.links
tex = nodes.new('ShaderNodeTexNoise')
tex.inputs['Scale'].default_value = 155
tex.inputs['Detail'].default_value = 2
mapping = nodes.new('ShaderNodeVectorMath')
mapping.operation = 'MULTIPLY'
mapping.inputs[1].default_value = (1, 22, 3)
coords = nodes.new('ShaderNodeTexCoord')
links.new(coords.outputs['Generated'], mapping.inputs[0])
links.new(mapping.outputs[0], tex.inputs['Vector'])
bump = nodes.new('ShaderNodeBump')
bump.inputs['Strength'].default_value = .14
bump.inputs['Distance'].default_value = .008
links.new(tex.outputs['Fac'], bump.inputs['Height'])
links.new(bump.outputs['Normal'], nodes.get('Principled BSDF').inputs['Normal'])

def box(name, pos, scale, mat, bevel=.04, parent=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=pos)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    if bevel:
        mod = obj.modifiers.new('Soft machined edges', 'BEVEL')
        mod.width, mod.segments = bevel, 4
        obj.modifiers.new('Weighted corner normals', 'WEIGHTED_NORMAL')
    if parent:
        obj.parent = parent
    return obj

def cylinder(name, pos, radius, depth, mat, rotation=(0, 0, 0), parent=None):
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=radius, depth=depth, location=pos)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_euler = rotation
    obj.data.materials.append(mat)
    bevel = obj.modifiers.new('Metal edge', 'BEVEL')
    bevel.width, bevel.segments = .008, 3
    obj.modifiers.new('Weighted normals', 'WEIGHTED_NORMAL')
    if parent:
        obj.parent = parent
    return obj

# A hollow shell rather than a solid cube: open frames have real interior depth.
box('Base', (0, 0, .18), (3.8, 2.18, .22), aluminium, .08)
box('Front wall', (0, -1.035, .43), (3.8, .12, .46), aluminium)
box('Back wall', (0, 1.035, .43), (3.8, .12, .46), aluminium)
for x in (-1.84, 1.84):
    box('Side wall', (x, 0, .43), (.12, 2.1, .46), aluminium)
box('Interior floor', (0, 0, .31), (3.51, 1.91, .12), inner)
for x in (-1.68, 1.68):
    for y in (-.91, .91):
        box('Protective corner', (x, y, .20), (.40, .39, .38), rubber, .07)
for x in (-1.77, 1.77):
    for y in (-.93, .93):
        cylinder('Corner bolt', (x, y, .67), .048, .028, steel)

for x in (-1.16, 1.16):
    box('Latch plate', (x, -1.105, .47), (.31, .055, .29), steel, .025)
    box('Latch black insert', (x, -1.142, .49), (.16, .035, .13), rubber, .02)
for x in (-.43, .43):
    box('Handle mount', (x, -1.11, .37), (.18, .12, .22), steel)
    box('Handle arm', (x, -1.24, .37), (.08, .28, .09), rubber)
box('Handle grip', (0, -1.37, .37), (.93, .12, .13), rubber, .055)
for x in (-1.5, -.9, .9, 1.5):
    box('Front panel rib', (x, -1.11, .42), (.026, .015, .24), steel, .008)

lid = bpy.data.objects.new('Hinge pivot', None)
bpy.context.collection.objects.link(lid)
lid.location = (0, 1.035, .70)
box('Lid shell', (0, -1.035, .065), (3.82, 2.20, .20), aluminium, .08, lid)
box('Lid inset', (0, -1.035, .18), (3.36, 1.74, .065), aluminium, .08, lid)
box('Lid underside', (0, -1.035, -.047), (3.52, 1.93, .03), inner, .02, lid)
for x in (-1.7, 1.7):
    for y in (-1.96, -.11):
        box('Lid rubber corner', (x, y, .078), (.40, .39, .25), rubber, .06, lid)
for x in (-1.35, 1.35):
    cylinder('Rear hinge', (x, 1.03, .71), .06, .34, steel, (0, math.pi/2, 0))
for x in (-1.16, 1.16):
    box('Latch hook', (x, -2.16, .01), (.31, .08, .17), steel, .02, lid)
for x in (-1.32, -1.24, 1.24, 1.32):
    box('Lid rail', (x, -1.03, .225), (.025, 1.35, .018), steel, .006, lid)
box('Small serial plate', (0, -.75, .23), (.68, .24, .035), rubber, .015, lid)
bpy.ops.object.text_add(location=(-.25, -.82, .25))
text = bpy.context.object
text.name = 'DT serial mark'
text.data.body = 'DT / 001'
text.data.size = .13
text.data.extrude = .001
text.data.materials.append(badge)
text.parent = lid

def area(name, pos, energy, color, size, target=(0, 0, .5)):
    bpy.ops.object.light_add(type='AREA', location=pos)
    obj = bpy.context.object
    obj.name = name
    obj.data.energy, obj.data.color, obj.data.size = energy, color, size
    obj.rotation_euler = (Vector(target)-obj.location).to_track_quat('-Z', 'Y').to_euler()

area('Large softbox', (-3, -4, 7), 1000, (.82, .92, 1), 5)
area('Warm edge strip', (4, 2, 5), 1300, (1, .88, .65), 3)
area('Low cool fill', (-4, 3, 2), 700, (.38, .65, .59), 4)
area('Front reflection', (0, -5, 3), 300, (1, 1, 1), 3)
# Center the handle/latches in a frontal view. A slight elevation keeps the lid
# strike surface and the interior visible without a three-quarter yaw.
bpy.ops.object.camera_add(location=(0, -10, 6.3))
camera = bpy.context.object
camera.rotation_euler = (Vector((0, 0, 1.0))-camera.location).to_track_quat('-Z', 'Y').to_euler()
camera.data.type = 'ORTHO'
camera.data.ortho_scale = 5.65
scene = bpy.context.scene
scene.camera = camera
scene.render.engine = 'CYCLES'
scene.cycles.samples = 48
scene.cycles.use_denoising = True
scene.render.film_transparent = True
scene.render.resolution_x = scene.render.resolution_y = 768
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGBA'
scene.world.color = (.13, .13, .13)
scene.view_settings.view_transform = 'AgX'
scene.render.fps = 24
bpy.context.view_layer.update()

def image_point(point):
    p = world_to_camera_view(scene, camera, Vector(point))
    return (round(p.x, 6), round(1 - p.y, 6))

# Normalized PNG coordinates used by GachaStyle and RewardLight.target.
print('CASE_PROJECTION', {
    'visibleWidth': round(3.82 / camera.data.ortho_scale, 6),
    'ground': image_point((0, -1.095, .07)),
    'lidBackLeft': image_point((-1.55, .68, .915)),
    'lidFrontRight': image_point((1.55, -.68, .915)),
}, flush=True)
frames = [] if '--save-only' in sys.argv else range(24)
if '--preview' in sys.argv:
    OUT = ROOT / 'build/gacha-art/front-preview'
    OUT.mkdir(parents=True, exist_ok=True)
    frames = (0, 23)
for i in frames:
    lid.rotation_euler.x = -math.radians(102) * i/23
    scene.frame_set(i+1)
    scene.render.filepath = str(OUT / f'case_{i:02d}.png')
    bpy.ops.render.render(write_still=True)
lid.rotation_euler.x = 0
(ROOT / 'build/gacha-art').mkdir(parents=True, exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / 'build/gacha-art/case.blend'))
