import Cocoa
import FlutterMacOS
import IOKit.pwr_mgt
import IOKit.ps

private final class CustomClockView: NSView {
  var onDateChanged: ((Date) -> Void)?
  var date = Date() {
    didSet {
      needsDisplay = true
    }
  }

  override var isFlipped: Bool {
    true
  }

  override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
    true
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    let bounds = self.bounds.insetBy(dx: 8, dy: 8)
    let diameter = min(bounds.width, bounds.height)
    let rect = NSRect(
      x: bounds.midX - diameter / 2,
      y: bounds.midY - diameter / 2,
      width: diameter,
      height: diameter
    )
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let radius = diameter / 2

    NSColor(calibratedRed: 0.78, green: 0.89, blue: 0.92, alpha: 1).setFill()
    NSBezierPath(ovalIn: rect).fill()
    NSColor(calibratedWhite: 0.97, alpha: 1).setFill()
    NSBezierPath(ovalIn: rect.insetBy(dx: 10, dy: 10)).fill()

    let numberAttributes: [NSAttributedString.Key: Any] = [
      .font: NSFont.systemFont(ofSize: 18, weight: .medium),
      .foregroundColor: NSColor.labelColor
    ]
    for number in 1...12 {
      let angle = (Double(number) / 12.0) * 2.0 * Double.pi - Double.pi / 2.0
      let text = NSString(string: "\(number)")
      let textSize = text.size(withAttributes: numberAttributes)
      let point = CGPoint(
        x: center.x + CGFloat(cos(angle)) * (radius - 27) - textSize.width / 2,
        y: center.y + CGFloat(sin(angle)) * (radius - 27) - textSize.height / 2
      )
      text.draw(at: point, withAttributes: numberAttributes)
    }

    let calendar = Calendar.current
    let hour = calendar.component(.hour, from: date) % 12
    let minute = calendar.component(.minute, from: date)
    drawHand(
      center: center,
      angle: ((Double(hour) + Double(minute) / 60.0) / 12.0) * 2.0 * Double.pi - Double.pi / 2.0,
      length: radius * 0.45,
      width: 4
    )
    drawHand(
      center: center,
      angle: (Double(minute) / 60.0) * 2.0 * Double.pi - Double.pi / 2.0,
      length: radius * 0.72,
      width: 3
    )
    NSColor.black.setFill()
    NSBezierPath(ovalIn: NSRect(x: center.x - 4, y: center.y - 4, width: 8, height: 8)).fill()
  }

  private func drawHand(center: CGPoint, angle: Double, length: CGFloat, width: CGFloat) {
    let path = NSBezierPath()
    path.lineWidth = width
    path.lineCapStyle = .round
    path.move(to: center)
    path.line(to: CGPoint(
      x: center.x + CGFloat(cos(angle)) * length,
      y: center.y + CGFloat(sin(angle)) * length
    ))
    NSColor.black.setStroke()
    path.stroke()
  }

  override func mouseDown(with event: NSEvent) {
    updateDate(from: convert(event.locationInWindow, from: nil))
  }

  override func mouseDragged(with event: NSEvent) {
    updateDate(from: convert(event.locationInWindow, from: nil))
  }

  private func updateDate(from point: CGPoint) {
    let bounds = self.bounds.insetBy(dx: 8, dy: 8)
    let center = CGPoint(x: bounds.midX, y: bounds.midY)
    let dx = point.x - center.x
    let dy = point.y - center.y
    guard hypot(dx, dy) > 12 else {
      return
    }

    let rawAngle = atan2(Double(dy), Double(dx)) + Double.pi / 2.0
    let normalizedAngle = rawAngle < 0 ? rawAngle + 2.0 * Double.pi : rawAngle
    let minute = Int((normalizedAngle / (2.0 * Double.pi) * 60.0).rounded()) % 60
    let calendar = Calendar.current
    let hour = calendar.component(.hour, from: date)
    let nextDate = calendar.date(
      bySettingHour: hour,
      minute: minute,
      second: 0,
      of: date
    ) ?? date
    date = nextDate
    onDateChanged?(nextDate)
  }
}

private enum CustomTimeInputFocus {
  case hours
  case minutes
  case untilTime
}

private final class FocusAwareTextField: NSTextField {
  var onFocus: (() -> Void)?

  override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
    true
  }

  override func becomeFirstResponder() -> Bool {
    onFocus?()
    return super.becomeFirstResponder()
  }

  override func mouseDown(with event: NSEvent) {
    onFocus?()
    super.mouseDown(with: event)
  }
}

private final class FocusAwareDatePicker: NSDatePicker {
  var onFocus: (() -> Void)?

  override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
    true
  }

  override func becomeFirstResponder() -> Bool {
    onFocus?()
    return super.becomeFirstResponder()
  }

  override func mouseDown(with event: NSEvent) {
    onFocus?()
    super.mouseDown(with: event)
  }
}

private final class CustomTimeMenuView: NSView {
  private let modeControl = NSSegmentedControl(labels: ["持续", "至"], trackingMode: .selectOne, target: nil, action: nil)
  private let hoursField = FocusAwareTextField(string: "0")
  private let minutesField = FocusAwareTextField(string: "45")
  private let hoursStepper = NSStepper()
  private let minutesStepper = NSStepper()
  private let timePicker = FocusAwareDatePicker()
  private let clockView = CustomClockView()
  private let continueButton = NSButton(title: "继续", target: nil, action: nil)
  private let separator = NSBox()
  private let focusHighlight = NSView()
  private let hoursLabel = NSTextField(labelWithString: "小时")
  private let minutesLabel = NSTextField(labelWithString: "分钟")
  private let onContinue: (Int) -> Void
  private var activeInput: CustomTimeInputFocus = .hours

