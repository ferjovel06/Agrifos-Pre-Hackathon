import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/api/api_client.dart';
import '../../data/api/readings_repository.dart';
import '../../data/sensor/usb_sensor_service.dart';
import '../../domain/entities/sensor_diagnostic.dart';

enum SensorStatus { disconnected, connecting, connected, reconnecting, error }

enum SaveStatus { idle, saving, saved, error }

class SensorProvider extends ChangeNotifier {
  final _service = UsbSensorService();
  final ReadingsRepository _readingsRepository;
  SensorStatus status = SensorStatus.disconnected;
  SensorReading? lastReading;
  String? errorMessage;

  SaveStatus saveStatus = SaveStatus.idle;
  String? saveErrorMessage;
  SensorDiagnostic? savedDiagnosis;

  SensorProvider({ReadingsRepository? readingsRepository})
    : _readingsRepository = readingsRepository ?? ReadingsRepository() {
    _initAutoConnect();
  }

  static const _maxAutoRetries = 5;
  static const _retryDelay = Duration(seconds: 3);
  int _retryCount = 0;
  bool _userRequestedDisconnect = false;
  StreamSubscription<void>? _usbAttachSub;
  StreamSubscription<void>? _nativeDisconnectSub;

  /// Watches for the OTG sensor being plugged in and connects automatically,
  /// without the user having to tap "Conectar sensor".
  void _initAutoConnect() {
    // Covers two startup cases: the app was cold-started because the
    // sensor was just plugged in, or the sensor was already plugged in
    // from an earlier session.
    _service.consumeColdStartUsbAttach().then((coldStarted) async {
      if (coldStarted) {
        connectAndListen();
        return;
      }
      final available = await _service.hasAvailableDevice();
      if (available && status == SensorStatus.disconnected) {
        connectAndListen();
      }
    });

    // Covers the sensor being plugged in while the app is already running.
    _usbAttachSub = _service.usbAttachEvents().listen((_) {
      if (status == SensorStatus.disconnected || status == SensorStatus.error) {
        _userRequestedDisconnect = false;
        connectAndListen();
      }
    });

    // Covers the sensor being unplugged while connected: the native layer
    // notices the I/O error immediately, instead of waiting for the next
    // ~2s poll to fail.
    _nativeDisconnectSub = _service.nativeDisconnectEvents().listen((_) {
      if (!_userRequestedDisconnect && status != SensorStatus.disconnected) {
        _scheduleReconnect('se desconectó el sensor');
      }
    });
  }

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
        savedDiagnosis = null;
        saveStatus = SaveStatus.idle;
        saveErrorMessage = null;
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
          savedDiagnosis = null;
          saveStatus = SaveStatus.idle;
          saveErrorMessage = null;
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

  /// Sends [lastReading] to the backend for the given [parcelId].
  Future<void> saveCurrentReading(String parcelId) async {
    final reading = lastReading;
    if (reading == null || saveStatus == SaveStatus.saving) return;

    saveStatus = SaveStatus.saving;
    saveErrorMessage = null;
    notifyListeners();

    try {
      final savedReading = await _readingsRepository.submitReading(
        parcelId: parcelId,
        reading: reading,
      );
      savedDiagnosis = savedReading.diagnosis;
      saveStatus = SaveStatus.saved;
      notifyListeners();
    } on ApiAuthException catch (e) {
      saveStatus = SaveStatus.error;
      saveErrorMessage = e.message;
      notifyListeners();
    } on ApiException catch (e) {
      saveStatus = SaveStatus.error;
      saveErrorMessage = e.message;
      notifyListeners();
    } catch (e) {
      saveStatus = SaveStatus.error;
      saveErrorMessage = 'No se pudo guardar la lectura: $e';
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    _userRequestedDisconnect = true;
    await _service.dispose();
    status = SensorStatus.disconnected;
    lastReading = null;
    savedDiagnosis = null;
    errorMessage = null;
    saveStatus = SaveStatus.idle;
    saveErrorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _userRequestedDisconnect = true;
    _usbAttachSub?.cancel();
    _nativeDisconnectSub?.cancel();
    _service.dispose();
    super.dispose();
  }
}
