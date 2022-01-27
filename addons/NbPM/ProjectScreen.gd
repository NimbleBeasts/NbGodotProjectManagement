tool
extends Control


const Scene_Lane = preload("res://addons/NbPM/lane/Lane.tscn")
const Scene_InputField = preload("res://addons/NbPM/settings/InputField.tscn")

var Settings_Category = null
var Settings_User = null
var Settings_Tag = null
var Settings_Folder = null

var _project_cfg_provided = false
var _user_cfg_provided = false

var drag = false

var tasks = []

var base_color: Color

#TODO this needs to be handover by plugin loader
var task_directory = "res://_PM/tasks"

var task_timestamp = 0

# Loader Reference
var ref = null


func hide_all():
	$ProjectSettingsWindow.hide()
	$UserSettingsWindow.hide()
	$TaskView.hide()
	$Scroll.hide()


# Update the project settings window; Called by loader each time the cfg has changed.
func update_project_config():
	print("update_project_config")
	Settings_Category = get_node("ProjectSettingsWindow/Category/scroll/v")
	Settings_User = get_node("ProjectSettingsWindow/Users/scroll/v")
	Settings_Tag = get_node("ProjectSettingsWindow/Tags/scroll/v")
	Settings_Folder = get_node("ProjectSettingsWindow/ExcludeFolders/scroll/v")
	
	# Update Settings
	# Categories
	_clear_setting_items(Settings_Category)
	_add_setting_items(Settings_Category, ref.config_project.categories)
	# Users
	_clear_setting_items(Settings_User)
	_add_setting_items(Settings_User, ref.config_project.user_names)
	# Tags
	_clear_setting_items(Settings_Tag)
	_add_setting_items(Settings_Tag, ref.config_project.tags)
	# Folders
	_clear_setting_items(Settings_Folder)
	_add_setting_items(Settings_Folder, ref.config_project.exclude_folders)
	
	# Clear olds
	$TaskView/Input/Stage.clear()
	$TaskView/Input/Assigned.clear()
	$UserSettingsWindow/UserSelect.clear()
	for lane in $Scroll/h.get_children():
		lane.queue_free()
	
	var id = 0
	
	for cat in ref.config_project.categories:
		# Update Options
		$TaskView/Input/Stage.add_item(cat, id)
	
		# Update Lanes
		var lane = Scene_Lane.instance()
		lane.setup(self, cat, id, base_color)
		$Scroll/h.add_child(lane)
		id += 1
	
	id = 0
	for user in ref.config_project.user_names:
		# Update Options
		$TaskView/Input/Assigned.add_item(user, id)
		$UserSettingsWindow/UserSelect.add_item(user, id)
		id += 1


	
# Update the user settings window; Called by loader each time the cfg has changed.
func update_user_config():
	print("update_user_config")
	# Update Settings
	
	# Update Options
	pass
	
	
# Save project settings to config
func _on_ProjectSettingsSaveButton_button_up():
	ref.config_project.categories = _get_setting_items(Settings_Category)
	ref.config_project.user_names = _get_setting_items(Settings_User)
	ref.config_project.tags = _get_setting_items(Settings_Tag)
	ref.config_project.exclude_folders = _get_setting_items(Settings_Folder)
	ref.save_project_config()
	
	$ProjectSettingsWindow.hide()
	
	if _project_cfg_provided == false:
		_project_cfg_provided = true
		setup_steps()

func _on_UserSettingsSaveButton_button_up():
	ref.config_user.user_id = $UserSettingsWindow/UserSelect.selected
	
	$UserSettingsWindow.hide()
	
	ref.save_user_config()
	if _user_cfg_provided == false:
		_user_cfg_provided = true
		setup_steps()
	

# Get value of underlying item input fields
func _get_setting_items(ref):
	var array = []
	for item in ref.get_children():
		array.append(item.get_value())
	return array


# Remove all item input fields
func _clear_setting_items(ref):
	if ref:
		for child in ref.get_children():
			child.queue_free()
	else:
		printerr("_clear_setting_items ref not found")

# Add item input fields for each array element
func _add_setting_items(ref, array):
	var remove = ""
	match ref:
		Settings_Category:
			remove = "_remove_category_item"
		Settings_User:
			remove = "_remove_user_item"
		Settings_Tag:
			remove = "_remove_tag_item"
		_: #Settings_Folder
			remove = "_remove_folder_item"
	
	for item in array:
		_add_setting_item(ref, remove, item)



