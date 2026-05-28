extends Resource
class_name BikeConfig

@export var frame_id: String = "trail"
@export var wheel_id: String = "mtb_29"
@export var fork_id: String = "trail_susp"
@export var handlebar_id: String = "riser"
@export var seat_id: String = "trail"
@export var pedal_id: String = "platform"
@export var paint_color: Color = Color(0.1, 0.5, 0.9, 1.0)

@export var frame_paint_color: Color = Color(0.1, 0.5, 0.9, 1.0)
@export var fork_paint_color: Color = Color(0.1, 0.5, 0.9, 1.0)
@export var rim_paint_color: Color = Color(0.32, 0.34, 0.36, 1.0)
@export var handlebar_paint_color: Color = Color(0.1, 0.5, 0.9, 1.0)
@export var seat_paint_color: Color = Color(0.1, 0.5, 0.9, 1.0)

@export var frame_paint_finish: String = "gloss"
@export var fork_paint_finish: String = "gloss"
@export var rim_paint_finish: String = "metallic"
@export var handlebar_paint_finish: String = "gloss"
@export var seat_paint_finish: String = "matte"

func to_dict() -> Dictionary:
	return {
		"frame_id": frame_id,
		"wheel_id": wheel_id,
		"fork_id": fork_id,
		"handlebar_id": handlebar_id,
		"seat_id": seat_id,
		"pedal_id": pedal_id,
		"paint_color": paint_color.to_html(),
		"frame_paint_color": frame_paint_color.to_html(),
		"fork_paint_color": fork_paint_color.to_html(),
		"rim_paint_color": rim_paint_color.to_html(),
		"handlebar_paint_color": handlebar_paint_color.to_html(),
		"seat_paint_color": seat_paint_color.to_html(),
		"frame_paint_finish": frame_paint_finish,
		"fork_paint_finish": fork_paint_finish,
		"rim_paint_finish": rim_paint_finish,
		"handlebar_paint_finish": handlebar_paint_finish,
		"seat_paint_finish": seat_paint_finish
	}

func from_dict(data: Dictionary) -> void:
	frame_id = data.get("frame_id", frame_id)
	wheel_id = data.get("wheel_id", wheel_id)
	fork_id = data.get("fork_id", fork_id)
	handlebar_id = data.get("handlebar_id", handlebar_id)
	seat_id = data.get("seat_id", seat_id)
	pedal_id = data.get("pedal_id", pedal_id)
	if data.has("paint_color"):
		paint_color = Color(data["paint_color"])
	if data.has("frame_paint_color"):
		frame_paint_color = Color(data["frame_paint_color"])
		fork_paint_color = Color(data["fork_paint_color"])
		rim_paint_color = Color(data["rim_paint_color"])
		handlebar_paint_color = Color(data["handlebar_paint_color"])
		seat_paint_color = Color(data["seat_paint_color"])
	else:
		frame_paint_color = paint_color
		fork_paint_color = paint_color
		handlebar_paint_color = paint_color
		seat_paint_color = paint_color
	frame_paint_finish = data.get("frame_paint_finish", frame_paint_finish)
	fork_paint_finish = data.get("fork_paint_finish", fork_paint_finish)
	rim_paint_finish = data.get("rim_paint_finish", rim_paint_finish)
	handlebar_paint_finish = data.get("handlebar_paint_finish", handlebar_paint_finish)
	seat_paint_finish = data.get("seat_paint_finish", seat_paint_finish)

func sync_legacy_paint_color() -> void:
	paint_color = frame_paint_color
