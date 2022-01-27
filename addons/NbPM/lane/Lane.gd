tool
extends Panel

signal item_drag_start()

var pm_ref = null

const Scene_Card = preload("res://addons/NbPM/card/Card.tscn")

var _id = 0
var _count = 0

var base_color: Color

func setup(ref, title, id, color):
	$v/Toolbar/Title.set_text(title)
	pm_ref = ref
	_id = id
	
	base_color = color
	$v/Toolbar/ItemCount/Bg.color = base_color

func drop(data):
	pm_ref.move_task(_id, data)
	pm_ref.stop_card_drag()

func clear():
	for card in $v/Items/v.get_children():
		card.queue_free()
	_count = 0
	$v/Toolbar/ItemCount.set_text(str(_count))


func add(context, assigned_string):
	var card = Scene_Card.instance()
	card.setup(pm_ref, context, assigned_string, base_color)
	$v/Items/v.add_child(card)
	_count += 1
	$v/Toolbar/ItemCount.set_text(str(_count))


func drag_start():
	$DropZone.show()
	self.modulate = Color(1.0, 1.0, 1.0, 0.6)

func drag_stop():
	$DropZone.hide()
	self.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _on_AddTaskButton_button_up():
	pm_ref.new_task(_id)
