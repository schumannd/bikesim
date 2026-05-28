extends Object
class_name BikeRig

## Single source of truth for bike/rider placement and simple fall recovery.

const RIDER_PELVIS_LOCAL := Vector3(0.0, 0.73, 0.04)
const RIDE_SURFACE_Y := 0.0
const GARAGE_FLOOR_Y := 0.0
const FALL_RESET_Y := -8.0

static func ride_spawn_position(xz: Vector3 = Vector3.ZERO) -> Vector3:
	return Vector3(xz.x, RIDE_SURFACE_Y, xz.z)

static func collision_shape_y(wheel_radius: float) -> float:
	return wheel_radius + 0.16

static func mount_rider_on_bike(bike: Node3D, bike_visual: Node3D, rider: Node3D) -> void:
	var anchor := bike_visual.get_node_or_null("SeatAnchor")
	if anchor == null or not anchor is Node3D:
		return
	# Keep rider under the bike body so rebuilding BikeVisual does not delete it.
	if rider.get_parent() != bike:
		rider.reparent(bike, true)
	rider.position = bike_visual.position + (anchor as Node3D).position - RIDER_PELVIS_LOCAL

static func should_reset_fall(world_y: float) -> bool:
	return world_y < FALL_RESET_Y
