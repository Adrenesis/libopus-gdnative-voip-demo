extends Node
const OpusLobbyDisplayer = preload("res://scenes/OpusLobbyDisplayer.tscn")
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
	send_to_logger("Failed to create server0!")
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

func _on_player_connected(id):
	send_to_logger("Player with id: %s connected" % id)

func _on_player_disconnected(id):
	send_to_logger("Player with id: %s disconnected" % id)

func _on_client_failed():
	update_status("Error.")
	send_to_logger("Failed to create client!")
	status = STATUS_DISCONNECTED
	if displayer:
		displayer.enable_server_settings()

func _on_packet_sent(size):
	send_to_logger("send recording of size %s" % size)

func _on_packet_received(id):
	send_to_logger("received audio from player with id: %s" % id)
