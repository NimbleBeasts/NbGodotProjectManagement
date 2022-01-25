tool
extends Control

var pm_ref = null

func setup(ref, context):
	pm_ref = ref

#TODO: handover EditorPlugin.get_editor_interface().get_editor_settings().get_setting("interface/theme/base_color")
func _ready():
	$Bg/v/Content/RichTextLabel.bbcode_text = "as"
	var rand = randi() % 20
	for i in range(rand):
		$Bg/v/Content/RichTextLabel.bbcode_text += "asdas\n"
		
	yield(get_tree(), "idle_frame")
	#print($Bg/v/Content/RichTextLabel.rect_size.y)
	var size = int(min(320, 32 + 8 + $Bg/v/Content/RichTextLabel.rect_size.y))
	self.rect_min_size.y = size
	self.rect_size.y = size

	
func _on_Menu_button_up():
	pass # Replace with function body.


