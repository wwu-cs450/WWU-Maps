"""Kretschmar Hall / CSP, floor 2.

Traced from the plan image (reference/KRH-CSP_Floor2.png). Coordinates are pixels on
that 10200 x 6600 sheet; each floor's image has its own position and scale, so
sheets of different floors do not line up with each other.

The numbers below are read off the image by eye and then moved onto the drawn
wall lines by `PlanImage` (see image.py). The main (east-west) wing and the hub are
aligned to the sheet; the north-east wing is rotated 45 degrees and is
described in its own (u, v) frame, see `wing`.

As on floors 1 and 3, a connector joins Kretschmar Hall (the main wing) to
the Chan Shun Pavilion (hub and north-east wing): an open lobby running from
the main wing's north-east corner, past the hub, up to the wing. Its west
side is the entrance vestibule; its east side is the wall the image draws
from the hub up to the wing. The strip between the main wing's east wall
and the hub is part of it (the image shows only a bridge there).
"""

import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "scripts"))

from paths import image_path  # noqa: E402
from render import Floor, Frame, hdoor, rect, vdoor  # noqa: E402
from plan_image import PlanImage, Tracer  # noqa: E402

BUILDING = "KRH-CSP"
LEVEL = 2
IMAGE = image_path(BUILDING, LEVEL)

image = PlanImage(IMAGE)
# The rotated wing. u runs along its long side (toward the upper right on the
# sheet), v across it (toward the lower right).
wing = Frame(origin=(1000.0, 6000.0), angle_deg=-45)
t = Tracer(image, wing)
X, Y = image.x, image.y
U, V = t.wing_image.x, t.wing_image.y

# --- Main wing walls -----------------------------------------------------------

X0 = X(1666, 3950, 4250)  # west exterior wall
X1 = X(5565, 3450, 3750)  # east exterior wall
TOP = Y(3415, 3150, 3450)  # north exterior wall
BOT = Y(4265, 2550, 3100)  # south exterior wall
HALL_N = Y(3775, 3150, 3350)  # corridor walls
HALL_S = Y(3905, 3200, 3600)
LAB_S = Y(3770, 4780, 5200)  # the north-east lab's corridor wall

# North side, west to east.
x_a = X(2322, 3420, 3470)
x_b = X(2500, 3420, 3480)
t.room(rect(X0, TOP, x_a, HALL_N))
t.room(rect(x_a, TOP, x_b, HALL_N), "stairs")

# Office suite around a small lobby.
x_c = X(2640, 3420, 3540)
x_d = X(2785, 3420, 3540)
x_e = X(2915, 3420, 3590)
x_f = X(3105, 3420, 3760)
x_g = X(2600, 3660, 3770)
x_h = X(2860, 3670, 3770)
x_i = X(2975, 3670, 3770)
y_a = Y(3600, 2690, 2780)
y_b = Y(3660, 2870, 3090)
t.room(rect(x_b, TOP, x_c, y_a))
t.room(rect(x_c, TOP, x_d, y_a))
t.room(rect(x_d, TOP, x_e, y_a))
t.room(rect(x_e, TOP, x_f, y_b))
t.room(rect(x_b, y_a, x_g, HALL_N))
t.room([(x_g, y_a), (x_e, y_a), (x_e, y_b), (x_h, y_b), (x_h, HALL_N), (x_g, HALL_N)])  # lobby
t.room(rect(x_h, y_b, x_i, HALL_N))
t.room(rect(x_i, y_b, x_f, HALL_N))

x_j = X(3475, 3420, 3540)
t.room(rect(x_f, TOP, x_j, HALL_N))

# Second suite: small rooms around a lobby that opens onto the corridor.
x_k = X(3620, 3420, 3560)
x_l = X(3760, 3420, 3560)
x_m = X(3895, 3420, 3560)
x_n = X(4078, 3420, 3510)
x_o = X(4205, 3420, 3760)
x_p = X(3700, 3650, 3770)
x_q = X(3900, 3640, 3770)
y_c = Y(3570, 3625, 3695)
y_d = Y(3565, 3900, 4030)
y_e = Y(3620, 4090, 4200)
y_f = Y(3630, 3710, 3890)
t.room(rect(x_j, TOP, x_k, y_f))
t.room(rect(x_k, TOP, x_l, y_c))
t.room(rect(x_l, TOP, x_m, y_c))
t.room(rect(x_m, TOP, x_n, y_d))
t.room(rect(x_n, TOP, x_o, y_e))
t.room(rect(x_j, y_f, x_p, HALL_N))
t.room(rect(x_p, y_f, x_q, HALL_N))
t.room([(x_k, y_c), (x_m, y_c), (x_m, y_d), (x_n, y_d), (x_n, y_e), (x_o, y_e),
        (x_o, HALL_N), (x_q, HALL_N), (x_q, y_f), (x_k, y_f)])  # lobby

# x_r..x_s is the north entrance passage (steps down to the door): corridor.
x_r = X(4597, 3450, 3600)
x_s = X(4735, 3450, 3750)
t.room(rect(x_o, TOP, x_r, HALL_N))
t.room(rect(x_s, TOP, X1, LAB_S))  # north lab

