"""Kretschmar Hall / CSP, floor 3.

Traced by eye from the plan image (reference/KRH-CSP_Floor3.png), without
snapping to the image (see krh_csp_floor1.py for that). Coordinates are pixels
on the 10200 x 6600 sheet. The main (east-west) wing, the connector and the hub are
aligned to the sheet; the north-east wing is rotated 45 degrees and is
described in its own (u, v) frame, see `wing` below.

Stair treads are drawn here for the preview only; the app draws its own.
"""

import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "scripts"))

from paths import image_path  # noqa: E402
from render import Floor, Frame, Room, flight, hdoor, rect, vdoor  # noqa: E402

BUILDING = "KRH-CSP"
LEVEL = 3
IMAGE = image_path(BUILDING, LEVEL)

# The rotated wing. u runs along its long side (toward the upper right on the
# sheet), v across it (toward the lower right).
wing = Frame(origin=(5650.6, 3037.0), angle_deg=-45)

# Wing walls in (u, v).
W_LEFT, W_RIGHT = 101, 1688  # end walls
W_TOP, W_BOTTOM = 108, 1120  # long exterior walls
W_HALL_N, W_HALL_S = 545, 683  # corridor walls

# Main wing walls.
MAIN_X0, MAIN_X1 = 2423, 6370
MAIN_Y0, MAIN_Y1 = 3798, 4657
HALL_N, HALL_S = 4162, 4291  # main corridor walls

# Connector diagonal exterior wall, from the main wing up to the rotated wing.
DIAG_BOTTOM = (6038, MAIN_Y0)
DIAG_TOP = wing(W_LEFT, W_HALL_S)


def diag_x(y):
    (x0, y0), (x1, y1) = DIAG_BOTTOM, DIAG_TOP
    return x0 + (y - y0) * (x1 - x0) / (y1 - y0)


footprint = [
    (MAIN_X0, MAIN_Y0),
    DIAG_BOTTOM,
    DIAG_TOP,
    wing(W_LEFT, W_TOP),
    wing(W_RIGHT, W_TOP),
    wing(W_RIGHT, W_BOTTOM),
    wing(545, W_BOTTOM),
    (6760, 3444),
    (6760, 3627),
    (6963, 3627),
    (6963, 4579),
    (6575, 4579),
    (6575, 4505),
    (MAIN_X1, 4505),
    (MAIN_X1, MAIN_Y1),
    (MAIN_X0, MAIN_Y1),
]

rooms = []
doors = []
treads = []


def room(poly, kind="room", label=None):
    rooms.append(Room(poly, kind, label))


# --- Main wing, west end -----------------------------------------------------

room(rect(MAIN_X0, MAIN_Y0, 2576, 4108))
doors.append(vdoor(2576, 4050, 4100))
room(rect(2576, MAIN_Y0, 2740, 4035))
doors.append(hdoor(4035, 2677, 2729))
room(rect(2740, MAIN_Y0, 2904, 4035))
doors.append(hdoor(4035, 2848, 2900))
room([(2904, MAIN_Y0), (3092, MAIN_Y0), (3092, 4074), (3010, 4074), (3010, 4035), (2904, 4035)])
doors.append(hdoor(4035, 2915, 2965))

# West stairs.
room(
    [(3092, MAIN_Y0), (3265, MAIN_Y0), (3265, 4030), (3305, 4080), (3225, 4084),
     (3179, 4045), (3179, 3972), (3092, 3972)],
    "stairs",
)
treads += flight((3099, 3880), (3172, 3880), (3172, 3966), (3099, 3966), 7)
treads += flight((3186, 3880), (3258, 3880), (3258, 3966), (3186, 3966), 7)

room(rect(2648, 4108, 2904, 4360))
doors.append(vdoor(2904, 4221, 4268))
room(rect(MAIN_X0, 4108, 2648, 4286))
doors.append(hdoor(4108, 2592, 2644))
room(rect(MAIN_X0, 4286, 2648, 4475))
doors.append(vdoor(2648, 4412, 4465))
room(rect(MAIN_X0, 4475, 2645, MAIN_Y1))
doors.append(hdoor(4475, 2588, 2640))

room([(2645, 4490), (2728, 4433), (2822, 4433), (2822, MAIN_Y1), (2645, MAIN_Y1)])
doors.append(hdoor(4433, 2760, 2815))
room(rect(2822, 4433, 2995, MAIN_Y1))
doors.append(hdoor(4433, 2934, 2987))
room(rect(2995, 4433, 3168, MAIN_Y1))
doors.append(hdoor(4433, 3107, 3162))
room([(3168, 4433), (3265, 4433), (3265, 4385), (3365, 4385), (3365, MAIN_Y1), (3168, MAIN_Y1)])
doors.append(hdoor(4433, 3175, 3230))

