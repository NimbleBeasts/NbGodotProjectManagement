tool
extends Panel


const Scene_Card = preload("res://addons/NbPM/Card.tscn")

func setup(title):
	$v/Toolbar/Title.set_text(title)
	
	var cnt = 0
	for i in range(randi() % 7):
		var card = Scene_Card.instance()
		$v/Items/v.add_child(card)
		cnt += 1
	
	$v/Toolbar/ItemCount.set_text(str(cnt))
