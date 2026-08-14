import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/sensor/usb_sensor_service.dart';

enum SensorStatus { disconnected, connecting, connected, reconnecting, error }

class SensorProvider extends ChangeNotifier {
  final _service = UsbSensorService();
  SensorStatus status = SensorStatus.disconnected;
  SensorReading? lastReading;
  String? errorMessage;

  static const _maxAutoRetries = 5;
  static const _retryDelay = Duration(seconds: 3);
  int _retryCount = 0;
  bool _userRequestedDisconnect = false;

  Future<void> connectAndListen() async {
    _userRequestedDisconnect = false;
    status = SensorStatus.connecting;
    errorMessage = null;
    notifyListeners();

    final ok = await _service.connect();
    if (!ok) {
      status = SensorStatus.error;
      errorMessage = 'No se detectó el sensor por OTG';
      notifyListeners();
      return;
    }

    _retryCount = 0;
    status = SensorStatus.connected;
    notifyListeners();

    _service.readings().listen(
      (reading) {
        lastReading = reading;
        notifyListeners();
      },
      onError: (e) {
        if (e is SensorDisconnectedException && !_userRequestedDisconnect) {
          _scheduleReconnect(e.message);
        } else {
          status = SensorStatus.error;
          errorMessage = e.toString();
          notifyListeners();
        }
      },
    );
  }

  void _scheduleReconnect(String reason) {
    if (_retryCount >= _maxAutoRetries) {
      status = SensorStatus.error;
      errorMessage =
          'Se perdió la conexión con el sensor y se agotaron los '
          'reintentos automáticos ($_maxAutoRetries). Verifica el cable OTG '
          'y toca "Conectar sensor" para intentar de nuevo.';
      notifyListeners();
      return;
    }

    _retryCount++;
    status = SensorStatus.reconnecting;
    errorMessage =
        'Conexión perdida ($reason). Reintentando '
        '($_retryCount/$_maxAutoRetries)...';
    notifyListeners();

    Timer(_retryDelay, () async {
      if (_userRequestedDisconnect) return;
      final ok = await _service.connect();
      if (!ok) {
        _scheduleReconnect('no se detectó el sensor');
        return;
      }

      status = SensorStatus.connected;
      errorMessage = null;
      notifyListeners();

      _service.readings().listen(
        (reading) {
          _retryCount = 0;
          lastReading = reading;
          notifyListeners();
        },
        onError: (e) {
          if (e is SensorDisconnectedException && !_userRequestedDisconnect) {
            _scheduleReconnect(e.message);
          } else {
            status = SensorStatus.error;
            errorMessage = e.toString();
            notifyListeners();
          }
        },
      );
    });
  }

  Future<void> disconnect() async {
    _userRequestedDisconnect = true;
    await _service.dispose();
    status = SensorStatus.disconnected;
    lastReading = null;
    errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _userRequestedDisconnect = true;
    _service.dispose();
    super.dispose();
  }
}
