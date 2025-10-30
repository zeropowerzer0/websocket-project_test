extends Node

# The port we will listen to.
const PORT = 2345

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

	# Iterate over all connected peers
	for peer_id in _peers.keys():
		var peer = _peers[peer_id]
		peer.poll()

		match peer.get_ready_state():
			WebSocketPeer.STATE_OPEN:
				while peer.get_available_packet_count() > 0:
					var packet = peer.get_packet()
					if peer.was_string_packet():
						var msg = packet.get_string_from_utf8()
						print("< Peer %d: %s" % [peer_id, msg])

						# Broadcast message to all connected peers
						for other_id in _peers.keys():
							var other_peer = _peers[other_id]
							if other_peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
								# Optionally skip the sender:
								if other_id != peer_id:
									other_peer.send_text("Peer %d: %s" % [peer_id, msg])
					else:
						print("< Peer %d sent binary data (%d bytes)" % [peer_id, packet.size()])
						for other_peer in _peers.values():
							if other_peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
								other_peer.send(packet)

			WebSocketPeer.STATE_CLOSED:
				_peers.erase(peer_id)
				print("- Peer %d disconnected" % peer_id)
