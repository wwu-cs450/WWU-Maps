"""Kretschmar Hall / CSP, floor 1.

Traced from the plan image (reference/KRH-CSP_Floor1.png). Coordinates are pixels on
that 10200 x 6600 sheet; note that each floor's image has its own position and
scale, so sheets of different floors do not line up with each other.

The numbers below are read off the image by eye and then moved onto the drawn
wall lines by `PlanImage` (see image.py). The main (east-west) wing, the connector
and the east auditorium are aligned to the sheet; the north-east wing is
rotated 45 degrees and is described in its own (u, v) frame, see `wing`.

Simplifications: the two tiered halls are single rooms (seating, stage and
back rooms are not drawn), and free-standing partitions are left out.
"""

import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "scripts"))

from paths import image_path  # noqa: E402
from render import Floor, Frame, hdoor, rect, vdoor  # noqa: E402
from plan_image import PlanImage, Tracer  # noqa: E402

BUILDING = "KRH-CSP"
LEVEL = 1
IMAGE = image_path(BUILDING, LEVEL)

image = PlanImage(IMAGE)
# The rotated wing. u runs along its long side (toward the upper right on the
# sheet), v across it (toward the lower right).
wing = Frame(origin=(1000.0, 6000.0), angle_deg=-45)
t = Tracer(image, wing)
X, Y = image.x, image.y
U, V = t.wing_image.x, t.wing_image.y

# --- Main wing walls -----------------------------------------------------------

X0 = X(2992, 3700, 4400)  # west exterior wall
X1 = X(6540, 3700, 3980)  # east wall
TOP = Y(3677, 3050, 3550)  # north exterior wall
BOT = Y(4447, 3050, 3400)  # south exterior wall
HALL_N = Y(4000, 4400, 5000)  # corridor walls
HALL_S = Y(4120, 4800, 5400)

# North side, west to east.
x_a = X(3333, 3700, 3850)
x_st0 = X(3588, 3700, 3950, win=10)
x_st1 = X(3660, 3700, 3950)
x_b = X(3875, 3700, 3950)
x_c0 = X(4175, 3585, 3670)
x_c = X(4340, 3700, 3950)
x_d = X(5068, 3700, 3850)
x_e = X(5522, 3700, 3950)
x_f = X(5698, 3820, 3980)
x_g = X(5900, 3510, 3660)
y_a = Y(3927, 3050, 3300)
y_b = Y(3880, 3720, 3860)
y_c = Y(3575, 4200, 4330)
y_e = Y(3880, 5540, 5680)
y_g = Y(3497, 5720, 5880)

t.room(rect(X0, TOP, x_a, y_a))
t.room([(x_a, TOP), (x_st0, TOP), (x_st0, HALL_N), (x_a, HALL_N)])
t.room(rect(x_st0, TOP, x_st1, HALL_N), "stairs")
# x_st1..x_b is the north entrance lobby: left as corridor.
t.room(rect(x_b, TOP, x_c, HALL_N))
t.room(rect(x_c0, y_c, x_c, TOP))
t.room(rect(x_c, TOP, x_d, HALL_N))
t.room(rect(x_d, TOP, x_e, HALL_N))
t.room(rect(x_e, TOP, x_f, y_e))
t.room(rect(x_e, y_e, x_f, HALL_N))
t.room(rect(x_f, y_g, x_g, TOP))
t.room(rect(x_f, TOP, X1, HALL_N))

# South-west corner: a suite of small rooms around a lobby.
y_s1 = Y(4047, 3010, 3180)
y_s2 = Y(4140, 3200, 3330)
y_s3 = Y(4162, 3010, 3120)
y_s4 = Y(4272, 3010, 3120)
x_s1 = 3130  # the lobby's west side (drawn as an octagon)
x_s2 = X(3187, 4050, 4135)
x_s4 = X(3280, 4290, 4440)
x_s5 = X(3455, 4290, 4440)

t.room([(X0, y_a), (x_a, y_a), (x_a, y_s2), (x_s2, y_s2), (x_s2, y_s1), (X0, y_s1)])
t.room(rect(X0, y_s1, x_s1, y_s3))
t.room(rect(X0, y_s3, x_s1, y_s4))
t.room(rect(x_s1, y_s1, x_s2, y_s4))
t.room([(x_s2, y_s2), (3395, y_s2), (3395, HALL_S), (x_s5, HALL_S), (x_s5, y_s4), (x_s2, y_s4)])
t.room(rect(X0, y_s4, x_s4, BOT))
t.room(rect(x_s4, y_s4, x_s5, BOT))

