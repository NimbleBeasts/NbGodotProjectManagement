tool
extends Control


const Scene_Lane = preload("res://addons/NbPM/Lane/Lane.tscn")

var categories = ["Backlog", "To do", "In progress", "Done"]

var drag = false

var tasks = []

#TODO this needs to be handover by plugin loader
var task_directory = "res://_PM/tasks"


var new_task = {
	"title": "Task Title",
	"category": 0,
	"assigned": -1,
	"timestamp": 0,
	"description": ""
}



func _ready():
	print("ProjectScreen Loaded")

	var id = 0
	for cat in categories:
		var lane = Scene_Lane.instance()
		lane.setup(self, cat, id)
		$Scroll/h.add_child(lane)
		id += 1
		
	_update_tasks()


func add_new_task(category = -1):
	$TaskView.show()
	# Title, Category, Assigned, Timestamp created, Description

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
