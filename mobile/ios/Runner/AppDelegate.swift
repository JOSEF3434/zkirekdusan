import Flutter
import UIKit
import AVFAudio
import AVFoundation
import AVKit
import CoreBluetooth

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, CBCentralManagerDelegate, CBPeripheralDelegate, FlutterStreamHandler {
  private var pipChannel: FlutterMethodChannel?
  private var airplayChannel: FlutterMethodChannel?
  private var externalDeviceChannel: FlutterMethodChannel?
  private var externalEventChannel: FlutterEventChannel?
  private var eventSink: FlutterEventSink?

  // CoreBluetooth state
  private var centralManager: CBCentralManager?
  private var discoveredPeripherals: [String: CBPeripheral] = [:]
  private var connectedPeripherals: [String: CBPeripheral] = [:]
  private var bleStatusCache: [String: [String: Any]] = [:]
  private var pendingBleConnectResult: [String: FlutterResult] = [:]
  private var bleScanTimer: Timer?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure audio session for background playback and PiP
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers, .allowAirPlay])
      try session.setActive(true)
    } catch {
      print("[AppDelegate] AVAudioSession setup error: \(error)")
    }

    if let controller = window?.rootViewController as? FlutterViewController {
      registerChannels(messenger: controller.binaryMessenger, viewController: controller)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func registerChannels(messenger: FlutterBinaryMessenger, viewController: UIViewController?) {
    pipChannel = FlutterMethodChannel(name: "com.zikrekidusan.mobile/pip", binaryMessenger: messenger)
    pipChannel?.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "isPipSupported":
        result(AVPictureInPictureController.isPictureInPictureSupported())
      case "enableAutoPip", "disableAutoPip", "updatePlaybackState":
        result(true)
      case "enterPip":
        result(false)
      case "isInPip":
        result(false)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    airplayChannel = FlutterMethodChannel(name: "com.zkirekdusan/cast_airplay", binaryMessenger: messenger)
    airplayChannel?.setMethodCallHandler { [weak viewController] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "presentRoutePickerWithUrl":
        DispatchQueue.main.async {
          let picker = AVRoutePickerView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
          picker.prioritizesVideoDevices = true
          picker.isHidden = true
          if let rootView = viewController?.view {
            rootView.addSubview(picker)
            for sub in picker.subviews {
              if let button = sub as? UIButton {
                button.sendActions(for: .touchUpInside)
                break
              }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
              picker.removeFromSuperview()
            }
          }
          result(true)
        }
      case "stopCast":
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    externalDeviceChannel = FlutterMethodChannel(name: "com.zkirekdusan/external_devices", binaryMessenger: messenger)
    externalDeviceChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard let self = self else {
        result(FlutterError(code: "DISPOSED", message: "AppDelegate deallocated", details: nil))
        return
      }
      self.handleExternalDeviceCall(call, result: result)
    }

    externalEventChannel = FlutterEventChannel(name: "com.zkirekdusan/external_devices_events", binaryMessenger: messenger)
    externalEventChannel?.setStreamHandler(self)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // MARK: - FlutterStreamHandler

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }

  // MARK: - External Devices Bridge

  private func handleExternalDeviceCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformCapabilities":
      var externalSupported = false
      if #available(iOS 17.0, *) {
        externalSupported = true
      }
      result([
        "platform": "ios",
        "systemVersion": UIDevice.current.systemVersion,
        "usbHostSupported": externalSupported,
        "externalCamera2Supported": externalSupported,
        "bluetoothSupported": true,
        "bluetoothEnabled": (centralManager?.state == .poweredOn),
        "bleSupported": true,
        "wifiMulticastSupported": true,
        "screenCaptureSupported": true,
      ])

    case "enumerateUsbDevices":
      // iOS exposes external USB-C UVC cameras through AVCaptureDevice on iOS 17+ (not raw UsbManager).
      result(enumerateIosExternalAsUsbList())

    case "enumerateExternalCameras":
      result(enumerateCaptureDevices())

    case "enumerateAudioInputs":
      result(enumerateAudioInputs())

    case "getBondedBluetoothDevices":
      let list: [[String: Any]] = connectedPeripherals.map { (id, p) in
        [
          "address": id,
          "name": p.name ?? "Bluetooth Device",
          "paired": true,
          "connected": p.state == .connected,
        ]
      }
      result(list)

    case "startBleScan":
      let args = call.arguments as? [String: Any]
      let timeoutMs = (args?["timeoutMs"] as? Int) ?? 8000
      startBleScan(timeoutMs: timeoutMs, result: result)

    case "stopBleScan":
      stopBleScan()
      result(true)

    case "connectBleDevice":
      guard let args = call.arguments as? [String: Any],
            let address = args["address"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "address required", details: nil))
        return
      }
      connectBleDevice(address: address, result: result)

    case "disconnectBleDevice":
      if let args = call.arguments as? [String: Any],
         let address = args["address"] as? String,
         let p = connectedPeripherals.removeValue(forKey: address) {
        centralManager?.cancelPeripheralConnection(p)
      }
      result(true)

    case "readBleDeviceStatus":
      if let args = call.arguments as? [String: Any],
         let address = args["address"] as? String {
        result(bleStatusCache[address] ?? ["connected": connectedPeripherals[address]?.state == .connected])
      } else {
        result(["connected": false])
      }

    case "triggerBleRemoteCommand":
      result(FlutterError(
        code: "UNSUPPORTED",
        message: "Connected Bluetooth device does not expose a supported standard camera recording GATT characteristic.",
        details: nil
      ))

    case "acquireMulticastLock", "releaseMulticastLock":
      result(true)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func enumerateCaptureDevices() -> [[String: Any]] {
    var deviceTypes: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera]
    if #available(iOS 17.0, *) {
      deviceTypes.append(.external)
    }
    let session = AVCaptureDevice.DiscoverySession(
      deviceTypes: deviceTypes,
      mediaType: .video,
      position: .unspecified
    )
    return session.devices.map { dev in
      var isExternal = false
      if #available(iOS 17.0, *) {
        isExternal = (dev.deviceType == .external)
      }
      let facing: String
      if isExternal {
        facing = "external"
      } else if dev.position == .front {
        facing = "front"
      } else if dev.position == .back {
        facing = "back"
      } else {
        facing = "unknown"
      }

      var resolutions: [String] = []
      var fpsSet = Set<Int>()
      for fmt in dev.formats {
        let dims = CMVideoFormatDescriptionGetDimensions(fmt.formatDescription)
        let label = "\(dims.width)x\(dims.height)"
        if !resolutions.contains(label) && resolutions.count < 6 {
          resolutions.append(label)
        }
        for range in fmt.videoSupportedFrameRateRanges {
          fpsSet.insert(Int(range.maxFrameRate.rounded()))
        }
      }

      return [
        "cameraId": dev.uniqueID,
        "name": dev.localizedName,
        "facing": facing,
        "isExternal": isExternal,
        "resolutions": resolutions,
        "supportedFps": Array(fpsSet).sorted(),
      ]
    }
  }

  private func enumerateIosExternalAsUsbList() -> [[String: Any?]] {
    if #available(iOS 17.0, *) {
      let session = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.external],
        mediaType: .video,
        position: .unspecified
      )
      return session.devices.map { dev in
        let lower = dev.localizedName.lowercased()
        let classification = lower.contains("sdi")
          ? "sdiCapture"
          : (lower.contains("hdmi") || lower.contains("cam link") || lower.contains("capture")
              ? "hdmiCapture"
              : "uvcCamera")
        return [
          "deviceName": dev.uniqueID,
          "displayName": dev.localizedName,
          "hasPermission": true,
          "isUvc": true,
          "hasAudio": false,
          "classification": classification,
          "nonUvcReason": nil,
        ]
      }
    }
    return []
  }

  private func enumerateAudioInputs() -> [[String: Any]] {
    let inputs = AVAudioSession.sharedInstance().availableInputs ?? []
    return inputs.map { port in
      let kind: String
      switch port.portType {
      case .usbAudio:
        kind = "usb"
      case .bluetoothHFP, .bluetoothA2DP, .bluetoothLE:
        kind = "bluetooth"
      case .headsetMic, .lineIn:
        kind = "wired"
      case .builtInMic:
        kind = "builtin"
      default:
        kind = "other"
      }
      return [
        "id": port.uid,
        "name": port.portName,
        "kind": kind,
      ]
    }
  }

  // MARK: - CoreBluetooth

  private func ensureCentral() -> CBCentralManager {
    if let cm = centralManager { return cm }
    let cm = CBCentralManager(delegate: self, queue: nil)
    centralManager = cm
    return cm
  }

  private func startBleScan(timeoutMs: Int, result: @escaping FlutterResult) {
    let cm = ensureCentral()
    if cm.state == .unauthorized {
      result(FlutterError(code: "PERMISSION_DENIED", message: "Bluetooth permission denied in iOS Settings.", details: nil))
      return
    }
    if cm.state == .poweredOff {
      result(FlutterError(code: "BLUETOOTH_OFF", message: "Bluetooth is turned off.", details: nil))
      return
    }
    if cm.state == .poweredOn {
      cm.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
      bleScanTimer?.invalidate()
      let secs = Double(max(1500, min(20000, timeoutMs))) / 1000.0
      bleScanTimer = Timer.scheduledTimer(withTimeInterval: secs, repeats: false) { [weak self] _ in
        self?.stopBleScan()
      }
    }
    result(true)
  }

  private func stopBleScan() {
    bleScanTimer?.invalidate()
    bleScanTimer = nil
    centralManager?.stopScan()
  }

  private func connectBleDevice(address: String, result: @escaping FlutterResult) {
    guard let peripheral = discoveredPeripherals[address] else {
      result(FlutterError(code: "NOT_FOUND", message: "BLE peripheral not found: \(address)", details: nil))
      return
    }
    pendingBleConnectResult[address] = result
    peripheral.delegate = self
    ensureCentral().connect(peripheral, options: nil)
  }

  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    // State updates are queried on next capabilities/scan call.
  }

  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
    let name = peripheral.name ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String)
    guard let validName = name, !validName.isEmpty else { return }
    let id = peripheral.identifier.uuidString
    discoveredPeripherals[id] = peripheral
    eventSink?([
      "event": "ble_discovered",
      "address": id,
      "name": validName,
      "rssi": RSSI.intValue,
    ])
  }

  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    let id = peripheral.identifier.uuidString
    connectedPeripherals[id] = peripheral
    bleStatusCache[id] = [
      "connected": true,
      "supportsRemoteRecording": false,
    ]
    peripheral.discoverServices([CBUUID(string: "180F"), CBUUID(string: "180A")])
    if let res = pendingBleConnectResult.removeValue(forKey: id) {
      res(bleStatusCache[id])
    }
  }

  func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    let id = peripheral.identifier.uuidString
    if let res = pendingBleConnectResult.removeValue(forKey: id) {
      res(FlutterError(code: "BLE_CONNECT_FAILED", message: error?.localizedDescription ?? "Failed to connect", details: nil))
    }
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    guard let services = peripheral.services else { return }
    for service in services {
      peripheral.discoverCharacteristics(nil, for: service)
    }
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    guard let chars = service.characteristics else { return }
    for c in chars {
      if c.uuid == CBUUID(string: "2A19") || c.uuid == CBUUID(string: "2A24") || c.uuid == CBUUID(string: "2A29") {
        peripheral.readValue(for: c)
      }
    }
  }

  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    guard let data = characteristic.value else { return }
    let id = peripheral.identifier.uuidString
    var map = bleStatusCache[id] ?? ["connected": true]
    if characteristic.uuid == CBUUID(string: "2A19"), let first = data.first {
      map["batteryLevel"] = Int(first)
    } else if characteristic.uuid == CBUUID(string: "2A24"), let str = String(data: data, encoding: .utf8) {
      map["model"] = str
    } else if characteristic.uuid == CBUUID(string: "2A29"), let str = String(data: data, encoding: .utf8) {
      map["manufacturer"] = str
    }
    bleStatusCache[id] = map
    eventSink?(["event": "ble_status", "address": id, "status": map])
  }
}