# South side, west to east. The gaps at 3455..3535 and 4305..4385 are
# passages from the corridor to exterior doors.
x_h = X(3535, 4150, 4440)
x_i = X(3790, 4150, 4440)
x_j = X(3850, 4150, 4440)
x_k = X(4125, 4170, 4440)
x_l = X(4305, 4150, 4440)
x_m = X(4385, 4150, 4440)
x_n = X(4767, 4150, 4330, win=10)
x_o = X(5152, 4150, 4290)
x_p = X(5490, 4150, 4440, win=10)
x_q = X(5650, 4150, 4360)
x_r = X(5995, 4150, 4300)
x_s = X(6250, 4150, 4300)
y_h = Y(4240, 3550, 3780)

t.room(rect(x_h, HALL_S, x_i, y_h))
t.room(rect(x_h, y_h, x_i, BOT))
t.room(rect(x_i, HALL_S, x_j, BOT))
t.room(rect(x_j, HALL_S, x_k, BOT))
t.room(rect(x_k, HALL_S, x_l, BOT))
t.room(rect(x_m, HALL_S, x_n, BOT))
t.room(rect(x_n, HALL_S, x_o, BOT))
t.room(rect(x_o, HALL_S, x_p, BOT))
t.room(rect(x_p, HALL_S, x_q, BOT), "stairs")  # south stairs
t.room(rect(x_q, HALL_S, x_r, BOT))
t.room(rect(x_r, HALL_S, x_s, BOT))
t.room(rect(x_s, HALL_S, X1, BOT))

# --- South lecture hall --------------------------------------------------------

x_lh0 = X(4007, 4460, 4600)
y_lh = Y(4607, 4100, 4290)

t.room(rect(x_lh0, BOT, x_l, y_lh))  # backstage lobby
HALL_POLY = [
    (3915, 4650), (x_lh0, 4625), (x_lh0, y_lh), (x_m, y_lh), (x_m, 4625), (4480, 4650),
    (4612, 5150), (4400, 5197), (4200, 5217), (3990, 5192), (3788, 5150),
]
t.room(HALL_POLY)

# --- Connector (north of the main wing's east end) -----------------------------

CONN_X0 = X(6244, 3350, 3660)  # west exterior wall
CONN_X1 = X(6602, 3110, 3260)  # west wall of the north-south corridor
EAST_X = X(6720, 3050, 3280)  # east wall of the north-south corridor
y_n2 = Y(3347, 6410, 6590)
y_n4 = Y(3265, 6495, 6590)
y_n5 = Y(3160, 6420, 6590)
x_n1 = X(6485, 3275, 3340)

# The rotated wing's south-west end wall runs on past the connector's west
# wall; JOIN is where the two meet, A where the wing's corridor wall starts.
def on_end_wall(x=None, y=None):
    """The point of the wing's end wall (u = W_LEFT) at sheet column x / row y."""
    if x is not None:
        v = (x - wing.origin[0] - W_LEFT * wing.U[0]) / wing.V[0]
    else:
        v = (y - wing.origin[1] - W_LEFT * wing.U[1]) / wing.V[1]
    return wing(W_LEFT, v)


W_LEFT = U(5685, 1450, 1790)
W_HALL_N = V(1815, 6350, 6550)
JOIN = on_end_wall(x=CONN_X0)
A = wing(W_LEFT, W_HALL_N)
END = on_end_wall(y=y_n2)

y_n1 = Y(3492, 6260, 6520)  # wall between the two restrooms
t.room([(CONN_X0, y_n1), (CONN_X1, y_n1), (CONN_X1, 3610), (X1, TOP), (CONN_X0, TOP)])
t.room([JOIN, END, (CONN_X1, y_n2), (CONN_X1, y_n1), (CONN_X0, y_n1)])
t.room(rect(x_n1, y_n4, CONN_X1, y_n2))
t.room([A, wing(wing.u_at_y(W_HALL_N, y_n5), W_HALL_N), (CONN_X1, y_n5), (CONN_X1, y_n4),
        (x_n1, y_n4), (x_n1, y_n2), END])