# --- Main wing, north side of the corridor -----------------------------------

room(rect(3513, MAIN_Y0, 3863, 4047))
doors.append(vdoor(3513, 3985, 4040))
room(rect(3513, 4047, 3632, HALL_N))
doors.append(vdoor(3513, 4085, 4135))
room(rect(3632, 4047, 3755, HALL_N))
doors.append(hdoor(HALL_N, 3642, 3698))
room(rect(3755, 4047, 3877, HALL_N))
room([(3863, MAIN_Y0), (3975, MAIN_Y0), (3975, HALL_N), (3877, HALL_N), (3877, 4047), (3863, 4047)])
doors.append(hdoor(HALL_N, 3888, 3939))

room(rect(3975, MAIN_Y0, 4397, HALL_N))
doors.append(hdoor(HALL_N, 4311, 4365))
room(rect(4397, MAIN_Y0, 4913, HALL_N))
doors += [hdoor(HALL_N, 4415, 4469), hdoor(HALL_N, 4853, 4906)]
room(rect(4913, MAIN_Y0, 5391, HALL_N))
doors.append(hdoor(HALL_N, 5319, 5375))
room(rect(5391, MAIN_Y0, 6044, HALL_N))
doors += [hdoor(HALL_N, 5398, 5453), hdoor(HALL_N, 5942, 5995)]
room(rect(6044, MAIN_Y0, MAIN_X1, 3969))
doors.append(vdoor(MAIN_X1, 3905, 3955))
room(rect(6044, 3969, MAIN_X1, HALL_N))
doors.append(vdoor(MAIN_X1, 3985, 4035))

# --- Main wing, south side of the corridor -----------------------------------

room(rect(3365, HALL_S, 3520, 4475))
doors.append(hdoor(HALL_S, 3456, 3513))
room(rect(3365, 4475, 3520, MAIN_Y1))
doors.append(vdoor(3520, 4540, 4595))
room(rect(3520, HALL_S, 3884, MAIN_Y1))
doors.append(hdoor(HALL_S, 3526, 3579))
room(rect(3884, HALL_S, 4257, MAIN_Y1))
doors.append(hdoor(HALL_S, 4193, 4251))
room(rect(4257, HALL_S, 4678, MAIN_Y1))
doors.append(hdoor(HALL_S, 4615, 4663))
room(rect(4678, HALL_S, 5048, MAIN_Y1))
doors.append(hdoor(HALL_S, 4990, 5041))
room(rect(5048, HALL_S, 5195, MAIN_Y1))
doors.append(hdoor(HALL_S, 5054, 5115))

# South stairs.
room(rect(5195, HALL_S, 5392, MAIN_Y1), "stairs")
doors.append(hdoor(HALL_S, 5208, 5270))
treads += flight((5290, 4335), (5385, 4335), (5385, 4470), (5290, 4470), 9)
treads += flight((5205, 4445), (5283, 4445), (5283, 4580), (5205, 4580), 9)

room(rect(5392, HALL_S, 5720, MAIN_Y1))
doors.append(hdoor(HALL_S, 5651, 5713))
room(rect(5720, HALL_S, MAIN_X1, MAIN_Y1))
doors += [hdoor(HALL_S, 5726, 5785), hdoor(HALL_S, 6305, 6360)]

# --- Connector between the main wing and the rotated wing --------------------

CONN_X = 6405  # west wall of the connector corridor

room(rect(6241, 3664, CONN_X, MAIN_Y0))
doors.append(hdoor(3664, 6248, 6300))
room([(diag_x(3586), 3586), (6241, 3586), (6241, MAIN_Y0), DIAG_BOTTOM])
doors.append(vdoor(6241, 3595, 3650))
room([DIAG_TOP, (CONN_X, DIAG_TOP[1]), (CONN_X, 3586), (diag_x(3586), 3586)])
doors.append(vdoor(CONN_X, 3530, 3580))

