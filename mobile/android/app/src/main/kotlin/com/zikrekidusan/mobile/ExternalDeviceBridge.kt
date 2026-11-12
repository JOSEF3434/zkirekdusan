package com.zikrekidusan.mobile

import android.Manifest
import android.annotation.SuppressLint
import android.app.PendingIntent
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.graphics.SurfaceTexture
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

/**
 * Native Android bridge for external camera, USB/UVC capture, audio input,
 * Bluetooth/BLE telemetry/control, and Wi-Fi multicast lock management.
 */
class ExternalDeviceBridge(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        const val METHOD_CHANNEL = "com.zkirekdusan/external_devices"
        const val EVENT_CHANNEL = "com.zkirekdusan/external_devices_events"
        private const val ACTION_USB_PERMISSION = "com.zikrekidusan.mobile.USB_PERMISSION"

        private val BATTERY_SERVICE_UUID = UUID.fromString("0000180f-0000-1000-8000-00805f9b34fb")
        private val BATTERY_LEVEL_CHAR_UUID = UUID.fromString("00002a19-0000-1000-8000-00805f9b34fb")
        private val DEVICE_INFO_SERVICE_UUID = UUID.fromString("0000180a-0000-1000-8000-00805f9b34fb")
        private val MANUFACTURER_CHAR_UUID = UUID.fromString("00002a29-0000-1000-8000-00805f9b34fb")
        private val MODEL_CHAR_UUID = UUID.fromString("00002a24-0000-1000-8000-00805f9b34fb")
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null

    private var usbReceiver: BroadcastReceiver? = null
    private var pendingUsbPermissionResult: MethodChannel.Result? = null
    private var pendingUsbDeviceName: String? = null

    private var multicastLock: WifiManager.MulticastLock? = null

    // BLE scanning & GATT connections
    private var bleScanner: BluetoothLeScanner? = null
    private var bleScanCallback: ScanCallback? = null
    private var bleScanStopRunnable: Runnable? = null
    private val gattConnections = mutableMapOf<String, BluetoothGatt>()
    private val bleStatusCache = mutableMapOf<String, MutableMap<String, Any?>>()
    private val pendingBleConnectResults = mutableMapOf<String, MethodChannel.Result>()

    fun register(flutterEngine: FlutterEngine) {
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
        methodChannel?.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
        eventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })

        registerHardwareReceivers()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getPlatformCapabilities" -> result.success(getPlatformCapabilities())
            "enumerateUsbDevices" -> result.success(enumerateUsbDevices())
            "requestUsbPermission" -> {
                val deviceName = call.argument<String>("deviceName")
                if (deviceName.isNullOrBlank()) {
                    result.error("INVALID_ARGS", "deviceName is required", null)
                } else {
                    requestUsbPermission(deviceName, result)
                }
            }
            "enumerateExternalCameras" -> result.success(enumerateExternalCameras())
            "enumerateAudioInputs" -> result.success(enumerateAudioInputs())
            "getBondedBluetoothDevices" -> handleGetBondedBluetooth(result)
            "startBleScan" -> {
                val timeoutMs = call.argument<Int>("timeoutMs") ?: 8000
                startBleScan(timeoutMs, result)
            }
            "stopBleScan" -> {
                stopBleScan()
                result.success(true)
            }
            "connectBleDevice" -> {
                val address = call.argument<String>("address")
                if (address.isNullOrBlank()) {
                    result.error("INVALID_ARGS", "address is required", null)
                } else {
                    connectBleDevice(address, result)
                }
            }
            "disconnectBleDevice" -> {
                val address = call.argument<String>("address")
                if (address != null) disconnectBleDevice(address)
                result.success(true)
            }
            "readBleDeviceStatus" -> {
                val address = call.argument<String>("address")
                if (address.isNullOrBlank()) {
                    result.error("INVALID_ARGS", "address is required", null)
                } else {
                    result.success(bleStatusCache[address] ?: mapOf("connected" to gattConnections.containsKey(address)))
                }
            }
            "triggerBleRemoteCommand" -> {
                result.error(
                    "UNSUPPORTED",
                    "Connected Bluetooth device does not expose a supported standard camera recording GATT characteristic.",
                    null
                )
            }
            "acquireMulticastLock" -> result.success(acquireMulticastLock())
            "releaseMulticastLock" -> {
                releaseMulticastLock()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun getPlatformCapabilities(): Map<String, Any> {
        val pm = context.packageManager
        val btManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        val btAdapter = btManager?.adapter
        return mapOf(
            "platform" to "android",
            "sdkInt" to Build.VERSION.SDK_INT,
            "usbHostSupported" to pm.hasSystemFeature(PackageManager.FEATURE_USB_HOST),
            "externalCamera2Supported" to (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M),
            "bluetoothSupported" to (btAdapter != null),
            "bluetoothEnabled" to (btAdapter?.isEnabled == true),
            "bleSupported" to pm.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE),
            "wifiMulticastSupported" to true,
            "screenCaptureSupported" to true,
        )
    }

    // ─── USB / UVC / HDMI / SDI Capture Enumeration ───────────────────────────

    private fun enumerateUsbDevices(): List<Map<String, Any?>> {
        val usbManager = context.getSystemService(Context.USB_SERVICE) as? UsbManager ?: return emptyList()
        val list = mutableListOf<Map<String, Any?>>()

        for (device in usbManager.deviceList.values) {
            list.add(serializeUsbDevice(usbManager, device))
        }
        return list
    }

    private fun serializeUsbDevice(usbManager: UsbManager, device: UsbDevice): Map<String, Any?> {
        var hasVideoClass = device.deviceClass == UsbConstants.USB_CLASS_VIDEO
        var hasAudioClass = device.deviceClass == UsbConstants.USB_CLASS_AUDIO
        var hasStillImageClass = device.deviceClass == UsbConstants.USB_CLASS_STILL_IMAGE
        var hasMassStorageClass = device.deviceClass == UsbConstants.USB_CLASS_MASS_STORAGE

        for (i in 0 until device.interfaceCount) {
            val iface = device.getInterface(i)
            when (iface.interfaceClass) {
                UsbConstants.USB_CLASS_VIDEO -> hasVideoClass = true
                UsbConstants.USB_CLASS_AUDIO -> hasAudioClass = true
                UsbConstants.USB_CLASS_STILL_IMAGE -> hasStillImageClass = true
                UsbConstants.USB_CLASS_MASS_STORAGE -> hasMassStorageClass = true
            }
        }

        val product = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            device.productName ?: ""
        } else ""
        val manufacturer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            device.manufacturerName ?: ""
        } else ""
        val combinedName = "$manufacturer $product".trim().ifEmpty { "USB Device ${device.vendorId}:${device.productId}" }
        val lowerName = combinedName.lowercase()

        val classification: String
        val nonUvcReason: String?

        if (hasVideoClass) {
            classification = when {
                lowerName.contains("sdi") || lowerName.contains("blackmagic") || lowerName.contains("magewell") && lowerName.contains("sdi") ->
                    "sdiCapture"
                lowerName.contains("hdmi") || lowerName.contains("cam link") || lowerName.contains("elgato") ||
                    lowerName.contains("avermedia") || lowerName.contains("capture") || lowerName.contains("macrosilicon") ||
                    lowerName.contains("ms210") || lowerName.contains("ms213") ->
                    "hdmiCapture"
                else -> "uvcCamera"
            }
            nonUvcReason = null
        } else if (hasAudioClass) {
            classification = "usbAudio"
            nonUvcReason = "USB Audio interface detected (no UVC video capture interface)."
        } else if (hasStillImageClass || hasMassStorageClass) {
            classification = "nonUvcCamera"
            nonUvcReason = "Connected over USB in PTP/MTP or Storage mode without UVC video output. " +
                "Enable USB Webcam/UVC mode on the camera or connect its HDMI/SDI output through a USB UVC capture card."
        } else {
            classification = "unsupportedUsb"
            nonUvcReason = "USB device class ${device.deviceClass} does not expose standard UVC video output."
        }

        return mapOf(
            "deviceName" to device.deviceName,
            "deviceId" to device.deviceId,
            "vendorId" to device.vendorId,
            "productId" to device.productId,
            "productName" to product.ifEmpty { null },
            "manufacturerName" to manufacturer.ifEmpty { null },
            "displayName" to combinedName,
            "hasPermission" to usbManager.hasPermission(device),
            "isUvc" to hasVideoClass,
            "hasAudio" to hasAudioClass,
            "classification" to classification,
            "nonUvcReason" to nonUvcReason,
        )
    }

    private fun requestUsbPermission(deviceName: String, result: MethodChannel.Result) {
        val usbManager = context.getSystemService(Context.USB_SERVICE) as? UsbManager
        if (usbManager == null) {
            result.success(false)
            return
        }
        val device = usbManager.deviceList.values.firstOrNull { it.deviceName == deviceName }
        if (device == null) {
            result.error("NOT_FOUND", "USB device not found: $deviceName", null)
            return
        }
        if (usbManager.hasPermission(device)) {
            result.success(true)
            return
        }
        if (pendingUsbPermissionResult != null) {
            result.error("BUSY", "Another USB permission request is in progress", null)
            return
        }

        pendingUsbPermissionResult = result
        pendingUsbDeviceName = deviceName

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val intent = Intent(ACTION_USB_PERMISSION).setPackage(context.packageName)
        val pi = PendingIntent.getBroadcast(context, 0, intent, flags)
        usbManager.requestPermission(device, pi)
    }

    // ─── Camera2 External & Built-in Enumeration ─────────────────────────────

    private fun enumerateExternalCameras(): List<Map<String, Any?>> {
        val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as? CameraManager ?: return emptyList()
        val results = mutableListOf<Map<String, Any?>>()

        for (cameraId in cameraManager.cameraIdList) {
            try {
                val chars = cameraManager.getCameraCharacteristics(cameraId)
                val facing = chars.get(CameraCharacteristics.LENS_FACING)
                val facingLabel = when (facing) {
                    CameraCharacteristics.LENS_FACING_FRONT -> "front"
                    CameraCharacteristics.LENS_FACING_BACK -> "back"
                    CameraCharacteristics.LENS_FACING_EXTERNAL -> "external"
                    else -> "unknown"
                }

                val map = chars.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP)
                val sizes = map?.getOutputSizes(SurfaceTexture::class.java)
                    ?.sortedByDescending { it.width * it.height }
                    ?.take(6)
                    ?.map { "${it.width}x${it.height}" }
                    ?: emptyList()

                val fpsRanges = chars.get(CameraCharacteristics.CONTROL_AE_AVAILABLE_TARGET_FPS_RANGES)
                    ?.map { it.upper }
                    ?.distinct()
                    ?.sorted()
                    ?: emptyList()

                results.add(
                    mapOf(
                        "cameraId" to cameraId,
                        "facing" to facingLabel,
                        "isExternal" to (facing == CameraCharacteristics.LENS_FACING_EXTERNAL),
                        "resolutions" to sizes,
                        "supportedFps" to fpsRanges,
                    )
                )
            } catch (_: Exception) {
                // Skip camera IDs that fail characteristic inspection
            }
        }
        return results
    }

    // ─── Audio Input Enumeration ──────────────────────────────────────────────

    private fun enumerateAudioInputs(): List<Map<String, Any?>> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return emptyList()
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return emptyList()
        val devices = audioManager.getDevices(AudioManager.GET_DEVICES_INPUTS)
        return devices.map { d ->
            val kind = when (d.type) {
                AudioDeviceInfo.TYPE_USB_DEVICE,
                AudioDeviceInfo.TYPE_USB_HEADSET,
                AudioDeviceInfo.TYPE_USB_ACCESSORY -> "usb"
                AudioDeviceInfo.TYPE_BLUETOOTH_SCO,
                AudioDeviceInfo.TYPE_BLUETOOTH_A2DP -> "bluetooth"
                AudioDeviceInfo.TYPE_WIRED_HEADSET,
                AudioDeviceInfo.TYPE_LINE_ANALOG,
                AudioDeviceInfo.TYPE_LINE_DIGITAL -> "wired"
                AudioDeviceInfo.TYPE_BUILTIN_MIC -> "builtin"
                else -> "other"
            }
            mapOf(
                "id" to d.id.toString(),
                "name" to (d.productName?.toString()?.takeIf { it.isNotBlank() } ?: "Audio Input (${kind.uppercase()})"),
                "kind" to kind,
                "sampleRates" to d.sampleRates.toList(),
                "channelCounts" to d.channelCounts.toList(),
            )
        }
    }

    // ─── Bluetooth & BLE Control / Telemetry ──────────────────────────────────

    private fun hasBluetoothConnectPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        return ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun hasBluetoothScanPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        return ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_SCAN) ==
            PackageManager.PERMISSION_GRANTED
    }

    @SuppressLint("MissingPermission")
    private fun handleGetBondedBluetooth(result: MethodChannel.Result) {
        if (!hasBluetoothConnectPermission()) {
            result.error("PERMISSION_DENIED", "BLUETOOTH_CONNECT permission is required.", null)
            return
        }
        val btManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        val adapter = btManager?.adapter
        if (adapter == null || !adapter.isEnabled) {
            result.success(emptyList<Map<String, Any?>>())
            return
        }
        val bonded = adapter.bondedDevices?.map { dev ->
            mapOf(
                "address" to dev.address,
                "name" to (dev.name ?: "Bluetooth Device"),
                "type" to dev.type,
                "paired" to true,
                "connected" to gattConnections.containsKey(dev.address),
            )
        } ?: emptyList()
        result.success(bonded)
    }

    @SuppressLint("MissingPermission")
    private fun startBleScan(timeoutMs: Int, result: MethodChannel.Result) {
        if (!hasBluetoothScanPermission()) {
            result.error("PERMISSION_DENIED", "BLUETOOTH_SCAN permission is required to discover Bluetooth devices.", null)
            return
        }
        val btManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        val adapter = btManager?.adapter
        if (adapter == null || !adapter.isEnabled) {
            result.error("BLUETOOTH_OFF", "Bluetooth adapter is disabled or unavailable.", null)
            return
        }
        val scanner = adapter.bluetoothLeScanner
        if (scanner == null) {
            result.error("BLE_UNAVAILABLE", "BLE scanner is unavailable on this device.", null)
            return
        }

        stopBleScan()
        bleScanner = scanner

        val callback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, scanResult: ScanResult) {
                val device = scanResult.device ?: return
                val name = if (hasBluetoothConnectPermission()) {
                    device.name ?: scanResult.scanRecord?.deviceName
                } else {
                    scanResult.scanRecord?.deviceName
                }
                if (name.isNullOrBlank()) return

                emitEvent(
                    mapOf(
                        "event" to "ble_discovered",
                        "address" to device.address,
                        "name" to name,
                        "rssi" to scanResult.rssi,
                    )
                )
            }
        }
        bleScanCallback = callback
        try {
            scanner.startScan(callback)
            val stopRunnable = Runnable { stopBleScan() }
            bleScanStopRunnable = stopRunnable
            mainHandler.postDelayed(stopRunnable, timeoutMs.coerceIn(1500, 20000).toLong())
            result.success(true)
        } catch (e: SecurityException) {
            result.error("PERMISSION_DENIED", e.message, null)
        } catch (e: Exception) {
            result.error("BLE_SCAN_ERROR", e.message, null)
        }
    }

    @SuppressLint("MissingPermission")
    private fun stopBleScan() {
        bleScanStopRunnable?.let { mainHandler.removeCallbacks(it) }
        bleScanStopRunnable = null
        val cb = bleScanCallback
        val scanner = bleScanner
        bleScanCallback = null
        if (cb != null && scanner != null) {
            try {
                scanner.stopScan(cb)
            } catch (_: Exception) {}
        }
    }

    @SuppressLint("MissingPermission")
    private fun connectBleDevice(address: String, result: MethodChannel.Result) {
        if (!hasBluetoothConnectPermission()) {
            result.error("PERMISSION_DENIED", "BLUETOOTH_CONNECT permission is required.", null)
            return
        }
        val btManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        val adapter = btManager?.adapter
        val device = try {
            adapter?.getRemoteDevice(address)
        } catch (_: IllegalArgumentException) {
            null
        }
        if (device == null) {
            result.error("NOT_FOUND", "Bluetooth device not found: $address", null)
            return
        }

        // Disconnect stale connection if any
        disconnectBleDevice(address)
        pendingBleConnectResults[address] = result

        val gattCallback = object : BluetoothGattCallback() {
            override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
                if (newState == BluetoothProfile.STATE_CONNECTED && status == BluetoothGatt.GATT_SUCCESS) {
                    bleStatusCache[address] = mutableMapOf(
                        "connected" to true,
                        "batteryLevel" to null,
                        "manufacturer" to null,
                        "model" to null,
                        "supportsRemoteRecording" to false,
                    )
                    gatt.discoverServices()
                } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                    gattConnections.remove(address)
                    gatt.close()
                    bleStatusCache[address]?.set("connected", false)
                    emitEvent(mapOf("event" to "ble_disconnected", "address" to address))
                    val pending = pendingBleConnectResults.remove(address)
                    if (pending != null) {
                        mainHandler.post {
                            pending.error("BLE_CONNECT_FAILED", "Failed to connect to BLE device (status=$status)", null)
                        }
                    }
                }
            }

            override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
                val batteryChar = gatt.getService(BATTERY_SERVICE_UUID)?.getCharacteristic(BATTERY_LEVEL_CHAR_UUID)
                if (batteryChar != null) {
                    gatt.readCharacteristic(batteryChar)
                } else {
                    readNextDeviceInfoOrFinish(gatt, address)
                }
            }

            @Deprecated("Deprecated in Java")
            override fun onCharacteristicRead(
                gatt: BluetoothGatt,
                characteristic: BluetoothGattCharacteristic,
                status: Int,
            ) {
                if (status == BluetoothGatt.GATT_SUCCESS) {
                    @Suppress("DEPRECATION")
                    val bytes = characteristic.value ?: ByteArray(0)
                    when (characteristic.uuid) {
                        BATTERY_LEVEL_CHAR_UUID -> {
                            if (bytes.isNotEmpty()) {
                                val pct = bytes[0].toInt() and 0xFF
                                bleStatusCache[address]?.set("batteryLevel", pct)
                            }
                            readNextDeviceInfoOrFinish(gatt, address)
                            return
                        }
                        MANUFACTURER_CHAR_UUID -> {
                            bleStatusCache[address]?.set("manufacturer", String(bytes))
                        }
                        MODEL_CHAR_UUID -> {
                            bleStatusCache[address]?.set("model", String(bytes))
                        }
                    }
                }
                finishBleConnect(address)
            }
        }

        val gatt = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            device.connectGatt(context, false, gattCallback, BluetoothDevice.TRANSPORT_LE)
        } else {
            @Suppress("DEPRECATION")
            device.connectGatt(context, false, gattCallback)
        }
        if (gatt == null) {
            pendingBleConnectResults.remove(address)
            result.error("BLE_CONNECT_FAILED", "connectGatt returned null", null)
            return
        }
        gattConnections[address] = gatt

        mainHandler.postDelayed({
            if (pendingBleConnectResults.containsKey(address)) {
                finishBleConnect(address)
            }
        }, 6000)
    }

    @SuppressLint("MissingPermission")
    private fun readNextDeviceInfoOrFinish(gatt: BluetoothGatt, address: String) {
        val modelChar = gatt.getService(DEVICE_INFO_SERVICE_UUID)?.getCharacteristic(MODEL_CHAR_UUID)
        if (modelChar != null && bleStatusCache[address]?.get("model") == null) {
            gatt.readCharacteristic(modelChar)
        } else {
            finishBleConnect(address)
        }
    }

    private fun finishBleConnect(address: String) {
        val pending = pendingBleConnectResults.remove(address) ?: return
        val statusMap = bleStatusCache[address] ?: mapOf("connected" to true)
        mainHandler.post {
            pending.success(statusMap)
        }
        emitEvent(mapOf("event" to "ble_status", "address" to address, "status" to statusMap))
    }

    @SuppressLint("MissingPermission")
    private fun disconnectBleDevice(address: String) {
        pendingBleConnectResults.remove(address)
        val gatt = gattConnections.remove(address) ?: return
        try {
            gatt.disconnect()
            gatt.close()
        } catch (_: Exception) {}
    }

    // ─── Wi-Fi Multicast Lock (SSDP / DLNA) ───────────────────────────────────

    private fun acquireMulticastLock(): Boolean {
        return try {
            if (multicastLock == null) {
                val wifi = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
                multicastLock = wifi?.createMulticastLock("zikrekidusan_ssdp")?.apply {
                    setReferenceCounted(false)
                }
            }
            if (multicastLock?.isHeld == false) {
                multicastLock?.acquire()
            }
            multicastLock?.isHeld == true
        } catch (_: Exception) {
            false
        }
    }

    private fun releaseMulticastLock() {
        try {
            if (multicastLock?.isHeld == true) {
                multicastLock?.release()
            }
        } catch (_: Exception) {}
    }

    // ─── Hardware Hotplug Receivers ───────────────────────────────────────────

    private fun registerHardwareReceivers() {
        if (usbReceiver != null) return
        usbReceiver = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context?, intent: Intent?) {
                when (intent?.action) {
                    ACTION_USB_PERMISSION -> {
                        val granted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
                        val pending = pendingUsbPermissionResult
                        pendingUsbPermissionResult = null
                        pendingUsbDeviceName = null
                        pending?.success(granted)
                    }
                    UsbManager.ACTION_USB_DEVICE_ATTACHED -> {
                        emitEvent(mapOf("event" to "usb_attached"))
                    }
                    UsbManager.ACTION_USB_DEVICE_DETACHED -> {
                        emitEvent(mapOf("event" to "usb_detached"))
                    }
                    BluetoothDevice.ACTION_ACL_CONNECTED -> {
                        emitEvent(mapOf("event" to "bluetooth_acl_connected"))
                    }
                    BluetoothDevice.ACTION_ACL_DISCONNECTED -> {
                        emitEvent(mapOf("event" to "bluetooth_acl_disconnected"))
                    }
                }
            }
        }
        val filter = IntentFilter().apply {
            addAction(ACTION_USB_PERMISSION)
            addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED)
            addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)
            addAction(BluetoothDevice.ACTION_ACL_CONNECTED)
            addAction(BluetoothDevice.ACTION_ACL_DISCONNECTED)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(usbReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(usbReceiver, filter)
        }
    }

    private fun emitEvent(payload: Map<String, Any?>) {
        mainHandler.post {
            eventSink?.success(payload)
        }
    }

    fun dispose() {
        stopBleScan()
        releaseMulticastLock()
        for (addr in gattConnections.keys.toList()) {
            disconnectBleDevice(addr)
        }
        usbReceiver?.let {
            try {
                context.unregisterReceiver(it)
            } catch (_: Exception) {}
            usbReceiver = null
        }
    }
}
