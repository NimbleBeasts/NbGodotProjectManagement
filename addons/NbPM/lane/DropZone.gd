tool
extends NinePatchRect


func can_drop_data(position, data):
	#print("can drop data")
	return true


func drop_data(position, data):
	#print("drop")
	#print(data)
	get_parent().drop(data)
	#get_parent().pm_ref.stop_card_drag()