t.door(*vdoor(CONN_X1, 3500, 3540))
t.door(*vdoor(CONN_X1, 3432, 3484))

# --- East auditorium -----------------------------------------------------------

AUD_X1 = X(7235, 3800, 4200)  # east exterior wall
AUD_Y0 = Y(3527, 7060, 7220)  # north exterior wall
AUD_Y1 = Y(4360, 6740, 7040)  # south exterior wall
x_au0 = X(6800, 3900, 4200)
y_au0 = Y(3662, 6830, 7000)
y_el = Y(3783, 6740, 6800)
y_au1 = Y(4243, 6700, 6790)
x_vest = 6890  # entrance lobby's east (exterior) wall, north of the stairs

t.room(rect(EAST_X, AUD_Y0, 7045, y_au0), "stairs")
t.room(rect(EAST_X, y_au0, x_au0, y_el), "elevator", "Elev.")
t.door(*vdoor(EAST_X, 3705, 3765))
t.room([(7045, AUD_Y0), (AUD_X1, AUD_Y0), (AUD_X1, 3725), (7110, 3725), (7045, y_au0)])
t.room([
    (EAST_X, y_el), (x_au0, y_el), (x_au0, y_au0), (7045, y_au0), (7110, 3725),
    (AUD_X1, 3725), (AUD_X1, 4292), (7060, AUD_Y1), (6870, AUD_Y1), (x_au0, 4250),
    (x_au0, y_au1), (EAST_X, y_au1),
])
t.door((7125, 3725), (7215, 3725))

# --- Rotated wing ----------------------------------------------------------------

W_RIGHT = U(7105, 1450, 1800)
W_TOP = V(1425, 5750, 7050)
W_BOTTOM = V(2338, 6300, 7050)
W_HALL_S = V(1940, 6350, 6550)
u_a = U(5985, 1450, 1740)
u_b = U(6285, 1450, 1760)
u_c = U(6585, 1450, 1760)
u_d = U(6200, 1960, 2120)
u_e = U(6500, 1960, 2120)
u_f = U(6760, 2040, 2320)
v_st = V(1897, 6800, 7040)

t.room(wing.rect(W_LEFT, W_TOP, u_a, W_HALL_N))
t.room(wing.rect(u_a, W_TOP, u_b, W_HALL_N))
t.room(wing.rect(u_b, W_TOP, u_c, W_HALL_N))
t.room(wing.rect(u_c, W_TOP, W_RIGHT, W_HALL_N))
t.room(wing.rect(6800, W_HALL_N, W_RIGHT, v_st), "stairs")

# Room beside the connector lobby, cut off by the north-south corridor.
u_cut = wing.u_at_x(W_HALL_S, EAST_X)
y_lobby = Y(3350, 6740, 6880)
u_corner = wing.u_at_y(W_BOTTOM, y_lobby)
t.room([(EAST_X, wing(u_cut, W_HALL_S)[1]), wing(u_d, W_HALL_S), wing(u_d, W_BOTTOM),
        wing(u_corner, W_BOTTOM), (EAST_X, y_lobby)])
t.room(wing.rect(u_d, W_HALL_S, u_e, W_BOTTOM))
t.room([wing(u_e, W_HALL_S), wing(6625, W_HALL_S), wing(6625, 2020), wing(u_f, 2020),
        wing(u_f, W_BOTTOM), wing(u_e, W_BOTTOM)])
t.room(wing.rect(6625, W_HALL_S, 6800, 2020), "stairs")
t.room([wing(u_f, v_st), wing(W_RIGHT, v_st), wing(W_RIGHT, W_BOTTOM), wing(u_f, W_BOTTOM),
        wing(u_f, 2020), wing(6800, 2020), wing(6800, 1952), wing(u_f, 1952)])

# --- Footprint -------------------------------------------------------------------

