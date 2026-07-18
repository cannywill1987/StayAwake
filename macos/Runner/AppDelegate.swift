import Cocoa
import Carbon.HIToolbox
import FlutterMacOS
import IOKit.pwr_mgt
import IOKit.ps
import ServiceManagement
import UserNotifications

private struct StayAwakeOnboardingPage {
  let title: String
  let subtitle: String
  let body: String
  let buttonTitle: String?
  let illustration: StayAwakeOnboardingIllustration
}

private enum StayAwakeOnboardingIllustration {
  case appIcon
  case devices
  case menu
  case preferences
  case thanks
}

private enum StayAwakeNativeText {
  static let appName = "NoSleepy - Wake Keeper"
  static var languageMode = "system"
  static var effectiveLanguageCode = {
    let language = Locale.preferredLanguages.first?.split(separator: "-").first.map(String.init) ?? "en"
    return supportedLanguageCodes.contains(language) ? language : "en"
  }()
  static let supportedLanguageCodes = ["en", "zh", "ja", "fr", "it", "de", "es"]

  static var languageCode: String {
    if languageMode != "system" {
      return languageMode
    }
    let code = effectiveLanguageCode.split(separator: "-").first.map(String.init) ?? "en"
    return supportedLanguageCodes.contains(code) ? code : "en"
  }

  static var isChinese: Bool {
    languageCode == "zh"
  }

  static func pick(_ en: String, _ zh: String) -> String {
    let value = isChinese ? zh : (localizedStrings[languageCode]?[en] ?? en)
    return value.replacingOccurrences(of: "StayAwake", with: appName)
  }

  static func minutes(_ value: Int) -> String {
    switch languageCode {
    case "zh":
      return "\(value) 分钟"
    case "ja":
      return "\(value) 分"
    case "fr":
      return "\(value) min"
    case "it":
      return "\(value) min"
    case "de":
      return "\(value) Min."
    case "es":
      return "\(value) min"
    default:
      return "\(value) minutes"
    }
  }

  static func hours(_ value: Int) -> String {
    switch languageCode {
    case "zh":
      return "\(value) 小时"
    case "ja":
      return "\(value) 時間"
    case "fr":
      return "\(value) h"
    case "it":
      return "\(value) h"
    case "de":
      return "\(value) Std."
    case "es":
      return "\(value) h"
    default:
      return "\(value) hours"
    }
  }

  static let localizedStrings: [String: [String: String]] = [
    "ja": [
      "Start New Session:": "新しいセッションを開始:",
      "Indefinitely": "無期限",
      "Minutes >": "分 >",
      "Hours >": "時間 >",
      "Quick Settings >": "クイック設定 >",
      "Settings...": "設定...",
      "Do not show this window again": "このウィンドウを再表示しない",
      "Previous": "前へ",
      "Next": "次へ",
      "Done": "完了",
      "Welcome to StayAwake": "StayAwake へようこそ",
      "A local keep-awake utility built for Mac.": "Mac 向けのローカルスリープ防止ツールです。",
      "What can StayAwake do?": "StayAwake でできること",
      "Where is StayAwake?": "StayAwake はどこにありますか？",
      "StayAwake lives in the menu bar at the top-right of your screen.": "StayAwake は画面右上のメニューバーにあります。",
      "Click here to find StayAwake": "ここをクリックして StayAwake を探す",
      "What else can StayAwake do?": "StayAwake のその他の機能",
      "Open the StayAwake menu": "StayAwake メニューを開く",
      "Thanks for using StayAwake": "StayAwake をご利用いただきありがとうございます",
      "StayAwake Onboarding": "StayAwake ガイド",
      "For": "期間",
      "Until": "時刻まで",
      "Continue": "続ける",
      "Hours": "時間",
      "Minutes": "分",
      "Quick Settings": "クイック設定",
      "Session Defaults": "セッション既定値",
      "System Controls": "システム制御",
      "Other": "その他",
      "Allow display sleep": "ディスプレイスリープを許可",
      "Allow system sleep when display is off": "ディスプレイオフ時のシステムスリープを許可",
      "Allow screen saver after 45m idle": "45分アイドル後のスクリーンセーバーを許可",
      "Allow screen lock": "画面ロックを許可",
      "Enable triggers": "トリガーを有効化",
      "Enable disk wake": "ディスク維持を有効化",
      "Show remaining session time in menu bar": "残り時間をメニューバーに表示",
      "OK": "OK",
      "Started manually": "手動で開始",
      "End Current Session": "現在のセッションを終了",
      "Current Session Details:": "現在のセッション詳細:",
      "Remaining time unknown": "残り時間不明",
      "Press a New Global Shortcut": "新しいグローバルショートカットを押してください",
      "Waiting for input...": "入力待ち...",
      "StayAwake: Idle": "StayAwake: 待機中",
      "Custom Time / Until": "カスタム時間 / 時刻まで",
      "While Files Are Downloading...": "ファイルのダウンロード中...",
      "About StayAwake": "StayAwake について",
      "Open Main Window": "メインウィンドウを開く",
      "Show Onboarding": "ガイドを表示",
      "Open Rules Settings": "ルール設定を開く",
      "Feedback & Support": "フィードバックとサポート",
      "Quit StayAwake": "StayAwake を終了",
      "While App Is Running": "アプリ実行中",
      "Enable Running App Trigger": "実行中アプリトリガーを有効化",
      "Hide Helper Apps and Processes": "ヘルパーアプリとプロセスを隠す",
      "No running apps available": "選択可能な実行中アプリはありません",
      "Open Rules Settings...": "ルール設定を開く...",
    ],
    "fr": [
      "Start New Session:": "Démarrer une session :",
      "Indefinitely": "Indéfiniment",
      "Minutes >": "Minutes >",
      "Hours >": "Heures >",
      "Quick Settings >": "Réglages rapides >",
      "Settings...": "Réglages...",
      "Do not show this window again": "Ne plus afficher cette fenêtre",
      "Previous": "Précédent",
      "Next": "Suivant",
      "Done": "Terminé",
      "Welcome to StayAwake": "Bienvenue dans StayAwake",
      "A local keep-awake utility built for Mac.": "Un utilitaire local de maintien éveillé pour Mac.",
      "What can StayAwake do?": "Que peut faire StayAwake ?",
      "Where is StayAwake?": "Où se trouve StayAwake ?",
      "StayAwake lives in the menu bar at the top-right of your screen.": "StayAwake se trouve dans la barre des menus en haut à droite.",
      "Click here to find StayAwake": "Cliquez ici pour trouver StayAwake",
      "What else can StayAwake do?": "Que peut faire StayAwake d’autre ?",
      "Open the StayAwake menu": "Ouvrir le menu StayAwake",
      "Thanks for using StayAwake": "Merci d’utiliser StayAwake",
      "StayAwake Onboarding": "Guide StayAwake",
      "For": "Pendant",
      "Until": "Jusqu’à",
      "Continue": "Continuer",
      "Hours": "Heures",
      "Minutes": "Minutes",
      "Quick Settings": "Réglages rapides",
      "Session Defaults": "Valeurs par défaut",
      "System Controls": "Contrôles système",
      "Other": "Autre",
      "Allow display sleep": "Autoriser la veille de l’écran",
      "Allow system sleep when display is off": "Autoriser la veille système écran éteint",
      "Allow screen saver after 45m idle": "Autoriser l’économiseur après 45 min",
      "Allow screen lock": "Autoriser le verrouillage",
      "Enable triggers": "Activer les déclencheurs",
      "Enable disk wake": "Activer le maintien du disque",
      "Show remaining session time in menu bar": "Afficher le temps restant dans la barre",
      "OK": "OK",
      "Started manually": "Démarré manuellement",
      "End Current Session": "Terminer la session actuelle",
      "Current Session Details:": "Détails de la session :",
      "Remaining time unknown": "Temps restant inconnu",
      "Press a New Global Shortcut": "Appuyez sur un nouveau raccourci global",
      "Waiting for input...": "En attente...",
      "StayAwake: Idle": "StayAwake : inactif",
      "Custom Time / Until": "Durée personnalisée / jusqu’à",
      "While Files Are Downloading...": "Pendant les téléchargements...",
      "About StayAwake": "À propos de StayAwake",
      "Open Main Window": "Ouvrir la fenêtre principale",
      "Show Onboarding": "Afficher le guide",
      "Open Rules Settings": "Ouvrir les règles",
      "Feedback & Support": "Commentaires et support",
      "Quit StayAwake": "Quitter StayAwake",
      "While App Is Running": "Quand l’app est ouverte",
      "Enable Running App Trigger": "Activer le déclencheur d’app",
      "Hide Helper Apps and Processes": "Masquer les apps et processus auxiliaires",
      "No running apps available": "Aucune app disponible",
      "Open Rules Settings...": "Ouvrir les règles...",
    ],
    "it": [
      "Start New Session:": "Avvia nuova sessione:",
      "Indefinitely": "Senza limite",
      "Minutes >": "Minuti >",
      "Hours >": "Ore >",
      "Quick Settings >": "Impostazioni rapide >",
      "Settings...": "Impostazioni...",
      "Do not show this window again": "Non mostrare più questa finestra",
      "Previous": "Indietro",
      "Next": "Avanti",
      "Done": "Fine",
      "Welcome to StayAwake": "Benvenuto in StayAwake",
      "A local keep-awake utility built for Mac.": "Un’utilità locale anti-sospensione per Mac.",
      "What can StayAwake do?": "Cosa può fare StayAwake?",
      "Where is StayAwake?": "Dov’è StayAwake?",
      "StayAwake lives in the menu bar at the top-right of your screen.": "StayAwake si trova nella barra dei menu in alto a destra.",
      "Click here to find StayAwake": "Fai clic qui per trovare StayAwake",
      "What else can StayAwake do?": "Cos’altro può fare StayAwake?",
      "Open the StayAwake menu": "Apri il menu StayAwake",
      "Thanks for using StayAwake": "Grazie per usare StayAwake",
      "StayAwake Onboarding": "Guida StayAwake",
      "For": "Per",
      "Until": "Fino a",
      "Continue": "Continua",
      "Hours": "Ore",
      "Minutes": "Minuti",
      "Quick Settings": "Impostazioni rapide",
      "Session Defaults": "Predefiniti sessione",
      "System Controls": "Controlli di sistema",
      "Other": "Altro",
      "Allow display sleep": "Consenti stop dello schermo",
      "Allow system sleep when display is off": "Consenti stop sistema a schermo spento",
      "Allow screen saver after 45m idle": "Consenti salvaschermo dopo 45 min",
      "Allow screen lock": "Consenti blocco schermo",
      "Enable triggers": "Abilita attivatori",
      "Enable disk wake": "Abilita disco attivo",
      "Show remaining session time in menu bar": "Mostra tempo restante nella barra",
      "OK": "OK",
      "Started manually": "Avviata manualmente",
      "End Current Session": "Termina sessione corrente",
      "Current Session Details:": "Dettagli sessione:",
      "Remaining time unknown": "Tempo restante sconosciuto",
      "Press a New Global Shortcut": "Premi una nuova scorciatoia globale",
      "Waiting for input...": "In attesa...",
      "StayAwake: Idle": "StayAwake: inattivo",
      "Custom Time / Until": "Durata personalizzata / fino a",
      "While Files Are Downloading...": "Durante i download...",
      "About StayAwake": "Informazioni su StayAwake",
      "Open Main Window": "Apri finestra principale",
      "Show Onboarding": "Mostra guida",
      "Open Rules Settings": "Apri regole",
      "Feedback & Support": "Feedback e supporto",
      "Quit StayAwake": "Esci da StayAwake",
      "While App Is Running": "Quando l’app è in esecuzione",
      "Enable Running App Trigger": "Abilita attivatore app",
      "Hide Helper Apps and Processes": "Nascondi app e processi helper",
      "No running apps available": "Nessuna app disponibile",
      "Open Rules Settings...": "Apri regole...",
    ],
    "de": [
      "Start New Session:": "Neue Sitzung starten:",
      "Indefinitely": "Unbegrenzt",
      "Minutes >": "Minuten >",
      "Hours >": "Stunden >",
      "Quick Settings >": "Schnelleinstellungen >",
      "Settings...": "Einstellungen...",
      "Do not show this window again": "Dieses Fenster nicht erneut anzeigen",
      "Previous": "Zurück",
      "Next": "Weiter",
      "Done": "Fertig",
      "Welcome to StayAwake": "Willkommen bei StayAwake",
      "A local keep-awake utility built for Mac.": "Ein lokales Wachhalte-Tool für den Mac.",
      "What can StayAwake do?": "Was kann StayAwake?",
      "Where is StayAwake?": "Wo ist StayAwake?",
      "StayAwake lives in the menu bar at the top-right of your screen.": "StayAwake befindet sich rechts oben in der Menüleiste.",
      "Click here to find StayAwake": "Hier klicken, um StayAwake zu finden",
      "What else can StayAwake do?": "Was kann StayAwake noch?",
      "Open the StayAwake menu": "StayAwake-Menü öffnen",
      "Thanks for using StayAwake": "Danke, dass du StayAwake verwendest",
      "StayAwake Onboarding": "StayAwake-Einführung",
      "For": "Für",
      "Until": "Bis",
      "Continue": "Weiter",
      "Hours": "Stunden",
      "Minutes": "Minuten",
      "Quick Settings": "Schnelleinstellungen",
      "Session Defaults": "Sitzungsstandard",
      "System Controls": "Systemsteuerung",
      "Other": "Sonstiges",
      "Allow display sleep": "Display-Ruhezustand erlauben",
      "Allow system sleep when display is off": "System-Ruhezustand bei ausgeschaltetem Display erlauben",
      "Allow screen saver after 45m idle": "Bildschirmschoner nach 45 Min. erlauben",
      "Allow screen lock": "Bildschirmsperre erlauben",
      "Enable triggers": "Auslöser aktivieren",
      "Enable disk wake": "Festplatte wach halten",
      "Show remaining session time in menu bar": "Restzeit in Menüleiste anzeigen",
      "OK": "OK",
      "Started manually": "Manuell gestartet",
      "End Current Session": "Aktuelle Sitzung beenden",
      "Current Session Details:": "Sitzungsdetails:",
      "Remaining time unknown": "Restzeit unbekannt",
      "Press a New Global Shortcut": "Neuen globalen Kurzbefehl drücken",
      "Waiting for input...": "Warte auf Eingabe...",
      "StayAwake: Idle": "StayAwake: inaktiv",
      "Custom Time / Until": "Eigene Zeit / bis",
      "While Files Are Downloading...": "Während Dateien geladen werden...",
      "About StayAwake": "Über StayAwake",
      "Open Main Window": "Hauptfenster öffnen",
      "Show Onboarding": "Einführung anzeigen",
      "Open Rules Settings": "Regeleinstellungen öffnen",
      "Feedback & Support": "Feedback & Support",
      "Quit StayAwake": "StayAwake beenden",
      "While App Is Running": "Während App läuft",
      "Enable Running App Trigger": "App-Auslöser aktivieren",
      "Hide Helper Apps and Processes": "Hilfsapps und Prozesse ausblenden",
      "No running apps available": "Keine laufenden Apps verfügbar",
      "Open Rules Settings...": "Regeleinstellungen öffnen...",
    ],
    "es": [
      "Start New Session:": "Iniciar nueva sesión:",
      "Indefinitely": "Indefinidamente",
      "Minutes >": "Minutos >",
      "Hours >": "Horas >",
      "Quick Settings >": "Ajustes rápidos >",
      "Settings...": "Ajustes...",
      "Do not show this window again": "No volver a mostrar esta ventana",
      "Previous": "Anterior",
      "Next": "Siguiente",
      "Done": "Listo",
      "Welcome to StayAwake": "Bienvenido a StayAwake",
      "A local keep-awake utility built for Mac.": "Una utilidad local anti-suspensión para Mac.",
      "What can StayAwake do?": "¿Qué puede hacer StayAwake?",
      "Where is StayAwake?": "¿Dónde está StayAwake?",
      "StayAwake lives in the menu bar at the top-right of your screen.": "StayAwake está en la barra de menús, arriba a la derecha.",
      "Click here to find StayAwake": "Haz clic aquí para encontrar StayAwake",
      "What else can StayAwake do?": "¿Qué más puede hacer StayAwake?",
      "Open the StayAwake menu": "Abrir el menú StayAwake",
      "Thanks for using StayAwake": "Gracias por usar StayAwake",
      "StayAwake Onboarding": "Guía de StayAwake",
      "For": "Durante",
      "Until": "Hasta",
      "Continue": "Continuar",
      "Hours": "Horas",
      "Minutes": "Minutos",
      "Quick Settings": "Ajustes rápidos",
      "Session Defaults": "Valores de sesión",
      "System Controls": "Controles del sistema",
      "Other": "Otros",
      "Allow display sleep": "Permitir reposo de pantalla",
      "Allow system sleep when display is off": "Permitir reposo del sistema con pantalla apagada",
      "Allow screen saver after 45m idle": "Permitir salvapantallas tras 45 min",
      "Allow screen lock": "Permitir bloqueo de pantalla",
      "Enable triggers": "Activar disparadores",
      "Enable disk wake": "Activar disco despierto",
      "Show remaining session time in menu bar": "Mostrar tiempo restante en la barra",
      "OK": "OK",
      "Started manually": "Iniciado manualmente",
      "End Current Session": "Finalizar sesión actual",
      "Current Session Details:": "Detalles de sesión:",
      "Remaining time unknown": "Tiempo restante desconocido",
      "Press a New Global Shortcut": "Pulsa un nuevo atajo global",
      "Waiting for input...": "Esperando entrada...",
      "StayAwake: Idle": "StayAwake: inactivo",
      "Custom Time / Until": "Tiempo personalizado / hasta",
      "While Files Are Downloading...": "Mientras se descargan archivos...",
      "About StayAwake": "Acerca de StayAwake",
      "Open Main Window": "Abrir ventana principal",
      "Show Onboarding": "Mostrar guía",
      "Open Rules Settings": "Abrir reglas",
      "Feedback & Support": "Comentarios y soporte",
      "Quit StayAwake": "Salir de StayAwake",
      "While App Is Running": "Mientras la app está activa",
      "Enable Running App Trigger": "Activar disparador de app",
      "Hide Helper Apps and Processes": "Ocultar apps y procesos auxiliares",
      "No running apps available": "No hay apps disponibles",
      "Open Rules Settings...": "Abrir reglas...",
    ],
  ]
}

