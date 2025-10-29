extends Node

# The port we will listen to.
const PORT = 9080

# Our TCP Server instance.
var _tcp_server = TCPServer.new()

# Our connected peers list.
var _peers: Dictionary[int, WebSocketPeer] = {}

var last_peer_id := 1


func _ready():
	# Start listening on the given port.
	var err = _tcp_server.listen(PORT)
	if err == OK:
		print("Server started.")
	else:
		push_error("Unable to start server.")
		set_process(false)


func _process(_delta):
	while _tcp_server.is_connection_available():
		last_peer_id += 1
		print("+ Peer %d connected." % last_peer_id)
		var ws = WebSocketPeer.new()
		ws.accept_stream(_tcp_server.take_connection())
		_peers[last_peer_id] = ws

	# Iterate over all connected peers using "keys()" so we can erase in the loop
	for peer_id in _peers.keys():
		var peer = _peers[peer_id]

		peer.poll()

		var peer_state = peer.get_ready_state()
		if peer_state == WebSocketPeer.STATE_OPEN:
			while peer.get_available_packet_count():
				var packet = peer.get_packet()
				if peer.was_string_packet():
					var packet_text = packet.get_string_from_utf8()
					print("< Got text data from peer %d: %s ... echoing" % [peer_id, packet_text])
					# Echo the packet back.
					peer.send_text(packet_text)
				else:
					print("< Got binary data from peer %d: %d ... echoing" % [peer_id, packet.size()])
					# Echo the packet back.
					peer.send(packet)
		elif peer_state == WebSocketPeer.STATE_CLOSED:
			# Remove the disconnected peer.
			_peers.erase(peer_id)
			var code = peer.get_close_code()
			var reason = peer.get_close_reason()
			print("- Peer %s closed with code: %d, reason %s. Clean: %s" % [peer_id, code, reason, code != -1])
