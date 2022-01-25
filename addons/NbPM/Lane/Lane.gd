tool
extends Panel

signal item_drag_start()

var pm_ref = null

const Scene_Card = preload("res://addons/NbPM/Card/Card.tscn")
var _id = 0

func setup(ref, title, id):
	$v/Toolbar/Title.set_text(title)
	pm_ref = ref
	_id = id
	
#	var cnt = 0
#	for i in range(randi() % 7):
#		var card = Scene_Card.instance()
#		card.setup(pm_ref)
#		$v/Items/v.add_child(card)
#		cnt += 1
#
#	$v/Toolbar/ItemCount.set_text(str(cnt))

func clear():
	pass

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
	pm_ref.add_new_task(_id)
