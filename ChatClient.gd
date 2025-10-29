extends Control

@onready var chat_log = $ChatLog
@onready var msg_input = $MessageInput
@onready var send_btn = $SendButton

var client := WebSocketPeer.new()

func _ready():
	send_btn.pressed.connect(_on_send_pressed)
	connect_to_server("ws://127.0.0.1:9080")

func connect_to_server(url: String):
	var err = client.connect_to_url(url)
	if err != OK:
		chat_log.text += "❌ Connection failed.\n"
		return
	chat_log.text += "🔗 Connecting to server...\n"
	set_process(true)

func _process(_delta):
	client.poll()

	match client.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			while client.get_available_packet_count() > 0:
				var msg = client.get_packet().get_string_from_utf8()
				chat_log.text += "💬 " + msg + "\n"

		WebSocketPeer.STATE_CLOSED:
			chat_log.text += "🔴 Disconnected from server.\n"
			set_process(false)

func _on_send_pressed():
	var msg = msg_input.text.strip_edges()
	if msg == "":
		return
	if client.get_ready_state() == WebSocketPeer.STATE_OPEN:
		client.send_text(msg)
		chat_log.text += "🫵 You: " + msg + "\n"
		msg_input.clear()
	else:
		chat_log.text += "⚠️ Not connected.\n"
