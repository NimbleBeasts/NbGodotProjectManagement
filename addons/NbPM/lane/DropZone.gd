tool
extends NinePatchRect


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	print("drop setup")


func can_drop_data(position, data):
	#print("can drop data")
	return true


func drop_data(position, data):
	print("drop")
	print(data)
	get_parent().drop(data)
	#get_parent().pm_ref.stop_card_drag()

