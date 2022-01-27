tool
extends Control

var ref = null

var exclude_dir_list = ["addons"]
var tags = []
var regex = RegEx.new()


var _file_list = []

var _todo_database = []

func update_project_config():
	var config = ref.config_project
	
	# Parse exclude list
	exclude_dir_list = []
	for folder in config.exclude_folders:
		exclude_dir_list.append(folder)
	
	var string = ""
	# Parse tags
	tags = config.tags.duplicate()
	for tag in tags:
		string += tag + "|"
	string = string.trim_suffix("|")

	# Search regex
	var regex_string = "(?:#|//)\\s*(%s)\\s*(\\:)?\\s*([^\\n]+)" % string
	regex.compile(regex_string)
	#print("scanning with: " + regex_string)
	assert(regex.is_valid())

	# Setup Todo Dock
	setup_dropdown()

	# Update
	_update_todos()


func setup(loader_ref, database):
	ref = loader_ref
	_todo_database = database

	# Parse configs
	update_project_config()

	# Signals
	ref.get_editor_interface().get_resource_filesystem().connect("filesystem_changed", self, "_update_todos")
	

func setup_dropdown():
	$ToolbarBox/DropdownMenu.icon = ref.get_editor_interface().get_base_control().get_icon("GuiDropdown", "EditorIcons")
	var popup_menu = $ToolbarBox/DropdownMenu.get_popup()
	popup_menu.clear()
	for tag in tags:
		popup_menu.add_check_item("Show " + str(tag))
		#TODO

	popup_menu.add_separator()
	popup_menu.add_item("Help", 10)
	
	popup_menu.connect("id_pressed", self, "_menu_click")

func _menu_click(id):
	print("click")



func _update_todos():
	# Detect changes
	if _scan_directory() != 0:
		# Remove old db relicts
		_clean_deleted_files()
		# Save the new db
		ref.config_user.todo_database = _todo_database.duplicate()
		ref.save_user_config()
		# Re-built todo tree
		_update_gui()


## Delete non-existing files from db
func _clean_deleted_files():
	var ids = []
	
	# Check if file in db still exists in scanned list
	for i in range(_todo_database.size()):
		if not _todo_database[i].file_path in _file_list:
			#print("delete:" + str(_todo_database[i].file_path))
			ids.append(i)

	# Invert array to delete backwards
	ids.invert()
	for id in ids:
		_todo_database.remove(id)
	
	_file_list = []

func _update_gui():
	var tree = $Tree
	
	tree.clear()
	var root = tree.create_item()
	tree.set_hide_root(true)
	tree.set_columns(3)
	tree.set_column_expand(0, true)
	tree.set_column_expand(1, false)
	tree.set_column_expand(2, false)
	tree.set_column_min_width(0, 100)
	tree.set_column_min_width(1, 24)
	tree.set_column_min_width(2, 24)

	var icon_ref = ref.get_editor_interface().get_base_control()
	for file in _todo_database:
		#{"file_path": file_path, "hash": file_hash, "todos": []
		var child_file = tree.create_item(root)
		child_file.set_icon(0, icon_ref.get_icon("Script", "EditorIcons"))
		child_file.set_text(0, file.file_path.substr(6))
		child_file.set_metadata(0, {"type": "SHOW_SOURCE", "line": 1, "path_file": file.file_path})
		
		for todo in file.todos:
			#{"type": type, "line": line_count, "description": description, "task_id": -1}
			var child_todo = tree.create_item(child_file)
			child_todo.set_text(0, str(todo.line) + ": " + str(todo.description))
			child_todo.set_metadata(0, {"type": "SHOW_SOURCE", "line": todo.line, "path_file": file.file_path})
			child_todo.add_button(1, icon_ref.get_icon("PathFollow", "EditorIcons"))
			child_todo.set_metadata(1, {"type": "SHOW_SOURCE", "line": todo.line, "path_file": file.file_path})
			if todo.task_id == -1:
				child_todo.add_button(2, icon_ref.get_icon("Add", "EditorIcons"))
				child_todo.set_metadata(2, {"type": "CREATE_TASK", "todo": todo, "path_file": file.file_path})
			else:
				child_todo.add_button(2, icon_ref.get_icon("TabContainer", "EditorIcons"))
				child_todo.set_metadata(2, {"type": "VIEW_TASK", "todo": todo, "path_file": file.file_path})