  init(defaultMinutes: Int, onContinue: @escaping (Int) -> Void) {
    self.onContinue = onContinue
    super.init(frame: NSRect(x: 0, y: 0, width: 235, height: 342))
    setup(defaultMinutes: defaultMinutes)
  }

  required init?(coder: NSCoder) {
    nil
  }

  override var isFlipped: Bool {
    true
  }

  override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
    true
  }

  override func layout() {
    super.layout()
    modeControl.frame = NSRect(x: 72, y: 24, width: 92, height: 32)
    hoursField.frame = NSRect(x: 82, y: 88, width: 70, height: 32)
    hoursStepper.frame = NSRect(x: 158, y: 86, width: 20, height: 36)
    hoursLabel.frame = NSRect(x: 0, y: 126, width: bounds.width, height: 24)
    separator.frame = NSRect(x: 52, y: 162, width: bounds.width - 104, height: 1)
    minutesField.frame = NSRect(x: 82, y: 184, width: 70, height: 32)
    minutesStepper.frame = NSRect(x: 158, y: 182, width: 20, height: 36)
    minutesLabel.frame = NSRect(x: 0, y: 222, width: bounds.width, height: 24)
    timePicker.frame = NSRect(x: 52, y: 78, width: 132, height: 32)
    clockView.frame = NSRect(x: 36, y: 116, width: 164, height: 164)
    continueButton.frame = NSRect(x: 36, y: 294, width: bounds.width - 72, height: 32)
    updateFocusHighlight()
  }

  private func setup(defaultMinutes: Int) {
    wantsLayer = true
    layer?.backgroundColor = NSColor.clear.cgColor

    focusHighlight.wantsLayer = true
    focusHighlight.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.22).cgColor
    focusHighlight.layer?.borderColor = NSColor.controlAccentColor.withAlphaComponent(0.85).cgColor
    focusHighlight.layer?.borderWidth = 2
    focusHighlight.layer?.cornerRadius = 8
    addSubview(focusHighlight)

    modeControl.selectedSegment = 0
    modeControl.target = self
    modeControl.action = #selector(modeChanged)
    addSubview(modeControl)

    configureNumberField(hoursField)
    configureNumberField(minutesField)
    hoursField.onFocus = { [weak self] in
      self?.setActiveInput(.hours)
    }
    minutesField.onFocus = { [weak self] in
      self?.setActiveInput(.minutes)
    }
    hoursField.stringValue = "\(max(0, defaultMinutes / 60))"
    minutesField.stringValue = "\(max(0, defaultMinutes % 60))"
    addSubview(hoursField)
    addSubview(minutesField)

    configureStepper(hoursStepper, maxValue: 24, value: Double(max(0, defaultMinutes / 60)))
    configureStepper(minutesStepper, maxValue: 55, value: Double(max(0, defaultMinutes % 60)))
    addSubview(hoursStepper)
    addSubview(minutesStepper)

    for label in [hoursLabel, minutesLabel] {
      label.alignment = .center
      label.font = NSFont.systemFont(ofSize: 17, weight: .semibold)
      addSubview(label)
    }

    separator.boxType = .separator
    addSubview(separator)

    timePicker.datePickerStyle = .textFieldAndStepper
    timePicker.datePickerElements = .hourMinute
    timePicker.onFocus = { [weak self] in
      self?.setActiveInput(.untilTime)
    }
    timePicker.target = self
    timePicker.action = #selector(untilTimeChanged)
    timePicker.dateValue = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    clockView.date = timePicker.dateValue
    clockView.onDateChanged = { [weak self] date in
      self?.timePicker.dateValue = date
    }
    addSubview(timePicker)
    addSubview(clockView)

    continueButton.bezelStyle = .rounded
    continueButton.target = self
    continueButton.action = #selector(continuePressed)
    addSubview(continueButton)

    modeChanged()
  }

  private func configureNumberField(_ field: NSTextField) {
    field.alignment = .center
    field.font = NSFont.monospacedDigitSystemFont(ofSize: 24, weight: .regular)
    field.drawsBackground = true
    field.backgroundColor = .textBackgroundColor
    field.formatter = NumberFormatter()
    field.target = self
    field.action = #selector(fieldChanged)
  }

  private func configureStepper(_ stepper: NSStepper, maxValue: Double, value: Double) {
    stepper.minValue = 0
    stepper.maxValue = maxValue
    stepper.increment = 1
    stepper.integerValue = Int(value)
    stepper.target = self
    stepper.action = #selector(stepperChanged(_:))
  }

  @objc private func modeChanged() {
    let durationMode = modeControl.selectedSegment == 0
    for view in [hoursField, hoursStepper, hoursLabel, separator, minutesField, minutesStepper, minutesLabel] {
      view.isHidden = !durationMode
    }
    timePicker.isHidden = durationMode
    clockView.isHidden = durationMode
    setActiveInput(durationMode ? .hours : .untilTime)
  }

  @objc private func stepperChanged(_ sender: NSStepper) {
    if sender == hoursStepper {
      setActiveInput(.hours)
      hoursField.integerValue = sender.integerValue
    } else {
      setActiveInput(.minutes)
      minutesField.integerValue = sender.integerValue
    }
  }

  @objc private func fieldChanged() {
    let hours = min(max(hoursField.integerValue, 0), 24)
    let minutes = min(max(minutesField.integerValue, 0), 55)
    hoursField.integerValue = hours
    minutesField.integerValue = minutes
    hoursStepper.integerValue = hours
    minutesStepper.integerValue = minutes
  }

  @objc private func untilTimeChanged() {
    setActiveInput(.untilTime)
    clockView.date = timePicker.dateValue
  }

  private func setActiveInput(_ input: CustomTimeInputFocus) {
    activeInput = input
    hoursField.backgroundColor = input == .hours
      ? NSColor.controlAccentColor.withAlphaComponent(0.2)
      : .textBackgroundColor
    minutesField.backgroundColor = input == .minutes
      ? NSColor.controlAccentColor.withAlphaComponent(0.2)
      : .textBackgroundColor
    updateFocusHighlight()
  }

  private func updateFocusHighlight() {
    let targetFrame: NSRect
    switch activeInput {
    case .hours:
      targetFrame = hoursField.frame.insetBy(dx: -7, dy: -5)
    case .minutes:
      targetFrame = minutesField.frame.insetBy(dx: -7, dy: -5)
    case .untilTime:
      targetFrame = timePicker.frame.insetBy(dx: -7, dy: -5)
    }
    focusHighlight.frame = targetFrame
    focusHighlight.isHidden =
      (activeInput == .untilTime && timePicker.isHidden) ||
      (activeInput != .untilTime && hoursField.isHidden)
  }

  @objc private func continuePressed() {
    fieldChanged()
    let seconds = modeControl.selectedSegment == 0 ? durationSeconds() : untilSeconds()
    onContinue(max(seconds, 60))
  }

  private func durationSeconds() -> Int {
    let minutes = hoursField.integerValue * 60 + minutesField.integerValue
    return minutes * 60
  }

  private func untilSeconds() -> Int {
    let calendar = Calendar.current
    let selected = calendar.dateComponents([.hour, .minute], from: timePicker.dateValue)
    var target = calendar.date(
      bySettingHour: selected.hour ?? 0,
      minute: selected.minute ?? 0,
      second: 0,
      of: Date()
    ) ?? Date()
    if target <= Date() {
      target = calendar.date(byAdding: .day, value: 1, to: target) ?? target
    }
    return Int(target.timeIntervalSinceNow.rounded(.up))
  }
}

