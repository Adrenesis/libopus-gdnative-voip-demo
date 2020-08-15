extends ScrollContainer


var AudioBusDisplay = preload("res://addons/adrenesis.opusLobby/scenes/EditorAudioBusMini.tscn")

func read_audioserver_buses(reset = true):
	if reset:
		for child in $VBoxContainer.get_children():
			$VBoxContainer.remove_child(child)
			child.queue_free()
		print("reseted")
	for i in range(0, AudioServer.get_bus_count()):
		var audioBusDisplayer = AudioBusDisplay.instance()
		
		audioBusDisplayer.busId = i
		$VBoxContainer.add_child(audioBusDisplayer)
		audioBusDisplayer.inputNode = get_parent().input
		audioBusDisplayer.find_node("NameField").text = AudioServer.get_bus_name(i)
