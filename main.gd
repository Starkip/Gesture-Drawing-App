extends Node

@onready var folder_dialog: FileDialog = $FolderDialog
@onready var image_display: TextureRect = $ImageDisplayer
@onready var timer_select: OptionButton = $Controls/Timers
@onready var image_count: SpinBox = $Controls/ImageCount
@onready var timer_display: Label = $Controls/HBoxContainer/TimerDisplay
@onready var imgs_left: Label = $Controls/HBoxContainer/ImgsLeft
@onready var image_timer: Timer = $ImageTimer
@onready var start_session: Button = $Controls/StartSession
@onready var image_loader: Button = $Controls/LoadFolder
@onready var images_loaded: Label = $ImagesLoaded

var image_list: Array[ImageTexture] = []
var current_timer: float = 30.0
var session_on: bool = false
var images_left: int = 0 
var max_images: int = 0
var shuffled_list: Array[ImageTexture] = []

func _ready() -> void:
	timer_select.add_item("30s", 30)
	timer_select.add_item("60s", 60)
	timer_select.add_item("120s", 120)
	timer_select.add_item("300s", 300)
	image_display.hide()
	timer_display.hide()
	imgs_left.hide()

	var images_loaded_ok := image_list.size() > 0
	if images_loaded_ok:
		images_loaded.text = "Images are loaded"
	else:
		images_loaded.text = "Images are not loaded"


func _on_folder_dialog_dir_selected(dir: String) -> void:
	var images_check := load_images_from_folder(dir, image_count.value)
	if images_check:
		images_loaded.text = "Images are loaded"
	else:
		images_loaded.text = "Images are not loaded"
	print("Loaded ", image_list.size(), " images!")

func load_images_from_folder(path: String, max_count: int) -> bool:
	image_list.clear()
	var dir = DirAccess.open(path)
	if dir == null:
		print("Error opening folder!")
		return false
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	var loaded := 0
	while file_name != "" and loaded < max_count:
		var ext = file_name.get_extension().to_lower()
		if ext in ["png", "jpg", "jpeg", "webp"]:
			var full_path = path.path_join(file_name)
			var img = Image.load_from_file(full_path)
			if img != null:
				var tex = ImageTexture.create_from_image(img)
				image_list.append(tex)
				loaded += 1
				print("Loaded: " + file_name)
			else:
				print("Failed to load: " + full_path)
		file_name = dir.get_next()
	dir.list_dir_end()
	max_images = image_list.size()
	images_left = max_images
	shuffled_list = image_list.duplicate()
	shuffled_list.shuffle()
	print("Total loaded: ", image_list.size())
	if image_list.size() > 0:
		pick_random_image()
		return true
	else:
		return false

func pick_random_image():
	if shuffled_list.size() > 0:
		var img_tex = shuffled_list.pop_front()
		image_display.texture = img_tex
		images_left -= 1
		update_imgs_left(images_left)
	else:
		end_session()


func _on_load_folder_pressed() -> void:
	folder_dialog.popup_centered()

func update_timer_display(time_left: float):
	timer_display.text = "%.1f s /" % time_left 

func update_imgs_left(String):
	imgs_left.text = str(images_left)


func _on_start_session_pressed() -> void:

	if session_on:
		print("Session already on")
		return

	if image_list.size() == 0:
		print("load imgs first")
		return


	match timer_select.selected:
		0:
			current_timer = 30.0
		1:
			current_timer = 60.0
		2:
			current_timer = 120.0
		3:
			current_timer = 300.0
		_:
			current_timer = 30.0

	image_timer.wait_time = current_timer
	session_on = true
	timer_display.show()
	image_display.show()
	images_loaded.hide()
	imgs_left.show()
	image_timer.start()
	update_timer_display(current_timer)
	images_left = max_images
	update_imgs_left(images_left)
	print("Session started: ", current_timer, "s timer")
	start_session.hide()
	image_count.hide()
	timer_select.hide()
	image_loader.hide()

func _process(_delta: float) -> void:
	if not image_timer.is_stopped():
		update_timer_display(image_timer.time_left)
		imgs_left.text = str(images_left)

func _on_image_timer_timeout() -> void:
	if images_left > 0:
		pick_random_image()
		image_timer.start()
	else:
		end_session()

func end_session():
	session_on = false
	image_timer.stop()
	start_session.show()
	image_count.show()
	timer_select.show()
	image_loader.show()
	timer_display.hide()
	imgs_left.hide()
	image_display.hide()
	image_list.clear()
	images_loaded.show()
	images_loaded.text = "Load new Images"
