tool
extends Control

var pm_ref = null

var _context = {}

func setup(ref, context):
	pm_ref = ref
	_context = context
	
	$Bg/v/toolbar/Title.set_text(str(context.title))
	$Bg/v/Description.bbcode_text = str(context.description)
	
	
	var popup_menu = $Bg/v/toolbar/Menu.get_popup()
	popup_menu.clear()
	popup_menu.add_item("View")
	popup_menu.add_item("Delete")


#TODO: handover EditorPlugin.get_editor_interface().get_editor_settings().get_setting("interface/theme/base_color")

	
func _on_Menu_button_up():
	pass # Replace with function body.


func _on_View_button_up():
	pm_ref.view_task(_context.hash)