# If provided null, indicates, project was not set up.
func setup(loader_ref, project_cfg_provided, user_cfg_provided):
	print("setup")
	print("project: " + str(project_cfg_provided))
	print("user: " + str(user_cfg_provided))
	assert(loader_ref)
	ref = loader_ref
	_project_cfg_provided = project_cfg_provided
	_user_cfg_provided = user_cfg_provided
	base_color = loader_ref.get_editor_interface().get_editor_settings().get_setting("interface/theme/base_color")
		
	# Setup project config window
	update_project_config()
	# Setup user config window
	update_user_config()
	
	# Project config was not set-up, lets do this first
	setup_steps()
	



func setup_steps():
	hide_all()
	# No project config provided
	if _project_cfg_provided == false:
		$ProjectSettingsWindow.show()
		return
	# No user config provided
	elif _user_cfg_provided == false:
		$UserSettingsWindow.show()
		return
	else:
		$Scroll.show()
		# Update Tasks
		_update_tasks()



func new_task(category = -1, context = {}):
	$TaskView.show()
	# Title, Category, Assigned, Timestamp created, Description
	
	#TODO reset everything


func view_task(task_hash):
	$TaskView.show()
	
	for task in tasks:
		if task.hash == task_hash:
			$TaskView/Input/Title.text = task.title
			$TaskView/Input/Stage.select(task.category)
			$TaskView/Input/Assigned.select(task.assigned)
			task_timestamp = task.timestamp
			$TaskView/Description.text = task.description

func delete_task(task_hash):
	var dir = Directory.new()
	dir.remove(task_directory + "/" + task_hash + ".task")
	_update_tasks()

func _update_tasks():
	print("_update_tasks")
	_scan_tasks()
	_update_gui()


func _update_gui():
	#TODO: only re-render, if file has changed
	var id = 0
	print("_update_gui")
	
	# Loop over categories
	for lane in $Scroll/h.get_children():
		lane.clear()

		# Check if task matches category
		for task in tasks:
			if task.category == id:
				var assigned_string =  ref.config_project.user_names[task.assigned]
				lane.add(task, assigned_string)
		
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
					#print(file_name)
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


func _process(delta):
	if drag:
		if not Input.is_mouse_button_pressed(BUTTON_LEFT):
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



func move_task(id, task_hash):
	
	for task in tasks:
		if task.hash == task_hash:
			var data = task.duplicate()
			data.category = id
			var file = File.new()
			file.open(task_directory + "/" + task_hash + ".task", File.WRITE)
			file.store_line(JSON.print(data, "\t"))
			file.close()
			_update_tasks()
			break

func _on_TaskViewSaveButton_button_up():
	if task_timestamp == 0:
		task_timestamp = OS.get_unix_time()
	
	var time_hash = str(task_timestamp).sha256_text()
	
	var save_task = {
		"title": $TaskView/Input/Title.text,
		"category": $TaskView/Input/Stage.selected,
		"assigned": $TaskView/Input/Assigned.selected,
		"timestamp": task_timestamp,
		"hash": time_hash,
		"description": $TaskView/Description.text,
		"todos": []
	}
	
	var file = File.new()
	file.open(task_directory + "/" + time_hash + ".task", File.WRITE)
	file.store_line(JSON.print(save_task, "\t"))
	file.close()
	
	task_timestamp = 0
	_update_tasks()
	$TaskView.hide()


func _remove_category_item(reference, id):
	reference.queue_free()
func _remove_user_item(reference, id):
	reference.queue_free()
func _remove_tag_item(reference, id):
	reference.queue_free()
func _remove_folder_item(reference, id):
	reference.queue_free()

func _add_setting_item(reference, remove_function, value = ""):
	var item = Scene_InputField.instance()
	var id = reference.get_child_count()
	item.setup(id, value)
	item.connect("remove_input", self, remove_function)
	reference.add_child(item)
	
	
func _on_AddCategory_button_up():
	_add_setting_item(Settings_Category, "_remove_category_item")


func _on_AddUser_button_up():
	_add_setting_item(Settings_User, "_remove_user_item")


func _on_AddTag_button_up():
	_add_setting_item(Settings_Tag, "_remove_tag_item")


func _on_AddFolder_button_up():
	_add_setting_item(Settings_Folder, "_remove_folder_item")


func _on_UserButton_button_up():
	if $UserSettingsWindow.visible:
		$UserSettingsWindow.hide()
	else:
		$UserSettingsWindow.show()


func _on_ProjectButton_button_up():
	if $ProjectSettingsWindow.visible:
		$ProjectSettingsWindow.hide()
	else:
		$ProjectSettingsWindow.show()


func _on_ProjectSettingsCloseButton_button_up():
	_on_ProjectButton_button_up()


func _on_UserSettingsCloseButton_button_up():
	_on_UserButton_button_up()

func _on_TaskViewCloseButton_button_up():
	$TaskView.hide()


func _on_UpdateButton_button_up():
	_update_tasks()
