extends Label

var messageField : LineEdit
var opusLobby : Control

func _ready():
	messageField = get_node("../../MessageField")
	messageField.connect("gui_input", self, "_on_field_input")

func _on_field_input(ev : InputEvent):
	if ev is InputEventKey:
		if ev.get_scancode() == KEY_ENTER and ev.pressed:
			send_message()

func get_time_string():
	var timeDict = OS.get_time()
	var hour = timeDict.hour
	var minute = timeDict.minute
	var second = timeDict.second
	return "[%02d:%02d:%02d]" % [hour, minute, second]

remote func receive_message(_id, nickname, message):
	self.text += "%s%s: %s\n" % [get_time_string(), nickname, message]

func send_message():
	var nickname = Network.nickname
	var message = messageField.text
	opusLobby.send_to_logger("%s%s: %s\n" % [get_time_string(), nickname, message])
	messageField.text = ''
	rpc("receive_message", get_tree().get_network_unique_id(), nickname, message)

