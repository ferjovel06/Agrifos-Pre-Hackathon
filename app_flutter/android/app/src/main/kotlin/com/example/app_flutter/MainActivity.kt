package com.example.app_flutter

import android.content.Intent
import android.hardware.usb.UsbManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The AndroidManifest declares a USB_DEVICE_ATTACHED intent-filter (see
 * device_filter.xml) so Android hands this specific sensor's attach event
 * to this Activity - either by cold-starting the app, or, since
 * launchMode is singleTop, via onNewIntent() if the app is already
 * running. This bridges that event to Dart so the app can auto-connect
 * without the user pressing "Conectar sensor".
 *
 * The flutter_serial_communication plugin does NOT do this on its own -
 * its "device connection" stream only fires as a result of Dart calling
 * connect()/disconnect() itself, never from the OS attach broadcast.
 */
class MainActivity : FlutterActivity() {
    private val usbAttachChannelName = "agrifos/usb_attach"
    private var usbAttachChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, usbAttachChannelName)
        usbAttachChannel = channel

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                // Dart calls this once at startup to check whether *this*
                // launch was triggered by the sensor being plugged in
                // (cold start via the intent-filter) rather than a normal
                // app open.
                "consumeUsbAttachIntent" -> {
                    result.success(intent?.action == UsbManager.ACTION_USB_DEVICE_ATTACHED)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.action == UsbManager.ACTION_USB_DEVICE_ATTACHED) {
            // App was already running: notify Dart immediately.
            usbAttachChannel?.invokeMethod("usbDeviceAttached", null)
        }
    }
}