private final class QuickSettingsMenuView: NSView {
  private let onToggle: (String, Bool) -> Void
  private var rows: [(button: NSButton, key: String)] = []
  private var sectionLabels: [NSTextField] = []
  private var separators: [NSBox] = []
  private let noteLabel = NSTextField(wrappingLabelWithString: "快速设置代表设置中相应项目的状态，不一定代表当前会话。")
  private let helpButton = NSButton(title: "?", target: nil, action: nil)

  init(
    allowDisplaySleep: Bool,
    allowSystemSleepWhenDisplayOff: Bool,
    allowScreenSaver: Bool,
    stopOnLowBattery: Bool,
    lowBatteryStopPercent: Int,
    lockScreenAfterIdle: Bool,
    moveCursorAfterIdle: Bool,
    triggersEnabled: Bool,
    keepDiskAwake: Bool,
    showRemainingSessionTime: Bool,
    onToggle: @escaping (String, Bool) -> Void
  ) {
    self.onToggle = onToggle
    super.init(frame: NSRect(x: 0, y: 0, width: 410, height: 465))
    setup(
      allowDisplaySleep: allowDisplaySleep,
      allowSystemSleepWhenDisplayOff: allowSystemSleepWhenDisplayOff,
      allowScreenSaver: allowScreenSaver,
      stopOnLowBattery: stopOnLowBattery,
      lowBatteryStopPercent: lowBatteryStopPercent,
      lockScreenAfterIdle: lockScreenAfterIdle,
      moveCursorAfterIdle: moveCursorAfterIdle,
      triggersEnabled: triggersEnabled,
      keepDiskAwake: keepDiskAwake,
      showRemainingSessionTime: showRemainingSessionTime
    )
  }

  required init?(coder: NSCoder) {
    nil
  }

  override var isFlipped: Bool {
    true
  }

  private func layoutContent() {
    noteLabel.frame = NSRect(x: 24, y: 20, width: 320, height: 44)
    helpButton.frame = NSRect(x: 356, y: 24, width: 30, height: 30)

    var y: CGFloat = 80
    layoutSection(index: 0, title: "会话默认设置", rowRange: 0..<4, y: &y)
    layoutSeparator(index: 0, y: y - 4)
    y += 12
    layoutSection(index: 1, title: "系统控制", rowRange: 4..<6, y: &y)
    layoutSeparator(index: 1, y: y - 4)
    y += 12
    layoutSection(index: 2, title: "其他", rowRange: 6..<9, y: &y)
  }

