extends Resource
class_name CharacterConfig

@export var hair_style: String = "short"
@export var outfit_id: String = "casual"
@export var skin_tone: Color = Color(0.86, 0.67, 0.52, 1.0)
@export var outfit_color: Color = Color(0.2, 0.2, 0.2, 1.0)

func to_dict() -> Dictionary:
	return {
		"hair_style": hair_style,
		"outfit_id": outfit_id,
		"skin_tone": skin_tone.to_html(),
		"outfit_color": outfit_color.to_html()
	}

func from_dict(data: Dictionary) -> void:
	hair_style = data.get("hair_style", hair_style)
	outfit_id = data.get("outfit_id", outfit_id)
	skin_tone = Color(data.get("skin_tone", skin_tone.to_html()))
	outfit_color = Color(data.get("outfit_color", outfit_color.to_html()))
