extends Button


var pm_ref = null

func setup(ref):
	pm_ref = ref
	

func get_drag_data(_pos):
	print("drag")
	# Use another colorpicker as drag preview.
	var cpb = ColorPickerButton.new()
	cpb.rect_size = Vector2(50, 50)
	set_drag_preview(cpb)
	# Return color as drag data.
	if pm_ref:
		pm_ref.start_card_drag()
	return "color"