  private func setup(
    allowDisplaySleep: Bool,
    allowSystemSleepWhenDisplayOff: Bool,
    allowScreenSaver: Bool,
    stopOnLowBattery: Bool,
    lowBatteryStopPercent: Int,
    lockScreenAfterIdle: Bool,
    moveCursorAfterIdle: Bool,
    triggersEnabled: Bool,
    keepDiskAwake: Bool,
    showRemainingSessionTime: Bool
  ) {
    wantsLayer = true
    layer?.backgroundColor = NSColor.clear.cgColor

    noteLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
    noteLabel.textColor = .secondaryLabelColor
    addSubview(noteLabel)

    helpButton.bezelStyle = .helpButton
    helpButton.target = self
    helpButton.action = #selector(showHelp)
    addSubview(helpButton)

    for _ in 0..<3 {
      let label = NSTextField(labelWithString: "")
      label.font = NSFont.systemFont(ofSize: 15, weight: .bold)
      label.textColor = .labelColor
      sectionLabels.append(label)
      addSubview(label)
    }

    for _ in 0..<2 {
      let separator = NSBox()
      separator.boxType = .separator
      separators.append(separator)
      addSubview(separator)
    }

    addRow("允许显示器睡眠", key: "allowDisplaySleep", enabled: allowDisplaySleep)
    addRow("当显示器关闭时允许系统睡眠", key: "allowSystemSleepWhenDisplayOff", enabled: allowSystemSleepWhenDisplayOff)
    addRow("允许屏幕保护程序在闲置 45m 后运行", key: "allowScreenSaver", enabled: allowScreenSaver)
    addRow("当电池电量低于 \(lowBatteryStopPercent)% 时结束会话", key: "stopOnLowBattery", enabled: stopOnLowBattery)
    addRow("闲置 1m 后锁定屏幕", key: "lockScreenAfterIdle", enabled: lockScreenAfterIdle)
    addRow("闲置 5m 后移动光标", key: "moveCursorAfterIdle", enabled: moveCursorAfterIdle)
    addRow("启用触发器", key: "triggersEnabled", enabled: triggersEnabled)
    addRow("启用硬盘唤醒", key: "keepDiskAwake", enabled: keepDiskAwake)
    addRow("在菜单栏中显示剩余的会话时间", key: "showRemainingSessionTime", enabled: showRemainingSessionTime)
    layoutContent()
  }