# Two rooms tucked under the rotated wing's corridor wall.
y_split = 3236
corner = wing(wing.u_at_y(W_HALL_N, y_split), W_HALL_N)
room([corner, (CONN_X, y_split), (CONN_X, DIAG_TOP[1]), DIAG_TOP, wing(W_LEFT, W_HALL_N)])
doors.append(vdoor(CONN_X, 3383, 3433))
top = wing(wing.u_at_x(W_HALL_N, CONN_X), W_HALL_N)
room([corner, top, (CONN_X, y_split)])
doors.append(vdoor(CONN_X, 3110, 3158))

# --- Hub (east of the connector corridor) ------------------------------------

HUB_X0, HUB_X1 = 6575, 6963

room(rect(HUB_X0, 3627, HUB_X1, 3800), "stairs")
doors.append(vdoor(HUB_X0, 3650, 3705))
treads += flight((6735, 3640), (6735, 3713), (6880, 3713), (6880, 3640), 11)
treads += flight((6735, 3720), (6735, 3793), (6880, 3793), (6880, 3720), 11)

room(rect(HUB_X0, 3800, 6720, 3933), "elevator", "Elev.")
doors.append(vdoor(HUB_X0, 3825, 3905))
room(rect(6720, 3800, HUB_X1, 3933))
room(rect(HUB_X0, 3933, HUB_X1, 4310))
doors += [vdoor(HUB_X0, 3940, 3990), vdoor(HUB_X1, 3945, 3995)]
room(rect(HUB_X0, 4310, HUB_X1, 4579))
doors.append(vdoor(HUB_X0, 4372, 4425))

# --- Rotated wing -------------------------------------------------------------

room([wing(W_LEFT, W_TOP), wing(815, W_TOP), wing(815, 318), wing(797, 318),
      wing(797, W_HALL_N), wing(W_LEFT, W_HALL_N)])
doors.append((wing(618, W_HALL_N), wing(672, W_HALL_N)))
room(wing.rect(815, W_TOP, 960, 318))
doors.append((wing(960, 262), wing(960, 316)))
room(wing.rect(797, 318, 960, W_HALL_N))
doors += [(wing(805, W_HALL_N), wing(858, W_HALL_N)), (wing(818, 318), wing(868, 318))]
room(wing.rect(960, W_TOP, W_RIGHT, W_HALL_N))
doors.append((wing(1032, W_HALL_N), wing(1088, W_HALL_N)))

# East stairs at the far end of the wing corridor.
room(wing.rect(1390, W_HALL_N, W_RIGHT, W_HALL_S), "stairs")
doors.append((wing(1390, 585), wing(1390, 640)))
treads += flight(wing(1475, 552), wing(1475, 610), wing(1612, 610), wing(1612, 552), 10)
treads += flight(wing(1475, 620), wing(1475, 678), wing(1612, 678), wing(1612, 620), 10)

# Room with the chamfered corner, beside the connector lobby.
room([(6542, wing(580, W_HALL_S)[1]), wing(685, W_HALL_S), wing(685, W_BOTTOM),
      wing(545, W_BOTTOM), (6627, 3443), (6540, 3358)])
doors.append((wing(685, 785), wing(685, 840)))
room(wing.rect(685, W_HALL_S, 1160, W_BOTTOM))
doors.append((wing(820, W_HALL_S), wing(870, W_HALL_S)))
room(wing.rect(1160, W_HALL_S, W_RIGHT, W_BOTTOM))
doors.append((wing(1228, W_HALL_S), wing(1280, W_HALL_S)))

floor = Floor(
    footprint=footprint,
    rooms=rooms,
    doors=doors,
    treads=treads,
)

# Stairs read from their treads, so only the elevator is labeled. Room numbers
# still need to be matched to rooms on site (see KRH-CSP_Rooms.csv).

# Sheet pixel -> (lat, lng), from OSM. The hub's east side is left out: OSM's
# outline there includes the terrace and disagrees with the plan by 3-4 m,
# while these points agree to about half a metre.
CONTROL_POINTS = [
    ((MAIN_X0, MAIN_Y0), (46.046145, -118.391023)),  # main wing, NW corner
    ((MAIN_X0, MAIN_Y1), (46.045989, -118.391023)),  # main wing, SW corner
    (DIAG_BOTTOM, (46.046147, -118.390132)),  # connector, foot of diagonal
    (DIAG_TOP, (46.046208, -118.390088)),  # connector, top of diagonal
    (wing(W_LEFT, W_TOP), (46.046281, -118.390194)),  # NE wing, west corner
    (wing(W_RIGHT, W_TOP), (46.046478, -118.389915)),  # NE wing, north corner
    (wing(W_RIGHT, W_BOTTOM), (46.046352, -118.389731)),  # NE wing, east corner
]
