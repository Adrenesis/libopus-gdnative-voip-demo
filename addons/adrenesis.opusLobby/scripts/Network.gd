extends Node

signal client_started
signal client_stopped
signal connected_successfully
signal connection_failed
signal server_disconnected
signal server_started
signal server_stopped
signal server_failed
signal player_connected
signal player_disconnected
signal client_failed
signal audio_buses_changed

const OpusLobby = preload("res://addons/adrenesis.opusLobby/scenes/OpusLobby.tscn")
var serverPort : int = 3000 
var maxPlayers : int = 20 
var serverIp : String = "127.0.0.1" 
var nickname : String = "Player" 

var output : AudioStreamPlayer
var player_list = []
var player_stream = Dictionary()

var peer : NetworkedMultiplayerENet = null

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	get_tree().connect("connection_failed", self, "_connected_fail")
	output = get_node('OpusLobby/Output')
	add_child(OpusLobby.instance())

func start_client():
	peer = NetworkedMultiplayerENet.new()
	var err = peer.create_client(serverIp, serverPort)
	if err != OK:
		emit_signal("client_failed")
		return
	get_tree().set_network_peer(peer)
	emit_signal("client_started")

func stop_client():
	peer.close_connection()
	emit_signal("client_stopped")

func _connected_ok():
	emit_signal("connected_successfully")

func _connected_fail():
	emit_signal("connection_failed")

func _server_disconnected():
	emit_signal("server_disconnected")

################################
#SERVER
################################

func stop_server():
	peer.close_connection()
	emit_signal("server_stopped")

func start_server():
	player_list.push_back(1)

	peer = NetworkedMultiplayerENet.new()
	var err = peer.create_server(serverPort, maxPlayers)
	if err != OK:
		emit_signal("server_failed")
		return
	get_tree().set_network_peer(peer)
	emit_signal("server_started")

func _create_audio_bus_and_stream_player(name : String):
	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, name)
	AudioServer.set_bus_send(AudioServer.get_bus_count() - 1, "Master")
	var audioStreamPlayer = AudioStreamPlayer.new()
	audioStreamPlayer.stream = AudioStreamSample.new()
	audioStreamPlayer.autoplay = true
	audioStreamPlayer.bus = name
	audioStreamPlayer.name = name + "Output"
	player_stream[name] = audioStreamPlayer
	output.add_child(audioStreamPlayer)
	emit_signal("audio_buses_changed")

remote func _add_player(_id):
	if player_list.find(_id) == -1:
		emit_signal("player_connected", [_id])
		player_list.push_back(_id)
		print(_id)
		if(_id != get_tree().get_network_unique_id()):
			_create_audio_bus_and_stream_player("Player" + str(_id))

func _player_connected(_id):
	emit_signal("player_connected", [_id])
	player_list.push_back(_id)
	_create_audio_bus_and_stream_player("Player" + str(_id))
	rpc("_add_player", _id)
	for player in player_list:
		rpc("_add_player", player)
	

func _destroy_bus_and_audio_stream_player(name : String):
	AudioServer.remove_bus(AudioServer.get_bus_index(name))
	var audioStreamPlayer = player_stream[name]
	audioStreamPlayer.queue_free()
	player_stream[name] = null
	emit_signal("audio_buses_changed")

remote func _remove_player(_id):
	print(_id)
	emit_signal("player_disconnected", [_id])
	_destroy_bus_and_audio_stream_player("Player" + str(_id))
	player_list.remove((player_list.find(_id)))

func _player_disconnected(_id):
	emit_signal("player_disconnected", [_id])
	player_list.remove((player_list.find(_id)))
	_destroy_bus_and_audio_stream_player("Player" + str(_id))
	rpc("_remove_player", _id)
