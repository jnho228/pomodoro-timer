extends ColorRect

# the timer is a circle text progression that's 0 to 1000, so divide the time in seconds
# i guess by 1000 to get a smaller unit. Should make it look smooth instead of chunks at a time

export var session_color: Color
export var break_color: Color
export var default_color: Color

export var not_started_text: String
export var session_text: String
export var short_break_text: String
export var long_break_text: String

export var session_finished_sound: AudioStream
export var break_finished_sound: AudioStream

var play_texture := preload("res://right.png")
var pause_texture := preload("res://pause.png")

var is_timer_running := false

var session_time := 25
var short_break_time := 5
var long_break_time := 15

# 0 - session, 1 - short, 2 - session, 3 - short, 4 - session, 5 - short, 6 - session, 7 - long, then repeat
var current_session_tally := 0 # this will go up with each completed session/break.

var current_time := 0 # this will take from the default above and multiply by 60

var second_counter := 1.0


func _ready():
	load_settings()
	$SessionLabel.text = not_started_text
	color = default_color


func _process(delta):
	if !is_timer_running:
		return
	
	if second_counter <= 0:
		current_time -= 1
		second_counter = 1.0
	else:
		second_counter -= delta
	
	# Text Display
	var current_minutes := int(current_time / 60)
	var current_seconds := stepify(fmod(current_time, 60), 0)
	var min_text := str(current_minutes)
	var sec_text = str(current_seconds)
	
	$TextureProgress/TimerLabel.text = min_text + ":" + ("0" if current_seconds < 10 else "") + sec_text
	
	# Timer Display
	$TextureProgress.value = current_time
	
	if current_time <= 0:
		is_timer_running = false
		$PlayPauseButton.icon = play_texture
		
		if current_session_tally == 0 || current_session_tally == 2 || current_session_tally == 4 || current_session_tally == 6:
			$AudioStreamPlayer.stream = session_finished_sound
			$AudioStreamPlayer.play()
		else:
			$AudioStreamPlayer.stream = break_finished_sound
			$AudioStreamPlayer.play()
		
		current_session_tally += 1
		
		if current_session_tally > 7:
			current_session_tally = 0
		
		OS.request_attention() # Make it flash to show we're ready!


func _on_PlayPauseButton_pressed():
	is_timer_running = !is_timer_running
	$PlayPauseButton.icon = pause_texture if is_timer_running else play_texture
	
	if current_time <= 0: # change it here later !
		if current_session_tally == 0 || current_session_tally == 2 || current_session_tally == 4 || current_session_tally == 6:
			current_time = session_time * 60
			$SessionLabel.text = session_text
			color = session_color
		elif current_session_tally == 1 || current_session_tally == 3 || current_session_tally == 5:
			current_time = short_break_time * 60
			$SessionLabel.text = short_break_text
			color = break_color
		else:
			current_time = long_break_time * 60
			$SessionLabel.text = long_break_text
			color = break_color
		
		$TextureProgress.max_value = current_time
		$TextureProgress.value = current_time


func _on_StopButton_pressed():
	is_timer_running = false
	$PlayPauseButton.icon = play_texture
	
	$TextureProgress.max_value = session_time * 60
	$TextureProgress.value = session_time * 60
	
	$TextureProgress/TimerLabel.text = str(session_time) + ":00"
	
	current_session_tally = 0
	current_time = 0
	
	$SessionLabel.text = not_started_text
	color = default_color



func _on_SettingsButton_pressed():
	#$Settings.show()
	$Settings/AnimationPlayer.play("show")


func _on_ReturnButton_pressed(): 
	# will make sure the entered text is fine
	session_time = $Settings/SessionTime.value
	short_break_time = $Settings/ShortSessionTime.value
	long_break_time = $Settings/LongSessionTime.value
	
	save_settings()
	
	#$Settings.hide()
	$Settings/AnimationPlayer.play("hide")


func save_data():
	var save_dict = {
		"filename" : get_filename(),
		"parent" : get_parent().get_path(),
		"session_time" : session_time,
		"short_break_time" : short_break_time,
		"long_break_time" : long_break_time
	}
	return save_dict


func save_settings():
	var save_settings = File.new()
	save_settings.open("user://pomodoro_settings.save", File.WRITE)
	save_settings.store_line(to_json(save_data()))
	save_settings.close()


func load_settings():
	var save_settings = File.new()
	if not save_settings.file_exists("user://pomodoro_settings.save"):
		return
	
	save_settings.open("user://pomodoro_settings.save", File.READ)
	#while save_settings.get_position() < save_settings.get_len():
	
	var setting_data = parse_json(save_settings.get_line())
	session_time = setting_data["session_time"]
	short_break_time = setting_data["short_break_time"]
	long_break_time = setting_data["long_break_time"]
	
	$Settings/SessionTime.value = session_time
	$Settings/ShortSessionTime.value = short_break_time
	$Settings/LongSessionTime.value = long_break_time
	
	$TextureProgress/TimerLabel.text = str(session_time) + ":00"
	
	save_settings.close()