# South side, west to east.
x_t = X(2320, 4020, 4250)
x_u = X(2505, 4020, 4250)
x_v = X(3155, 3920, 4250)
x_w = X(3622, 3920, 4250)
x_x = X(3700, 3920, 4100)
x_y = X(4040, 3920, 4250)
x_z = X(4407, 3920, 4250)
x_aa = X(4915, 3920, 4250)
x_ab = X(5458, 4090, 4250)
y_g = Y(4115, 3710, 4030)
y_h = Y(4010, 5465, 5555)
t.room(rect(X0, HALL_S, x_t, BOT))
t.room(rect(x_t, HALL_S, x_u, BOT))
t.room(rect(x_u, HALL_S, x_v, BOT))
t.room(rect(x_v, HALL_S, x_w, BOT))
t.room(rect(x_w, HALL_S, x_x, y_g))
t.room(rect(x_x, HALL_S, x_y, y_g))  # restrooms, simplified
t.room(rect(x_w, y_g, x_y, BOT))
t.room(rect(x_y, HALL_S, x_z, BOT))
t.room(rect(x_z, HALL_S, x_r, BOT), "stairs")
t.room(rect(x_r, HALL_S, x_aa, BOT))
t.room(rect(x_aa, HALL_S, x_ab, BOT))  # south lab
t.room(rect(x_ab, HALL_S, X1, y_h))
t.room(rect(x_ab, y_h, X1, BOT))  # leads to the bridge
main_rooms = list(t.rooms)

# --- Hub -------------------------------------------------------------------------

HX0 = X(5760, 3620, 3780)
HX1 = X(6135, 4060, 4160)
HY0 = Y(3255, 5770, 6120)
HY1 = Y(4172, 5780, 6120)
y_i = Y(3410, 5900, 6120)
y_j = Y(3612, 5940, 6120)
BRIDGE_Y0, BRIDGE_Y1 = 4100, 4155

t.room(rect(HX0, HY0, HX1, y_i), "stairs")
t.room(rect(5785, 3425, 5875, 3545), "elevator", "Elev.")
t.room(rect(5880, y_i, HX1, y_j))
t.room(rect(HX0, y_j, HX1, HY1))

# --- Rotated wing ----------------------------------------------------------------

W_LEFT = U(5181, 480, 760)
W_RIGHT = U(6750, 480, 880)
W_TOP = V(468, 5400, 6700)
W_BOTTOM = V(1465, 5700, 6700)
v_n = V(720, 5600, 6150)  # south wall of the north offices
v_s = V(1228, 5650, 6150)  # north wall of the south offices
Y_CUT = Y(3045, 5385, 5515)  # sheet-aligned wall that cuts off the wing's south corner


def cut(u):
    """v of the cut wall at wing coordinate u."""
    return (Y_CUT - wing.origin[1] - u * wing.U[1]) / wing.V[1]


def cut_u(v):
    return (Y_CUT - wing.origin[1] - v * wing.V[1]) / wing.U[1]


# North offices.
us = [U(u, 480, 680, win=10) for u in (5375, 5540, 5705, 5870, 6035, 6198, 6365)]
t.room(wing.rect(W_LEFT, W_TOP, us[0], 745))
for u0, u1 in zip(us, us[1:]):
    t.room(wing.rect(u0, W_TOP, u1, v_n))
u_ne = U(6553, 480, 620, win=10)
t.room(wing.rect(us[-1], W_TOP, u_ne, 644))
t.room(wing.rect(u_ne, W_TOP, W_RIGHT, 670))

# East end: stairs between two small rooms.
u_e = U(6568, 740, 880, win=10)
u_st = U(6456, 900, 940, win=10)
v_st0 = V(890, 6470, 6740)
v_st1 = V(1055, 6470, 6740)
t.room(wing.rect(u_e, 670, W_RIGHT, v_st0))
t.room(wing.rect(u_st, v_st0, W_RIGHT, v_st1), "stairs")
t.room(wing.rect(u_e, v_st1, W_RIGHT, 1278))
u_se = U(6560, 1310, 1450, win=10)
t.room(wing.rect(u_se, 1278, W_RIGHT, W_BOTTOM))

# South offices; the first two are cut by the sheet-aligned wall.
ss = [U(u, 1250, 1450, win=10) for u in (5562, 5719, 5881, 6044, 6206, 6372)]
t.room([wing(5490, v_s), wing(ss[0], v_s), wing(ss[0], cut(ss[0])), wing(5490, cut(5490))])
t.room([wing(ss[0], v_s), wing(ss[1], v_s), wing(ss[1], W_BOTTOM),
        wing(cut_u(W_BOTTOM), W_BOTTOM), wing(ss[0], cut(ss[0]))])
for u0, u1 in zip(ss[1:], ss[2:]):
    t.room(wing.rect(u0, v_s, u1, W_BOTTOM))
t.room(wing.rect(ss[-1], 1300, u_se, W_BOTTOM))

