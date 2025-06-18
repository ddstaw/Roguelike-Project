extends Button

var is_music_playing = true

func _ready():
	connect("pressed", Callable(self, "_on_MusicToggleButton_pressed"))

func _on_MusicToggleButton_pressed():
	var music_player = musicplayer.get_node("AudioStreamPlayer")  # Use the correct name of the child node
	if music_player != null and music_player is AudioStreamPlayer:
		if is_music_playing:
			music_player.stop()
		else:
			music_player.play()
		is_music_playing = !is_music_playing
	else:
		print("AudioStreamPlayer node not found!")
