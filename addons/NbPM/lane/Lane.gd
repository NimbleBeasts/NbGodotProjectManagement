tool
extends Panel

signal item_drag_start()

var pm_ref = null

const Scene_Card = preload("res://addons/NbPM/card/Card.tscn")

var _id = 0



func setup(ref, title, id):
	$v/Toolbar/Title.set_text(title)
	pm_ref = ref
	_id = id


func drop(data):
	pm_ref.move_task(_id, data)
	pm_ref.stop_card_drag()

func clear():
	for card in $v/Items/v.get_children():
		card.queue_free()

func add(context):
	var card = Scene_Card.instance()
	card.setup(pm_ref, context)
	$v/Items/v.add_child(card)

func drag_start():
	$DropZone.show()
	self.modulate = Color(1.0, 1.0, 1.0, 0.6)

func drag_stop():
	$DropZone.hide()
	self.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _on_AddTaskButton_button_up():
	pm_ref.new_task(_id)
