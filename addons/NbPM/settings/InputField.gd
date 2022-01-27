tool
extends Control

var id = 0

signal remove_input(reference, id)

func setup(my_id, value = ""):
	id = my_id
	$LineEdit.text = value

func _on_Button_button_up():
	emit_signal("remove_input", self, id)

func get_value():
	return $LineEdit.text