private final class StayAwakeOnboardingIllustrationView: NSView {
  var illustration = StayAwakeOnboardingIllustration.appIcon {
    didSet {
      needsDisplay = true
    }
  }

  override var isFlipped: Bool {
    true
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
    NSColor(calibratedWhite: 0.94, alpha: 1).setFill()
    bounds.fill()
    NSColor.separatorColor.setStroke()
    NSBezierPath(rect: NSRect(x: 0, y: bounds.maxY - 1, width: bounds.width, height: 1)).stroke()

    switch illustration {
    case .appIcon:
      drawAppIcon()
    case .devices:
      drawDevices()
    case .menu:
      drawMenu()
    case .preferences:
      drawPreferences()
    case .thanks:
      drawThanks()
    }
  }

  private func drawAppIcon() {
    let size: CGFloat = 172
    let rect = NSRect(x: bounds.midX - size / 2, y: 38, width: size, height: size)
    let iconPath = NSBezierPath(roundedRect: rect, xRadius: 42, yRadius: 42)
    NSColor(calibratedWhite: 0.84, alpha: 1).setFill()
    iconPath.fill()
    NSColor.white.withAlphaComponent(0.8).setStroke()
    iconPath.lineWidth = 3
    iconPath.stroke()

    let screen = NSRect(x: rect.midX - 48, y: rect.midY - 43, width: 96, height: 96)
    NSColor.black.setFill()
    NSBezierPath(roundedRect: screen, xRadius: 26, yRadius: 26).fill()
    NSColor(calibratedRed: 0.97, green: 0.59, blue: 0.36, alpha: 1).setFill()
    NSBezierPath(roundedRect: screen.insetBy(dx: 11, dy: 11), xRadius: 18, yRadius: 18).fill()

    let badge = NSRect(x: rect.midX + 12, y: rect.midY + 4, width: 78, height: 78)
    NSColor(calibratedRed: 1, green: 0.79, blue: 0.22, alpha: 1).setFill()
    NSBezierPath(ovalIn: badge).fill()
    NSColor(calibratedRed: 0.79, green: 0.56, blue: 0.06, alpha: 1).setStroke()
    let slash = NSBezierPath()
    slash.lineWidth = 8
    slash.move(to: CGPoint(x: badge.minX + 10, y: badge.midY - 4))
    slash.line(to: CGPoint(x: badge.maxX - 8, y: badge.midY + 8))
    slash.stroke()
  }

  private func drawDevices() {
    let monitor = NSRect(x: bounds.midX - 150, y: 60, width: 300, height: 156)
    drawScreen(rect: monitor, lineWidth: 8)
    NSColor.black.setFill()
    NSBezierPath(rect: NSRect(x: monitor.midX - 9, y: monitor.maxY, width: 18, height: 34)).fill()

    let laptop = NSRect(x: bounds.midX + 205, y: 124, width: 205, height: 104)
    drawScreen(rect: laptop, lineWidth: 7)
    let phone = NSRect(x: bounds.midX - 405, y: 144, width: 78, height: 106)
    drawScreen(rect: phone, lineWidth: 6)
  }

  private func drawMenu() {
    let bar = NSRect(x: bounds.midX - 300, y: 70, width: 600, height: 190)
    drawScreen(rect: bar, lineWidth: 8)
    NSColor(calibratedWhite: 0.88, alpha: 1).setFill()
    NSBezierPath(rect: NSRect(x: bar.minX + 8, y: bar.minY + 8, width: bar.width - 16, height: 26)).fill()

    let menu = NSRect(x: bar.maxX - 172, y: bar.minY + 28, width: 152, height: 156)
    NSColor(calibratedWhite: 0.86, alpha: 1).setFill()
    NSBezierPath(roundedRect: menu, xRadius: 4, yRadius: 4).fill()
    NSColor.gray.setStroke()
    NSBezierPath(roundedRect: menu, xRadius: 4, yRadius: 4).stroke()

    let rows = [
      StayAwakeNativeText.pick("Start New Session:", "开启新会话:"),
      StayAwakeNativeText.pick("Indefinitely", "无限期"),
      StayAwakeNativeText.pick("Minutes >", "分钟 >"),
      StayAwakeNativeText.pick("Hours >", "小时 >"),
      StayAwakeNativeText.pick("Quick Settings >", "快速设置 >"),
      StayAwakeNativeText.pick("Settings...", "设置...")
    ]
    for (index, row) in rows.enumerated() {
      let y = menu.minY + 12 + CGFloat(index) * 21
      row.draw(
        at: CGPoint(x: menu.minX + 12, y: y),
        withAttributes: [
          .font: NSFont.systemFont(ofSize: index == 0 ? 12 : 11, weight: index == 0 ? .semibold : .regular),
          .foregroundColor: NSColor.labelColor
        ]
      )
    }

    let pill = NSRect(x: menu.minX + 6, y: bar.minY + 8, width: 28, height: 26)
    NSColor.systemTeal.setFill()
    NSBezierPath(rect: pill).fill()
    "STAY".draw(
      at: CGPoint(x: pill.minX + 34, y: pill.minY + 5),
      withAttributes: [.font: NSFont.systemFont(ofSize: 12, weight: .medium), .foregroundColor: NSColor.labelColor]
    )
  }

  private func drawPreferences() {
    let window = NSRect(x: bounds.midX - 300, y: 48, width: 600, height: 208)
    NSColor(calibratedWhite: 0.84, alpha: 1).setFill()
    NSBezierPath(roundedRect: window, xRadius: 5, yRadius: 5).fill()
    NSColor.gray.setStroke()
    NSBezierPath(roundedRect: window, xRadius: 5, yRadius: 5).stroke()
    for i in 0..<7 {
      let x = window.minX + 24 + CGFloat(i) * 74
      NSColor(calibratedWhite: i == 2 ? 0.72 : 0.96, alpha: 1).setFill()
      NSBezierPath(roundedRect: NSRect(x: x, y: window.minY + 28, width: 42, height: 42), xRadius: 6, yRadius: 6).fill()
    }
    NSColor.systemBlue.setFill()
    for i in 0..<5 {
      NSBezierPath(roundedRect: NSRect(x: window.minX + 150, y: window.minY + 96 + CGFloat(i) * 24, width: 14, height: 14), xRadius: 3, yRadius: 3).fill()
    }
    NSColor(calibratedWhite: 0.92, alpha: 1).setFill()
    NSBezierPath(rect: NSRect(x: window.minX + 140, y: window.minY + 84, width: 310, height: 138)).fill()
  }

  private func drawThanks() {
    NSColor.systemRed.setFill()
    let heart = NSBezierPath()
    let center = CGPoint(x: bounds.midX, y: 114)
    heart.move(to: CGPoint(x: center.x, y: center.y + 92))
    heart.curve(
      to: CGPoint(x: center.x - 92, y: center.y + 8),
      controlPoint1: CGPoint(x: center.x - 82, y: center.y + 52),
      controlPoint2: CGPoint(x: center.x - 110, y: center.y + 8)
    )
    heart.curve(
      to: CGPoint(x: center.x, y: center.y - 58),
      controlPoint1: CGPoint(x: center.x - 92, y: center.y - 56),
      controlPoint2: CGPoint(x: center.x - 10, y: center.y - 48)
    )
    heart.curve(
      to: CGPoint(x: center.x + 92, y: center.y + 8),
      controlPoint1: CGPoint(x: center.x + 10, y: center.y - 48),
      controlPoint2: CGPoint(x: center.x + 92, y: center.y - 56)
    )
    heart.curve(
      to: CGPoint(x: center.x, y: center.y + 92),
      controlPoint1: CGPoint(x: center.x + 110, y: center.y + 8),
      controlPoint2: CGPoint(x: center.x + 82, y: center.y + 52)
    )
    heart.fill()
  }

  private func drawScreen(rect: NSRect, lineWidth: CGFloat) {
    NSColor.black.setStroke()
    let path = NSBezierPath(rect: rect)
    path.lineWidth = lineWidth
    path.stroke()
    NSColor(calibratedWhite: 0.93, alpha: 1).setFill()
    rect.insetBy(dx: lineWidth, dy: lineWidth).fill()
  }
}

private final class StayAwakeOnboardingWindowController: NSWindowController {
  private let pages: [StayAwakeOnboardingPage]
  private let onFindStayAwake: () -> Void
  private let onFinish: (Bool) -> Void
  private var pageIndex = 0
  private let illustrationView = StayAwakeOnboardingIllustrationView()
  private let titleLabel = NSTextField(labelWithString: "")
  private let subtitleLabel = NSTextField(labelWithString: "")
  private let bodyLabel = NSTextField(labelWithString: "")
  private let findButton = NSButton(title: "", target: nil, action: nil)
  private let dontShowCheckbox = NSButton(checkboxWithTitle: StayAwakeNativeText.pick("Do not show this window again", "不再显示此窗口"), target: nil, action: nil)
  private let previousButton = NSButton(title: StayAwakeNativeText.pick("Previous", "上一步"), target: nil, action: nil)
  private let nextButton = NSButton(title: StayAwakeNativeText.pick("Next", "下一步"), target: nil, action: nil)

