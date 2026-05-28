extends Resource
class_name BikeConfig

@export var frame_id: String = "trail"
@export var wheel_id: String = "mtb_29"
@export var fork_id: String = "trail_susp"
@export var handlebar_id: String = "riser"
@export var seat_id: String = "trail"
@export var pedal_id: String = "platform"
@export var paint_color: Color = Color(0.1, 0.5, 0.9, 1.0)

func to_dict() -> Dictionary:
	return {
		"frame_id": frame_id,
		"wheel_id": wheel_id,
		"fork_id": fork_id,
		"handlebar_id": handlebar_id,
		"seat_id": seat_id,
		"pedal_id": pedal_id,
		"paint_color": paint_color.to_html()
	}

func from_dict(data: Dictionary) -> void:
	frame_id = data.get("frame_id", frame_id)
	wheel_id = data.get("wheel_id", wheel_id)
	fork_id = data.get("fork_id", fork_id)
	handlebar_id = data.get("handlebar_id", handlebar_id)
	seat_id = data.get("seat_id", seat_id)
	pedal_id = data.get("pedal_id", pedal_id)
	paint_color = Color(data.get("paint_color", paint_color.to_html()))
