extends Control


var AudioBusDisplay = preload("res://scenes/EditorAudioBus.tscn")
var hboxContainer : HBoxContainer = null

func _ready():
	hboxContainer = get_node("ScrollContainer/HBoxContainer")

func read_audioserver_buses(reset = true):
	if ! hboxContainer:
		hboxContainer = get_node("ScrollContainer/HBoxContainer")
	if reset:
		for child in hboxContainer.get_children():
			hboxContainer.remove_child(child)
			child.queue_free()
		print("reseted")
	for i in range(0, AudioServer.get_bus_count()):
		var audioBusDisplayer = AudioBusDisplay.instance()
		
		audioBusDisplayer.busId = i
		hboxContainer.add_child(audioBusDisplayer)
		audioBusDisplayer.inputNode = get_parent().input
		print(get_parent().input)
		audioBusDisplayer.find_node("NameField").text = AudioServer.get_bus_name(i)
