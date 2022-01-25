tool
extends Control


const Scene_Lane = preload("res://addons/NbPM/lane/Lane.tscn")

var categories = ["Backlog", "To do", "In progress", "Done"]

var drag = false

var tasks = []

#TODO this needs to be handover by plugin loader
var task_directory = "res://_PM/tasks"

var task_timestamp = 0

#var new_task = {
#	"title": "Task Title",
#	"category": 0,
#	"assigned": -1,
#	"timestamp": 0,
#	"hash": "",
#	"description": "",
#	"todos": []
#}



func _ready():
	print("ProjectScreen Loaded")
	$TaskView/Toolbar/Stage.clear()

	var id = 0
	for cat in categories:
		var lane = Scene_Lane.instance()
		lane.setup(self, cat, id)
		$Scroll/h.add_child(lane)
		
		$TaskView/Toolbar/Stage.add_item(cat, id)
		
		id += 1
	
	
	
	
	_update_tasks()



func new_task(category = -1, context = {}):
	$TaskView.show()
	# Title, Category, Assigned, Timestamp created, Description

func view_task(task_hash):
	$TaskView.show()
	
	for task in tasks:
		if task.hash == task_hash:
			$TaskView/Toolbar/Title.text = task.title
			$TaskView/Toolbar/Stage.select(task.category)
			$TaskView/Toolbar/Assigned.select(task.assigned)
			task_timestamp = task.timestamp
			$TaskView/Toolbar/Description.text = task.description

func _update_tasks():
	print("_update")
	_scan_tasks()
	_update_gui()


func _update_gui():
	#TODO: only re-render, if file has changed
	var id = 0
	
	# Loop over categories
	for lane in $Scroll/h.get_children():
		lane.clear()
		
		# Check if task matches category
		for task in tasks:
			if task.category == id:
				lane.add(task)
		id += 1


func _scan_tasks():
	var dir = Directory.new()
	# Clean tasks
	tasks = []
	
	# Scan task directory
	if dir.open(task_directory) == OK:
		dir.list_dir_begin(true, true)
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir():
				if file_name.get_extension() == "task":
					print(file_name)
					_scan_file(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()

func _scan_file(file_name):
	var file = File.new()
	file.open(task_directory + "/" + file_name, File.READ)
	tasks.append(parse_json(file.get_as_text()))
	file.close()

func _store_taks():
	pass


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


func _on_TaskViewCloseButton_button_up():
	$TaskView.hide()


func _on_TaskViewSaveButton_button_up():
	if task_timestamp == 0:
		task_timestamp = OS.get_unix_time()
	
	var time_hash = str(task_timestamp).sha256_text()
	
	var save_task = {
		"title": $TaskView/Toolbar/Title.text,
		"category": $TaskView/Toolbar/Stage.selected,
		"assigned": $TaskView/Toolbar/Assigned.selected,
		"timestamp": task_timestamp,
		"hash": time_hash,
		"description": $TaskView/Toolbar/Description.text,
		"todos": []
	}
	
	var file = File.new()
	file.open(task_directory + "/" + time_hash + ".task", File.WRITE)
	file.store_line(JSON.print(save_task, "\t"))
	file.close()
	
	task_timestamp = 0
	_update_tasks()
	$TaskView.hide()