func _scan_directory(path = "res://"):
	var changes = 0
	var dir = Directory.new()
	
	if dir.open(path) == OK:
		dir.list_dir_begin(true, true)
		var file_name = dir.get_next()
		
		# Scan directories
		while file_name != "":
			# Build path tree
			var file_path = path
			if path == "res://":
				file_path += file_name
			else:
				file_path += "/" + file_name
			
			if dir.current_is_dir():
				# Recursive call to scan directory
				if not file_name in exclude_dir_list:
					# Scan directory
					changes += _scan_directory(file_path)
			else:
				if file_name.get_extension() == "gd":
					_file_list.append(file_path)
					# Scan file
					changes += _scan_file(path, file_name)
					#print("-----------------------------------")
			
			file_name = dir.get_next()
	
		dir.list_dir_end()
	
	return changes


func _scan_file(path, file_name):
	var changes = 0
	var file = File.new()
	
	# Build file path
	var file_path = path
	if path == "res://":
		file_path += file_name
	else:
		file_path += "/" + file_name
	
	# Get file hash
	var file_hash = file.get_sha256(file_path)
	# Look up file in database, check for modification
	var db_index = _db_find_index_by_file_path(file_path)

	#print("file: " + file_name)
	
	# Check if we have an existing library
	if db_index != -1:
		if _todo_database[db_index].hash == file_hash:
			# File has not been changed since last parsing
			#print("no changes")
			return 0

		# Clear old entries
		_todo_database[db_index].todos = []

	
	# Load source and parse the source code
	var source = load(file_path).source_code
	var regex_findings = regex.search_all(source)

	# Create db file entry if needed
	if db_index == -1:
		_todo_database.append({"file_path": file_path, "hash": file_hash, "todos": []})
		db_index = _todo_database.size() - 1

	# Parse regex findings
	for finding in regex_findings:
		# TYPE: text
		# 0 = complete line, 1 = type, 3 = description
		var type = finding.get_string(1)
		var description = finding.get_string(3)
		
		var line_count = 1
		for line in source.split("\n"):
			if line == finding.get_string(0): break
			line_count += 1
		
		_todo_database[db_index].todos.append({"type": type, "line": line_count, "description": description, "task_id": -1})
		changes += 1
	
	print("todos found: " + str(changes))
#	print(file_path)
#	print(file_hash)
#	print(todos)
#	print("--------------------------------")
#	print(changes)
	return changes

func _db_find_index_by_file_path(path):
	var index = 0
	for entry in _todo_database:
		if path == entry.file_path:
			return index
		index += 1
	
	return -1


func _on_Tree_item_activated():
	_process_click($Tree.get_selected().get_metadata(0))



func _on_Tree_button_pressed(item, column, id):
	_process_click(item.get_metadata(column))

	
func _process_click(metadata):
	print(metadata)
	if metadata.type == "SHOW_SOURCE":
		# Jump to source
		#{"type": "SHOW_SOURCE", "line": todo.line, "path_file": file.file_path}
		var source = load(metadata.path_file)
		var editor = ref.get_editor_interface().get_script_editor()
		if editor.has_method("_goto_script_line"):
			editor._goto_script_line(source, metadata.line - 1)
		else:
			printerr("Method '_goto_script_line' not found on script_editor_plugin.")
	else: #VIEW_TASK or CREATE_TASK
		ref.jump_to_main_screen(metadata)
