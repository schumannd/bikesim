extends Object
class_name BikeRig

## Single source of truth for bike/rider placement and simple fall recovery.

const RIDER_PELVIS_LOCAL := Vector3(0.0, 0.73, 0.04)
const RIDE_SURFACE_Y := 0.0
const GARAGE_FLOOR_Y := 0.0
const FALL_RESET_Y := -8.0
const BIKE_CAPSULE_HEIGHT := 1.2
const BIKE_CAPSULE_RADIUS := 0.45
const MAX_STEP_HEIGHT_RATIO := 0.5
const GARAGE_BUILDING_POSITION := Vector3(-18.0, 0.0, -16.0)

## World position outside the garage door (rideable road, facing toward the open world).
static func garage_exit_spawn() -> Vector3:
	return ride_spawn_position(Vector3(-10.0, 0.0, 2.0))

static func garage_exit_yaw() -> float:
	var exit_pos := garage_exit_spawn()
	var toward_world := Vector3.ZERO - exit_pos
	return atan2(toward_world.x, toward_world.z)

static func wizard_exit_from_tower(tower_world_pos: Vector3) -> Vector3:
	return ride_spawn_position(tower_world_pos + Vector3(7.0, 0.0, 7.0))

static func wizard_exit_yaw(tower_world_pos: Vector3) -> float:
	var exit_pos := wizard_exit_from_tower(tower_world_pos)
	var away := exit_pos - tower_world_pos
	return atan2(away.x, away.z)

static func house_exit_spawn(entrance_world: Vector3) -> Vector3:
	return ride_spawn_position(entrance_world)

static func ride_spawn_position(xz: Vector3 = Vector3.ZERO) -> Vector3:
	return Vector3(xz.x, RIDE_SURFACE_Y, xz.z)

static func max_step_height(wheel_radius: float) -> float:
	return wheel_radius * MAX_STEP_HEIGHT_RATIO

static func collision_shape_y(wheel_radius: float) -> float:
	# Capsule bottom sits at -max_step so curbs up to ~half a wheel still clear.
	var half_extent := BIKE_CAPSULE_HEIGHT * 0.5 + BIKE_CAPSULE_RADIUS
	return half_extent - max_step_height(wheel_radius)

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