  init(onFindStayAwake: @escaping () -> Void, onFinish: @escaping (Bool) -> Void) {
    self.onFindStayAwake = onFindStayAwake
    self.onFinish = onFinish
    pages = [
      StayAwakeOnboardingPage(
        title: StayAwakeNativeText.pick("Welcome to StayAwake", "欢迎使用 StayAwake"),
        subtitle: StayAwakeNativeText.pick("A local keep-awake utility built for Mac.", "一个专为 Mac 设计的单机防睡眠工具。"),
        body: StayAwakeNativeText.pick("StayAwake keeps your Mac, display, and long-running tasks awake when you need them. Everything runs locally, with no account, sync, or remote backend.", "StayAwake 可以让你的 Mac、显示器和正在工作的任务在需要时保持唤醒。所有控制都在本机完成，不需要账号、同步或远程后端。"),
        buttonTitle: nil,
        illustration: .appIcon
      ),
      StayAwakeOnboardingPage(
        title: StayAwakeNativeText.pick("What can StayAwake do?", "StayAwake 能做什么？"),
        subtitle: StayAwakeNativeText.pick("Keep your Mac awake during meetings, downloads, presentations, and long tasks.", "让 Mac 在会议、下载、演示和长任务期间保持清醒。"),
        body: StayAwakeNativeText.pick("After you start a session, StayAwake uses a native macOS power assertion to block system sleep. You can choose indefinitely, a preset duration, or a custom time, and decide whether screen savers or display sleep are allowed.", "开启一个会话后，StayAwake 会通过 macOS 原生电源断言阻止系统进入睡眠。你可以选择无限期、固定时长或自定义时长，也可以决定是否允许屏幕保护程序或显示器睡眠。"),
        buttonTitle: nil,
        illustration: .devices
      ),
      StayAwakeOnboardingPage(
        title: StayAwakeNativeText.pick("Where is StayAwake?", "StayAwake 在哪里显示？"),
        subtitle: StayAwakeNativeText.pick("StayAwake lives in the menu bar at the top-right of your screen.", "StayAwake 在屏幕右上角的菜单栏里。"),
        body: StayAwakeNativeText.pick("Click StayAwake in the menu bar to open its menu. From there you can start or stop sessions, choose minutes or hours, set a custom time, open quick settings, or open the full settings window.", "默认情况下，单击菜单栏里的 StayAwake 会显示菜单。你可以快速开启或停止会话、选择分钟/小时、自定义时间、进入快速设置，或打开完整设置窗口。"),
        buttonTitle: StayAwakeNativeText.pick("Click here to find StayAwake", "单击这里找到 StayAwake"),
        illustration: .menu
      ),
      StayAwakeOnboardingPage(
        title: StayAwakeNativeText.pick("What else can StayAwake do?", "StayAwake 还能做什么？"),
        subtitle: StayAwakeNativeText.pick("Tune session behavior around the way you work.", "你可以按自己的工作方式调整会话行为。"),
        body: StayAwakeNativeText.pick("StayAwake supports quick settings, launch at login, notifications, low-battery stops, app-running triggers, download triggers, disk wake, and global shortcuts. Most settings are saved locally for single-machine use.", "StayAwake 支持快速设置、开机启动、通知提醒、低电量停止、App 运行时触发、下载触发、硬盘唤醒和全局快捷键。大多数设置都保存在本机，适合单机使用。"),
        buttonTitle: StayAwakeNativeText.pick("Open the StayAwake menu", "打开 StayAwake 菜单"),
        illustration: .preferences
      ),
      StayAwakeOnboardingPage(
        title: StayAwakeNativeText.pick("Thanks for using StayAwake", "感谢使用 StayAwake"),
        subtitle: StayAwakeNativeText.pick("You are ready to keep your Mac awake.", "现在可以开始让你的 Mac 保持清醒了。"),
        body: StayAwakeNativeText.pick("If you want to view this guide again, open StayAwake in the menu bar and choose Feedback & Support, then Show Onboarding.", "如果之后需要重新查看引导，可以从菜单栏 StayAwake 的“反馈和支持”中打开“显示新手引导”。"),
        buttonTitle: nil,
        illustration: .thanks
      )
    ]

    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 920, height: 720),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false
    )
    window.title = StayAwakeNativeText.pick("StayAwake Onboarding", "StayAwake 新手引导")
    window.center()
    window.isReleasedWhenClosed = false
    super.init(window: window)
    buildInterface()
    updatePage()
  }

  required init?(coder: NSCoder) {
    nil
  }

  override func showWindow(_ sender: Any?) {
    super.showWindow(sender)
    NSApp.activate(ignoringOtherApps: true)
    window?.makeKeyAndOrderFront(sender)
  }

  private func buildInterface() {
    guard let contentView = window?.contentView else {
      return
    }
    contentView.wantsLayer = true
    contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

    illustrationView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(illustrationView)

    titleLabel.alignment = .center
    titleLabel.font = NSFont.systemFont(ofSize: 32, weight: .semibold)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(titleLabel)

    subtitleLabel.alignment = .center
    subtitleLabel.font = NSFont.systemFont(ofSize: 19, weight: .regular)
    subtitleLabel.textColor = .secondaryLabelColor
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(subtitleLabel)

    let divider = NSBox()
    divider.boxType = .separator
    divider.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(divider)

    bodyLabel.font = NSFont.systemFont(ofSize: 18, weight: .regular)
    bodyLabel.maximumNumberOfLines = 0
    bodyLabel.lineBreakMode = .byWordWrapping
    bodyLabel.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(bodyLabel)

    findButton.target = self
    findButton.action = #selector(findStayAwake)
    findButton.bezelStyle = .rounded
    findButton.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(findButton)

    let footer = NSVisualEffectView()
    footer.material = .windowBackground
    footer.state = .active
    footer.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(footer)

    dontShowCheckbox.state = .on
    dontShowCheckbox.translatesAutoresizingMaskIntoConstraints = false
    footer.addSubview(dontShowCheckbox)

    previousButton.target = self
    previousButton.action = #selector(previousPage)
    previousButton.bezelStyle = .rounded
    previousButton.translatesAutoresizingMaskIntoConstraints = false
    footer.addSubview(previousButton)

    nextButton.target = self
    nextButton.action = #selector(nextPage)
    nextButton.bezelStyle = .rounded
    nextButton.translatesAutoresizingMaskIntoConstraints = false
    footer.addSubview(nextButton)

    NSLayoutConstraint.activate([
      illustrationView.topAnchor.constraint(equalTo: contentView.topAnchor),
      illustrationView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      illustrationView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      illustrationView.heightAnchor.constraint(equalToConstant: 292),

      titleLabel.topAnchor.constraint(equalTo: illustrationView.bottomAnchor, constant: 44),
      titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 56),
      titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -56),

      subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
      subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 56),
      subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -56),

      divider.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
      divider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 56),
      divider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -56),

      bodyLabel.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 34),
      bodyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 88),
      bodyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -88),

      findButton.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 28),
      findButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

      footer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      footer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      footer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      footer.heightAnchor.constraint(equalToConstant: 78),

      dontShowCheckbox.leadingAnchor.constraint(equalTo: footer.leadingAnchor, constant: 28),
      dontShowCheckbox.centerYAnchor.constraint(equalTo: footer.centerYAnchor),

      nextButton.trailingAnchor.constraint(equalTo: footer.trailingAnchor, constant: -28),
      nextButton.centerYAnchor.constraint(equalTo: footer.centerYAnchor),
      nextButton.widthAnchor.constraint(equalToConstant: 82),

      previousButton.trailingAnchor.constraint(equalTo: nextButton.leadingAnchor, constant: -20),
      previousButton.centerYAnchor.constraint(equalTo: footer.centerYAnchor),
      previousButton.widthAnchor.constraint(equalToConstant: 82)
    ])
  }

  private func updatePage() {
    let page = pages[pageIndex]
    illustrationView.illustration = page.illustration
    titleLabel.stringValue = page.title
    subtitleLabel.stringValue = page.subtitle
    bodyLabel.stringValue = page.body
    findButton.title = page.buttonTitle ?? ""
    findButton.isHidden = page.buttonTitle == nil
    previousButton.isEnabled = pageIndex > 0
    nextButton.title = pageIndex == pages.count - 1
      ? StayAwakeNativeText.pick("Done", "完成")
      : StayAwakeNativeText.pick("Next", "下一步")
  }

  @objc private func findStayAwake() {
    onFindStayAwake()
  }

  @objc private func previousPage() {
    pageIndex = max(0, pageIndex - 1)
    updatePage()
  }

  @objc private func nextPage() {
    if pageIndex == pages.count - 1 {
      onFinish(dontShowCheckbox.state == .on)
      close()
      return
    }
    pageIndex += 1
    updatePage()
  }
}

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
  private let modeControl = NSSegmentedControl(
    labels: [
      StayAwakeNativeText.pick("For", "持续"),
      StayAwakeNativeText.pick("Until", "至")
    ],
    trackingMode: .selectOne,
    target: nil,
    action: nil
  )
  private let hoursField = FocusAwareTextField(string: "0")
  private let minutesField = FocusAwareTextField(string: "45")
  private let hoursStepper = NSStepper()
  private let minutesStepper = NSStepper()
  private let timePicker = FocusAwareDatePicker()
  private let clockView = CustomClockView()
  private let continueButton = NSButton(title: StayAwakeNativeText.pick("Continue", "继续"), target: nil, action: nil)
  private let separator = NSBox()
  private let focusHighlight = NSView()
  private let hoursLabel = NSTextField(labelWithString: StayAwakeNativeText.pick("Hours", "小时"))
  private let minutesLabel = NSTextField(labelWithString: StayAwakeNativeText.pick("Minutes", "分钟"))
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
  private let noteLabel = NSTextField(wrappingLabelWithString: StayAwakeNativeText.pick("Quick settings reflect saved defaults and automation toggles, not necessarily the current session.", "快速设置代表设置中相应项目的状态，不一定代表当前会话。"))
  private let helpButton = NSButton(title: "?", target: nil, action: nil)

  init(
    allowDisplaySleep: Bool,
    allowSystemSleepWhenDisplayOff: Bool,
    allowScreenSaver: Bool,
    stopOnLowBattery: Bool,
    lowBatteryStopPercent: Int,
    allowScreenLock: Bool,
    lockScreenAfterIdle: Bool,
    moveCursorAfterIdle: Bool,
    triggersEnabled: Bool,
    keepDiskAwake: Bool,
    showRemainingSessionTime: Bool,
    onToggle: @escaping (String, Bool) -> Void
  ) {
    self.onToggle = onToggle
    super.init(frame: NSRect(x: 0, y: 0, width: 410, height: 495))
    setup(
      allowDisplaySleep: allowDisplaySleep,
      allowSystemSleepWhenDisplayOff: allowSystemSleepWhenDisplayOff,
      allowScreenSaver: allowScreenSaver,
      stopOnLowBattery: stopOnLowBattery,
      lowBatteryStopPercent: lowBatteryStopPercent,
      allowScreenLock: allowScreenLock,
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
    layoutSection(index: 0, title: StayAwakeNativeText.pick("Session Defaults", "会话默认设置"), rowRange: 0..<5, y: &y)
    layoutSeparator(index: 0, y: y - 4)
    y += 12
    layoutSection(index: 1, title: StayAwakeNativeText.pick("System Controls", "系统控制"), rowRange: 5..<7, y: &y)
    layoutSeparator(index: 1, y: y - 4)
    y += 12
    layoutSection(index: 2, title: StayAwakeNativeText.pick("Other", "其他"), rowRange: 7..<10, y: &y)
  }

  private func setup(
    allowDisplaySleep: Bool,
    allowSystemSleepWhenDisplayOff: Bool,
    allowScreenSaver: Bool,
    stopOnLowBattery: Bool,
    lowBatteryStopPercent: Int,
    allowScreenLock: Bool,
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

    addRow(StayAwakeNativeText.pick("Allow display sleep", "允许显示器睡眠"), key: "allowDisplaySleep", enabled: allowDisplaySleep)
    addRow(StayAwakeNativeText.pick("Allow system sleep when display is off", "当显示器关闭时允许系统睡眠"), key: "allowSystemSleepWhenDisplayOff", enabled: allowSystemSleepWhenDisplayOff)
    addRow(StayAwakeNativeText.pick("Allow screen saver after 45m idle", "允许屏幕保护程序在闲置 45m 后运行"), key: "allowScreenSaver", enabled: allowScreenSaver)
    addRow(StayAwakeNativeText.pick("Allow screen lock", "允许屏幕锁定"), key: "allowScreenLock", enabled: allowScreenLock)
    addRow(StayAwakeNativeText.pick("End session below \(lowBatteryStopPercent)% battery", "当电池电量低于 \(lowBatteryStopPercent)% 时结束会话"), key: "stopOnLowBattery", enabled: stopOnLowBattery)
    addRow(StayAwakeNativeText.pick("Lock screen after 1m idle", "闲置 1m 后锁定屏幕"), key: "lockScreenAfterIdle", enabled: lockScreenAfterIdle)
    addRow(StayAwakeNativeText.pick("Move cursor after 5m idle", "闲置 5m 后移动光标"), key: "moveCursorAfterIdle", enabled: moveCursorAfterIdle)
    addRow(StayAwakeNativeText.pick("Enable triggers", "启用触发器"), key: "triggersEnabled", enabled: triggersEnabled)
    addRow(StayAwakeNativeText.pick("Enable disk wake", "启用硬盘唤醒"), key: "keepDiskAwake", enabled: keepDiskAwake)
    addRow(StayAwakeNativeText.pick("Show remaining session time in menu bar", "在菜单栏中显示剩余的会话时间"), key: "showRemainingSessionTime", enabled: showRemainingSessionTime)
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
    alert.messageText = StayAwakeNativeText.pick("Quick Settings", "快速设置")
    alert.informativeText = StayAwakeNativeText.pick("These are saved defaults and automation toggles. They affect future sessions; an already running session may need to restart before every setting fully applies.", "这里显示的是默认设置和自动化开关的保存状态。它们会影响后续会话；当前已开启的会话可能需要重新开始后才完全采用新设置。")
    alert.addButton(withTitle: StayAwakeNativeText.pick("OK", "好"))
    alert.runModal()
  }

  @objc private func rowToggled(_ sender: NSButton) {
    guard let key = sender.identifier?.rawValue else {
      return
    }
    onToggle(key, sender.state == .on)
  }
}

private final class CurrentSessionMenuView: NSView {
  private let detailFont = NSFont.systemFont(ofSize: 16, weight: .regular)
  private let titleFont = NSFont.systemFont(ofSize: 17, weight: .semibold)
  private let actionFont = NSFont.systemFont(ofSize: 16, weight: .semibold)
  private let remainingLabel = NSTextField(labelWithString: "")
  private let sourceLabel = NSTextField(labelWithString: StayAwakeNativeText.pick("Started manually", "手动开启"))
  private let displaySleepButton = NSButton(checkboxWithTitle: StayAwakeNativeText.pick("Allow display sleep", "允许显示器睡眠"), target: nil, action: nil)
  private let systemSleepButton = NSButton(checkboxWithTitle: StayAwakeNativeText.pick("Allow system sleep when display is off", "当显示器关闭时允许系统睡眠"), target: nil, action: nil)
  private let screenSaverButton = NSButton(checkboxWithTitle: StayAwakeNativeText.pick("Allow screen saver after 45m idle", "允许屏幕保护程序在闲置 45m 后运行"), target: nil, action: nil)
  private let screenLockButton = NSButton(checkboxWithTitle: StayAwakeNativeText.pick("Allow screen lock", "允许屏幕锁定"), target: nil, action: nil)
  private let stopButton = NSButton(title: StayAwakeNativeText.pick("End Current Session", "结束当前会话"), target: nil, action: nil)
  private let shortcutLabel = NSTextField(labelWithString: "⌘ X")
  private let onToggle: (String, Bool) -> Void
  private let onStop: () -> Void

