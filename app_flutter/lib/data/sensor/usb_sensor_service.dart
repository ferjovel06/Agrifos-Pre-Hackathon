import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';
import 'package:flutter_serial_communication/models/device_info.dart';

class SensorReading {
  final double nitrogen, phosphorus, potassium, ec, ph, temperature, humidity;
  SensorReading({
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.ec,
    required this.ph,
    required this.temperature,
    required this.humidity,
  });
}

class SensorDisconnectedException implements Exception {
  final String message;
  SensorDisconnectedException(this.message);
  @override
  String toString() => message;
}

class UsbSensorService {
  final _plugin = FlutterSerialCommunication();
  final _bufferedBytes = <int>[];
  StreamSubscription? _sub;
  Timer? _pollTimer;
  StreamController<SensorReading>? _controller;

  //   0x00 Humidity (0.1 %RH) · 0x01 Temperature (0.1 °C)
  //   0x02 EC (1 us/cm) · 0x03 pH (0.1 pH)
  //   0x04 Nitrogen · 0x05 Phosphorus · 0x06 Potassium (mg/kg)
  static const int _startReg = 0x0000;
  static const int _regCount = 7;

  Future<bool> connect() async {
    final devices = await _plugin.getAvailableDevices();
    if (devices.isEmpty) return false;

    final DeviceInfo device = devices.first;
    final ok = await _plugin.connect(device, 9600);
    if (!ok) return false;

    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  /// Whether a matching USB device is already plugged in right now.
  ///
  /// Used at app/provider startup, since the native attach bridge (see
  /// [usbAttachEvents]) only fires on a *new* attach/onNewIntent — it
  /// won't tell us about a sensor that was already connected before the
  /// listener was set up.
  Future<bool> hasAvailableDevice() async {
    final devices = await _plugin.getAvailableDevices();
    return devices.isNotEmpty;
  }

  static const _usbAttachChannel = MethodChannel('agrifos/usb_attach');

  /// Whether *this* app launch was triggered by Android because the
  /// sensor was just plugged in (cold start via the `USB_DEVICE_ATTACHED`
  /// intent-filter declared in AndroidManifest.xml — see MainActivity.kt).
  /// Consult once at startup; unrelated to normal app opens.
  Future<bool> consumeColdStartUsbAttach() async {
    try {
      final attached = await _usbAttachChannel.invokeMethod<bool>(
        'consumeUsbAttachIntent',
      );
      return attached ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Fires every time Android delivers a new USB-attach intent to the app
  /// while it's already running (bridged from `MainActivity.onNewIntent`).
  ///
  /// This is the real "sensor was just plugged in" signal — NOT the
  /// plugin's own `getDeviceConnectionListener()`, whose stream only
  /// echoes Dart's own `connect()`/`disconnect()` calls and never fires
  /// from an actual OS-level attach event.
  Stream<void> usbAttachEvents() {
    final controller = StreamController<void>.broadcast();
    _usbAttachChannel.setMethodCallHandler((call) async {
      if (call.method == 'usbDeviceAttached') {
        controller.add(null);
      }
    });
    return controller.stream;
  }

  /// Fires when the plugin's native layer closes the port on its own —
  /// e.g. after an I/O error from unplugging the cable while connected.
  /// Its `true` values just echo our own `connect()` calls (not a real
  /// attach signal, see [usbAttachEvents] for that), but its `false`
  /// values ARE a reliable, immediate physical-disconnect signal.
  Stream<void> nativeDisconnectEvents() {
    return _plugin
        .getDeviceConnectionListener()
        .receiveBroadcastStream()
        .where((event) => event == false)
        .map((_) {});
  }

  Stream<SensorReading> readings() {
    _bufferedBytes.clear();
    final controller = StreamController<SensorReading>();
    _controller = controller;
    final eventChannel = _plugin.getSerialMessageListener();

    _sub = eventChannel.receiveBroadcastStream().listen(
          (event) {
        final bytes = (event as List).cast<int>();
        _bufferedBytes.addAll(bytes);
        _tryParseModbusFrame(controller);
      },
      onError: (e) =>
          _handleDisconnect(controller, 'Error en el canal serial: $e'),
    );

    _sendQuery();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
          (_) => _sendQuery(),
    );
    return controller.stream;
  }

  Future<void> _sendQuery() async {
    if (_controller == null || _controller!.isClosed) return;
    final request = _buildModbusRequest(
      slaveId: 0x01,
      startReg: _startReg,
      count: _regCount,
    );
    try {
      final sent = await _plugin.write(Uint8List.fromList(request));
      if (!sent) {
        _handleDisconnect(
          _controller!,
          'Se perdió la conexión con el sensor',
        );
      }
    } catch (e) {
      _handleDisconnect(
        _controller!,
        'Se perdió la conexión con el sensor: $e',
      );
    }
  }

  void _handleDisconnect(
      StreamController<SensorReading> controller,
      String message,
      ) {
    if (controller.isClosed) return;
    _pollTimer?.cancel();
    _pollTimer = null;
    _sub?.cancel();
    if (kDebugMode) debugPrint('[sensor] desconexión detectada: $message');
    controller.addError(SensorDisconnectedException(message));
    controller.close();
  }

  List<int> _buildModbusRequest({
    required int slaveId,
    required int startReg,
    required int count,
  }) {
    final frame = [
      slaveId,
      0x03,
      startReg >> 8,
      startReg & 0xFF,
      count >> 8,
      count & 0xFF,
    ];
    final crc = _crc16(frame);
    return [...frame, crc & 0xFF, crc >> 8];
  }

  int _crc16(List<int> data) {
    int crc = 0xFFFF;
    for (final b in data) {
      crc ^= b;
      for (var i = 0; i < 8; i++) {
        crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xA001 : crc >> 1;
      }
    }
    return crc;
  }

  void _tryParseModbusFrame(StreamController<SensorReading> controller) {
    final expectedByteCount = _regCount * 2; // 14
    final expectedFrameLen = 5 + expectedByteCount; // 19

    while (_bufferedBytes.length >= 3 &&
        !(_bufferedBytes[0] == 0x01 &&
            _bufferedBytes[1] == 0x03 &&
            _bufferedBytes[2] == expectedByteCount)) {
      _bufferedBytes.removeAt(0);
    }

    if (_bufferedBytes.length < expectedFrameLen) return;

    final frame = _bufferedBytes.sublist(0, expectedFrameLen);

    final dataForCrc = frame.sublist(0, frame.length - 2);
    final crcCalc = _crc16(dataForCrc);
    final crcRecv = frame[frame.length - 2] | (frame[frame.length - 1] << 8);
    if (crcCalc != crcRecv) {
      _bufferedBytes.removeAt(0);
      _tryParseModbusFrame(controller);
      return;
    }

    _bufferedBytes.removeRange(0, expectedFrameLen);

    final regs = <int>[];
    for (var i = 3; i < frame.length - 2; i += 2) {
      regs.add((frame[i] << 8) | frame[i + 1]);
    }

    controller.add(
      SensorReading(
        humidity: regs[0] / 10.0,
        temperature: _toSigned16(regs[1]) / 10.0,
        ec: regs[2].toDouble(),
        ph: regs[3] / 10.0,
        nitrogen: regs[4].toDouble(),
        phosphorus: regs[5].toDouble(),
        potassium: regs[6].toDouble(),
      ),
    );
  }

  int _toSigned16(int value) => value >= 0x8000 ? value - 0x10000 : value;

  Future<void> dispose() async {
    _pollTimer?.cancel();
    await _sub?.cancel();
    if (_controller != null && !_controller!.isClosed) {
      await _controller!.close();
    }
    try {
      await _plugin.disconnect();
    } catch (_) {}
  }
}