footprint = [
    (X0, TOP), (x_c0, TOP), (x_c0, y_c), (x_c, y_c), (x_c, TOP),
    (x_f, TOP), (x_f, y_g), (x_g, y_g), (x_g, TOP), (CONN_X0, TOP),
    JOIN, wing(W_LEFT, W_TOP), wing(W_RIGHT, W_TOP), wing(W_RIGHT, W_BOTTOM),
    wing(u_corner, W_BOTTOM), (x_vest, y_lobby), (x_vest, AUD_Y0),
    (AUD_X1, AUD_Y0), (AUD_X1, 4292), (7060, AUD_Y1), (EAST_X, AUD_Y1),
    (EAST_X, 4340), (X1, 4340), (X1, BOT), (x_m, BOT),
    *HALL_POLY[4:], *HALL_POLY[:2], (x_lh0, BOT), (X0, BOT),
]

# --- Doors -----------------------------------------------------------------------

# Door swings and tags on the image hide many openings, so these are placed by
# hand; find_doors() then adds the ones that show as clean gaps in a wall.


def wdoor(u0, v0, u1, v1):
    return (wing(u0, v0), wing(u1, v1))


t.doors += [
    # Main wing, north side.
    vdoor(x_a, 3862, 3920), hdoor(HALL_N, 3340, 3388), hdoor(HALL_N, 5140, 5225),
    vdoor(x_f, 3705, 3780), hdoor(HALL_N, 5597, 5643),
    # South-west suite.
    vdoor(x_a, 4045, 4100), hdoor(y_s2, 3340, 3392), vdoor(x_s1, 4085, 4130),
    vdoor(x_s1, 4205, 4250), vdoor(x_s2, 4165, 4215), hdoor(y_s4, 3195, 3245),
    hdoor(y_s4, 3365, 3415),
    # Main wing, south side.
    vdoor(x_h, 4245, 4290), vdoor(x_n, 4350, 4398), hdoor(HALL_S, 5085, 5130),
    vdoor(x_o, 4335, 4390), hdoor(HALL_S, 5385, 5465), hdoor(HALL_S, 5500, 5545),
    hdoor(BOT, 5530, 5575), hdoor(HALL_S, 6055, 6100), hdoor(BOT, 5825, 5898),
    hdoor(BOT, 4515, 4585),
    # South lecture hall and its lobby.
    hdoor(BOT, 4015, 4065), hdoor(y_lh, 4015, 4062), vdoor(x_l, 4465, 4515),
    hdoor(y_lh, 4318, 4372),
    # Rotated wing.
    wdoor(5945, W_HALL_N, 5985, W_HALL_N), wdoor(6245, W_HALL_N, 6285, W_HALL_N),
    wdoor(6540, W_HALL_N, 6580, W_HALL_N), wdoor(6800, 1830, 6800, 1885),
    wdoor(6765, v_st, 6798, v_st), wdoor(6640, W_HALL_S, 6700, W_HALL_S),
]
t.find_doors()

# Room numbers from KRH-CSP_Rooms.csv, which lists the doors met walking a loop:
# east along the corridor's north side, round the wing, back along the south
# side. Keys are positions in t.rooms. Rooms the list does not pin down (the
# south side between the two exterior passages, sub-rooms of suites) are left
# without a number.
LABELS = {
    1: "113", 3: "114", 5: "115", 6: "116", 7: "117", 10: "118",
    32: "156", 33: "157",
    40: "163", 41: "164", 42: "165", 43: "166", 49: "167", 47: "154", 46: "153", 45: "154",
    29: "100", 28: "101", 27: "102", 25: "104", 24: "105", 23: "106",
    31: "107",  # south lecture hall
    15: "111", 11: "112",
}
for index, number in LABELS.items():
    t.rooms[index].label = number

floor = Floor(footprint=footprint, rooms=t.rooms, doors=t.doors)

# Sheet pixel -> (lat, lng). The building corners shared with floor 3, at the
# positions floor 3 was matched to in OpenStreetMap.
CONTROL_POINTS = [
    ((X0, TOP), (46.046145, -118.391023)),  # main wing, NW corner
    ((X0, BOT), (46.045989, -118.391023)),  # main wing, SW corner
    (wing(W_LEFT, W_TOP), (46.046281, -118.390194)),  # NE wing, west corner
    (wing(W_RIGHT, W_TOP), (46.046478, -118.389915)),  # NE wing, north corner
    (wing(W_RIGHT, W_BOTTOM), (46.046352, -118.389731)),  # NE wing, east corner
]
