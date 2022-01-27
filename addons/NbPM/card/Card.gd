tool
extends Control

const Scene_Preview = preload("res://addons/NbPM/card/DragPreview.tscn")

var pm_ref = null

var _context = {}

func setup(ref, context, assigned_string, color):
	pm_ref = ref
	_context = context
		
	$Bg/v/toolbar/Title.set_text(str(context.title))
	$Bg/v/Description.bbcode_text = str(context.description)
	$Bg.color = color
	$Bg/v/Content/Assigned.set_text(str(assigned_string))
	
	var popup_menu = $Bg/v/toolbar/Menu.get_popup()
	popup_menu.clear()
	popup_menu.add_item("View", 0)
	popup_menu.add_item("Delete", 1)
	popup_menu.connect("id_pressed", self, "_on_item_pressed")


func get_drag_data(_pos):
	var preview = Scene_Preview.instance()
	set_drag_preview(preview)

	if pm_ref:
		pm_ref.start_card_drag()
	return _context.hash


func _on_item_pressed(id):
	if id == 0:
		pm_ref.view_task(_context.hash)
	elif id == 1:
		pm_ref.delete_task(_context.hash)


func _on_View_button_up():
	pm_ref.view_task(_context.hash)

