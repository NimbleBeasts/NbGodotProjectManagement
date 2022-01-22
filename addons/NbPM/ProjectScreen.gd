tool
extends Control

const Scene_Lane = preload("res://addons/NbPM/Lane.tscn")

var categories = ["Backlog", "To do", "In progress", "Done"]

var drag = false

func _ready():
	print("ProjectScreen Loaded")
	

	for cat in categories:
		var lane = Scene_Lane.instance()
		lane.setup(self, cat)
		$Scroll/h.add_child(lane)

func _input(event):
	if drag:
		if event is InputEventMouseButton:
			if event.get_button_index() == BUTTON_LEFT and event.pressed == false:
				stop_card_drag()

func start_card_drag():
	for child in $Scroll/h.get_children():
		child.drag_start()
		drag = true

func stop_card_drag():
	for child in $Scroll/h.get_children():
		child.drag_stop()

func jump_to_main_screen(metadata):
	$RichTextLabel.bbcode_text = str(metadata)



func _on_SettingsButton_button_up():
	if $SettingsWindow.visible:
		$SettingsWindow.hide()
	else:
		$SettingsWindow.show()
