tool
extends Control

var pm_ref = null

var _context = {}

func setup(ref, context, color):
	pm_ref = ref
	_context = context
	
	$Bg/v/toolbar/Title.set_text(str(context.title))
	$Bg/v/Description.bbcode_text = str(context.description)
	$Bg.color = color
	
	
	var popup_menu = $Bg/v/toolbar/Menu.get_popup()
	popup_menu.clear()
	popup_menu.add_item("View")
	popup_menu.add_item("Delete")


const Scene_Preview = preload("res://addons/NbPM/card/DragPreview.tscn")



func get_drag_data(_pos):
	var preview = Scene_Preview.instance()
	set_drag_preview(preview)

	if pm_ref:
		pm_ref.start_card_drag()
	return _context.hash

#TODO: handover EditorPlugin.get_editor_interface().get_editor_settings().get_setting("interface/theme/base_color")

	
func _on_Menu_button_up():
	pass # Replace with function body.


func _on_View_button_up():
	pm_ref.view_task(_context.hash)

