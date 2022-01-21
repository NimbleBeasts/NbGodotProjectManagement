tool
extends Control

const Scene_Lane = preload("res://addons/NbPM/Lane.tscn")

var categories = ["Backlog", "To do", "In progress", "Done"]

func _ready():
	print("ProjectScreen Loaded")
	

	for cat in categories:
		var lane = Scene_Lane.instance()
		lane.setup(cat)
		$Scroll/h.add_child(lane)



func jump_to_main_screen(metadata):
	$RichTextLabel.bbcode_text = str(metadata)



func _on_SettingsButton_button_up():
	if $SettingsWindow.visible:
		$SettingsWindow.hide()
	else:
		$SettingsWindow.show()
