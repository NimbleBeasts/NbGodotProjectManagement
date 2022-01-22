tool
extends Panel

signal item_drag_start()

var pm_ref = null

const Scene_Card = preload("res://addons/NbPM/Card.tscn")


func setup(ref, title):
	$v/Toolbar/Title.set_text(title)
	pm_ref = ref
	
	var cnt = 0
	for i in range(randi() % 7):
		var card = Scene_Card.instance()
		card.setup(pm_ref)
		$v/Items/v.add_child(card)
		cnt += 1
	
	$v/Toolbar/ItemCount.set_text(str(cnt))

func drag_start():
	$DropZone.show()
	self.modulate = Color(1.0, 1.0, 1.0, 0.6)

func drag_stop():
	$DropZone.hide()
	self.modulate = Color(1.0, 1.0, 1.0, 1.0)
