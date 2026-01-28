import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:get/get.dart';

class SocketService extends GetxService {
  late IO.Socket socket;
  final _isConnected = false.obs;

  bool get isConnected => _isConnected.value;
  String? get socketId => socket.id;

  @override
  void onInit() {
    super.onInit();
    initSocket();
  }

  void initSocket() {
    // Connect to the backend EventServer (running on port 5001)
    // Adjust URL if needed (e.g., if running on a device vs emulator vs web)
    // For local dev, 127.0.0.1:5001 or localhost:5001
    socket = IO.io(
      'http://localhost:5001',
      IO.OptionBuilder()
          .setTransports(['websocket']) // for Flutter or Dart VM
          .enableAutoConnect()
          .build(),
    );

    socket.onConnect((_) {
      print('✅ Socket connected: ${socket.id}');
      _isConnected.value = true;
    });

    socket.onDisconnect((_) {
      print('❌ Socket disconnected');
      _isConnected.value = false;
    });

    socket.onError((data) {
      print('🔥 Socket error: $data');
    });
  }

  void on(String event, Function(dynamic) handler) {
    socket.on(event, handler);
  }

  void off(String event, [Function(dynamic)? handler]) {
    socket.off(event, handler);
  }

  @override
  void onClose() {
    socket.dispose();
    super.onClose();
  }
}