  init(
    sessionEndsAt: Date?,
    allowDisplaySleep: Bool,
    allowSystemSleepWhenDisplayOff: Bool,
    allowScreenSaver: Bool,
    allowScreenLock: Bool,
    onToggle: @escaping (String, Bool) -> Void,
    onStop: @escaping () -> Void
  ) {
    self.onToggle = onToggle
    self.onStop = onStop
    super.init(frame: NSRect(x: 0, y: 0, width: 420, height: 272))
    setup(
      sessionEndsAt: sessionEndsAt,
      allowDisplaySleep: allowDisplaySleep,
      allowSystemSleepWhenDisplayOff: allowSystemSleepWhenDisplayOff,
      allowScreenSaver: allowScreenSaver,
      allowScreenLock: allowScreenLock
    )
  }

  required init?(coder: NSCoder) {
    nil
  }

  override var isFlipped: Bool {
    true
  }

  private func setup(
    sessionEndsAt: Date?,
    allowDisplaySleep: Bool,
    allowSystemSleepWhenDisplayOff: Bool,
    allowScreenSaver: Bool,
    allowScreenLock: Bool
  ) {
    let titleLabel = NSTextField(labelWithString: StayAwakeNativeText.pick("Current Session Details:", "当前会话详细信息:"))
    titleLabel.font = titleFont
    titleLabel.frame = NSRect(x: 18, y: 10, width: 360, height: 24)
    addSubview(titleLabel)

    remainingLabel.stringValue = remainingText(sessionEndsAt: sessionEndsAt)
    remainingLabel.font = detailFont
    remainingLabel.frame = NSRect(x: 36, y: 42, width: 340, height: 22)
    addSubview(remainingLabel)

    sourceLabel.font = detailFont
    sourceLabel.frame = NSRect(x: 36, y: 70, width: 340, height: 22)
    addSubview(sourceLabel)

    configure(button: displaySleepButton, key: "allowDisplaySleep", enabled: allowDisplaySleep, y: 108)
    configure(button: systemSleepButton, key: "allowSystemSleepWhenDisplayOff", enabled: allowSystemSleepWhenDisplayOff, y: 138)
    configure(button: screenSaverButton, key: "allowScreenSaver", enabled: allowScreenSaver, y: 168)
    configure(button: screenLockButton, key: "allowScreenLock", enabled: allowScreenLock, y: 198)

    stopButton.bezelStyle = .rounded
    stopButton.font = actionFont
    stopButton.controlSize = .regular
    stopButton.target = self
    stopButton.action = #selector(stopPressed)
    stopButton.keyEquivalent = "x"
    stopButton.keyEquivalentModifierMask = .command
    stopButton.frame = NSRect(x: 36, y: 234, width: 300, height: 26)
    addSubview(stopButton)

    shortcutLabel.font = detailFont
    shortcutLabel.textColor = .tertiaryLabelColor
    shortcutLabel.alignment = .right
    shortcutLabel.frame = NSRect(x: 348, y: 238, width: 46, height: 20)
    addSubview(shortcutLabel)
  }

  private func configure(button: NSButton, key: String, enabled: Bool, y: CGFloat) {
    button.font = detailFont
    button.controlSize = .regular
    button.identifier = NSUserInterfaceItemIdentifier(key)
    button.state = enabled ? .on : .off
    button.target = self
    button.action = #selector(togglePressed(_:))
    button.frame = NSRect(x: 34, y: y, width: 360, height: 24)
    addSubview(button)
  }

  private func remainingText(sessionEndsAt: Date?) -> String {
    guard let sessionEndsAt else {
      return StayAwakeNativeText.pick("Remaining time unknown", "剩余时间不确定")
    }
    let remaining = max(0, Int(sessionEndsAt.timeIntervalSinceNow.rounded(.up)))
    let hours = remaining / 3600
    let minutes = (remaining % 3600 + 59) / 60
    if hours > 0 {
      return StayAwakeNativeText.pick("\(hours)h \(minutes)m remaining", "剩余 \(hours) 小时 \(minutes) 分钟")
    }
    return StayAwakeNativeText.pick("\(max(1, minutes))m remaining", "剩余 \(max(1, minutes)) 分钟")
  }

  @objc private func togglePressed(_ sender: NSButton) {
    guard let key = sender.identifier?.rawValue else {
      return
    }
    onToggle(key, sender.state == .on)
  }

  @objc private func stopPressed() {
    onStop()
  }
}

private final class HotkeyRecorderView: NSView {
  var onRecord: (([String: Any]) -> Void)?
  var onCancel: (() -> Void)?
  private let titleLabel = NSTextField(labelWithString: StayAwakeNativeText.pick("Press a New Global Shortcut", "按下新的全局快捷键"))
  private let hintLabel = NSTextField(wrappingLabelWithString: StayAwakeNativeText.pick("Use Control / Option / Command plus a letter. Press Esc to cancel.", "建议使用 Control / Option / Command 加一个字母，Esc 取消。"))
  private let previewLabel = NSTextField(labelWithString: StayAwakeNativeText.pick("Waiting for input...", "等待输入..."))

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    setup()
  }

  required init?(coder: NSCoder) {
    nil
  }

  override var acceptsFirstResponder: Bool {
    true
  }

  private func setup() {
    wantsLayer = true
    layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

    titleLabel.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
    titleLabel.frame = NSRect(x: 22, y: 22, width: 320, height: 26)
    addSubview(titleLabel)

    hintLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
    hintLabel.textColor = .secondaryLabelColor
    hintLabel.frame = NSRect(x: 22, y: 58, width: 320, height: 44)
    addSubview(hintLabel)

    previewLabel.alignment = .center
    previewLabel.font = NSFont.monospacedSystemFont(ofSize: 28, weight: .bold)
    previewLabel.textColor = .labelColor
    previewLabel.wantsLayer = true
    previewLabel.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    previewLabel.layer?.cornerRadius = 10
    previewLabel.frame = NSRect(x: 22, y: 122, width: 320, height: 70)
    addSubview(previewLabel)
  }

  override func keyDown(with event: NSEvent) {
    if event.keyCode == UInt16(kVK_Escape) {
      onCancel?()
      return
    }

    let carbonModifiers = Self.carbonModifiers(from: event.modifierFlags)
    guard carbonModifiers != 0,
          let key = Self.displayKey(from: event),
          !key.isEmpty else {
      NSSound.beep()
      previewLabel.stringValue = StayAwakeNativeText.pick("Needs modifier + letter", "需要修饰键 + 字母")
      return
    }

    let label = "\(Self.modifierLabel(from: event.modifierFlags))\(key)"
    previewLabel.stringValue = label
    onRecord?([
      "label": label,
      "keyCode": Int(event.keyCode),
      "modifiers": Int(carbonModifiers)
    ])
  }

  private static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
    var modifiers: UInt32 = 0
    if flags.contains(.command) {
      modifiers |= UInt32(cmdKey)
    }
    if flags.contains(.option) {
      modifiers |= UInt32(optionKey)
    }
    if flags.contains(.control) {
      modifiers |= UInt32(controlKey)
    }
    if flags.contains(.shift) {
      modifiers |= UInt32(shiftKey)
    }
    return modifiers
  }

  private static func modifierLabel(from flags: NSEvent.ModifierFlags) -> String {
    var label = ""
    if flags.contains(.control) {
      label += "⌃"
    }
    if flags.contains(.option) {
      label += "⌥"
    }
    if flags.contains(.shift) {
      label += "⇧"
    }
    if flags.contains(.command) {
      label += "⌘"
    }
    return label
  }

  private static func displayKey(from event: NSEvent) -> String? {
    let text = event.charactersIgnoringModifiers?.uppercased() ?? ""
    if text.count == 1 {
      return text
    }
    return nil
  }
}

@main
class AppDelegate: FlutterAppDelegate, NSMenuDelegate, UNUserNotificationCenterDelegate {
  private struct ShellProcessResult {
    let terminationStatus: Int32
    let stdout: String
    let stderr: String
  }

