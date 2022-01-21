
extends Control

var ref = null

var exclude_dir_list = ["addons"]
var regex = RegEx.new()

var database = []

enum TreeButtonType {JumpToSource = 0, AssignTask = 1}

func _ready():
	# TODO: todo prefixes can be configured in project.cfg
	
	# Setup Todo Dock
	setup_dropdown()
	
	# Search regex
	regex.compile("(?:#|//)\\s*(TODO|FIXME|NOTE)\\s*(\\:)?\\s*([^\\n]+)")
	assert(regex.is_valid())
	
	
	_update_todos()
	

	
func setup_dropdown():
	$ToolbarBox/DropdownMenu.icon = get_icon("GuiDropdown", "EditorIcons")
	var popup_menu = $ToolbarBox/DropdownMenu.get_popup()
	popup_menu.add_check_item("Show TODO")
	popup_menu.add_check_item("Show FIXME")
	popup_menu.add_check_item("Show NOTE")
	popup_menu.add_separator()
	popup_menu.add_item("Help", 10)
	popup_menu.connect("id_pressed", self, "_menu_click")

func _menu_click(id):
	print("click")
	print(id)

func _init():
	print("todo init")



func _update_todos():
	if _scan_directory() != 0:
		_update_gui()

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
	tree.set_column_min_width(1, 16)
	tree.set_column_min_width(2, 16)

	
	for file in database:
		#{"file_path": file_path, "hash": file_hash, "todos": []
		var child_file = tree.create_item(root)
		child_file.set_icon(0, get_icon("Script", "EditorIcons"))
		child_file.set_text(0, file.file_path.substr(6))
		child_file.set_metadata(0, file.file_path)
		for todo in file.todos:
			#{"type": type, "line": line_count, "description": description, "task_id": -1}
			var child_todo = tree.create_item(child_file)
			child_todo.set_text(0, str(todo.line) + ": " + str(todo.description))
			#child_todo.set_text(1, "&")
			child_todo.add_button(1, get_icon("Script", "EditorIcons"))
			child_todo.add_button(2, get_icon("Script", "EditorIcons"))
			#child_todo.set_text(2, "+")

func _scan_directory(path = "res://"):
	var changes = 0
	var dir = Directory.new()
	
	if dir.open(path) == OK:
		dir.list_dir_begin(true, true)
		var file_name = dir.get_next()
		
		# Scan directories
		while file_name != "":
			if dir.current_is_dir():
				# Recursive call to scan directory
				if not file_name in exclude_dir_list:
					# Build path tree
					var new_path = path
					if path == "res://":
						new_path += file_name
					else:
						new_path += "/" + file_name
					# Scan directory
					changes += _scan_directory(new_path)
			else:
				if file_name.get_extension() == "gd":
					print("file: " + file_name)
					# Scan file
					changes += _scan_file(path, file_name)
			
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
	if db_index != -1:
		if database[db_index].hash == file_hash:
			# File has not been changed since last parsing
			return 0
		else:
			# Remove all entries that are not linked to project board
			for i in range(database[db_index].todos.size()):
				if database[db_index].todos[i].task_id == -1:
					database[db_index].todos.remove(i)
	
	# Load source and parse the source code
	var source = load(file_path).source_code
	var regex_findings = regex.search_all(source)
	var todos = []
	
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
		
		todos.append({"type": type, "line": line_count, "description": description, "task_id": -1})

	# Create db file entry if needed
	if db_index == -1:
		database.append({"file_path": file_path, "hash": file_hash, "todos": []})
	
	# Update existing or create todos
	for i in range(todos.size()):
		var exists = false
		if db_index != -1:
			for entry in database[db_index].todos:
				# Entry exists, update line number
				if entry.type == todos[i].type and entry.description == todos[i].description:
					entry.line = todos[i].line
					todos.remove(i)
					exists = true
					changes += 1
		if not exists:
			database[db_index].todos.append(todos[i])
			changes += 1
#	print(file_path)
#	print(file_hash)
#	print(todos)
#	print("--------------------------------")
	print(changes)
	return changes

func _db_find_index_by_file_path(path):
	var index = 0
	for entry in database:
		if path == entry.file_path:
			return index
		index += 1
	
	return -1


func _process(delta):
	$RichTextLabel.bbcode_text = str(database)

func _on_Button_button_up():
	_update_todos()


func _on_Tree_item_activated():
	print("activated")
	print($Tree.get_selected())



func _on_Tree_button_pressed(item, column, id):
	if column == TreeButtonType.JumpToSource:
		# Jump to source
		pass
	else:
		# Open assigned task or create a new one
		# TODO: implementation
		pass
	print("click" + str(item) + " " + str(column))
	
	
	
