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
signal nickname_changed
signal players_name_updated
signal audio_buses_changed

const OpusLobby = preload("res://addons/adrenesis.opusLobby/scenes/OpusLobby.tscn")
var serverPort : int = 3000 
var maxPlayers : int = 20 
var serverIp : String = "127.0.0.1" 
var nickname : String = "Player"
var lastId : int 

onready var output : AudioStreamPlayer
var player_list = []
var players_nickname = Dictionary()
var player_stream = Dictionary()

var peer : NetworkedMultiplayerENet = null

func _ready():
	rpc_config("finish_link", 1)
	get_tree().connect("network_peer_connected", self, "_player_connecting")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnecting")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	get_tree().connect("connection_failed", self, "_connected_fail")
	add_child(OpusLobby.instance())
	output = get_node('OpusLobby/Output')
	

func start_client():
	peer = NetworkedMultiplayerENet.new()
	var err = peer.create_client(serverIp, serverPort)
	if err != OK:
		emit_signal("client_failed")
		return
	get_tree().set_network_peer(peer)
	lastId = get_tree().get_network_unique_id()
	emit_signal("client_started")

func stop_client():
	remove_players()
	peer.close_connection()
	emit_signal("client_stopped")

func _connected_ok():
	emit_signal("connected_successfully")

func _connected_fail():
	remove_players()
	emit_signal("connection_failed")

func _server_disconnected():
	remove_players()
	emit_signal("server_disconnected")

################################
#SERVER
################################

func stop_server():
	remove_players()
	peer.close_connection()
	players_nickname.erase(1)
	emit_signal("server_stopped")

func start_server():
	player_list.push_back(1)
	players_nickname[1] = nickname

	peer = NetworkedMultiplayerENet.new()
	var err = peer.create_server(serverPort, maxPlayers)
	if err != OK:
		emit_signal("server_failed")
		return
	get_tree().set_network_peer(peer)
	lastId = get_tree().get_network_unique_id()
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

func get_net_id():
	return get_tree().get_network_unique_id()

func is_server(_id = null):
	if _id:
		return _id == 1
	else:
		return get_net_id() == 1

func is_this_instance(_id):
	return _id == get_net_id()

func check_and_reformulate_nickname(_originalNickname, _nickname, i = 0):
	if players_nickname.values().find(_nickname) != -1:
		print("orginalNickname: " + _originalNickname)
		print(_nickname)
		return check_and_reformulate_nickname(_originalNickname, _originalNickname +" (" + str(i) + ")", i+1)
	else:
		return _nickname

remote func reset_names(_players_nickname):
	players_nickname = _players_nickname
	print("name updating signal emitting...")
	emit_signal("players_name_updated")

remote func set_players(_player_list, _players_nickname):
	players_nickname = _players_nickname
	for player in _player_list:
		print("updating players")
		_add_player(player, false)

remote func _add_player(_id, confirm = true):
	if player_list.find(_id) == -1:
		player_list.push_back(_id)
		print("adding" + str(_id))
		if _id != get_tree().get_network_unique_id() and confirm:
			print("calling nickname of " + str(_id))
			rpc_id(_id, "call_for_nickname", get_tree().get_network_unique_id())
		if not confirm:
			confirm_connection(_id, players_nickname[_id])

remote func call_for_nickname(caller_id):
	_add_player(1)
	print("answering nickname")
#	print("my nickname is called" + str(get_tree().get_network_unique_id()))
	print("my id: " + str(get_tree().get_network_unique_id()))
#	if(get_tree().get_network_unique_id() == 1):
#		print("my id: " + str(get_tree().get_network_unique_id()))
#		confirm_nickname(get_tree().get_network_unique_id(), nickname)
#	else:
	rpc_id(caller_id, "answer_nickname", get_net_id(), nickname)

remote func answer_nickname(_id, _nickname):
	if not is_server(_id) and is_server():
		_nickname = check_and_reformulate_nickname(_nickname, _nickname)
		print(_nickname)
		print(_id)
		rpc_id(_id, "confirm_nickname", _id, _nickname, get_net_id())
		players_nickname[_id] = _nickname
	else:
		players_nickname[_id] = _nickname
		confirm_connection(_id, _nickname)

remote func confirm_nickname(_id, _nickname, _caller_id):
	print("nickname confirmed of " + str(_id) + ": " + _nickname)
	nickname = _nickname
	emit_signal("nickname_changed", nickname)
	rpc_id(_caller_id, "confirm_connection", _id, _nickname)

remote func confirm_connection(_id, _nickname):
	emit_signal("player_connected", _id, _nickname)
	print("confirming connection")
	if is_server():
		print("as server")
		rpc("reset_names", players_nickname)
	players_nickname[_id] = _nickname
	_create_audio_bus_and_stream_player("Player" + str(_id))

func _player_connecting(_id):
#	emit_signal("player_connected", _id, "000000")
#	player_list.push_back(_id)
	
#	_create_audio_bus_and_stream_player("Player" + str(_id))
	if is_server():
		rpc("_add_player", _id)
		_add_player(_id)
#		rpc_id(_id, "_add_player", 1)
		rpc_id(_id, "set_players", player_list, players_nickname)
#	for player in player_list:
#		rpc("_add_player", player)
	

func _destroy_bus_and_audio_stream_player(name : String):
#	print("destroying " + name)
	AudioServer.remove_bus(AudioServer.get_bus_index(name))
	var audioStreamPlayer = player_stream[name]
	audioStreamPlayer.queue_free()
	player_stream[name] = null
	emit_signal("audio_buses_changed")

puppet func _remove_player(_id, source_id):
#	print(_id)
	if _id != source_id:
		emit_signal("player_disconnected", _id, players_nickname[_id])
		_destroy_bus_and_audio_stream_player("Player" + str(_id))
		player_list.remove((player_list.find(_id)))
		players_nickname.erase(_id)
#		players_nickname.erase(_id)

func remove_players():
	print(player_list)
	for player_index in range(player_list.size()):
		var player = player_list[player_index]
		if player != lastId:
			emit_signal("player_disconnected", player, players_nickname[player])
			_destroy_bus_and_audio_stream_player("Player" + str(player))
#		player_list.remove(player_index)
#		print("removed player" + str(player) + " at index " + str(player_index))
	player_list = []
	players_nickname = Dictionary()
		

func _player_disconnecting(_id):
	emit_signal("player_disconnected", _id, players_nickname[_id])
#	player_list.remove((player_list.find(_id)))
#	_destroy_bus_and_audio_stream_player("Player" + str(_id))
	if is_server():
		_remove_player(_id, get_tree().get_network_unique_id())
		rpc("_remove_player", _id, get_tree().get_network_unique_id())
