"""Shared production timing for exact Blender sampling and packaging."""
PROJECTION_FPS = 240
SOURCE_BOUNDS = [0, 550, 3650, 4070, 4260, 4790, 5750]
# Shared with Flutter via track.json: accelerate the plate and projected heads
# together, then rejoin the unchanged stillness/contact timeline.
SPECIAL_BOOST = {
    'startMs': 2850, 'endMs': 3090, 'leadMs': 120,
    'trailMs': 200, 'trailStretch': .9,
}
TIMELINES = {
    'common': [0, 550, 2350, 3000, 3180, 3550, 4100],
    'rare': [0, 550, 3650, 4450, 4630, 5000, 5720],
    'special': [0, 550, 3650, 4570, 4760, 5290, 6250],
}
LANDING = {'windowMs': 260, 'brakeMs': 70, 'holdMs': 110, 'power': 4}

def approach_travel(ms, bounds, lead):
    start = .84+.05*(1-(1-lead/260)**3)
    duration = bounds[3]-bounds[2]
    def position(f):
        return start+(1-start)*(f-.35*f*f+.35*f*f*f)
    windup = bounds[3]-LANDING['windowMs']
    if ms < windup:
        return position((ms-bounds[2])/duration)
    f = (windup-bounds[2])/duration
    at = position(f)
    velocity = (1-start)*(1-.7*f+1.05*f*f)/duration
    age = ms-windup
    brake = LANDING['brakeMs']
    ready = at+velocity*brake/2
    if age < brake:
        return at+velocity*(age-age*age/(2*brake))
    launch = brake+LANDING['holdMs']
    if age < launch:
        return ready
    u = min(1, max(0, (age-launch)/(LANDING['windowMs']-launch)))
    return ready+(1-ready)*u**LANDING['power']

def source_time(ms, bounds, name):
    boost = SPECIAL_BOOST
    lead = boost['leadMs'] if name == 'special' else 0
    for i in range(len(bounds)-1):
        if ms <= bounds[i+1]:
            f = max(0, (ms-bounds[i])/(bounds[i+1]-bounds[i]))
            base = SOURCE_BOUNDS[i]+f*(SOURCE_BOUNDS[i+1]-SOURCE_BOUNDS[i])
            if i == 1 and lead:
                u = min(1, max(0, (ms-boost['startMs'])/(boost['endMs']-boost['startMs'])))
                return base + lead*u*u*(3-2*u)
            if i == 2:
                travel = approach_travel(ms, bounds, lead)
                if travel <= .89:
                    return 3650+260*(1-max(0,1-(travel-.84)/.05)**(1/3))
                return 3910+160*(max(0,(travel-.89)/.11)**(1/3))
            return base
    return SOURCE_BOUNDS[-1]