  private var statusItem: NSStatusItem?
  private var statusMenu = NSMenu()
  private var channel: FlutterMethodChannel?
  private var onboardingWindowController: StayAwakeOnboardingWindowController?
  private var assertionID = IOPMAssertionID(0)
  private var systemSleepAssertionID = IOPMAssertionID(0)
  private var assertionActive = false
  private var systemSleepAssertionActive = false
  private let onboardingCompletedKey = "StayAwakeOnboardingCompleted"
  private let screenLockPreferenceBackupKey = "StayAwakeScreenLockPreferenceBackup"
  private let disableSleepPreferenceBackupKey = "StayAwakeDisableSleepPreferenceBackup"
  private let powerProtectLastDiagnosticKey = "StayAwakePowerProtectLastDiagnostic"
  private let powerProtectScriptPath = "/Library/PrivilegedHelperTools/com.linzhibin.stayawake.powerprotect"
  private let powerProtectSudoersPath = "/private/etc/sudoers.d/stayawake_powerProtect"
  private let powerProtectSudoersMarker = "# StayAwake Power Protect"
  private var sessionEndsAt: Date?
  private var currentSessionSource = "manual"
  private var sessionTimer: Timer?
  private var preventDisplaySleep = true
  private var allowScreenSaver = false
  private var startWhenPluggedIn = false
  private var stopOnLowBattery = true
  private var appTriggerEnabled = false
  private var appTriggerName = ""
  private var appTriggerBundleIdentifier = ""
  private var hideHelperApps = true
  private var languageMode = "system"
  private var downloadTriggerEnabled = false
  private var startAtLogin = false
  private var lowBatteryStopPercent = 20
  private var customDurationMinutes = 45
  private var allowSystemSleepWhenDisplayOff = true
  private var allowScreenLock = false
  private var lockScreenAfterIdle = false
  private var startSessionAfterWake = false
  private var showNotifications = true
  private var forceSleepEndsSession = false
  private var lockWhenDisplayOff = false
  private var allowDisplaySleepWhenLocked = false
  private var moveCursorAfterIdle = false
  private var stopMovingCursorAfterMinutes = 30
  private var endSessionOnUserSwitch = false
  private var triggersEnabled = true
  private var keepDiskAwake = false
  private var diskWakeIntervalSeconds = 10
  private var diskWakePath = ""
  private var diskWakeName = ""
  private var globalHotkeyEnabled = false
  private var globalHotkeyKeyCode = UInt32(kVK_ANSI_S)
  private var globalHotkeyModifiers = UInt32(controlKey | optionKey | cmdKey)
  private var globalHotkeyLabel = "⌃⌥⌘S"
  private var activeSessionHotkey = "End current and start new"
  private var notificationReminderMinutes = 60
  private var notifyAutomationStart = true
  private var notifyAutomationEnd = true
  private var playStartStopSound = true
  private var playExtendSound = true
  private var clearDeliveredNotifications = true
  private var showRemainingSessionTime = false
  private var screenLockedByStayAwake = false
  private var statusTitleTimer: Timer?
  private var lockScreenTimer: Timer?
  private var moveCursorTimer: Timer?
  private var stopMovingCursorTimer: Timer?
  private var diskWakeTimer: Timer?
  private var screenSaverTimer: Timer?
  private var notificationReminderTimer: Timer?
  private var hotKeyRef: EventHotKeyRef?
  private var hotKeyHandlerRef: EventHandlerRef?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    restoreScreenLockPreferencesIfNeeded()
    restoreDisableSleepPreferenceIfNeeded()
    configureNotifications()
    configureWorkspaceObservers()
    configureGlobalHotkeyHandler()
    configureStatusItem()
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
      self?.configureMainWindowMenu()
      self?.configureStatusItemIfNeeded()
      self?.showOnboardingIfNeeded()
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

  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    showMainWindow()
    return true
  }

  override func applicationDidBecomeActive(_ notification: Notification) {
    configureMainWindowMenu()
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationWillTerminate(_ notification: Notification) {
    unregisterGlobalHotkey()
    restoreScreenLockPreferencesIfNeeded()
    restoreDisableSleepPreferenceIfNeeded()
    NSWorkspace.shared.notificationCenter.removeObserver(self)
  }

  private func configureStatusItem() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    statusItem?.isVisible = true
    statusItem?.button?.image = nil
    statusItem?.button?.imagePosition = .noImage
    statusItem?.button?.title = "STAY"
    statusMenu.delegate = self
    rebuildMenu()
    statusItem?.menu = statusMenu
  }

  private func configureStatusItemIfNeeded() {
    guard statusItem == nil || statusItem?.button == nil else {
      statusItem?.isVisible = true
      rebuildMenu()
      return
    }
    configureStatusItem()
  }

  private func configureMainWindowMenu() {
    guard let windowMenu = NSApp.mainMenu?.items.first(where: { $0.submenu?.identifier == NSUserInterfaceItemIdentifier("NSWindowMenu") || $0.title == "Window" })?.submenu else {
      return
    }
    let representedObject = "show-main-window"
    let title = StayAwakeNativeText.pick("Open Main Window", "打开主窗口")
    if windowMenu.items.contains(where: { ($0.representedObject as? String) == representedObject || $0.title == title }) {
      return
    }
    let item = NSMenuItem(
      title: title,
      action: #selector(showMainWindow),
      keyEquivalent: "0"
    )
    item.target = self
    item.representedObject = representedObject
    if let firstSeparatorIndex = windowMenu.items.firstIndex(where: { $0.isSeparatorItem }) {
      windowMenu.insertItem(item, at: firstSeparatorIndex)
    } else {
      windowMenu.addItem(item)
    }
  }

  private func recreateStatusItem() {
    if let statusItem {
      NSStatusBar.system.removeStatusItem(statusItem)
    }
    statusItem = nil
    configureStatusItem()
  }

  private func showOnboardingIfNeeded() {
    guard !UserDefaults.standard.bool(forKey: onboardingCompletedKey) else {
      return
    }
    showOnboarding()
  }

  private func showOnboarding() {
    if let onboardingWindowController {
      onboardingWindowController.showWindow(nil)
      return
    }

    let controller = StayAwakeOnboardingWindowController(
      onFindStayAwake: { [weak self] in
        self?.showStatusMenuFromOnboarding()
      },
      onFinish: { [weak self] dontShowAgain in
        guard let self else {
          return
        }
        if dontShowAgain {
          UserDefaults.standard.set(true, forKey: self.onboardingCompletedKey)
        }
        self.onboardingWindowController = nil
      }
    )
    onboardingWindowController = controller
    controller.showWindow(nil)
  }

  private func showStatusMenuFromOnboarding() {
    configureStatusItemIfNeeded()
    guard let button = statusItem?.button else {
      return
    }
    NSApp.activate(ignoringOtherApps: true)
    button.performClick(nil)
  }

  private func configureNotifications() {
    UNUserNotificationCenter.current().delegate = self
  }

  private func requestNotificationAuthorization() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(macOS 11.0, *) {
      completionHandler([.banner, .list, .sound])
    } else {
      completionHandler([.alert, .sound])
    }
  }

  private func configureWorkspaceObservers() {
    let center = NSWorkspace.shared.notificationCenter
    center.addObserver(self, selector: #selector(workspaceDidWake), name: NSWorkspace.didWakeNotification, object: nil)
    center.addObserver(self, selector: #selector(workspaceWillSleep), name: NSWorkspace.willSleepNotification, object: nil)
    center.addObserver(self, selector: #selector(screensDidSleep), name: NSWorkspace.screensDidSleepNotification, object: nil)
    center.addObserver(self, selector: #selector(sessionDidResignActive), name: NSWorkspace.sessionDidResignActiveNotification, object: nil)
    center.addObserver(self, selector: #selector(sessionDidBecomeActive), name: NSWorkspace.sessionDidBecomeActiveNotification, object: nil)
  }

  private func configureGlobalHotkeyHandler() {
    var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
    let selfPointer = Unmanaged.passUnretained(self).toOpaque()
    InstallEventHandler(
      GetApplicationEventTarget(),
      { _, _, userData in
        guard let userData else {
          return noErr
        }
        let delegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
        delegate.handleGlobalHotkeyPressed()
        return noErr
      },
      1,
      &eventType,
      selfPointer,
      &hotKeyHandlerRef
    )
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startSession":
      let args = call.arguments as? [String: Any]
      syncPreferences(args: args)
      let durationSeconds = args?["durationSeconds"] as? Int
      preventDisplaySleep = args?["preventDisplaySleep"] as? Bool ?? preventDisplaySleep
      allowScreenSaver = args?["allowScreenSaver"] as? Bool ?? allowScreenSaver
      currentSessionSource = args?["source"] as? String ?? "manual"
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
    case "setLoginItemEnabled":
      let enabled = call.arguments as? Bool ?? false
      result(setLoginItemEnabled(enabled))
    case "getLoginItemStatus":
      result(loginItemStatusPayload())
    case "getPowerProtectHelperStatus":
      result(powerProtectHelperStatusPayload())
    case "installPowerProtectHelper":
      let success = installPowerProtectHelperWithAdministratorPrivileges()
      result(powerProtectHelperStatusPayload(success: success))
    case "removePowerProtectHelper":
      let success = removePowerProtectHelperWithAdministratorPrivileges()
      result(powerProtectHelperStatusPayload(success: success))
    case "recordGlobalHotkey":
      result(recordGlobalHotkey())
    case "getDiskVolumes":
      result(diskVolumesPayload())
    case "chooseDiskWakePath":
      result(chooseDiskWakePath())
    case "clearDeliveredNotifications":
      clearDeliveredStayAwakeNotifications()
      result(true)
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
    if let nextStartAtLogin = args["startAtLogin"] as? Bool,
       nextStartAtLogin != startAtLogin {
      _ = setLoginItemEnabled(nextStartAtLogin)
    } else {
      startAtLogin = currentLoginItemEnabled(defaultValue: startAtLogin)
    }
    lowBatteryStopPercent = args["lowBatteryStopPercent"] as? Int ?? lowBatteryStopPercent
    customDurationMinutes = args["customDurationMinutes"] as? Int ?? customDurationMinutes
    allowSystemSleepWhenDisplayOff = args["allowSystemSleepWhenDisplayOff"] as? Bool ?? allowSystemSleepWhenDisplayOff
    allowScreenLock = args["allowScreenLock"] as? Bool ?? allowScreenLock
    lockScreenAfterIdle = args["lockScreenAfterIdle"] as? Bool ?? lockScreenAfterIdle
    startSessionAfterWake = args["startSessionAfterWake"] as? Bool ?? startSessionAfterWake
    showNotifications = args["showNotifications"] as? Bool ?? showNotifications
    forceSleepEndsSession = args["forceSleepEndsSession"] as? Bool ?? forceSleepEndsSession
    lockWhenDisplayOff = args["lockWhenDisplayOff"] as? Bool ?? lockWhenDisplayOff
    allowDisplaySleepWhenLocked = args["allowDisplaySleepWhenLocked"] as? Bool ?? allowDisplaySleepWhenLocked
    moveCursorAfterIdle = args["moveCursorAfterIdle"] as? Bool ?? moveCursorAfterIdle
    stopMovingCursorAfterMinutes = args["stopMovingCursorAfterMinutes"] as? Int ?? stopMovingCursorAfterMinutes
    endSessionOnUserSwitch = args["endSessionOnUserSwitch"] as? Bool ?? endSessionOnUserSwitch
    triggersEnabled = args["triggersEnabled"] as? Bool ?? triggersEnabled
    keepDiskAwake = args["keepDiskAwake"] as? Bool ?? keepDiskAwake
    diskWakeIntervalSeconds = args["diskWakeIntervalSeconds"] as? Int ?? diskWakeIntervalSeconds
    diskWakePath = args["diskWakePath"] as? String ?? diskWakePath
    diskWakeName = args["diskWakeName"] as? String ?? diskWakeName
    globalHotkeyEnabled = args["globalHotkeyEnabled"] as? Bool ?? globalHotkeyEnabled
    if let keyCode = args["globalHotkeyKeyCode"] as? Int {
      globalHotkeyKeyCode = UInt32(max(0, keyCode))
    }
    if let modifiers = args["globalHotkeyModifiers"] as? Int {
      globalHotkeyModifiers = UInt32(max(0, modifiers))
    }
    globalHotkeyLabel = args["globalHotkeyLabel"] as? String ?? globalHotkeyLabel
    activeSessionHotkey = args["activeSessionHotkey"] as? String ?? activeSessionHotkey
    notificationReminderMinutes = args["sessionReminderMinutes"] as? Int ?? notificationReminderMinutes
    notifyAutomationStart = args["notifyAutomationStart"] as? Bool ?? notifyAutomationStart
    notifyAutomationEnd = args["notifyAutomationEnd"] as? Bool ?? notifyAutomationEnd
    playStartStopSound = args["playStartStopSound"] as? Bool ?? playStartStopSound
    playExtendSound = args["playExtendSound"] as? Bool ?? playExtendSound
    clearDeliveredNotifications = args["clearDeliveredNotifications"] as? Bool ?? clearDeliveredNotifications
    showRemainingSessionTime = args["showRemainingSessionTime"] as? Bool ?? showRemainingSessionTime
    hideHelperApps = args["hideHelperApps"] as? Bool ?? hideHelperApps
    languageMode = args["languageMode"] as? String ?? languageMode
    StayAwakeNativeText.languageMode = languageMode
    StayAwakeNativeText.effectiveLanguageCode = args["effectiveLanguageCode"] as? String ?? StayAwakeNativeText.effectiveLanguageCode
    appTriggerName = args["appTriggerName"] as? String ?? appTriggerName
    appTriggerBundleIdentifier = args["appTriggerBundleId"] as? String ?? appTriggerBundleIdentifier
    if let rules = args["rules"] as? [String: Bool] {
      startWhenPluggedIn = rules["plugged-in"] ?? startWhenPluggedIn
      stopOnLowBattery = rules["low-battery"] ?? stopOnLowBattery
      appTriggerEnabled = rules["app-trigger"] ?? appTriggerEnabled
      downloadTriggerEnabled = rules["download-trigger"] ?? downloadTriggerEnabled
    }
    updateGlobalHotkeyRegistration()
    if showNotifications {
      requestNotificationAuthorization()
    }
    if assertionActive {
      acquireAssertion()
      updateClosedDisplaySleepPolicyForSession()
      updateScreenLockPolicyForSession()
    }
    configureSessionAuxiliaryTimers()
    rebuildMenu()
  }

  private func currentLoginItemEnabled(defaultValue: Bool = false) -> Bool {
    if #available(macOS 13.0, *) {
      return SMAppService.mainApp.status == .enabled
    }
    return UserDefaults.standard.bool(forKey: "StayAwakeStartAtLoginFallback") || defaultValue
  }

  private func setLoginItemEnabled(_ enabled: Bool) -> [String: Any] {
    var supported = false
    var success = true
    var message = enabled ? "Login item preference saved." : "Login item disabled."

    if #available(macOS 13.0, *) {
      supported = true
      do {
        if enabled {
          try SMAppService.mainApp.register()
        } else {
          try SMAppService.mainApp.unregister()
        }
        startAtLogin = SMAppService.mainApp.status == .enabled
        message = startAtLogin ? "Native login item enabled." : "Native login item disabled."
      } catch {
        success = false
        startAtLogin = SMAppService.mainApp.status == .enabled
        message = error.localizedDescription
      }
    } else {
      UserDefaults.standard.set(enabled, forKey: "StayAwakeStartAtLoginFallback")
      startAtLogin = enabled
      message = "Saved locally. Native Login Item requires macOS 13 or later."
    }

    rebuildMenu()
    channel?.invokeMethod("nativeStatusChanged", arguments: statusPayload())
    return [
      "supported": supported,
      "success": success,
      "enabled": startAtLogin,
      "message": message
    ]
  }

  func menuNeedsUpdate(_ menu: NSMenu) {
    guard menu === statusMenu else {
      return
    }
    rebuildMenu()
  }

  private func loginItemStatusPayload() -> [String: Any] {
    [
      "supported": {
        if #available(macOS 13.0, *) {
          return true
        }
        return false
      }(),
      "enabled": currentLoginItemEnabled(defaultValue: startAtLogin)
    ]
  }

  private func startSession(durationSeconds: Int?) {
    acquireAssertion()
    updateClosedDisplaySleepPolicyForSession()
    updateScreenLockPolicyForSession()

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
    notifySessionStarted(durationSeconds: durationSeconds)
    channel?.invokeMethod("nativeStatusChanged", arguments: statusPayload())
  }

  private func acquireAssertion() {
    releaseAssertion()
    let displaySleepAllowedForLock = allowDisplaySleepWhenLocked && screenLockedByStayAwake
    let assertionType = preventDisplaySleep && !displaySleepAllowedForLock
      ? kIOPMAssertionTypeNoDisplaySleep
      : kIOPMAssertionTypeNoIdleSleep
    let reason = "StayAwake active session" as CFString
    let status = IOPMAssertionCreateWithName(
      assertionType as CFString,
      IOPMAssertionLevel(kIOPMAssertionLevelOn),
      reason,
      &assertionID
    )
    assertionActive = status == kIOReturnSuccess

    if !allowSystemSleepWhenDisplayOff {
      let systemReason = "StayAwake active session - display off keeps system awake" as CFString
      let systemStatus = IOPMAssertionCreateWithName(
        kIOPMAssertionTypePreventSystemSleep as CFString,
        IOPMAssertionLevel(kIOPMAssertionLevelOn),
        systemReason,
        &systemSleepAssertionID
      )
      systemSleepAssertionActive = systemStatus == kIOReturnSuccess
    }
  }

  private func refreshCurrentAssertionPolicy() {
    guard assertionActive else {
      return
    }
    acquireAssertion()
    updateClosedDisplaySleepPolicyForSession()
    updateScreenLockPolicyForSession()
    configureSessionAuxiliaryTimers()
    channel?.invokeMethod("nativeStatusChanged", arguments: statusPayload())
  }

  private func stopSession() {
    let wasActive = assertionActive
    releaseAssertion()
    restoreDisableSleepPreferenceIfNeeded()
    restoreScreenLockPreferencesIfNeeded()
    sessionEndsAt = nil
    sessionTimer?.invalidate()
    sessionTimer = nil
    statusTitleTimer?.invalidate()
    statusTitleTimer = nil
    lockScreenTimer?.invalidate()
    lockScreenTimer = nil
    moveCursorTimer?.invalidate()
    moveCursorTimer = nil
    stopMovingCursorTimer?.invalidate()
    stopMovingCursorTimer = nil
    diskWakeTimer?.invalidate()
    diskWakeTimer = nil
    screenSaverTimer?.invalidate()
    screenSaverTimer = nil
    notificationReminderTimer?.invalidate()
    notificationReminderTimer = nil
    rebuildMenu()
    if wasActive {
      notifySessionStopped()
    }
    channel?.invokeMethod("nativeStatusChanged", arguments: statusPayload())
  }

  private func releaseAssertion() {
    if assertionActive {
      IOPMAssertionRelease(assertionID)
    }
    if systemSleepAssertionActive {
      IOPMAssertionRelease(systemSleepAssertionID)
    }
    assertionID = IOPMAssertionID(0)
    systemSleepAssertionID = IOPMAssertionID(0)
    assertionActive = false
    systemSleepAssertionActive = false
  }

  private func updateClosedDisplaySleepPolicyForSession() {
    guard assertionActive else {
      recordPowerProtectDiagnostic(stage: "closedDisplaySkippedInactive")
      restoreDisableSleepPreferenceIfNeeded()
      return
    }
    guard !allowSystemSleepWhenDisplayOff else {
      recordPowerProtectDiagnostic(stage: "closedDisplaySkippedAllowed")
      restoreDisableSleepPreferenceIfNeeded()
      return
    }
    recordPowerProtectDiagnostic(stage: "closedDisplayApplyRequested")
    applyDisableSleepForClosedDisplayIfNeeded()
  }

  private func applyDisableSleepForClosedDisplayIfNeeded() {
    let backupExists = UserDefaults.standard.dictionary(forKey: disableSleepPreferenceBackupKey) != nil
    let alreadyDisabled = currentDisableSleepEnabled()
    if backupExists, alreadyDisabled {
      recordPowerProtectDiagnostic(stage: "disableSleepAlreadyEnabled")
      return
    }

    let wasDisableSleepEnabled = alreadyDisabled
    if !wasDisableSleepEnabled {
      guard setDisableSleepWithAdministratorPrivileges(enabled: true) else {
        return
      }
      guard waitForDisableSleepState(true) else {
        recordPowerProtectDiagnostic(stage: "disableSleepVerificationFailed")
        return
      }
    }
    if UserDefaults.standard.dictionary(forKey: disableSleepPreferenceBackupKey) == nil {
      UserDefaults.standard.set([
        "wasDisableSleepEnabled": wasDisableSleepEnabled
      ], forKey: disableSleepPreferenceBackupKey)
    }
    recordPowerProtectDiagnostic(stage: "disableSleepEnabled")
  }

  private func restoreDisableSleepPreferenceIfNeeded() {
    guard let backup = UserDefaults.standard.dictionary(forKey: disableSleepPreferenceBackupKey) else {
      return
    }
    let wasDisableSleepEnabled = backup["wasDisableSleepEnabled"] as? Bool ?? false
    if wasDisableSleepEnabled ||
       (setDisableSleepWithAdministratorPrivileges(enabled: false) && waitForDisableSleepState(false)) {
      UserDefaults.standard.removeObject(forKey: disableSleepPreferenceBackupKey)
    }
  }

  private func currentDisableSleepEnabled() -> Bool {
    guard let output = shellOutput(path: "/usr/bin/pmset", arguments: ["-g", "everything"]) else {
      return false
    }
    return output
      .split(separator: "\n")
      .contains { line in
        line.trimmingCharacters(in: .whitespacesAndNewlines).range(
          of: #"^(disablesleep|SleepDisabled)\s+1(\s|$)"#,
          options: [.regularExpression, .caseInsensitive]
        ) != nil
      }
  }

  private func waitForDisableSleepState(_ expected: Bool, timeout: TimeInterval = 8) -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
      if currentDisableSleepEnabled() == expected {
        return true
      }
      Thread.sleep(forTimeInterval: 0.25)
    }
    return currentDisableSleepEnabled() == expected
  }

  private func setDisableSleepWithAdministratorPrivileges(enabled: Bool) -> Bool {
    let action = enabled ? "enable" : "disable"
    if runPowerProtect(action: action) {
      return true
    }
    return runDisableSleepWithAdministratorAuthorization(enabled: enabled)
  }

  private func runPowerProtect(action: String) -> Bool {
    guard let result = runPowerProtectResult(action: action) else {
      recordPowerProtectDiagnostic(stage: "helperLaunchFailed", action: action)
      NSLog("StayAwake power protect \(action) failed to launch sudo helper")
      return false
    }
    guard result.terminationStatus == 0 else {
      let stderr = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
      let stdout = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
      recordPowerProtectDiagnostic(
        stage: "helperFailed",
        action: action,
        status: Int(result.terminationStatus),
        stdout: stdout,
        stderr: stderr
      )
      NSLog("StayAwake power protect \(action) failed with status \(result.terminationStatus), stdout: \(stdout), stderr: \(stderr)")
      return false
    }
    recordPowerProtectDiagnostic(
      stage: "helperSucceeded",
      action: action,
      status: Int(result.terminationStatus),
      stdout: result.stdout.trimmingCharacters(in: .whitespacesAndNewlines),
      stderr: result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
    )
    return true
  }

  private func runPowerProtectResult(action: String) -> ShellProcessResult? {
    runProcessResult(path: "/usr/bin/sudo", arguments: ["-n", powerProtectScriptPath, action])
  }

  private func runDisableSleepWithAdministratorAuthorization(enabled: Bool) -> Bool {
    let value = enabled ? "1" : "0"
    let command = "/usr/bin/pmset -a disablesleep \(value)"
    let script = "do shell script \(appleScriptLiteral(command)) with administrator privileges"
    guard let result = runProcessResult(path: "/usr/bin/osascript", arguments: ["-e", script]) else {
      recordPowerProtectDiagnostic(stage: "authorizationLaunchFailed", action: "disablesleep-\(value)")
      return false
    }
    let stdout = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    let stderr = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
    guard result.terminationStatus == 0 else {
      recordPowerProtectDiagnostic(
        stage: "authorizationFailed",
        action: "disablesleep-\(value)",
        status: Int(result.terminationStatus),
        stdout: stdout,
        stderr: stderr
      )
      return false
    }
    recordPowerProtectDiagnostic(
      stage: "authorizationSucceeded",
      action: "disablesleep-\(value)",
      status: Int(result.terminationStatus),
      stdout: stdout,
      stderr: stderr
    )
    return true
  }

  private func powerProtectHelperInstalled() -> Bool {
    powerProtectHelperFilesExist() || powerProtectHelperUsableWithoutPassword()
  }

  private func powerProtectHelperFilesExist() -> Bool {
    let fileManager = FileManager.default
    return fileManager.fileExists(atPath: powerProtectScriptPath)
      || fileManager.fileExists(atPath: powerProtectSudoersPath)
  }

  private func powerProtectHelperUsableWithoutPassword() -> Bool {
    guard FileManager.default.isExecutableFile(atPath: powerProtectScriptPath) else {
      return false
    }
    if powerProtectSudoersRuleIsReadableAndValid() {
      return true
    }
    return powerProtectHelperCanRunWithoutPassword()
  }

  private func powerProtectSudoersRuleIsReadableAndValid() -> Bool {
    guard FileManager.default.fileExists(atPath: powerProtectSudoersPath),
          let sudoers = try? String(contentsOfFile: powerProtectSudoersPath, encoding: .utf8) else {
      return false
    }
    return sudoers.contains(powerProtectSudoersMarker)
      && sudoers.contains(powerProtectScriptPath)
  }

  private func powerProtectHelperCanRunWithoutPassword() -> Bool {
    guard let result = runPowerProtectResult(action: "status") else {
      return false
    }
    if result.terminationStatus == 0 {
      return true
    }
    let stderr = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
    return result.terminationStatus == 1 && stderr.isEmpty
  }

  private func powerProtectHelperStatusPayload(success: Bool? = nil) -> [String: Any] {
    var payload: [String: Any] = [
      "installed": powerProtectHelperInstalled(),
      "hasLocalHelperFiles": powerProtectHelperFilesExist(),
      "usableWithoutPassword": powerProtectHelperUsableWithoutPassword(),
      "scriptPath": powerProtectScriptPath,
      "sudoersPath": powerProtectSudoersPath
    ]
    if let diagnostic = UserDefaults.standard.dictionary(forKey: powerProtectLastDiagnosticKey) {
      payload["lastDiagnostic"] = diagnostic
    }
    if let success {
      payload["success"] = success
    }
    return payload
  }

  private func recordPowerProtectDiagnostic(
    stage: String,
    action: String? = nil,
    status: Int? = nil,
    stdout: String? = nil,
    stderr: String? = nil
  ) {
    var payload: [String: Any] = [
      "stage": stage,
      "timestamp": Date().timeIntervalSince1970,
      "assertionActive": assertionActive,
      "allowSystemSleepWhenDisplayOff": allowSystemSleepWhenDisplayOff
    ]
    if let action {
      payload["action"] = action
    }
    if let status {
      payload["status"] = status
    }
    if let stdout {
      payload["stdout"] = stdout
    }
    if let stderr {
      payload["stderr"] = stderr
    }
    UserDefaults.standard.set(payload, forKey: powerProtectLastDiagnosticKey)
  }

  private func installPowerProtectHelperWithAdministratorPrivileges() -> Bool {
    guard confirmPowerProtectInstall() else {
      return false
    }
    let script = "do shell script \(appleScriptLiteral(powerProtectInstallShellCommand())) with administrator privileges"
    return runProcess(path: "/usr/bin/osascript", arguments: ["-e", script])
  }

  private func removePowerProtectHelperWithAdministratorPrivileges() -> Bool {
    guard powerProtectHelperInstalled() else {
      restoreDisableSleepPreferenceIfNeeded()
      return true
    }
    guard confirmPowerProtectRemoval() else {
      return false
    }
    let shouldRestoreDisableSleep = shouldRestoreDisableSleepBeforeHelperRemoval()
    let script = "do shell script \(appleScriptLiteral(powerProtectRemovalShellCommand(restoreDisableSleep: shouldRestoreDisableSleep))) with administrator privileges"
    let success = runProcess(path: "/usr/bin/osascript", arguments: ["-e", script])
    if success {
      UserDefaults.standard.removeObject(forKey: disableSleepPreferenceBackupKey)
    }
    return success
  }

  private func shouldRestoreDisableSleepBeforeHelperRemoval() -> Bool {
    guard let backup = UserDefaults.standard.dictionary(forKey: disableSleepPreferenceBackupKey) else {
      return false
    }
    return !(backup["wasDisableSleepEnabled"] as? Bool ?? false)
  }

  private func confirmPowerProtectInstall() -> Bool {
    NSApp.activate(ignoringOtherApps: true)
    let alert = NSAlert()
    alert.alertStyle = .informational
    alert.messageText = StayAwakeNativeText.pick("Install StayAwake closed-display helper?", "安装 StayAwake 合盖助手？")
    alert.informativeText = StayAwakeNativeText.pick("To keep your MacBook awake after closing the lid, StayAwake needs one administrator authorization to install a restricted helper. After installation, sessions can use the helper without asking for an osascript administrator password every time.", "为了在合上 MacBook 盖子后继续保持唤醒，StayAwake 需要一次管理员授权安装一个受限 helper。安装后，会话开始和结束会使用免交互的 helper，不会每次都要求输入 osascript 管理员密码。")
    alert.addButton(withTitle: StayAwakeNativeText.pick("Install", "安装"))
    alert.addButton(withTitle: StayAwakeNativeText.pick("Cancel", "取消"))
    return alert.runModal() == .alertFirstButtonReturn
  }

  private func confirmPowerProtectRemoval() -> Bool {
    NSApp.activate(ignoringOtherApps: true)
    let alert = NSAlert()
    alert.alertStyle = .warning
    alert.messageText = StayAwakeNativeText.pick("Remove closed-display helper?", "移除合盖助手？")
    alert.informativeText = StayAwakeNativeText.pick(
      "StayAwake will remove its restricted helper and sudoers rule. Future closed-display sessions may ask for administrator authorization again if you reinstall the helper.",
      "StayAwake 将移除受限 helper 和 sudoers 规则。之后如果重新安装 helper，合盖防睡眠会话可能会再次请求管理员授权。"
    )
    alert.addButton(withTitle: StayAwakeNativeText.pick("Remove Helper", "移除助手"))
    alert.addButton(withTitle: StayAwakeNativeText.pick("Cancel", "取消"))
    return alert.runModal() == .alertFirstButtonReturn
  }

  private func showPowerProtectInstallResult(success: Bool) {
    NSApp.activate(ignoringOtherApps: true)
    let alert = NSAlert()
    alert.alertStyle = success ? .informational : .warning
    alert.messageText = success
      ? StayAwakeNativeText.pick("Closed-display helper installed", "合盖助手已安装")
      : StayAwakeNativeText.pick("Closed-display helper was not installed", "合盖助手未安装")
    alert.informativeText = success
      ? StayAwakeNativeText.pick("Future closed-display keep-awake sessions will use the restricted helper without showing an osascript administrator prompt every time.", "之后开启合盖防睡眠会话时，StayAwake 会使用受限 helper，不再每次弹出 osascript 管理员密码框。")
      : StayAwakeNativeText.pick("StayAwake can still run normal keep-awake sessions, but closed-display sessions may need authorization again.", "StayAwake 仍可使用普通防睡眠会话，但合盖防睡眠可能需要再次授权。")
    alert.addButton(withTitle: StayAwakeNativeText.pick("OK", "好"))
    alert.runModal()
  }

  private func showPowerProtectRemovalResult(success: Bool) {
    NSApp.activate(ignoringOtherApps: true)
    let alert = NSAlert()
    alert.alertStyle = success ? .informational : .warning
    alert.messageText = success
      ? StayAwakeNativeText.pick("Closed-display helper removed", "合盖助手已移除")
      : StayAwakeNativeText.pick("Closed-display helper was not removed", "合盖助手未移除")
    alert.informativeText = success
      ? StayAwakeNativeText.pick("The helper script and sudoers rule have been removed from this Mac.", "helper 脚本和 sudoers 规则已从这台 Mac 移除。")
      : StayAwakeNativeText.pick("StayAwake could not remove the helper. You can try again from Settings.", "StayAwake 未能移除 helper。你可以在设置中重试。")
    alert.addButton(withTitle: StayAwakeNativeText.pick("OK", "好"))
    alert.runModal()
  }

  private func powerProtectInstallShellCommand() -> String {
    """
    set -eu
    /bin/mkdir -p /Library/PrivilegedHelperTools /private/etc/sudoers.d
    /bin/cat > \(shellQuoted(powerProtectScriptPath)) <<'STAYAWAKE_POWER_PROTECT'
    #!/bin/sh
    set -eu

    case "${1:-}" in
      enable)
        /usr/bin/pmset -a disablesleep 1
        ;;
      disable)
        /usr/bin/pmset -a disablesleep 0
        ;;
      status)
        /usr/bin/pmset -g everything | /usr/bin/grep -Ei '^[[:space:]]*(disablesleep|SleepDisabled)[[:space:]]+1([[:space:]]|$)' >/dev/null
        ;;
      *)
        echo "Usage: stayawake-powerprotect enable|disable|status" >&2
        exit 64
        ;;
    esac
    STAYAWAKE_POWER_PROTECT
    /usr/sbin/chown root:wheel \(shellQuoted(powerProtectScriptPath))
    /bin/chmod 755 \(shellQuoted(powerProtectScriptPath))
    /bin/cat > \(shellQuoted(powerProtectSudoersPath)) <<'STAYAWAKE_POWER_PROTECT_SUDOERS'
    \(powerProtectSudoersMarker)
    %admin ALL=(root) NOPASSWD: \(powerProtectScriptPath) enable, \(powerProtectScriptPath) disable, \(powerProtectScriptPath) status
    STAYAWAKE_POWER_PROTECT_SUDOERS
    /usr/sbin/chown root:wheel \(shellQuoted(powerProtectSudoersPath))
    /bin/chmod 440 \(shellQuoted(powerProtectSudoersPath))
    /usr/sbin/visudo -cf \(shellQuoted(powerProtectSudoersPath))
    """
  }

  private func powerProtectRemovalShellCommand(restoreDisableSleep: Bool) -> String {
    """
    set -eu
    if [ \(restoreDisableSleep ? "1" : "0") -eq 1 ]; then
      /usr/bin/pmset -a disablesleep 0 || true
    fi
    /bin/rm -f \(shellQuoted(powerProtectScriptPath))
    /bin/rm -f \(shellQuoted(powerProtectSudoersPath))
    """
  }

  private func shellOutput(path: String, arguments: [String]) -> String? {
    guard let result = runProcessResult(path: path, arguments: arguments),
          result.terminationStatus == 0 else {
      return nil
    }
    return result.stdout
  }

  private func runProcess(path: String, arguments: [String]) -> Bool {
    runProcessResult(path: path, arguments: arguments)?.terminationStatus == 0
  }

  private func runProcessResult(path: String, arguments: [String]) -> ShellProcessResult? {
    let process = Process()
    let outputPipe = Pipe()
    let errorPipe = Pipe()
    process.executableURL = URL(fileURLWithPath: path)
    process.arguments = arguments
    process.standardOutput = outputPipe
    process.standardError = errorPipe
    do {
      try process.run()
    } catch {
      return nil
    }
    var stdoutData = Data()
    var stderrData = Data()
    let readGroup = DispatchGroup()
    readGroup.enter()
    DispatchQueue.global(qos: .utility).async {
      stdoutData = outputPipe.fileHandleForReading.readDataToEndOfFile()
      readGroup.leave()
    }
    readGroup.enter()
    DispatchQueue.global(qos: .utility).async {
      stderrData = errorPipe.fileHandleForReading.readDataToEndOfFile()
      readGroup.leave()
    }
    process.waitUntilExit()
    readGroup.wait()
    let stdout = String(
      data: stdoutData,
      encoding: .utf8
    ) ?? ""
    let stderr = String(
      data: stderrData,
      encoding: .utf8
    ) ?? ""
    return ShellProcessResult(
      terminationStatus: process.terminationStatus,
      stdout: stdout,
      stderr: stderr
    )
  }

  private func appleScriptLiteral(_ value: String) -> String {
    let escaped = value
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\"", with: "\\\"")
    return "\"\(escaped)\""
  }

  private func shellQuoted(_ value: String) -> String {
    "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
  }

  private func updateScreenLockPolicyForSession() {
    guard assertionActive, !allowScreenLock else {
      restoreScreenLockPreferencesIfNeeded()
      return
    }
    applyScreenLockPrevention()
  }

  private func applyScreenLockPrevention() {
    backupScreenLockPreferencesIfNeeded()
    setScreenSaverPreference("askForPassword", value: 0)
    setScreenSaverPreference("askForPasswordDelay", value: Int(Int32.max))
    synchronizeScreenSaverPreferences()
  }

  private func backupScreenLockPreferencesIfNeeded() {
    guard UserDefaults.standard.dictionary(forKey: screenLockPreferenceBackupKey) == nil else {
      return
    }
    let askForPassword = screenSaverPreference("askForPassword")
    let askForPasswordDelay = screenSaverPreference("askForPasswordDelay")
    UserDefaults.standard.set([
      "hadAskForPassword": askForPassword != nil,
      "askForPassword": askForPassword ?? 0,
      "hadAskForPasswordDelay": askForPasswordDelay != nil,
      "askForPasswordDelay": askForPasswordDelay ?? 0
    ], forKey: screenLockPreferenceBackupKey)
  }

  private func restoreScreenLockPreferencesIfNeeded() {
    guard let backup = UserDefaults.standard.dictionary(forKey: screenLockPreferenceBackupKey) else {
      return
    }
    if backup["hadAskForPassword"] as? Bool == true {
      setScreenSaverPreference("askForPassword", value: backup["askForPassword"] as? Int ?? 0)
    } else {
      setScreenSaverPreference("askForPassword", value: nil)
    }
    if backup["hadAskForPasswordDelay"] as? Bool == true {
      setScreenSaverPreference("askForPasswordDelay", value: backup["askForPasswordDelay"] as? Int ?? 0)
    } else {
      setScreenSaverPreference("askForPasswordDelay", value: nil)
    }
    synchronizeScreenSaverPreferences()
    UserDefaults.standard.removeObject(forKey: screenLockPreferenceBackupKey)
  }

  private func screenSaverPreference(_ key: String) -> Int? {
    guard let value = CFPreferencesCopyValue(
      key as CFString,
      "com.apple.screensaver" as CFString,
      kCFPreferencesCurrentUser,
      kCFPreferencesCurrentHost
    ) else {
      return nil
    }
    return (value as? NSNumber)?.intValue
  }

  private func setScreenSaverPreference(_ key: String, value: Int?) {
    CFPreferencesSetValue(
      key as CFString,
      value.map { NSNumber(value: $0) } as CFPropertyList?,
      "com.apple.screensaver" as CFString,
      kCFPreferencesCurrentUser,
      kCFPreferencesCurrentHost
    )
  }

  private func synchronizeScreenSaverPreferences() {
    CFPreferencesSynchronize(
      "com.apple.screensaver" as CFString,
      kCFPreferencesCurrentUser,
      kCFPreferencesCurrentHost
    )
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
    stopMovingCursorTimer?.invalidate()
    stopMovingCursorTimer = nil
    diskWakeTimer?.invalidate()
    diskWakeTimer = nil
    screenSaverTimer?.invalidate()
    screenSaverTimer = nil
    notificationReminderTimer?.invalidate()
    notificationReminderTimer = nil

    guard assertionActive else {
      return
    }

    if showRemainingSessionTime, sessionEndsAt != nil {
      statusTitleTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
        self?.updateStatusTitle()
      }
    }

    if lockScreenAfterIdle {
      lockScreenTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: false) { [weak self] _ in
        self?.lockScreen()
      }
    }

    if moveCursorAfterIdle {
      moveCursorTimer = Timer.scheduledTimer(withTimeInterval: 5 * 60, repeats: false) { _ in
        let location = NSEvent.mouseLocation
        CGWarpMouseCursorPosition(CGPoint(x: location.x + 1, y: location.y))
        CGWarpMouseCursorPosition(location)
      }
      stopMovingCursorTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(stopMovingCursorAfterMinutes * 60), repeats: false) { [weak self] _ in
        self?.moveCursorTimer?.invalidate()
        self?.moveCursorTimer = nil
      }
    }

    if keepDiskAwake {
      let interval = TimeInterval(max(5, diskWakeIntervalSeconds))
      diskWakeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
        self?.touchDiskWakeFile()
      }
      touchDiskWakeFile()
    }

    if allowScreenSaver {
      screenSaverTimer = Timer.scheduledTimer(withTimeInterval: 45 * 60, repeats: false) { [weak self] _ in
        self?.startScreenSaver()
      }
    }

    if showNotifications {
      notificationReminderTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(max(5, notificationReminderMinutes) * 60), repeats: true) { [weak self] _ in
        self?.deliverNotification(
          title: StayAwakeNativeText.pick("StayAwake is still keeping your Mac awake", "StayAwake 仍在保持唤醒"),
          body: self?.remainingNotificationText() ?? StayAwakeNativeText.pick("The current session is still running.", "当前会话仍在运行。"),
          sound: false,
          identifier: "stayawake.reminder"
        )
      }
    }
  }

  private func touchDiskWakeFile() {
    guard let folder = diskWakeTargetFolder() else {
      return
    }
    try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    let file = folder.appendingPathComponent(".disk-wake")
    let contents = "\(Date().timeIntervalSince1970)\n"
    try? contents.write(to: file, atomically: true, encoding: .utf8)
  }

  private func diskWakeTargetFolder() -> URL? {
    if !diskWakePath.isEmpty {
      return URL(fileURLWithPath: diskWakePath, isDirectory: true).appendingPathComponent(".stayawake", isDirectory: true)
    }
    return FileManager.default.urls(
      for: .applicationSupportDirectory,
      in: .userDomainMask
    ).first?.appendingPathComponent("StayAwake", isDirectory: true)
  }

  private func deliverNotification(title: String, body: String, sound: Bool, identifier: String) {
    guard showNotifications else {
      return
    }
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    if sound {
      content.sound = .default
    }
    let request = UNNotificationRequest(
      identifier: "\(identifier).\(Date().timeIntervalSince1970)",
      content: content,
      trigger: nil
    )
    UNUserNotificationCenter.current().add(request)
  }

  private func notifySessionStarted(durationSeconds: Int?) {
    let isAutomation = currentSessionSource == "automation"
    guard !isAutomation || notifyAutomationStart else {
      return
    }
    deliverNotification(
      title: StayAwakeNativeText.pick("StayAwake Started", "StayAwake 已开启"),
      body: durationSeconds.map {
        StayAwakeNativeText.pick("The session will run for about \($0 / 60) minutes.", "会话将运行约 \($0 / 60) 分钟。")
      } ?? StayAwakeNativeText.pick("The session will run indefinitely.", "会话将无限期运行。"),
      sound: playStartStopSound,
      identifier: "stayawake.started"
    )
  }

  private func notifySessionStopped() {
    let isAutomation = currentSessionSource == "automation"
    guard !isAutomation || notifyAutomationEnd else {
      return
    }
    deliverNotification(
      title: StayAwakeNativeText.pick("StayAwake Stopped", "StayAwake 已停止"),
      body: StayAwakeNativeText.pick("The native keep-awake assertion has been released.", "原生防睡眠断言已释放。"),
      sound: playStartStopSound,
      identifier: "stayawake.stopped"
    )
    if clearDeliveredNotifications {
      clearDeliveredStayAwakeNotifications()
    }
  }

  private func remainingNotificationText() -> String {
    guard let sessionEndsAt else {
      return StayAwakeNativeText.pick("The current indefinite session is still running.", "当前无限期会话仍在运行。")
    }
    let remaining = max(0, Int(sessionEndsAt.timeIntervalSinceNow.rounded(.up)))
    let minutes = max(1, (remaining + 59) / 60)
    return StayAwakeNativeText.pick("The current session has about \(minutes) minutes remaining.", "当前会话大约还剩 \(minutes) 分钟。")
  }

  private func clearDeliveredStayAwakeNotifications() {
    UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
      let identifiers = notifications
        .map(\.request.identifier)
        .filter { $0.hasPrefix("stayawake.") }
      UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
    }
  }

  private func startScreenSaver() {
    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/CoreServices/ScreenSaverEngine.app"))
  }

  private func lockScreen() {
    screenLockedByStayAwake = true
    if allowDisplaySleepWhenLocked {
      refreshCurrentAssertionPolicy()
    }
    let task = Process()
    task.launchPath = "/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession"
    task.arguments = ["-suspend"]
    try? task.run()
  }

  @objc private func workspaceDidWake() {
    screenLockedByStayAwake = false
    if startSessionAfterWake && !assertionActive {
      startDefaultSessionFromNative()
    } else {
      refreshCurrentAssertionPolicy()
    }
  }

  @objc private func workspaceWillSleep() {
    if forceSleepEndsSession {
      stopSession()
      channel?.invokeMethod("stopSession", arguments: nil)
    }
  }

  @objc private func screensDidSleep() {
    if lockWhenDisplayOff {
      lockScreen()
    }
  }

  @objc private func sessionDidResignActive() {
    if endSessionOnUserSwitch {
      stopSession()
      channel?.invokeMethod("stopSession", arguments: nil)
    }
  }

  @objc private func sessionDidBecomeActive() {
    screenLockedByStayAwake = false
    refreshCurrentAssertionPolicy()
  }

  private func updateGlobalHotkeyRegistration() {
    unregisterGlobalHotkey()
    guard globalHotkeyEnabled else {
      return
    }

    let hotKeyID = EventHotKeyID(
      signature: OSType(0x53544159),
      id: UInt32(1)
    )
    let status = RegisterEventHotKey(
      globalHotkeyKeyCode,
      globalHotkeyModifiers,
      hotKeyID,
      GetApplicationEventTarget(),
      0,
      &hotKeyRef
    )
    if status != noErr {
      hotKeyRef = nil
    }
  }

  private func unregisterGlobalHotkey() {
    if let hotKeyRef {
      UnregisterEventHotKey(hotKeyRef)
    }
    hotKeyRef = nil
  }

  private func handleGlobalHotkeyPressed() {
    if assertionActive {
      if activeSessionHotkey == "Ignore shortcut" {
        return
      }
      if activeSessionHotkey == "Extend current session" {
        extendCurrentSessionFromNative()
        return
      }
    }
    startDefaultSessionFromNative()
  }

  private func startDefaultSessionFromNative() {
    let seconds = defaultDurationSeconds()
    if let channel {
      if let seconds {
        channel.invokeMethod("startPreset", arguments: seconds)
      } else {
        channel.invokeMethod("startPreset", arguments: nil)
      }
    } else {
      currentSessionSource = "hotkey"
      startSession(durationSeconds: seconds)
    }
  }

  private func extendCurrentSessionFromNative() {
    let seconds = defaultDurationSeconds() ?? customDurationMinutes * 60
    if let channel {
      channel.invokeMethod("extendSession", arguments: seconds)
    } else if let sessionEndsAt {
      self.sessionEndsAt = sessionEndsAt.addingTimeInterval(TimeInterval(seconds))
      let remaining = max(1, Int(self.sessionEndsAt!.timeIntervalSinceNow.rounded(.up)))
      scheduleStopTimer(seconds: remaining)
      configureSessionAuxiliaryTimers()
      deliverNotification(
        title: StayAwakeNativeText.pick("StayAwake Extended", "StayAwake 已延长"),
        body: StayAwakeNativeText.pick("The current session was extended by \(seconds / 60) minutes.", "当前会话已延长 \(seconds / 60) 分钟。"),
        sound: playExtendSound,
        identifier: "stayawake.extended"
      )
    }
  }

  private func defaultDurationSeconds() -> Int? {
    customDurationMinutes >= 480 ? nil : customDurationMinutes * 60
  }

  private func recordGlobalHotkey() -> [String: Any]? {
    let panel = NSPanel(
      contentRect: NSRect(x: 0, y: 0, width: 364, height: 220),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false
    )
    let recorder = HotkeyRecorderView(frame: NSRect(x: 0, y: 0, width: 364, height: 220))
    var recorded: [String: Any]?
    recorder.onRecord = { payload in
      recorded = payload
      NSApp.stopModal(withCode: .OK)
    }
    recorder.onCancel = {
      NSApp.stopModal(withCode: .cancel)
    }
    panel.title = StayAwakeNativeText.pick("Record Global Shortcut", "录制全局快捷键")
    panel.contentView = recorder
    panel.center()
    NSApp.activate(ignoringOtherApps: true)
    panel.makeKeyAndOrderFront(nil)
    panel.makeFirstResponder(recorder)
    let response = NSApp.runModal(for: panel)
    panel.close()
    guard response == .OK, let recorded else {
      return nil
    }
    if let keyCode = recorded["keyCode"] as? Int {
      globalHotkeyKeyCode = UInt32(max(0, keyCode))
    }
    if let modifiers = recorded["modifiers"] as? Int {
      globalHotkeyModifiers = UInt32(max(0, modifiers))
    }
    globalHotkeyLabel = recorded["label"] as? String ?? globalHotkeyLabel
    updateGlobalHotkeyRegistration()
    return recorded
  }

  private func diskVolumesPayload() -> [[String: Any]] {
    let keys: Set<URLResourceKey> = [.volumeNameKey, .volumeIsRemovableKey, .volumeIsInternalKey]
    return FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: Array(keys), options: [])?.compactMap { url in
      let values = try? url.resourceValues(forKeys: keys)
      return [
        "name": values?.volumeName ?? url.lastPathComponent,
        "path": url.path,
        "isRemovable": values?.volumeIsRemovable ?? false,
        "isInternal": values?.volumeIsInternal ?? false
      ] as [String: Any]
    } ?? []
  }

  private func chooseDiskWakePath() -> [String: Any]? {
    let panel = NSOpenPanel()
    panel.title = StayAwakeNativeText.pick("Choose a Disk or Folder to Keep Awake", "选择保持唤醒的磁盘或文件夹")
    panel.message = StayAwakeNativeText.pick("StayAwake writes a lightweight .stayawake timestamp file in the selected location.", "StayAwake 会在所选位置写入轻量 .stayawake 时间戳文件。")
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.canCreateDirectories = true
    panel.allowsMultipleSelection = false
    if panel.runModal() == .OK, let url = panel.url {
      diskWakePath = url.path
      diskWakeName = url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent
      configureSessionAuxiliaryTimers()
      return [
        "path": diskWakePath,
        "name": diskWakeName
      ]
    }
    return nil
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

    if assertionActive {
      let currentSessionItem = NSMenuItem()
      currentSessionItem.view = CurrentSessionMenuView(
        sessionEndsAt: sessionEndsAt,
        allowDisplaySleep: !preventDisplaySleep,
        allowSystemSleepWhenDisplayOff: allowSystemSleepWhenDisplayOff,
        allowScreenSaver: allowScreenSaver,
        allowScreenLock: allowScreenLock
      ) { [weak self] key, value in
        self?.quickSettingChanged(key: key, value: value)
      } onStop: { [weak self] in
        self?.stopFromMenu()
      }
      statusMenu.addItem(currentSessionItem)
    } else {
      let endItem = NSMenuItem(title: StayAwakeNativeText.pick("StayAwake: Idle", "StayAwake：空闲"), action: nil, keyEquivalent: "")
      endItem.isEnabled = false
      statusMenu.addItem(endItem)
    }

    statusMenu.addItem(.separator())
    statusMenu.addItem(actionItem(title: StayAwakeNativeText.pick("Open Main Window", "打开主窗口"), action: #selector(showMainWindow), keyEquivalent: "0"))
    statusMenu.addItem(.separator())
    let startTitle = NSMenuItem(title: StayAwakeNativeText.pick("Start New Session:", "开启新会话:"), action: nil, keyEquivalent: "")
    startTitle.isEnabled = false
    statusMenu.addItem(startTitle)
    statusMenu.addItem(actionItem(title: StayAwakeNativeText.pick("Indefinitely", "无限期"), action: #selector(startIndefinitely), keyEquivalent: "i"))

    let minutesMenu = NSMenu()
    for minutes in stride(from: 5, through: 55, by: 5) {
      minutesMenu.addItem(durationItem(title: StayAwakeNativeText.minutes(minutes), seconds: minutes * 60))
    }
    statusMenu.addItem(submenuItem(title: StayAwakeNativeText.pick("Minutes", "分钟"), submenu: minutesMenu))

    let hoursMenu = NSMenu()
    for hours in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 24] {
      hoursMenu.addItem(durationItem(title: StayAwakeNativeText.hours(hours), seconds: hours * 60 * 60))
    }
    statusMenu.addItem(submenuItem(title: StayAwakeNativeText.pick("Hours", "小时"), submenu: hoursMenu))

    let customMenu = NSMenu()
    let customItem = NSMenuItem()
    customItem.view = CustomTimeMenuView(defaultMinutes: customDurationMinutes) { [weak self] seconds in
      self?.startCustomSeconds(seconds)
    }
    customMenu.addItem(customItem)
    statusMenu.addItem(submenuItem(title: StayAwakeNativeText.pick("Custom Time / Until", "自定义时间 / 直到"), submenu: customMenu))

    let appMenu = buildRunningAppMenu()
    statusMenu.addItem(submenuItem(title: runningAppTriggerMenuTitle(), submenu: appMenu))

    statusMenu.addItem(toggleItem(title: StayAwakeNativeText.pick("While Files Are Downloading...", "当下载文件时..."), action: #selector(toggleDownloadTrigger), enabled: downloadTriggerEnabled))

    let quickSettingsMenu = NSMenu()
    let quickSettingsItem = NSMenuItem()
    quickSettingsItem.view = QuickSettingsMenuView(
      allowDisplaySleep: !preventDisplaySleep,
      allowSystemSleepWhenDisplayOff: allowSystemSleepWhenDisplayOff,
      allowScreenSaver: allowScreenSaver,
      stopOnLowBattery: stopOnLowBattery,
      lowBatteryStopPercent: lowBatteryStopPercent,
      allowScreenLock: allowScreenLock,
      lockScreenAfterIdle: lockScreenAfterIdle,
      moveCursorAfterIdle: moveCursorAfterIdle,
      triggersEnabled: triggersEnabled,
      keepDiskAwake: keepDiskAwake,
      showRemainingSessionTime: showRemainingSessionTime
    ) { [weak self] key, value in
      self?.quickSettingChanged(key: key, value: value)
    }
    quickSettingsMenu.addItem(quickSettingsItem)
    statusMenu.addItem(submenuItem(title: StayAwakeNativeText.pick("Quick Settings", "快速设置"), submenu: quickSettingsMenu))
    statusMenu.addItem(actionItem(title: StayAwakeNativeText.pick("Settings...", "设置..."), action: #selector(openSettingsFromMenu), keyEquivalent: ","))

    statusMenu.addItem(.separator())
    statusMenu.addItem(actionItem(title: StayAwakeNativeText.pick("About StayAwake", "关于 StayAwake"), action: #selector(openAboutFromMenu)))
    let supportMenu = NSMenu()
    supportMenu.addItem(actionItem(title: StayAwakeNativeText.pick("Open Main Window", "打开主窗口"), action: #selector(showMainWindow)))
    supportMenu.addItem(actionItem(title: StayAwakeNativeText.pick("Show Onboarding", "显示新手引导"), action: #selector(openOnboardingFromMenu)))
    supportMenu.addItem(actionItem(title: StayAwakeNativeText.pick("Open Rules Settings", "打开规则设置"), action: #selector(openRulesFromMenu)))
    supportMenu.addItem(actionItem(title: StayAwakeNativeText.pick("Install / Repair Closed-Display Helper", "安装/修复合盖助手"), action: #selector(installPowerProtectFromMenu)))
    supportMenu.addItem(actionItem(title: StayAwakeNativeText.pick("Remove Closed-Display Helper", "移除合盖助手"), action: #selector(removePowerProtectFromMenu)))
    statusMenu.addItem(submenuItem(title: StayAwakeNativeText.pick("Feedback & Support", "反馈和支持"), submenu: supportMenu))
    statusMenu.addItem(.separator())
    statusMenu.addItem(actionItem(title: StayAwakeNativeText.pick("Quit StayAwake", "关闭 StayAwake"), action: #selector(quitApp), keyEquivalent: "q"))

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

  private func runningAppTriggerMenuTitle() -> String {
    let selectedTitle = appTriggerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      ? appTriggerBundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
      : appTriggerName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !selectedTitle.isEmpty else {
      return StayAwakeNativeText.pick("While App Is Running", "当 App 正在运行时")
    }

    let maxLength = 18
    let displayTitle = selectedTitle.count > maxLength
      ? "\(selectedTitle.prefix(maxLength))..."
      : selectedTitle
    return StayAwakeNativeText.pick("While App Is Running (\(displayTitle))", "当 App 正在运行时（\(displayTitle)）")
  }

  private func buildRunningAppMenu() -> NSMenu {
    let appMenu = NSMenu()
    appMenu.addItem(toggleItem(title: StayAwakeNativeText.pick("Enable Running App Trigger", "启用运行中 App 触发"), action: #selector(toggleAppTrigger), enabled: appTriggerEnabled))
    appMenu.addItem(toggleItem(title: StayAwakeNativeText.pick("Hide Helper Apps and Processes", "不显示帮助程序或进程"), action: #selector(toggleHideHelperApps), enabled: hideHelperApps))

    if !appTriggerBundleIdentifier.isEmpty {
      let selectedTitle = appTriggerName.isEmpty ? appTriggerBundleIdentifier : appTriggerName
      let selectedItem = NSMenuItem(title: StayAwakeNativeText.pick("Current Selection: \(selectedTitle)", "当前选择：\(selectedTitle)"), action: nil, keyEquivalent: "")
      selectedItem.isEnabled = false
      appMenu.addItem(selectedItem)
    }

    appMenu.addItem(.separator())

    let apps = runningApplicationsForMenu()
    if apps.isEmpty {
      let emptyItem = NSMenuItem(title: StayAwakeNativeText.pick("No running apps available", "没有可选的运行中 App"), action: nil, keyEquivalent: "")
      emptyItem.isEnabled = false
      appMenu.addItem(emptyItem)
    } else {
      for app in apps.prefix(30) {
        let title = app.name.isEmpty ? app.bundleIdentifier : app.name
        let item = actionItem(title: title, action: #selector(selectRunningAppFromMenu(_:)))
        item.representedObject = [
          "name": app.name,
          "bundleIdentifier": app.bundleIdentifier,
          "isRegular": app.isRegular
        ] as [String: Any]
        item.state = app.bundleIdentifier == appTriggerBundleIdentifier ? .on : .off
        item.toolTip = app.bundleIdentifier
        appMenu.addItem(item)
      }
      if apps.count > 30 {
        let moreItem = NSMenuItem(title: StayAwakeNativeText.pick("Open Rules Settings for More Apps...", "更多 App 请打开规则设置..."), action: #selector(openRulesFromMenu), keyEquivalent: "")
        moreItem.target = self
        appMenu.addItem(.separator())
        appMenu.addItem(moreItem)
      }
    }

    appMenu.addItem(.separator())
    appMenu.addItem(actionItem(title: StayAwakeNativeText.pick("Open Rules Settings...", "打开规则设置..."), action: #selector(openRulesFromMenu)))
    return appMenu
  }

  private struct RunningAppMenuEntry {
    let name: String
    let bundleIdentifier: String
    let isRegular: Bool
  }

  private func runningApplicationsForMenu() -> [RunningAppMenuEntry] {
    let apps = NSWorkspace.shared.runningApplications.compactMap { app -> RunningAppMenuEntry? in
      let name = app.localizedName ?? app.bundleIdentifier ?? ""
      let bundleIdentifier = app.bundleIdentifier ?? ""
      if name.isEmpty || bundleIdentifier.isEmpty {
        return nil
      }
      let isRegular = app.activationPolicy == .regular
      if hideHelperApps && !isRegular {
        return nil
      }
      return RunningAppMenuEntry(
        name: name,
        bundleIdentifier: bundleIdentifier,
        isRegular: isRegular
      )
    }

    return apps.sorted { lhs, rhs in
      let order = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
      if order == .orderedSame {
        return lhs.bundleIdentifier < rhs.bundleIdentifier
      }
      return order == .orderedAscending
    }
  }

  private func statusPayload() -> [String: Any] {
    [
      "active": assertionActive,
      "endsAt": sessionEndsAt?.timeIntervalSince1970 as Any,
      "preventDisplaySleep": preventDisplaySleep,
      "allowScreenSaver": allowScreenSaver,
      "startAtLogin": startAtLogin,
      "loginItemSupported": loginItemStatusPayload()["supported"] as? Bool ?? false
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
    var shouldRefreshAssertionPolicy = false
    switch key {
    case "allowDisplaySleep":
      preventDisplaySleep = !value
      shouldRefreshAssertionPolicy = true
      channel?.invokeMethod("toggleSetting", arguments: [
        "key": "preventDisplaySleep",
        "value": preventDisplaySleep
      ])
    case "allowSystemSleepWhenDisplayOff":
      allowSystemSleepWhenDisplayOff = value
      shouldRefreshAssertionPolicy = true
      sendSettingToggle(key: key, value: value)
    case "allowScreenLock":
      allowScreenLock = value
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
    case "startAtLogin":
      _ = setLoginItemEnabled(value)
      sendSettingToggle(key: key, value: startAtLogin)
    default:
      return
    }
    if shouldRefreshAssertionPolicy {
      refreshCurrentAssertionPolicy()
    } else {
      configureSessionAuxiliaryTimers()
    }
    updateScreenLockPolicyForSession()
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
    _ = setLoginItemEnabled(!startAtLogin)
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

  @objc private func toggleHideHelperApps() {
    hideHelperApps.toggle()
    channel?.invokeMethod("toggleSetting", arguments: [
      "key": "hideHelperApps",
      "value": hideHelperApps
    ])
    rebuildMenu()
  }

  @objc private func selectRunningAppFromMenu(_ sender: NSMenuItem) {
    guard let app = sender.representedObject as? [String: Any],
          let name = app["name"] as? String,
          let bundleIdentifier = app["bundleIdentifier"] as? String else {
      return
    }
    appTriggerName = name
    appTriggerBundleIdentifier = bundleIdentifier
    appTriggerEnabled = true
    channel?.invokeMethod("selectRunningApp", arguments: app)
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

  @objc private func openOnboardingFromMenu() {
    showOnboarding()
  }

  @objc private func installPowerProtectFromMenu() {
    showPowerProtectInstallResult(success: installPowerProtectHelperWithAdministratorPrivileges())
    channel?.invokeMethod("nativeStatusChanged", arguments: statusPayload())
  }

  @objc private func removePowerProtectFromMenu() {
    showPowerProtectRemovalResult(success: removePowerProtectHelperWithAdministratorPrivileges())
    channel?.invokeMethod("nativeStatusChanged", arguments: statusPayload())
  }

  @IBAction func showMainWindowFromMainMenu(_ sender: Any?) {
    showMainWindow()
  }

  @objc private func showMainWindow() {
    NSApp.activate(ignoringOtherApps: true)
    let mainWindow = NSApp.windows.first { $0 is MainFlutterWindow } ?? NSApp.windows.first
    mainWindow?.makeKeyAndOrderFront(nil)
  }

  @objc private func quitApp() {
    stopSession()
    NSApp.terminate(nil)
  }
}
