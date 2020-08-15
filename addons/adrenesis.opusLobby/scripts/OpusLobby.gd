extends Node
const OpusLobbyDisplayer = preload("res://addons/adrenesis.opusLobby/scenes/OpusLobbyDisplayer.tscn")
var remove_display : bool = false
var display_removed : bool = false
var loggerLog : String = ""
var logger : Control = null
var statusNode : Control = null
var displayer : Control = null
var statusString : String
var status : int = STATUS_DISCONNECTED

enum {
	STATUS_SERVER,
	STATUS_CLIENT,
	STATUS_DISCONNECTED
}

func _process(delta):
	if remove_display and not display_removed:
		remove_child(displayer)
		display_removed = true
	if not remove_display and display_removed:
		add_child(OpusLobbyDisplayer.instance())
		display_removed = false

func send_to_logger(message):
	if logger:
		logger.text += message + "\n"
	loggerLog += message + "\n"

func update_status(message):
	if statusNode:
		statusNode.text = message
		statusString = message

func _on_client_started():
	update_status("Connecting...")
	send_to_logger("Trying to connect...")
	status = STATUS_DISCONNECTED
	displayer.buttonVoice.disabled = false

func _on_client_stopped():
	update_status("Not Started.")
	send_to_logger("Disconnected.")
	status = STATUS_DISCONNECTED
	displayer.buttonVoice.disabled = true

func _on_connected_successfully():
	send_to_logger("Connected.")
	update_status("Connected OK!")
	status = STATUS_CLIENT

func _on_connection_failed():
	send_to_logger("Failed to connect.")
	update_status("Error.")
	status = STATUS_DISCONNECTED
	if displayer:
		displayer.enable_server_settings()

func _on_server_disconnected():
	send_to_logger("Server disconnected.")
	update_status("Disconnected")
	status = STATUS_DISCONNECTED
	if displayer:
		displayer.enable_server_settings()

func _on_server_failed():
	send_to_logger("Failed to create server!")
	update_status("Error.")
	status = STATUS_DISCONNECTED
	if displayer:
		displayer.enable_server_settings()

func _on_server_started():
	send_to_logger("Server Successfully started!")
	update_status("Server started!")
	status = STATUS_SERVER
	if displayer:
		displayer.buttonVoice.disabled = false

func _on_server_stopped():
	send_to_logger("Server stopped... Every peer has been disconnected.")
	update_status("Not Started.")
	status = STATUS_DISCONNECTED
	if displayer:
		displayer.buttonVoice.disabled = true

func _on_player_connected(id, nickname):
	send_to_logger("Player %s with id %s connected" % [ nickname, id ])

func _on_player_disconnected(id, nickname):
	send_to_logger("Player %s with id %s disconnected" % [ nickname, id ])

func _on_client_failed():
	update_status("Error.")
	send_to_logger("Failed to create client!")
	status = STATUS_DISCONNECTED
	if displayer:
		displayer.enable_server_settings()

func _on_nickname_changed(nickname):
	if displayer:
		displayer.nicknameField.text = nickname

func _on_packet_sent(size):
	send_to_logger("send recording of size %s" % size)

func _on_packet_received(id):
	send_to_logger("received audio from player with id: %s" % id)
