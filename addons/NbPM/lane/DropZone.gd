tool
extends NinePatchRect


func can_drop_data(position, data):
	return true


func drop_data(position, data):
	get_parent().drop(data)