  private func addRow(_ title: String, key: String, enabled: Bool) {
    let button = NSButton(checkboxWithTitle: title, target: self, action: #selector(rowToggled(_:)))
    button.font = NSFont.systemFont(ofSize: 15, weight: .regular)
    button.state = enabled ? .on : .off
    button.identifier = NSUserInterfaceItemIdentifier(key)
    rows.append((button, key))
    addSubview(button)
  }

  private func layoutSection(index: Int, title: String, rowRange: Range<Int>, y: inout CGFloat) {
    sectionLabels[index].stringValue = title
    sectionLabels[index].frame = NSRect(x: 24, y: y, width: 360, height: 22)
    y += 30

    for index in rowRange {
      rows[index].button.frame = NSRect(x: 34, y: y, width: 350, height: 24)
      y += 31
    }
  }

  private func layoutSeparator(index: Int, y: CGFloat) {
    separators[index].frame = NSRect(x: 24, y: y, width: 360, height: 1)
  }

  @objc private func showHelp() {
    let alert = NSAlert()
    alert.messageText = "快速设置"
    alert.informativeText = "这里显示的是默认设置和自动化开关的保存状态。它们会影响后续会话；当前已开启的会话可能需要重新开始后才完全采用新设置。"
    alert.addButton(withTitle: "好")
    alert.runModal()
  }

  @objc private func rowToggled(_ sender: NSButton) {
    guard let key = sender.identifier?.rawValue else {
      return
    }
    onToggle(key, sender.state == .on)
  }
}

@main
class AppDelegate: FlutterAppDelegate {
  private var statusItem: NSStatusItem?
  private var statusMenu = NSMenu()
  private var channel: FlutterMethodChannel?
  private var assertionID = IOPMAssertionID(0)
  private var assertionActive = false
  private var sessionEndsAt: Date?
  private var sessionTimer: Timer?
  private var preventDisplaySleep = true
  private var allowScreenSaver = false
  private var startWhenPluggedIn = false
  private var stopOnLowBattery = true
  private var appTriggerEnabled = false
  private var downloadTriggerEnabled = false
  private var startAtLogin = false
  private var lowBatteryStopPercent = 20
  private var customDurationMinutes = 45
  private var allowSystemSleepWhenDisplayOff = true
  private var lockScreenAfterIdle = false
  private var moveCursorAfterIdle = false
  private var triggersEnabled = true
  private var keepDiskAwake = false
  private var showRemainingSessionTime = false
  private var statusTitleTimer: Timer?
  private var lockScreenTimer: Timer?
  private var moveCursorTimer: Timer?
  private var diskWakeTimer: Timer?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    configureStatusItem()
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
      self?.configureStatusItemIfNeeded()
    }
  }

  func configureFlutterBridge(controller: FlutterViewController) {
    channel = FlutterMethodChannel(
      name: "app.stayawake/status_bar",
      binaryMessenger: controller.engine.binaryMessenger
    )
    channel?.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }
    recreateStatusItem()
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  private func configureStatusItem() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    statusItem?.isVisible = true
    statusItem?.button?.image = nil
    statusItem?.button?.imagePosition = .noImage
    statusItem?.button?.title = "STAY"
    statusItem?.menu = statusMenu
    rebuildMenu()
  }

  private func configureStatusItemIfNeeded() {
    guard statusItem == nil || statusItem?.button == nil else {
      statusItem?.isVisible = true
      rebuildMenu()
      return
    }
    configureStatusItem()
  }

  private func recreateStatusItem() {
    if let statusItem {
      NSStatusBar.system.removeStatusItem(statusItem)
    }
    statusItem = nil
    configureStatusItem()
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startSession":
      let args = call.arguments as? [String: Any]
      let durationSeconds = args?["durationSeconds"] as? Int
      preventDisplaySleep = args?["preventDisplaySleep"] as? Bool ?? true
      allowScreenSaver = args?["allowScreenSaver"] as? Bool ?? false
      startSession(durationSeconds: durationSeconds)
      result(statusPayload())
    case "stopSession":
      stopSession()
      result(statusPayload())
    case "getStatus":
      result(statusPayload())
    case "getPowerStatus":
      result(powerStatusPayload())
    case "getFrontmostApp":
      result(frontmostAppPayload())
    case "getRunningApps":
      result(runningAppsPayload())
    case "syncPreferences":
      syncPreferences(args: call.arguments as? [String: Any])
      result(statusPayload())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func syncPreferences(args: [String: Any]?) {
    guard let args else {
      return
    }
    preventDisplaySleep = args["preventDisplaySleep"] as? Bool ?? preventDisplaySleep
    allowScreenSaver = args["allowScreenSaver"] as? Bool ?? allowScreenSaver
    startAtLogin = args["startAtLogin"] as? Bool ?? startAtLogin
    lowBatteryStopPercent = args["lowBatteryStopPercent"] as? Int ?? lowBatteryStopPercent
    customDurationMinutes = args["customDurationMinutes"] as? Int ?? customDurationMinutes
    allowSystemSleepWhenDisplayOff = args["allowSystemSleepWhenDisplayOff"] as? Bool ?? allowSystemSleepWhenDisplayOff
    lockScreenAfterIdle = args["lockScreenAfterIdle"] as? Bool ?? lockScreenAfterIdle
    moveCursorAfterIdle = args["moveCursorAfterIdle"] as? Bool ?? moveCursorAfterIdle
    triggersEnabled = args["triggersEnabled"] as? Bool ?? triggersEnabled
    keepDiskAwake = args["keepDiskAwake"] as? Bool ?? keepDiskAwake
    showRemainingSessionTime = args["showRemainingSessionTime"] as? Bool ?? showRemainingSessionTime
    if let rules = args["rules"] as? [String: Bool] {
      startWhenPluggedIn = rules["plugged-in"] ?? startWhenPluggedIn
      stopOnLowBattery = rules["low-battery"] ?? stopOnLowBattery
      appTriggerEnabled = rules["app-trigger"] ?? appTriggerEnabled
      downloadTriggerEnabled = rules["download-trigger"] ?? downloadTriggerEnabled
    }
    configureSessionAuxiliaryTimers()
    rebuildMenu()
  }

  private func startSession(durationSeconds: Int?) {
    releaseAssertion()

    let assertionType = preventDisplaySleep ? kIOPMAssertionTypeNoDisplaySleep : kIOPMAssertionTypeNoIdleSleep
    let reason = "StayAwake active session" as CFString
    let status = IOPMAssertionCreateWithName(
      assertionType as CFString,
      IOPMAssertionLevel(kIOPMAssertionLevelOn),
      reason,
      &assertionID
    )

    assertionActive = status == kIOReturnSuccess
    if let durationSeconds {
      sessionEndsAt = Date().addingTimeInterval(TimeInterval(durationSeconds))
      scheduleStopTimer(seconds: durationSeconds)
    } else {
      sessionEndsAt = nil
      sessionTimer?.invalidate()
      sessionTimer = nil
    }
    rebuildMenu()
    configureSessionAuxiliaryTimers()
    channel?.invokeMethod("nativeStatusChanged", arguments: statusPayload())
  }

  private func stopSession() {
    releaseAssertion()
    sessionEndsAt = nil
    sessionTimer?.invalidate()
    sessionTimer = nil
    statusTitleTimer?.invalidate()
    statusTitleTimer = nil
    lockScreenTimer?.invalidate()
    lockScreenTimer = nil
    moveCursorTimer?.invalidate()
    moveCursorTimer = nil
    diskWakeTimer?.invalidate()
    diskWakeTimer = nil
    rebuildMenu()
    channel?.invokeMethod("nativeStatusChanged", arguments: statusPayload())
  }

  private func releaseAssertion() {
    if assertionActive {
      IOPMAssertionRelease(assertionID)
    }
    assertionID = IOPMAssertionID(0)
    assertionActive = false
  }

  private func scheduleStopTimer(seconds: Int) {
    sessionTimer?.invalidate()
    sessionTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(seconds), repeats: false) { [weak self] _ in
      self?.stopSession()
      self?.channel?.invokeMethod("stopSession", arguments: nil)
    }
  }

  private func configureSessionAuxiliaryTimers() {
    statusTitleTimer?.invalidate()
    statusTitleTimer = nil
    lockScreenTimer?.invalidate()
    lockScreenTimer = nil
    moveCursorTimer?.invalidate()
    moveCursorTimer = nil
    diskWakeTimer?.invalidate()
    diskWakeTimer = nil

    guard assertionActive else {
      return
    }

    if showRemainingSessionTime, sessionEndsAt != nil {
      statusTitleTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
        self?.updateStatusTitle()
      }
    }

    if lockScreenAfterIdle {
      lockScreenTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: false) { _ in
        let task = Process()
        task.launchPath = "/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession"
        task.arguments = ["-suspend"]
        try? task.run()
      }
    }

    if moveCursorAfterIdle {
      moveCursorTimer = Timer.scheduledTimer(withTimeInterval: 5 * 60, repeats: false) { _ in
        let location = NSEvent.mouseLocation
        CGWarpMouseCursorPosition(CGPoint(x: location.x + 1, y: location.y))
        CGWarpMouseCursorPosition(location)
      }
    }

    if keepDiskAwake {
      diskWakeTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
        self?.touchDiskWakeFile()
      }
      touchDiskWakeFile()
    }
  }

  private func touchDiskWakeFile() {
    guard let folder = FileManager.default.urls(
      for: .applicationSupportDirectory,
      in: .userDomainMask
    ).first?.appendingPathComponent("StayAwake", isDirectory: true) else {
      return
    }
    try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    let file = folder.appendingPathComponent(".disk-wake")
    let contents = "\(Date().timeIntervalSince1970)\n"
    try? contents.write(to: file, atomically: true, encoding: .utf8)
  }

  private func updateStatusTitle() {
    guard assertionActive else {
      statusItem?.button?.title = "STAY"
      return
    }
    guard showRemainingSessionTime, let sessionEndsAt else {
      statusItem?.button?.title = "STAY ON"
      return
    }
    let remaining = max(0, Int(sessionEndsAt.timeIntervalSinceNow.rounded(.up)))
    let hours = remaining / 3600
    let minutes = max(1, (remaining % 3600 + 59) / 60)
    statusItem?.button?.title = hours > 0 ? "STAY \(hours)h \(minutes)m" : "STAY \(minutes)m"
  }

  private func rebuildMenu() {
    statusMenu.removeAllItems()

    let title = assertionActive ? "StayAwake：已开启" : "StayAwake：空闲"
    let titleItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
    titleItem.isEnabled = false
    statusMenu.addItem(titleItem)

    if let sessionEndsAt {
      let formatter = DateFormatter()
      formatter.timeStyle = .short
      let endItem = NSMenuItem(title: "结束时间 \(formatter.string(from: sessionEndsAt))", action: nil, keyEquivalent: "")
      endItem.isEnabled = false
      statusMenu.addItem(endItem)
    } else if assertionActive {
      let endItem = NSMenuItem(title: "无限期会话", action: nil, keyEquivalent: "")
      endItem.isEnabled = false
      statusMenu.addItem(endItem)
    }

    statusMenu.addItem(.separator())
    let startTitle = NSMenuItem(title: "开启新会话:", action: nil, keyEquivalent: "")
    startTitle.isEnabled = false
    statusMenu.addItem(startTitle)
    statusMenu.addItem(actionItem(title: "无限期", action: #selector(startIndefinitely), keyEquivalent: "i"))

    let minutesMenu = NSMenu()
    for minutes in stride(from: 5, through: 55, by: 5) {
      minutesMenu.addItem(durationItem(title: "\(minutes) 分钟", seconds: minutes * 60))
    }
    statusMenu.addItem(submenuItem(title: "分钟", submenu: minutesMenu))

    let hoursMenu = NSMenu()
    for hours in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 24] {
      hoursMenu.addItem(durationItem(title: "\(hours) 小时", seconds: hours * 60 * 60))
    }
    statusMenu.addItem(submenuItem(title: "小时", submenu: hoursMenu))

    let customMenu = NSMenu()
    let customItem = NSMenuItem()
    customItem.view = CustomTimeMenuView(defaultMinutes: customDurationMinutes) { [weak self] seconds in
      self?.startCustomSeconds(seconds)
    }
    customMenu.addItem(customItem)
    statusMenu.addItem(submenuItem(title: "自定义时间 / 直到", submenu: customMenu))

    let appMenu = NSMenu()
    appMenu.addItem(toggleItem(title: "启用运行中 App 触发", action: #selector(toggleAppTrigger), enabled: appTriggerEnabled))
    appMenu.addItem(actionItem(title: "选择运行中的 App...", action: #selector(openRulesFromMenu)))
    statusMenu.addItem(submenuItem(title: "当 App 正在运行时", submenu: appMenu))

    statusMenu.addItem(toggleItem(title: "当下载文件时...", action: #selector(toggleDownloadTrigger), enabled: downloadTriggerEnabled))

    let stopItem = actionItem(title: "结束当前会话", action: #selector(stopFromMenu))
    stopItem.isEnabled = assertionActive
    statusMenu.addItem(stopItem)

    statusMenu.addItem(.separator())

    let quickSettingsMenu = NSMenu()
    let quickSettingsItem = NSMenuItem()
    quickSettingsItem.view = QuickSettingsMenuView(
      allowDisplaySleep: !preventDisplaySleep,
      allowSystemSleepWhenDisplayOff: allowSystemSleepWhenDisplayOff,
      allowScreenSaver: allowScreenSaver,
      stopOnLowBattery: stopOnLowBattery,
      lowBatteryStopPercent: lowBatteryStopPercent,
      lockScreenAfterIdle: lockScreenAfterIdle,
      moveCursorAfterIdle: moveCursorAfterIdle,
      triggersEnabled: triggersEnabled,
      keepDiskAwake: keepDiskAwake,
      showRemainingSessionTime: showRemainingSessionTime
    ) { [weak self] key, value in
      self?.quickSettingChanged(key: key, value: value)
    }
    quickSettingsMenu.addItem(quickSettingsItem)
    statusMenu.addItem(submenuItem(title: "快速设置", submenu: quickSettingsMenu))
    statusMenu.addItem(actionItem(title: "设置...", action: #selector(openSettingsFromMenu), keyEquivalent: ","))

    statusMenu.addItem(.separator())
    statusMenu.addItem(actionItem(title: "关于 StayAwake", action: #selector(openAboutFromMenu)))
    let supportMenu = NSMenu()
    supportMenu.addItem(actionItem(title: "打开主窗口", action: #selector(showMainWindow)))
    supportMenu.addItem(actionItem(title: "打开规则设置", action: #selector(openRulesFromMenu)))
    statusMenu.addItem(submenuItem(title: "反馈和支持", submenu: supportMenu))
    statusMenu.addItem(.separator())
    statusMenu.addItem(actionItem(title: "关闭 StayAwake", action: #selector(quitApp), keyEquivalent: "q"))

    statusItem?.button?.image = nil
    updateStatusTitle()
  }

  private func actionItem(title: String, action: Selector, keyEquivalent: String = "") -> NSMenuItem {
    let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
    item.target = self
    return item
  }

  private func durationItem(title: String, seconds: Int) -> NSMenuItem {
    let item = actionItem(title: title, action: #selector(startPresetFromMenu(_:)))
    item.representedObject = seconds
    return item
  }

  private func toggleItem(title: String, action: Selector, enabled: Bool) -> NSMenuItem {
    let item = actionItem(title: title, action: action)
    item.state = enabled ? .on : .off
    return item
  }

  private func submenuItem(title: String, submenu: NSMenu) -> NSMenuItem {
    let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
    statusMenu.setSubmenu(submenu, for: item)
    return item
  }

  private func statusPayload() -> [String: Any] {
    [
      "active": assertionActive,
      "endsAt": sessionEndsAt?.timeIntervalSince1970 as Any,
      "preventDisplaySleep": preventDisplaySleep,
      "allowScreenSaver": allowScreenSaver
    ]
  }

  private func powerStatusPayload() -> [String: Any] {
    guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
          let sourceType = IOPSGetProvidingPowerSourceType(snapshot)?.takeUnretainedValue() as String? else {
      return [
        "available": false,
        "source": "Unknown",
        "isPluggedIn": false
      ]
    }

    var batteryPercent: Int?
    if let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] {
      for source in sources {
        if let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any],
           let current = description[kIOPSCurrentCapacityKey] as? Int,
           let max = description[kIOPSMaxCapacityKey] as? Int,
           max > 0 {
          batteryPercent = Int((Double(current) / Double(max) * 100.0).rounded())
          break
        }
      }
    }

    return [
      "available": true,
      "source": sourceType,
      "isPluggedIn": sourceType != kIOPSBatteryPowerValue,
      "batteryPercent": batteryPercent as Any
    ]
  }

  private func frontmostAppPayload() -> [String: Any] {
    guard let app = NSWorkspace.shared.frontmostApplication else {
      return [
        "available": false,
        "name": "Unknown",
        "bundleIdentifier": ""
      ]
    }
    return [
      "available": true,
      "name": app.localizedName ?? "Unknown",
      "bundleIdentifier": app.bundleIdentifier ?? ""
    ]
  }

  private func runningAppsPayload() -> [[String: Any]] {
    let apps = NSWorkspace.shared.runningApplications.compactMap { app -> [String: Any]? in
      let name = app.localizedName ?? app.bundleIdentifier ?? ""
      let bundleIdentifier = app.bundleIdentifier ?? ""
      if name.isEmpty || bundleIdentifier.isEmpty {
        return nil
      }
      return [
        "name": name,
        "bundleIdentifier": bundleIdentifier,
        "isRegular": app.activationPolicy == .regular
      ]
    }

    return apps.sorted { lhs, rhs in
      let left = (lhs["name"] as? String ?? "").localizedCaseInsensitiveCompare(rhs["name"] as? String ?? "")
      if left == .orderedSame {
        return (lhs["bundleIdentifier"] as? String ?? "") < (rhs["bundleIdentifier"] as? String ?? "")
      }
      return left == .orderedAscending
    }
  }

  private func quickSettingChanged(key: String, value: Bool) {
    switch key {
    case "allowDisplaySleep":
      preventDisplaySleep = !value
      channel?.invokeMethod("toggleSetting", arguments: [
        "key": "preventDisplaySleep",
        "value": preventDisplaySleep
      ])
    case "allowSystemSleepWhenDisplayOff":
      allowSystemSleepWhenDisplayOff = value
      sendSettingToggle(key: key, value: value)
    case "allowScreenSaver":
      allowScreenSaver = value
      sendSettingToggle(key: key, value: value)
    case "stopOnLowBattery":
      stopOnLowBattery = value
      channel?.invokeMethod("toggleRule", arguments: [
        "id": "low-battery",
        "enabled": value
      ])
    case "lockScreenAfterIdle":
      lockScreenAfterIdle = value
      sendSettingToggle(key: key, value: value)
    case "moveCursorAfterIdle":
      moveCursorAfterIdle = value
      sendSettingToggle(key: key, value: value)
    case "triggersEnabled":
      triggersEnabled = value
      sendSettingToggle(key: key, value: value)
    case "keepDiskAwake":
      keepDiskAwake = value
      sendSettingToggle(key: key, value: value)
    case "showRemainingSessionTime":
      showRemainingSessionTime = value
      sendSettingToggle(key: key, value: value)
    default:
      return
    }
    configureSessionAuxiliaryTimers()
    rebuildMenu()
  }

  private func sendSettingToggle(key: String, value: Bool) {
    channel?.invokeMethod("toggleSetting", arguments: [
      "key": key,
      "value": value
    ])
  }

  @objc private func startPresetFromMenu(_ sender: NSMenuItem) {
    guard let seconds = sender.representedObject as? Int else {
      return
    }
    if let channel {
      channel.invokeMethod("startPreset", arguments: seconds)
    } else {
      startSession(durationSeconds: seconds)
    }
  }

  @objc private func start15Minutes() {
    if let channel {
      channel.invokeMethod("startPreset", arguments: 15 * 60)
    } else {
      startSession(durationSeconds: 15 * 60)
    }
  }

  @objc private func start30Minutes() {
    if let channel {
      channel.invokeMethod("startPreset", arguments: 30 * 60)
    } else {
      startSession(durationSeconds: 30 * 60)
    }
  }

  @objc private func start45Minutes() {
    if let channel {
      channel.invokeMethod("startPreset", arguments: 45 * 60)
    } else {
      startSession(durationSeconds: 45 * 60)
    }
  }

  @objc private func start1Hour() {
    if let channel {
      channel.invokeMethod("startPreset", arguments: 60 * 60)
    } else {
      startSession(durationSeconds: 60 * 60)
    }
  }

  @objc private func start2Hours() {
    if let channel {
      channel.invokeMethod("startPreset", arguments: 2 * 60 * 60)
    } else {
      startSession(durationSeconds: 2 * 60 * 60)
    }
  }

  @objc private func start4Hours() {
    if let channel {
      channel.invokeMethod("startPreset", arguments: 4 * 60 * 60)
    } else {
      startSession(durationSeconds: 4 * 60 * 60)
    }
  }

  @objc private func start8Hours() {
    if let channel {
      channel.invokeMethod("startPreset", arguments: 8 * 60 * 60)
    } else {
      startSession(durationSeconds: 8 * 60 * 60)
    }
  }

  @objc private func startCustomDuration() {
    if let channel {
      channel.invokeMethod("startPreset", arguments: customDurationMinutes * 60)
    } else {
      startSession(durationSeconds: customDurationMinutes * 60)
    }
  }

  private func startCustomSeconds(_ seconds: Int) {
    statusMenu.cancelTracking()
    if let channel {
      channel.invokeMethod("startPreset", arguments: seconds)
    } else {
      startSession(durationSeconds: seconds)
    }
  }

  @objc private func startIndefinitely() {
    if let channel {
      channel.invokeMethod("startPreset", arguments: nil)
    } else {
      startSession(durationSeconds: nil)
    }
  }

  @objc private func stopFromMenu() {
    if let channel {
      channel.invokeMethod("stopSession", arguments: nil)
    } else {
      stopSession()
    }
  }

  @objc private func togglePreventDisplaySleep() {
    preventDisplaySleep.toggle()
    channel?.invokeMethod("toggleSetting", arguments: [
      "key": "preventDisplaySleep",
      "value": preventDisplaySleep
    ])
    rebuildMenu()
  }

  @objc private func toggleAllowScreenSaver() {
    allowScreenSaver.toggle()
    channel?.invokeMethod("toggleSetting", arguments: [
      "key": "allowScreenSaver",
      "value": allowScreenSaver
    ])
    rebuildMenu()
  }

  @objc private func toggleStartAtLogin() {
    startAtLogin.toggle()
    channel?.invokeMethod("toggleSetting", arguments: [
      "key": "startAtLogin",
      "value": startAtLogin
    ])
    rebuildMenu()
  }

  @objc private func toggleStartWhenPluggedIn() {
    startWhenPluggedIn.toggle()
    channel?.invokeMethod("toggleRule", arguments: [
      "id": "plugged-in",
      "enabled": startWhenPluggedIn
    ])
    rebuildMenu()
  }

  @objc private func toggleStopOnLowBattery() {
    stopOnLowBattery.toggle()
    channel?.invokeMethod("toggleRule", arguments: [
      "id": "low-battery",
      "enabled": stopOnLowBattery
    ])
    rebuildMenu()
  }

  @objc private func toggleAppTrigger() {
    appTriggerEnabled.toggle()
    channel?.invokeMethod("toggleRule", arguments: [
      "id": "app-trigger",
      "enabled": appTriggerEnabled
    ])
    rebuildMenu()
  }

  @objc private func toggleDownloadTrigger() {
    downloadTriggerEnabled.toggle()
    channel?.invokeMethod("toggleRule", arguments: [
      "id": "download-trigger",
      "enabled": downloadTriggerEnabled
    ])
    rebuildMenu()
  }

  @objc private func openAboutFromMenu() {
    NSApp.activate(ignoringOtherApps: true)
    NSApp.orderFrontStandardAboutPanel(nil)
  }

  @objc private func openSessionsFromMenu() {
    showMainWindow()
    channel?.invokeMethod("openSection", arguments: "sessions")
  }

  @objc private func openRulesFromMenu() {
    showMainWindow()
    channel?.invokeMethod("openSection", arguments: "rules")
  }

  @objc private func openSettingsFromMenu() {
    showMainWindow()
    channel?.invokeMethod("openSection", arguments: "settings")
  }

  @objc private func showMainWindow() {
    NSApp.activate(ignoringOtherApps: true)
    NSApp.windows.first?.makeKeyAndOrderFront(nil)
  }

  @objc private func quitApp() {
    stopSession()
    NSApp.terminate(nil)
  }
}