# Central island.
i_u0 = U(5662, 1010, 1100, win=10)
i_u1 = U(5879, 1010, 1100, win=10)
i_u2 = U(5977, 1010, 1100, win=10)
i_u3 = U(6356, 860, 1080, win=10)
i_v0 = V(828, 6050, 6330)
i_v1 = V(1110, 5680, 5860)
t.room([wing(i_u0, i_v0), wing(i_u1, i_v0), wing(i_u1, 880), wing(i_u2, 880), wing(i_u2, 1000),
        wing(i_u1, 1000), wing(i_u1, i_v1), wing(i_u0, i_v1)])
t.room(wing.rect(i_u1, i_v0, i_u2, 880))
t.room(wing.rect(i_u1, 1000, i_u2, i_v1))
t.room(wing.rect(i_u2, i_v0, i_u3, i_v1))

# --- Footprint -------------------------------------------------------------------

CONN_X0 = X(5320, 3060, 3400)  # connector's west (exterior) wall, through the vestibule
# Below the vestibule the west wall turns and runs diagonally down to the main
# wing's north wall.
CONN_TURN = (CONN_X0, Y(3232, 5340, 5500))
CONN_FOOT = (5242, TOP)
SEAM_X = 5945  # connector's east wall, from the hub up to the wing
END = wing(W_LEFT, cut(W_LEFT))  # where the wing's end wall meets the cut wall
CUT_E = wing(cut_u(W_BOTTOM), W_BOTTOM)

footprint = [
    (X0, TOP), CONN_FOOT, CONN_TURN, (CONN_X0, Y_CUT), END,
    wing(W_LEFT, W_TOP), wing(W_RIGHT, W_TOP), wing(W_RIGHT, W_BOTTOM), CUT_E,
    (SEAM_X, Y_CUT), (SEAM_X, HY0), (HX1, HY0), (HX1, HY1), (HX0, HY1),
    (HX0, BRIDGE_Y1), (X1, BRIDGE_Y1), (X1, BOT), (X0, BOT),
]

# --- Doors -----------------------------------------------------------------------

# In the main wing, find_doors() picks up the openings that show as clean gaps
# and the rest are placed by hand. The wing's walls are drawn dashed, so all
# of its doors are placed by hand.


def wdoor(u0, v0, u1, v1):
    return (wing(u0, v0), wing(u1, v1))


MANUAL_MAIN = [
    hdoor(y_a, 2792, 2838), vdoor(x_g, 3612, 3656), hdoor(y_f, 3722, 3768),
    hdoor(HALL_N, 4012, 4058), hdoor(HALL_S, 2328, 2368), hdoor(HALL_S, 2575, 2620),
    hdoor(HALL_S, 3800, 3850), vdoor(X1, 4105, 4150),
]
t.doors += MANUAL_MAIN
t.find_doors(rooms=main_rooms)

t.doors += [
    # Hub.
    vdoor(HX0, 3275, 3345), vdoor(5785, 3445, 3525), hdoor(y_j, 5885, 5930),
    vdoor(HX0, 3795, 3885), vdoor(HX0, 4045, 4095),
    # Wing: north offices.
    wdoor(5335, 745, 5372, 745),
    wdoor(5492, v_n, 5535, v_n), wdoor(5545, v_n, 5590, v_n),
    wdoor(5822, v_n, 5865, v_n), wdoor(5875, v_n, 5920, v_n),
    wdoor(6150, v_n, 6193, v_n), wdoor(6203, v_n, 6250, v_n),
    wdoor(6495, 644, 6548, 644), wdoor(6575, 670, 6630, 670),
    # East end.
    wdoor(u_e, 678, u_e, 728), wdoor(u_st, 955, u_st, 1035), wdoor(u_e, 1232, u_e, 1275),
    wdoor(6570, 1278, 6635, 1278), wdoor(6500, 1300, 6555, 1300),
    # South offices.
    wdoor(5490, 1238, 5490, 1285), wdoor(5567, v_s, 5610, v_s),
    wdoor(5832, v_s, 5876, v_s), wdoor(5886, v_s, 5930, v_s),
    wdoor(6158, v_s, 6200, v_s), wdoor(6212, v_s, 6255, v_s),
    # Island.
    wdoor(5715, i_v0, 5760, i_v0), wdoor(5895, i_v0, 5940, i_v0),
    wdoor(5895, i_v1, 5940, i_v1), wdoor(6156, i_v1, 6206, i_v1), wdoor(5985, i_v0, 6028, i_v0),
    # Entrances.
    wdoor(W_LEFT, 795, W_LEFT, 870), vdoor(CONN_X0, 3075, 3200),
]

# Room numbers from KRH-CSP_Rooms.csv, which lists the doors met walking a loop:
# east along the corridor's north side, round the hub, back along the south
# side. Keys are positions in t.rooms. A suite's number is on its lobby.
LABELS = {
    0: "210", 7: "211", 10: "212", 18: "213", 19: "214", 20: "216",
    37: "251",
    31: "215", 30: "217", 28: "203", 24: "204", 23: "205", 22: "206", 21: "208",
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
