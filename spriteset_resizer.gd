extends Control

var loaded_image_data = null
var loaded_image_width = 0
var loaded_image_height = 0
var loaded_image_format = null

var resized_image_data = null
var resized_image_width = 0
var resized_image_height = 0

func show_error(error_message):
	%ErrorDialog.dialog_text = error_message;
	%ErrorDialog.popup_centered()

func _on_button_pressed():
	%FileDialog.popup_centered()

func _on_file_dialog_file_selected(path):
	if !FileAccess.file_exists(path):
		show_error("Invalid File")
		return
	
	var img = Image.load_from_file(path)
	var texture = ImageTexture.create_from_image(img)
	%ImagePreview.set_texture(texture)

	resized_image_data = null
	loaded_image_data = img.get_data()
	loaded_image_width = img.get_width()
	loaded_image_height = img.get_height()
	loaded_image_format = img.get_format()
	
	update_grid()

func update_grid():
	if loaded_image_data == null:
		show_error("No image loaded")
		return
	
	var img = Image.create_from_data(loaded_image_width, loaded_image_height, false, loaded_image_format, loaded_image_data)
	
	var width = int(%LoadedGridX.value)
	var height = int(%LoadedGridY.value)
	
	var bottom_line = loaded_image_height -1 if loaded_image_height % height == 0 else -1
	var right_line = loaded_image_width -1 if loaded_image_width % width == 0 else -1
	
	for x in loaded_image_width:
		for y in loaded_image_height:
			if x % width != 0 && y % height != 0:
				if x != right_line && y != bottom_line:
					continue
			img.set_pixel(x, y, Color.BLACK)
	
	var texture = ImageTexture.create_from_image(img)
	%ImagePreview.set_texture(texture)

func _on_loaded_grid_x_value_changed(_value):
	$UpdateGridTimer.start(0)

func _on_update_grid_timer_timeout():
	if loaded_image_data != null:
		update_grid()

func _on_loaded_grid_y_value_changed(_value):
	$UpdateGridTimer.start(0)

func _on_button_2_pressed():
	resize_image()

func resize_image():
	if loaded_image_data == null:
		show_error("No image loaded")
		return
	
	var img = Image.create_from_data(loaded_image_width, loaded_image_height, false, loaded_image_format, loaded_image_data)
	
	var width = int(%LoadedGridX.value)
	var height = int(%LoadedGridY.value)
	var target_width = int(%TargetGridX.value)
	var target_height = int(%TargetGridY.value)
	var x_frames = int(loaded_image_width) / width
	var y_frames = int(loaded_image_height) / height
	resized_image_width = x_frames * target_width
	resized_image_height = y_frames * target_height
	
	var bottom_anchor = %BottomAnchor.button_pressed

	var new_img = Image.create(resized_image_width, resized_image_height, false, loaded_image_format)
	
	for x in loaded_image_width:
		if x % width != 0:
			continue
		
		var x_index = x / width
		for y in loaded_image_height:
			if y % height != 0:
				continue
			var y_index = y / height
			
			var new_x = x_index * target_width
			var new_y = y_index * target_height
			var x_offset = max(0, (target_width - width) / 2)
			var y_offset = max(0, (target_height - height))
			
			var target_x = new_x + x_offset
			var target_y = new_y + y_offset

			var origin_width = min(target_width, width)
			var origin_height = min(target_height, height)
			var origin_x = max(x, x + (width - target_width) / 2)
			var origin_y_offset = (height - target_height) / 2 if bottom_anchor else (height - target_height)
			var origin_y = max(y, y + origin_y_offset)
			var region = Rect2i(origin_x, origin_y, origin_width, origin_height)
			
			new_img.blit_rect(img, region, Vector2i(target_x, target_y))
	
	resized_image_data = new_img.get_data()
	
	var bottom_line = resized_image_height -1 if resized_image_height % target_height == 0 else -1
	var right_line = resized_image_width -1 if resized_image_width % target_width == 0 else -1
	
	for x in resized_image_width:
		for y in resized_image_height:
			if x % target_width != 0 && y % target_height != 0:
				if x != right_line && y != bottom_line:
					continue
			new_img.set_pixel(x, y, Color.BLACK)
	
	var texture = ImageTexture.create_from_image(new_img)
	%ImagePreview.set_texture(texture)


func _on_button_3_pressed():
	if resized_image_data == null:
		return
	
	%SaveDialog.popup_centered()


func _on_save_dialog_file_selected(path):
	var file_path = path if path.to_lower().ends_with(".png") else path + ".png"
	var new_img = Image.create_from_data(resized_image_width, resized_image_height, false, loaded_image_format, resized_image_data)
	var error = new_img.save_png(file_path)

	if error != OK:
		show_error("Failed to save image")
	else:
		%SuccessDialog.popup_centered()


func _on_button_4_pressed():
	$UpdateGridTimer.start(0)
