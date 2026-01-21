import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebSocketService {
  static IO.Socket? _socket;
  static const String _serverUrl = 'https://usegiga.site'; // Production WebSocket

  static void connect(String userId) {
    _socket = IO.io(_serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'query': {'userId': userId}
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      print('WebSocket connected');
    });

    _socket!.onDisconnect((_) {
      print('WebSocket disconnected');
    });
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  // Listen to rider location updates
  static void onRiderLocationUpdate(Function(Map<String, dynamic>) callback) {
    _socket?.on('rider_location_update', (data) {
      callback(data as Map<String, dynamic>);
    });
  }

  // Listen to delivery status updates
  static void onDeliveryStatusUpdate(Function(Map<String, dynamic>) callback) {
    _socket?.on('delivery_status_update', (data) {
      callback(data as Map<String, dynamic>);
    });
  }

  // Emit rider location (for riders)
  static void emitRiderLocation(double lat, double lng) {
    _socket?.emit('update_location', {'lat': lat, 'lng': lng});
  }

  // Join delivery room
  static void joinDeliveryRoom(int deliveryId) {
    _socket?.emit('join_delivery', {'deliveryId': deliveryId});
  }

  // Leave delivery room
  static void leaveDeliveryRoom(int deliveryId) {
    _socket?.emit('leave_delivery', {'deliveryId': deliveryId});
  }
}
