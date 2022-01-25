###############################################################################
# Copyright (c) 2021 NimbleBeasts
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
###############################################################################
tool
extends EditorPlugin

###############################################################################
# Plugin Consts
###############################################################################
const PM_DIRECTORY = "res://_PM/"
const PM_TASK_DIRECTORY = "res://_PM/tasks"
const PM_PROJECT_CONFIG = "project.cfg"
const PM_USER_CONFIG = "user.cfg"
const TODO_CACHE = "cache.dat"

###############################################################################
# Scenes
###############################################################################
const Scene_TodoDock = preload("res://addons/NbPM/TodoDock.tscn")
const Scene_ProjectScreen = preload("res://addons/NbPM/ProjectScreen.tscn")

var todo_dock_instance = null
var project_screen_instance = null


###############################################################################
# Configs
###############################################################################

var config_project = {
	"user_names": [],
	"exclude_folders": ["addons"],
	"tags": ["TODO", "FIXME", "NOTE"]
}

var config_user = {
	"user_id": 0,
	"todo_database": []
}

var todo_cache = {}

func update_project_config():
	todo_dock_instance.update_project_config(config_project)

func store_todo_database(database):
	config_user.todo_database = database
	_save_config(PM_USER_CONFIG, config_user)

func jump_to_main_screen(metadata):
	if project_screen_instance:
		project_screen_instance.jump_to_main_screen(metadata)
		make_visible(true)
		get_editor_interface().set_main_screen_editor(get_plugin_name())

func _enter_tree():
	_load_configs()
	
	# Setup main screen
	project_screen_instance = Scene_ProjectScreen.instance()
	get_editor_interface().get_editor_viewport().add_child(project_screen_instance, true)
	make_visible(false)
	
	# Setup todo dock
	todo_dock_instance = Scene_TodoDock.instance()
	todo_dock_instance.setup(self, config_project, config_user.todo_database)
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR, todo_dock_instance)


func _exit_tree():
	remove_control_from_docks(todo_dock_instance)
	if project_screen_instance:
		project_screen_instance.queue_free()


func has_main_screen():
	return true


func make_visible(visible):
	if project_screen_instance:
		project_screen_instance.visible = visible


func get_plugin_name():
	return "ProjectManagement"


func get_plugin_icon():
	# Must return some kind of Texture for the icon.
	return get_editor_interface().get_base_control().get_icon("SpriteSheet", "EditorIcons")

func _load_configs():
	var dir = Directory.new()
	var cfg = File.new()
	
	# Create directories, if not exists
	if not dir.dir_exists(PM_DIRECTORY):
		dir.make_dir(PM_DIRECTORY)
	if not dir.dir_exists(PM_TASK_DIRECTORY):
		dir.make_dir(PM_TASK_DIRECTORY)
	
	# Project config
	if not cfg.file_exists(PM_DIRECTORY + PM_PROJECT_CONFIG):
		# Create project config
		_save_config(PM_PROJECT_CONFIG, config_project)
	else:
		# Load project config
		config_project = _load_config(PM_PROJECT_CONFIG)
	
	# User config
	if not cfg.file_exists(PM_DIRECTORY + PM_USER_CONFIG):
		# Create project config
		_save_config(PM_USER_CONFIG, config_user)
	else:
		# Load project config
		config_user = _load_config(PM_USER_CONFIG)

	# Add user.cfg to Git Ignore
	if not cfg.file_exists(PM_DIRECTORY + ".gitignore"):
		cfg.open(PM_DIRECTORY + ".gitignore", File.WRITE)
		cfg.store_line("/user.cfg")
		cfg.close()

func _save_config(file: String, settings: Dictionary):
	var cfg = File.new()
	cfg.open(PM_DIRECTORY + file, File.WRITE)
	cfg.store_line(JSON.print(settings, "\t"))
	cfg.close()

func _load_config(file: String):
	var cfg = File.new()
	cfg.open(PM_DIRECTORY + file, File.READ)
	var return_val = parse_json(cfg.get_as_text())
	cfg.close()
	return return_val

