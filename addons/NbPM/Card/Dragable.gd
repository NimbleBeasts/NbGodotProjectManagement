extends ColorRect

const Scene_Preview = preload("res://addons/NbPM/card/DragPreview.tscn")

var pm_ref = null

func _ready():
	pm_ref = get_parent().pm_ref
	

func get_drag_data(_pos):
	var preview = Scene_Preview.instance()
	set_drag_preview(preview)

	if pm_ref:
		pm_ref.start_card_drag()
	return "id"
