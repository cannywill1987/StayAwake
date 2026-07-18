import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

enum EnvEnum { dev, uat, prd }

enum ChannelEnum { normal, mac, windows, ios, android, web }

enum LoginTypeEnum { normal, email, phone, apple, google }

class Params {
  static const String appName = 'NoSleepy - Wake Keeper';
  static const EnvEnum env = EnvEnum.prd;
  static const String devBaseUrl = String.fromEnvironment(
    'STAYAWAKE_DEV_BASE_URL',
    defaultValue: 'http://127.0.0.1:9999',
  );
  static const String uatBaseUrl = String.fromEnvironment(
    'STAYAWAKE_UAT_BASE_URL',
    defaultValue: 'https://www.timerbell.com',
  );
  static const String prdBaseUrl = String.fromEnvironment(
    'STAYAWAKE_PRD_BASE_URL',
    defaultValue: 'https://www.timerbell.com',
  );
  static const String ossUrl = String.fromEnvironment(
    'STAYAWAKE_OSS_URL',
    defaultValue: 'http://oss.timerbell.com',
  );
  static const bool debugUseDevServer = bool.fromEnvironment(
    'STAYAWAKE_DEBUG_USE_DEV_SERVER',
    defaultValue: false,
  );
  static const bool isHttpCacheOn = false;
  static const bool isMongoDbCacheOn = true;
  static const int requestTimeout = 40000;
  static const int connectTimeout = 40000;
  static const int receiveTimeout = 40000;
  static const int mongoDbTimeout = 10000;
  static const String appScene = 'stayAwake';
  static const String sysCode = appName;
  static const String curVersion = '1.0.0';
  static const String appPromotionSceneCode = 'app_cross_promotion';
  static const String appPromotionListLocationCode = 'app_list';
  static const ChannelEnum channelEnum = ChannelEnum.mac;
  static const LoginTypeEnum loginTypeEnum = LoginTypeEnum.normal;
  static Locale? local;

  static bool get isDebug => kDebugMode || env == EnvEnum.dev;

  static String get mBaseUrl {
    if (kDebugMode && debugUseDevServer) return devBaseUrl;
    return switch (env) {
      EnvEnum.dev => devBaseUrl,
      EnvEnum.uat => uatBaseUrl,
      EnvEnum.prd => prdBaseUrl,
    };
  }

  static String get mUrl {
    if (env == EnvEnum.dev || (kDebugMode && debugUseDevServer)) {
      return 'http://localhost:3000/web';
    }
    return '$mBaseUrl/web';
  }
}

class Apis {
  static const String commentModel = '/api/1/classes/CommentModel';
  static const String getResourceList = '/api/resource/scene/getList';
  static const String uploadFile = '/api/common/uploadFile';
  static const String uploadImage = '/api/common/uploadImage';
  static const String uploadOSSFile = '/api/common/uploadOSSFile';
}

class Urls {
  static String get webHome => Params.mUrl;
  static String get privacy => '${Params.mUrl}/privacy';
  static String get terms => '${Params.mUrl}/terms';
}

class SharePreferenceKeys {
  static const String languageMode = 'languageMode';
  static const String deviceId = 'deviceId';
  static const String userInfo = 'userInfo';
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StayAwakeApp());
}

class StayAwakeApp extends StatelessWidget {
  const StayAwakeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF16A085),
      brightness: Brightness.light,
    );

    return ValueListenableBuilder<String>(
      valueListenable: AppLocaleController.languageMode,
      builder: (context, languageMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: Params.appName,
          locale: AppLocaleController.localeFor(languageMode),
          supportedLocales: AppText.supportedLocales,
          localizationsDelegates: const [
            AppTextDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          theme: ThemeData(
            colorScheme: colorScheme,
            scaffoldBackgroundColor: const Color(0xFFF6F7F4),
            useMaterial3: true,
            textTheme: Typography.blackCupertino,
          ),
          home: const StayAwakeHomePage(),
        );
      },
    );
  }
}

class AppLocaleController {
  static const system = 'system';
  static const english = 'en';
  static const chinese = 'zh';
  static const japanese = 'ja';
  static const french = 'fr';
  static const italian = 'it';
  static const german = 'de';
  static const spanish = 'es';
  static const fixedLanguageModes = [
    english,
    chinese,
    japanese,
    french,
    italian,
    german,
    spanish,
  ];

  static final ValueNotifier<String> languageMode = ValueNotifier<String>(
    system,
  );

  static void setLanguageMode(String mode) {
    languageMode.value = normalized(mode);
  }

  static String normalized(String? mode) {
    return fixedLanguageModes.contains(mode) ? mode! : system;
  }

  static Locale? localeFor(String mode) {
    final normalizedMode = normalized(mode);
    return normalizedMode == system ? null : Locale(normalizedMode);
  }

  static String effectiveLanguageCode(String mode) {
    final normalizedMode = normalized(mode);
    if (normalizedMode != system) {
      return normalizedMode;
    }
    final platformLocale = PlatformDispatcher.instance.locale;
    final platformLanguage = platformLocale.languageCode.toLowerCase();
    if (platformLanguage.startsWith('zh')) return chinese;
    return fixedLanguageModes.contains(platformLanguage)
        ? platformLanguage
        : english;
  }
}

class AppText {
  const AppText(this.locale);

  final Locale locale;

  static const supportedLocales = [
    Locale('en'),
    Locale('zh'),
    Locale('ja'),
    Locale('fr'),
    Locale('it'),
    Locale('de'),
    Locale('es'),
  ];

  static AppText of(BuildContext context) {
    return Localizations.of<AppText>(context, AppText) ??
        const AppText(Locale('en'));
  }

  bool get isZh => locale.languageCode.toLowerCase().startsWith('zh');

  String get languageCode => locale.languageCode.toLowerCase();

  String pick(String en, String zh) {
    final value = isZh ? zh : (_localizedStrings[languageCode]?[en] ?? en);
    return value.replaceAll('StayAwake', Params.appName);
  }

  String minutes(int value) => pick('$value minutes', '$value 分钟');

  String minutesShort(int value) => pick('${value}m', '$value 分钟');

  String secondsShort(int value) => pick('${value}s', '$value 秒');

  String percent(int value) => '$value%';

  String get indefinite => pick('Indefinite', '无限期');

  static const Map<String, Map<String, String>> _localizedStrings = {
    'ja': {
      'Automatic': '自動',
      'Follow system': 'システムに合わせる',
      'Chinese': '中国語',
      'Japanese': '日本語',
      'French': 'フランス語',
      'Italian': 'イタリア語',
      'German': 'ドイツ語',
      'Spanish': 'スペイン語',
      'Language': '言語',
      'Status': '状態',
      'Sessions': 'セッション',
      'Stay Awake Rules': 'スリープ防止ルール',
      'Settings': '設定',
      'Inactive': '非アクティブ',
      'Ending': '終了中',
      'Indefinite': '無期限',
      'Manual': '手動',
      'Menu bar': 'メニューバー',
      'Automation': '自動化',
      'Native assertion active': 'ネイティブのスリープ防止が有効',
      'Starting native assertion...': 'ネイティブのスリープ防止を開始中...',
      'Stopping...': '停止中...',
      'Native bridge unavailable': 'ネイティブブリッジを使用できません',
      'Quick sessions': 'クイックセッション',
      'Sleep behavior': 'スリープ動作',
      'Screen saver': 'スクリーンセーバー',
      'Stop keeping awake': 'スリープ防止を停止',
      'Start 1 hour': '1時間開始',
      'Menu bar controls enabled': 'メニューバー操作が有効',
      'Power source': '電源',
      'Activity': 'アクティビティ',
      'Session active': 'セッション実行中',
      'No active session': '実行中のセッションなし',
      'Native bridge': 'ネイティブブリッジ',
      'Status bar': 'ステータスバー',
      'Session defaults': 'セッション既定値',
      'General': '一般',
      'System controls': 'システム制御',
      'Triggers': 'トリガー',
      'Disk wake': 'ディスク維持',
      'Hotkeys': 'ホットキー',
      'Notifications': '通知',
      'Appearance': '外観',
      'Statistics': '統計',
      'Default duration': '既定の時間',
      'Prevent display sleep': 'ディスプレイスリープを防止',
      'Allow screen saver after idle': 'アイドル後のスクリーンセーバーを許可',
      'Start at login': 'ログイン時に起動',
      'Hide StayAwake in Dock': 'Dock で StayAwake を非表示',
      'Reduce motion': 'モーションを減らす',
      'Enable triggers': 'トリガーを有効化',
      'Keep disk awake': 'ディスクを起動状態に保つ',
      'Enable global shortcut': 'グローバルショートカットを有効化',
      'Show notifications': '通知を表示',
      'Menu bar icon': 'メニューバーアイコン',
      'Collect statistics': '統計を収集',
      'Local state file': 'ローカル状態ファイル',
      'Start failed': '開始に失敗しました',
      'Stop failed': '停止に失敗しました',
      'Extended session': 'セッションを延長しました',
      'Cancel': 'キャンセル',
      'Clear': 'クリア',
      'Choose target': '対象を選択',
      'Use default': '既定を使用',
      'Record shortcut': 'ショートカットを記録',
      'Clear now': '今すぐクリア',
      'Send feedback': 'フィードバックを送信',
      'Feedback': 'フィードバック',
      'User Feedback': 'ユーザーフィードバック',
      'Tell us what happened or what you want improved.':
          '問題や改善してほしい点をお知らせください。',
      'Rating': '評価',
      'Content': '内容',
      'Describe your feedback': 'フィードバックを入力してください',
      'Contact (optional)': '連絡先（任意）',
      'Email or phone, optional': 'メールまたは電話（任意）',
      'Feedback is saved with appScene: stayAwake.':
          'フィードバックは appScene: stayAwake 付きで保存されます。',
      'Server records for StayAwake feedback.':
          'StayAwake のフィードバックをサーバーから表示します。',
      'Submits feedback to the server.': 'フィードバックをサーバーに送信します。',
      'Official reply': '公式返信',
      'Reply time': '返信日時',
      'Feedback saved locally': 'フィードバックをローカルに保存しました',
      'Feedback submitted': 'フィードバックを送信しました',
      'Feedback server unavailable; saved locally for retry.':
          'サーバーを利用できないため、再試行用にローカル保存しました。',
      'Feedback failed to save': 'フィードバックを保存できませんでした',
      'Please enter feedback content.': 'フィードバック内容を入力してください。',
      'Submit feedback': '送信',
      'Discover Apps': 'アプリを見つける',
      'Promoted apps are loaded from the app_cross_promotion resource scene.':
          'おすすめアプリは app_cross_promotion リソースシーンから読み込まれます。',
      'Promotion resource unavailable': 'プロモーションリソースを利用できません',
      'Fallback examples are shown until the resource scene is configured.':
          'リソースシーンが設定されるまでサンプルを表示します。',
      'Category': 'カテゴリ',
      'Size': 'サイズ',
      'Download': 'ダウンロード',
      'No download link configured.': 'ダウンロードリンクが未設定です。',
      'Open link failed.': 'リンクを開けませんでした。',
      'Create': '作成',
      'Productivity': '生産性',
      'Focus timer and daily planning.': '集中タイマーと日々の計画。',
      'Manage focus sessions, tasks, and routine planning.':
          '集中セッション、タスク、日課の計画を管理します。',
      'Focus timer': '集中タイマー',
      'Task planning': 'タスク計画',
      'ACTIVE': '有効',
      'IDLE': '待機',
    },
    'fr': {
      'Automatic': 'Automatique',
      'Follow system': 'Suivre le système',
      'Chinese': 'Chinois',
      'Japanese': 'Japonais',
      'French': 'Français',
      'Italian': 'Italien',
      'German': 'Allemand',
      'Spanish': 'Espagnol',
      'Language': 'Langue',
      'Status': 'État',
      'Sessions': 'Sessions',
      'Stay Awake Rules': 'Règles de veille',
      'Settings': 'Réglages',
      'Inactive': 'Inactif',
      'Ending': 'Fin en cours',
      'Indefinite': 'Indéfini',
      'Manual': 'Manuel',
      'Menu bar': 'Barre des menus',
      'Automation': 'Automatisation',
      'Native assertion active': 'Assertion native active',
      'Starting native assertion...': 'Démarrage de l’assertion native...',
      'Stopping...': 'Arrêt...',
      'Native bridge unavailable': 'Pont natif indisponible',
      'Quick sessions': 'Sessions rapides',
      'Sleep behavior': 'Comportement de veille',
      'Screen saver': 'Économiseur d’écran',
      'Stop keeping awake': 'Arrêter le maintien éveillé',
      'Start 1 hour': 'Démarrer 1 h',
      'Menu bar controls enabled': 'Contrôles de la barre des menus activés',
      'Power source': 'Source d’alimentation',
      'Activity': 'Activité',
      'Session active': 'Session active',
      'No active session': 'Aucune session active',
      'Native bridge': 'Pont natif',
      'Status bar': 'Barre d’état',
      'Session defaults': 'Valeurs par défaut',
      'General': 'Général',
      'System controls': 'Contrôles système',
      'Triggers': 'Déclencheurs',
      'Disk wake': 'Maintien du disque',
      'Hotkeys': 'Raccourcis',
      'Notifications': 'Notifications',
      'Appearance': 'Apparence',
      'Statistics': 'Statistiques',
      'Default duration': 'Durée par défaut',
      'Prevent display sleep': 'Empêcher la veille de l’écran',
      'Allow screen saver after idle':
          'Autoriser l’économiseur après inactivité',
      'Start at login': 'Lancer à l’ouverture',
      'Hide StayAwake in Dock': 'Masquer StayAwake dans le Dock',
      'Reduce motion': 'Réduire les animations',
      'Enable triggers': 'Activer les déclencheurs',
      'Keep disk awake': 'Maintenir le disque éveillé',
      'Enable global shortcut': 'Activer le raccourci global',
      'Show notifications': 'Afficher les notifications',
      'Menu bar icon': 'Icône de barre des menus',
      'Collect statistics': 'Collecter les statistiques',
      'Local state file': 'Fichier d’état local',
      'Start failed': 'Échec du démarrage',
      'Stop failed': 'Échec de l’arrêt',
      'Extended session': 'Session prolongée',
      'Cancel': 'Annuler',
      'Clear': 'Effacer',
      'Choose target': 'Choisir la cible',
      'Use default': 'Utiliser par défaut',
      'Record shortcut': 'Enregistrer le raccourci',
      'Clear now': 'Effacer maintenant',
      'Send feedback': 'Envoyer un avis',
      'Feedback': 'Avis',
      'User Feedback': 'Avis utilisateur',
      'Tell us what happened or what you want improved.':
          'Dites-nous ce qui s’est passé ou ce que vous souhaitez améliorer.',
      'Rating': 'Note',
      'Content': 'Contenu',
      'Describe your feedback': 'Décrivez votre avis',
      'Contact (optional)': 'Contact (facultatif)',
      'Email or phone, optional': 'E-mail ou téléphone, facultatif',
      'Feedback is saved with appScene: stayAwake.':
          'L’avis est enregistré avec appScene: stayAwake.',
      'Server records for StayAwake feedback.':
          'Affiche les avis StayAwake enregistrés sur le serveur.',
      'Submits feedback to the server.': 'Envoie l’avis au serveur.',
      'Official reply': 'Réponse officielle',
      'Reply time': 'Heure de réponse',
      'Feedback saved locally': 'Avis enregistré localement',
      'Feedback submitted': 'Avis envoyé',
      'Feedback server unavailable; saved locally for retry.':
          'Serveur indisponible ; avis enregistré localement pour réessai.',
      'Feedback failed to save': 'Impossible d’enregistrer l’avis',
      'Please enter feedback content.': 'Veuillez saisir votre avis.',
      'Submit feedback': 'Envoyer',
      'Discover Apps': 'Découvrir des apps',
      'Promoted apps are loaded from the app_cross_promotion resource scene.':
          'Les apps promues sont chargées depuis la scène de ressources app_cross_promotion.',
      'Promotion resource unavailable': 'Ressource de promotion indisponible',
      'Fallback examples are shown until the resource scene is configured.':
          'Des exemples sont affichés tant que la scène de ressources n’est pas configurée.',
      'Category': 'Catégorie',
      'Size': 'Taille',
      'Download': 'Télécharger',
      'No download link configured.': 'Aucun lien de téléchargement configuré.',
      'Open link failed.': 'Impossible d’ouvrir le lien.',
      'Create': 'Créer',
      'Productivity': 'Productivité',
      'Focus timer and daily planning.':
          'Minuteur de concentration et planification quotidienne.',
      'Manage focus sessions, tasks, and routine planning.':
          'Gérez les sessions de concentration, les tâches et les routines.',
      'Focus timer': 'Minuteur de concentration',
      'Task planning': 'Planification des tâches',
      'ACTIVE': 'ACTIF',
      'IDLE': 'INACTIF',
    },
    'it': {
      'Automatic': 'Automatico',
      'Follow system': 'Segui il sistema',
      'Chinese': 'Cinese',
      'Japanese': 'Giapponese',
      'French': 'Francese',
      'Italian': 'Italiano',
      'German': 'Tedesco',
      'Spanish': 'Spagnolo',
      'Language': 'Lingua',
      'Status': 'Stato',
      'Sessions': 'Sessioni',
      'Stay Awake Rules': 'Regole anti-sospensione',
      'Settings': 'Impostazioni',
      'Inactive': 'Inattivo',
      'Ending': 'In chiusura',
      'Indefinite': 'Senza limite',
      'Manual': 'Manuale',
      'Menu bar': 'Barra dei menu',
      'Automation': 'Automazione',
      'Native assertion active': 'Asserzione nativa attiva',
      'Starting native assertion...': 'Avvio asserzione nativa...',
      'Stopping...': 'Arresto...',
      'Native bridge unavailable': 'Bridge nativo non disponibile',
      'Quick sessions': 'Sessioni rapide',
      'Sleep behavior': 'Comportamento sonno',
      'Screen saver': 'Salvaschermo',
      'Stop keeping awake': 'Interrompi mantenimento attivo',
      'Start 1 hour': 'Avvia 1 ora',
      'Menu bar controls enabled': 'Controlli nella barra menu attivi',
      'Power source': 'Alimentazione',
      'Activity': 'Attività',
      'Session active': 'Sessione attiva',
      'No active session': 'Nessuna sessione attiva',
      'Native bridge': 'Bridge nativo',
      'Status bar': 'Barra di stato',
      'Session defaults': 'Predefiniti sessione',
      'General': 'Generale',
      'System controls': 'Controlli di sistema',
      'Triggers': 'Attivatori',
      'Disk wake': 'Disco attivo',
      'Hotkeys': 'Scorciatoie',
      'Notifications': 'Notifiche',
      'Appearance': 'Aspetto',
      'Statistics': 'Statistiche',
      'Default duration': 'Durata predefinita',
      'Prevent display sleep': 'Impedisci stop dello schermo',
      'Allow screen saver after idle': 'Consenti salvaschermo dopo inattività',
      'Start at login': 'Avvia al login',
      'Hide StayAwake in Dock': 'Nascondi StayAwake nel Dock',
      'Reduce motion': 'Riduci movimento',
      'Enable triggers': 'Abilita attivatori',
      'Keep disk awake': 'Mantieni disco attivo',
      'Enable global shortcut': 'Abilita scorciatoia globale',
      'Show notifications': 'Mostra notifiche',
      'Menu bar icon': 'Icona barra menu',
      'Collect statistics': 'Raccogli statistiche',
      'Local state file': 'File stato locale',
      'Start failed': 'Avvio non riuscito',
      'Stop failed': 'Arresto non riuscito',
      'Extended session': 'Sessione estesa',
      'Cancel': 'Annulla',
      'Clear': 'Cancella',
      'Choose target': 'Scegli destinazione',
      'Use default': 'Usa predefinito',
      'Record shortcut': 'Registra scorciatoia',
      'Clear now': 'Cancella ora',
      'Send feedback': 'Invia feedback',
      'Feedback': 'Feedback',
      'User Feedback': 'Feedback utenti',
      'Tell us what happened or what you want improved.':
          'Dicci cosa è successo o cosa vorresti migliorare.',
      'Rating': 'Valutazione',
      'Content': 'Contenuto',
      'Describe your feedback': 'Descrivi il tuo feedback',
      'Contact (optional)': 'Contatto (facoltativo)',
      'Email or phone, optional': 'Email o telefono, facoltativo',
      'Feedback is saved with appScene: stayAwake.':
          'Il feedback viene salvato con appScene: stayAwake.',
      'Server records for StayAwake feedback.':
          'Mostra i feedback StayAwake dal server.',
      'Submits feedback to the server.': 'Invia il feedback al server.',
      'Official reply': 'Risposta ufficiale',
      'Reply time': 'Ora della risposta',
      'Feedback saved locally': 'Feedback salvato localmente',
      'Feedback submitted': 'Feedback inviato',
      'Feedback server unavailable; saved locally for retry.':
          'Server non disponibile; feedback salvato localmente per riprovare.',
      'Feedback failed to save': 'Impossibile salvare il feedback',
      'Please enter feedback content.': 'Inserisci il contenuto del feedback.',
      'Submit feedback': 'Invia feedback',
      'Discover Apps': 'Scopri app',
      'Promoted apps are loaded from the app_cross_promotion resource scene.':
          'Le app promosse vengono caricate dalla scena risorse app_cross_promotion.',
      'Promotion resource unavailable': 'Risorsa promozionale non disponibile',
      'Fallback examples are shown until the resource scene is configured.':
          'Gli esempi vengono mostrati finché la scena risorse non è configurata.',
      'Category': 'Categoria',
      'Size': 'Dimensione',
      'Download': 'Scarica',
      'No download link configured.': 'Nessun link di download configurato.',
      'Open link failed.': 'Impossibile aprire il link.',
      'Create': 'Crea',
      'Productivity': 'Produttività',
      'Focus timer and daily planning.':
          'Timer di concentrazione e pianificazione quotidiana.',
      'Manage focus sessions, tasks, and routine planning.':
          'Gestisci sessioni di concentrazione, attività e routine.',
      'Focus timer': 'Timer concentrazione',
      'Task planning': 'Pianificazione attività',
      'ACTIVE': 'ATTIVO',
      'IDLE': 'INATTIVO',
    },
    'de': {
      'Automatic': 'Automatisch',
      'Follow system': 'System folgen',
      'Chinese': 'Chinesisch',
      'Japanese': 'Japanisch',
      'French': 'Französisch',
      'Italian': 'Italienisch',
      'German': 'Deutsch',
      'Spanish': 'Spanisch',
      'Language': 'Sprache',
      'Status': 'Status',
      'Sessions': 'Sitzungen',
      'Stay Awake Rules': 'Wachhalteregeln',
      'Settings': 'Einstellungen',
      'Inactive': 'Inaktiv',
      'Ending': 'Beendet',
      'Indefinite': 'Unbegrenzt',
      'Manual': 'Manuell',
      'Menu bar': 'Menüleiste',
      'Automation': 'Automatisierung',
      'Native assertion active': 'Native Assertion aktiv',
      'Starting native assertion...': 'Native Assertion wird gestartet...',
      'Stopping...': 'Stoppt...',
      'Native bridge unavailable': 'Native Bridge nicht verfügbar',
      'Quick sessions': 'Schnellsitzungen',
      'Sleep behavior': 'Ruhezustandsverhalten',
      'Screen saver': 'Bildschirmschoner',
      'Stop keeping awake': 'Wachhalten stoppen',
      'Start 1 hour': '1 Stunde starten',
      'Menu bar controls enabled': 'Menüleistensteuerung aktiv',
      'Power source': 'Stromquelle',
      'Activity': 'Aktivität',
      'Session active': 'Sitzung aktiv',
      'No active session': 'Keine aktive Sitzung',
      'Native bridge': 'Native Bridge',
      'Status bar': 'Statusleiste',
      'Session defaults': 'Sitzungsstandard',
      'General': 'Allgemein',
      'System controls': 'Systemsteuerung',
      'Triggers': 'Auslöser',
      'Disk wake': 'Festplatte wach halten',
      'Hotkeys': 'Kurzbefehle',
      'Notifications': 'Mitteilungen',
      'Appearance': 'Darstellung',
      'Statistics': 'Statistiken',
      'Default duration': 'Standarddauer',
      'Prevent display sleep': 'Display-Ruhezustand verhindern',
      'Allow screen saver after idle':
          'Bildschirmschoner nach Inaktivität erlauben',
      'Start at login': 'Beim Anmelden starten',
      'Hide StayAwake in Dock': 'StayAwake im Dock ausblenden',
      'Reduce motion': 'Bewegung reduzieren',
      'Enable triggers': 'Auslöser aktivieren',
      'Keep disk awake': 'Festplatte wach halten',
      'Enable global shortcut': 'Globalen Kurzbefehl aktivieren',
      'Show notifications': 'Mitteilungen anzeigen',
      'Menu bar icon': 'Menüleistensymbol',
      'Collect statistics': 'Statistiken sammeln',
      'Local state file': 'Lokale Statusdatei',
      'Start failed': 'Start fehlgeschlagen',
      'Stop failed': 'Stop fehlgeschlagen',
      'Extended session': 'Sitzung verlängert',
      'Cancel': 'Abbrechen',
      'Clear': 'Leeren',
      'Choose target': 'Ziel wählen',
      'Use default': 'Standard verwenden',
      'Record shortcut': 'Kurzbefehl aufzeichnen',
      'Clear now': 'Jetzt leeren',
      'Send feedback': 'Feedback senden',
      'Feedback': 'Feedback',
      'User Feedback': 'Nutzerfeedback',
      'Tell us what happened or what you want improved.':
          'Sag uns, was passiert ist oder was verbessert werden soll.',
      'Rating': 'Bewertung',
      'Content': 'Inhalt',
      'Describe your feedback': 'Beschreibe dein Feedback',
      'Contact (optional)': 'Kontakt (optional)',
      'Email or phone, optional': 'E-Mail oder Telefon, optional',
      'Feedback is saved with appScene: stayAwake.':
          'Feedback wird mit appScene: stayAwake gespeichert.',
      'Server records for StayAwake feedback.':
          'Zeigt StayAwake-Feedback vom Server an.',
      'Submits feedback to the server.': 'Sendet Feedback an den Server.',
      'Official reply': 'Offizielle Antwort',
      'Reply time': 'Antwortzeit',
      'Feedback saved locally': 'Feedback lokal gespeichert',
      'Feedback submitted': 'Feedback gesendet',
      'Feedback server unavailable; saved locally for retry.':
          'Server nicht verfügbar; Feedback lokal zum Wiederholen gespeichert.',
      'Feedback failed to save': 'Feedback konnte nicht gespeichert werden',
      'Please enter feedback content.': 'Bitte Feedback eingeben.',
      'Submit feedback': 'Feedback senden',
      'Discover Apps': 'Apps entdecken',
      'Promoted apps are loaded from the app_cross_promotion resource scene.':
          'Beworbene Apps werden aus der Ressourcenszene app_cross_promotion geladen.',
      'Promotion resource unavailable': 'Promotion-Ressource nicht verfügbar',
      'Fallback examples are shown until the resource scene is configured.':
          'Beispiele werden angezeigt, bis die Ressourcenszene konfiguriert ist.',
      'Category': 'Kategorie',
      'Size': 'Größe',
      'Download': 'Laden',
      'No download link configured.': 'Kein Download-Link konfiguriert.',
      'Open link failed.': 'Link konnte nicht geöffnet werden.',
      'Create': 'Erstellen',
      'Productivity': 'Produktivität',
      'Focus timer and daily planning.': 'Fokus-Timer und Tagesplanung.',
      'Manage focus sessions, tasks, and routine planning.':
          'Verwalte Fokussitzungen, Aufgaben und Routinen.',
      'Focus timer': 'Fokus-Timer',
      'Task planning': 'Aufgabenplanung',
      'ACTIVE': 'AKTIV',
      'IDLE': 'INAKTIV',
    },
    'es': {
      'Automatic': 'Automático',
      'Follow system': 'Seguir sistema',
      'Chinese': 'Chino',
      'Japanese': 'Japonés',
      'French': 'Francés',
      'Italian': 'Italiano',
      'German': 'Alemán',
      'Spanish': 'Español',
      'Language': 'Idioma',
      'Status': 'Estado',
      'Sessions': 'Sesiones',
      'Stay Awake Rules': 'Reglas anti-suspensión',
      'Settings': 'Ajustes',
      'Inactive': 'Inactivo',
      'Ending': 'Finalizando',
      'Indefinite': 'Indefinido',
      'Manual': 'Manual',
      'Menu bar': 'Barra de menús',
      'Automation': 'Automatización',
      'Native assertion active': 'Aserción nativa activa',
      'Starting native assertion...': 'Iniciando aserción nativa...',
      'Stopping...': 'Deteniendo...',
      'Native bridge unavailable': 'Puente nativo no disponible',
      'Quick sessions': 'Sesiones rápidas',
      'Sleep behavior': 'Comportamiento de reposo',
      'Screen saver': 'Salvapantallas',
      'Stop keeping awake': 'Dejar de mantener activo',
      'Start 1 hour': 'Iniciar 1 hora',
      'Menu bar controls enabled': 'Controles de barra de menús activados',
      'Power source': 'Fuente de energía',
      'Activity': 'Actividad',
      'Session active': 'Sesión activa',
      'No active session': 'Sin sesión activa',
      'Native bridge': 'Puente nativo',
      'Status bar': 'Barra de estado',
      'Session defaults': 'Valores de sesión',
      'General': 'General',
      'System controls': 'Controles del sistema',
      'Triggers': 'Activadores',
      'Disk wake': 'Disco activo',
      'Hotkeys': 'Atajos',
      'Notifications': 'Notificaciones',
      'Appearance': 'Apariencia',
      'Statistics': 'Estadísticas',
      'Default duration': 'Duración predeterminada',
      'Prevent display sleep': 'Evitar reposo de pantalla',
      'Allow screen saver after idle':
          'Permitir salvapantallas tras inactividad',
      'Start at login': 'Iniciar al iniciar sesión',
      'Hide StayAwake in Dock': 'Ocultar StayAwake en el Dock',
      'Reduce motion': 'Reducir movimiento',
      'Enable triggers': 'Activar disparadores',
      'Keep disk awake': 'Mantener disco activo',
      'Enable global shortcut': 'Activar atajo global',
      'Show notifications': 'Mostrar notificaciones',
      'Menu bar icon': 'Icono de barra de menús',
      'Collect statistics': 'Recopilar estadísticas',
      'Local state file': 'Archivo de estado local',
      'Start failed': 'Error al iniciar',
      'Stop failed': 'Error al detener',
      'Extended session': 'Sesión extendida',
      'Cancel': 'Cancelar',
      'Clear': 'Borrar',
      'Choose target': 'Elegir destino',
      'Use default': 'Usar predeterminado',
      'Record shortcut': 'Grabar atajo',
      'Clear now': 'Borrar ahora',
      'Send feedback': 'Enviar comentarios',
      'Feedback': 'Comentarios',
      'User Feedback': 'Comentarios de usuarios',
      'Tell us what happened or what you want improved.':
          'Cuéntanos qué pasó o qué quieres mejorar.',
      'Rating': 'Valoración',
      'Content': 'Contenido',
      'Describe your feedback': 'Describe tus comentarios',
      'Contact (optional)': 'Contacto (opcional)',
      'Email or phone, optional': 'Email o teléfono, opcional',
      'Feedback is saved with appScene: stayAwake.':
          'Los comentarios se guardan con appScene: stayAwake.',
      'Server records for StayAwake feedback.':
          'Muestra comentarios de StayAwake desde el servidor.',
      'Submits feedback to the server.': 'Envía los comentarios al servidor.',
      'Official reply': 'Respuesta oficial',
      'Reply time': 'Hora de respuesta',
      'Feedback saved locally': 'Comentarios guardados localmente',
      'Feedback submitted': 'Comentarios enviados',
      'Feedback server unavailable; saved locally for retry.':
          'Servidor no disponible; comentarios guardados localmente para reintentar.',
      'Feedback failed to save': 'No se pudieron guardar los comentarios',
      'Please enter feedback content.': 'Ingresa el contenido del comentario.',
      'Submit feedback': 'Enviar',
      'Discover Apps': 'Descubrir apps',
      'Promoted apps are loaded from the app_cross_promotion resource scene.':
          'Las apps promocionadas se cargan desde la escena de recursos app_cross_promotion.',
      'Promotion resource unavailable': 'Recurso promocional no disponible',
      'Fallback examples are shown until the resource scene is configured.':
          'Se muestran ejemplos hasta que la escena de recursos esté configurada.',
      'Category': 'Categoría',
      'Size': 'Tamaño',
      'Download': 'Descargar',
      'No download link configured.': 'No hay enlace de descarga configurado.',
      'Open link failed.': 'No se pudo abrir el enlace.',
      'Create': 'Crear',
      'Productivity': 'Productividad',
      'Focus timer and daily planning.':
          'Temporizador de enfoque y planificación diaria.',
      'Manage focus sessions, tasks, and routine planning.':
          'Gestiona sesiones de enfoque, tareas y rutinas.',
      'Focus timer': 'Temporizador de enfoque',
      'Task planning': 'Planificación de tareas',
      'ACTIVE': 'ACTIVO',
      'IDLE': 'INACTIVO',
    },
  };
}

String _navTitle(AppText text, NavigationSection section) {
  return switch (section) {
    NavigationSection.status => text.pick('Status', '状态'),
    NavigationSection.sessions => text.pick('Sessions', '会话'),
    NavigationSection.rules => text.pick('Stay Awake Rules', '保持唤醒规则'),
    NavigationSection.settings => text.pick('Settings', '设置'),
    NavigationSection.feedback => text.pick('User Feedback', '用户反馈'),
    NavigationSection.promotions => text.pick('Discover Apps', '发现更多应用'),
  };
}

String _sessionRemainingLabel(AppText text, AwakeSession session) {
  if (!session.isActive) return text.pick('Inactive', '未开启');
  if (session.endsAt == null) return text.indefinite;
  final remaining = session.endsAt!.difference(DateTime.now());
  if (remaining.isNegative) return text.pick('Ending', '即将结束');
  final hours = remaining.inHours;
  final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}

String _sessionSourceLabel(AppText text, SessionSource source) {
  return switch (source) {
    SessionSource.manual => text.pick('Manual', '手动'),
    SessionSource.menuBar => text.pick('Menu bar', '菜单栏'),
    SessionSource.automation => text.pick('Automation', '自动规则'),
  };
}

String _nativeStatusLabel(AppText text, String status) {
  if (status == 'Ready') return text.pick('Ready', '就绪');
  if (status == 'Native assertion active') {
    return text.pick('Native assertion active', '原生防睡眠断言已开启');
  }
  if (status == 'Starting native assertion...') {
    return text.pick('Starting native assertion...', '正在开启原生防睡眠断言...');
  }
  if (status == 'Stopping...') return text.pick('Stopping...', '正在停止...');
  if (status.startsWith('Native bridge unavailable')) {
    return text.pick('Native bridge unavailable', '原生桥接不可用');
  }
  return status;
}

String _powerStatusLabel(AppText text, PowerStatus status) {
  if (!status.available) {
    return text.pick('Power status unavailable', '电源状态不可用');
  }
  final source = switch (status.source) {
    'AC Power' => text.pick('AC Power', '电源适配器'),
    'Battery Power' => text.pick('Battery Power', '电池供电'),
    _ => status.source,
  };
  final percent = status.batteryPercent == null
      ? ''
      : ' - ${status.batteryPercent}%';
  return '$source$percent';
}

String _downloadActivityLabel(AppText text, DownloadActivity activity) {
  if (!activity.available) {
    return text.pick('Downloads folder unavailable', '下载文件夹不可用');
  }
  if (activity.activeCount == 0) {
    return text.pick('No active browser download files', '没有正在下载的浏览器临时文件');
  }
  return text.pick(
    '${activity.activeCount} active download file${activity.activeCount == 1 ? '' : 's'}',
    '${activity.activeCount} 个正在下载的临时文件',
  );
}

String _frontmostAppLabel(AppText text, FrontmostApp app) {
  if (!app.available) {
    return text.pick('Frontmost app unavailable', '前台 App 不可用');
  }
  if (app.bundleIdentifier.isEmpty) return app.name;
  return '${app.name} (${app.bundleIdentifier})';
}

String _ruleTitle(AppText text, AwakeRule rule) {
  return switch (rule.id) {
    'plugged-in' => text.pick('Start when plugged in', '接入电源时开启'),
    'low-battery' => text.pick('Stop on low battery', '低电量时停止'),
    'menu-bar-window' => text.pick(
      'Keep menu bar control available',
      '保持菜单栏控制可用',
    ),
    'app-trigger' => text.pick('Running app trigger', '运行中 App 触发器'),
    'download-trigger' => text.pick('Download trigger', '下载触发器'),
    _ => rule.title,
  };
}

String _ruleDescription(AppText text, AwakeRule rule) {
  return switch (rule.id) {
    'plugged-in' => text.pick(
      'Automatically starts an indefinite session on AC power.',
      '接入电源时自动开启无限期会话。',
    ),
    'low-battery' => text.pick(
      'Stops active sessions when battery drops below the limit.',
      '电量低于阈值时停止当前会话。',
    ),
    'menu-bar-window' => text.pick(
      'The app stays open after the main window is closed.',
      '主窗口关闭后，应用仍在菜单栏中运行。',
    ),
    'app-trigger' => text.pick(
      'Start when the selected app is running.',
      '选中的 App 正在运行时开启会话。',
    ),
    'download-trigger' => text.pick(
      'Start while browser or system download temp files exist.',
      '浏览器或系统下载临时文件存在时开启会话。',
    ),
    _ => rule.description,
  };
}

class AppTextDelegate extends LocalizationsDelegate<AppText> {
  const AppTextDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppText.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppText> load(Locale locale) {
    final languageCode = locale.languageCode.toLowerCase();
    final resolved =
        AppLocaleController.fixedLanguageModes.contains(languageCode)
        ? Locale(languageCode)
        : const Locale('en');
    return SynchronousFuture<AppText>(AppText(resolved));
  }

  @override
  bool shouldReload(AppTextDelegate old) => false;
}

enum NavigationSection {
  status,
  sessions,
  rules,
  settings,
  feedback,
  promotions,
}

extension NavigationSectionX on NavigationSection {
  String get wireName => name;

  static NavigationSection? fromWire(String? value) {
    for (final section in NavigationSection.values) {
      if (section.name == value) return section;
    }
    return null;
  }
}

class StayAwakeHomePage extends StatefulWidget {
  const StayAwakeHomePage({super.key});

  @override
  State<StayAwakeHomePage> createState() => _StayAwakeHomePageState();
}

class _StayAwakeHomePageState extends State<StayAwakeHomePage> {
  static const _channel = MethodChannel('app.stayawake/status_bar');
  static final List<SessionPreset> _presets = [
    const SessionPreset('15m', Duration(minutes: 15)),
    const SessionPreset('30m', Duration(minutes: 30)),
    const SessionPreset('45m', Duration(minutes: 45)),
    const SessionPreset('1h', Duration(hours: 1)),
    const SessionPreset('2h', Duration(hours: 2)),
    const SessionPreset('4h', Duration(hours: 4)),
    const SessionPreset('8h', Duration(hours: 8)),
    const SessionPreset('Indefinite', null),
  ];

  final LocalStore _store = LocalStore();
  final LocalFeedbackStore _feedbackStore = LocalFeedbackStore();
  final RemoteFeedbackStore _remoteFeedbackStore = RemoteFeedbackStore(
    baseUrl: Params.mBaseUrl,
    appScene: Params.appScene,
  );
  Timer? _ticker;
  AwakeSession _session = AwakeSession.inactive();
  PowerStatus _powerStatus = PowerStatus.unknown();
  FrontmostApp _frontmostApp = FrontmostApp.unknown();
  List<RunningApp> _runningApps = const [];
  DownloadActivity _downloadActivity = DownloadActivity.unknown();
  AppSettings _settings = AppSettings.defaults();
  List<AwakeRule> _rules = AwakeRule.defaults();
  List<SessionLogEntry> _history = [];
  NavigationSection _selected = NavigationSection.status;
  String _nativeStatus = 'Ready';
  bool? _powerProtectHelperInstalled;
  bool _loading = false;
  bool _busy = false;
  bool _powerProtectHelperBusy = false;

  @override
  void initState() {
    super.initState();
    _channel.setMethodCallHandler(_handleNativeCall);
    _bootstrap();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final snapshot = await _store.read();
    if (!mounted) return;
    setState(() {
      _settings = snapshot.settings;
      _rules = snapshot.rules;
      _history = snapshot.history;
      _loading = false;
    });
    AppLocaleController.setLanguageMode(_settings.languageMode);
    await _syncFromNative();
    await _refreshPowerProtectHelperStatus();
    await _syncPreferencesToNative();
    await _refreshPowerStatus(applyRules: true);
    await _refreshFrontmostApp(applyRules: true);
    await _refreshRunningApps(applyRules: true);
    if (_ruleById('download-trigger')?.enabled == true) {
      await _refreshDownloadActivity(applyRules: true);
    }
    if (_settings.startSessionOnLaunch && !_session.isActive) {
      final duration = _settings.customDurationMinutes >= 480
          ? null
          : Duration(minutes: _settings.customDurationMinutes);
      await _startSession(duration, source: SessionSource.automation);
    }
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'startPreset':
        final seconds = call.arguments is int ? call.arguments as int : null;
        await _startSession(
          seconds == null ? null : Duration(seconds: seconds),
          source: SessionSource.menuBar,
        );
        return null;
      case 'stopSession':
        await _stopSession(reason: 'Stopped from menu bar');
        return null;
      case 'extendSession':
        final seconds = call.arguments is int ? call.arguments as int : null;
        if (seconds != null) {
          await _extendSession(Duration(seconds: seconds));
        }
        return null;
      case 'nativeStatusChanged':
        await _syncFromNative();
        await _refreshPowerProtectHelperStatus();
        return null;
      case 'openSection':
        final section = NavigationSectionX.fromWire(call.arguments?.toString());
        if (section != null && mounted) {
          setState(() => _selected = section);
        }
        return null;
      case 'toggleSetting':
        final args = call.arguments as Map?;
        await _handleNativeSettingToggle(
          args?['key']?.toString(),
          args?['value'] == true,
        );
        return null;
      case 'toggleRule':
        final args = call.arguments as Map?;
        final id = args?['id']?.toString();
        final enabled = args?['enabled'] == true;
        final rule = _ruleById(id);
        if (rule != null) {
          await _updateRule(rule, enabled);
        }
        return null;
      case 'selectRunningApp':
        final args = call.arguments as Map?;
        await _handleNativeRunningAppSelection(args);
        return null;
      default:
        return null;
    }
  }

  Future<void> _handleNativeSettingToggle(String? key, bool value) async {
    final nextSettings = switch (key) {
      'preventDisplaySleep' => _settings.copyWith(preventDisplaySleep: value),
      'allowScreenSaver' => _settings.copyWith(allowScreenSaver: value),
      'startAtLogin' => _settings.copyWith(startAtLogin: value),
      'allowSystemSleepWhenDisplayOff' => _settings.copyWith(
        allowSystemSleepWhenDisplayOff: value,
      ),
      'allowScreenLock' => _settings.copyWith(allowScreenLock: value),
      'lockScreenAfterIdle' => _settings.copyWith(lockScreenAfterIdle: value),
      'moveCursorAfterIdle' => _settings.copyWith(moveCursorAfterIdle: value),
      'triggersEnabled' => _settings.copyWith(triggersEnabled: value),
      'keepDiskAwake' => _settings.copyWith(keepDiskAwake: value),
      'hideHelperApps' => _settings.copyWith(hideHelperApps: value),
      'globalHotkeyEnabled' => _settings.copyWith(globalHotkeyEnabled: value),
      'showRemainingSessionTime' => _settings.copyWith(
        showRemainingSessionTime: value,
      ),
      _ => _settings,
    };
    await _updateSettings(nextSettings);
  }

  Future<void> _handleNativeRunningAppSelection(
    Map<dynamic, dynamic>? args,
  ) async {
    final name = args?['name']?.toString() ?? '';
    final bundleIdentifier = args?['bundleIdentifier']?.toString() ?? '';
    if (name.isEmpty || bundleIdentifier.isEmpty) return;

    final appRule = _ruleById('app-trigger');
    setState(() {
      _settings = _settings.copyWith(
        appTriggerName: name,
        appTriggerBundleId: bundleIdentifier,
      );
      if (appRule != null) {
        _rules = [
          for (final item in _rules)
            item.id == appRule.id ? item.copyWith(enabled: true) : item,
        ];
      }
    });
    await _persist();
    await _applyAppRules();
  }

  Future<void> _syncFromNative() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getStatus',
      );
      if (!mounted || result == null) return;
      final active = result['active'] == true;
      final nativeStartAtLogin = result['startAtLogin'] == true;
      final endsAtSeconds = result['endsAt'];
      DateTime? nativeEndsAt;
      if (endsAtSeconds is num) {
        nativeEndsAt = DateTime.fromMillisecondsSinceEpoch(
          (endsAtSeconds * 1000).round(),
        );
      }

      final shouldPersistSettings =
          _settings.startAtLogin != nativeStartAtLogin;
      setState(() {
        _nativeStatus = active ? 'Native assertion active' : 'Ready';
        if (shouldPersistSettings) {
          _settings = _settings.copyWith(startAtLogin: nativeStartAtLogin);
        }
        if (active && !_session.isActive) {
          _session = AwakeSession(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            startedAt: DateTime.now(),
            endsAt: nativeEndsAt,
            preventDisplaySleep: result['preventDisplaySleep'] == true,
            allowScreenSaver: result['allowScreenSaver'] == true,
            source: SessionSource.menuBar,
          );
        }
        if (!active && _session.isActive) {
          _session = AwakeSession.inactive();
        }
      });
      if (shouldPersistSettings) {
        await _persist();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _nativeStatus = 'Native bridge unavailable: $error';
      });
    }
  }

  Future<void> _refreshPowerStatus({bool applyRules = false}) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getPowerStatus',
      );
      if (!mounted || result == null) return;
      setState(() {
        _powerStatus = PowerStatus.fromJson(result);
      });
      if (applyRules) {
        await _applyPowerRules();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _powerStatus = PowerStatus.unknown();
      });
    }
  }

  Future<void> _refreshPowerProtectHelperStatus() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getPowerProtectHelperStatus',
      );
      if (!mounted || result == null) return;
      setState(() {
        _powerProtectHelperInstalled = _powerProtectHelperPresent(result);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _powerProtectHelperInstalled = null;
      });
    }
  }

  Future<void> _refreshFrontmostApp({bool applyRules = false}) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getFrontmostApp',
      );
      if (!mounted || result == null) return;
      setState(() {
        _frontmostApp = FrontmostApp.fromJson(result);
      });
      if (applyRules) {
        await _applyAppRules();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _frontmostApp = FrontmostApp.unknown();
      });
    }
  }

  void _tick() {
    if (_session.isActive && _session.endsAt != null) {
      if (DateTime.now().isAfter(_session.endsAt!)) {
        _stopSession(reason: 'Session ended automatically');
        return;
      }
      setState(() {});
    }

    if (DateTime.now().second % 30 == 0) {
      _refreshPowerStatus(applyRules: true);
      _refreshFrontmostApp(applyRules: true);
      _refreshRunningApps(applyRules: true);
      if (_ruleById('download-trigger')?.enabled == true) {
        _refreshDownloadActivity(applyRules: true);
      }
    }
  }

  Future<void> _applyPowerRules() async {
    if (_busy || !_settings.triggersEnabled) return;
    final powerRule = _rules.firstWhere((rule) => rule.id == 'plugged-in');
    final batteryRule = _rules.firstWhere((rule) => rule.id == 'low-battery');

    if (powerRule.enabled && _powerStatus.isPluggedIn && !_session.isActive) {
      await _startSession(null, source: SessionSource.automation);
      return;
    }

    final percent = _powerStatus.batteryPercent;
    if (batteryRule.enabled &&
        _session.isActive &&
        !_powerStatus.isPluggedIn &&
        percent != null &&
        percent <= _settings.lowBatteryStopPercent) {
      await _stopSession(reason: 'Stopped by low battery rule');
    }
  }

  Future<void> _applyAppRules() async {
    if (_busy || !_settings.triggersEnabled) return;
    final appRule = _rules.firstWhere((rule) => rule.id == 'app-trigger');
    if (!appRule.enabled ||
        _settings.appTriggerBundleId.isEmpty ||
        _runningApps.isEmpty) {
      return;
    }
    final isTargetRunning = _runningApps.any(
      (app) => app.bundleIdentifier == _settings.appTriggerBundleId,
    );
    if (isTargetRunning && !_session.isActive) {
      await _startSession(null, source: SessionSource.automation);
    }
  }

  Future<StayAwakeFeedbackRecord?> _submitFeedbackDraft(
    _FeedbackDraft draft,
  ) async {
    final text = AppText.of(context);
    final entry = StayAwakeFeedbackEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      appScene: Params.appScene,
      rating: draft.rating,
      content: draft.content,
      contact: draft.contact,
      language: AppLocaleController.effectiveLanguageCode(
        _settings.languageMode,
      ),
      platform: Platform.operatingSystem,
      status: 0,
      createdAt: DateTime.now(),
    );

    try {
      await _remoteFeedbackStore.submit(entry);
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text.pick('Feedback submitted', '反馈已提交'))),
      );
      return StayAwakeFeedbackRecord.fromEntry(entry);
    } catch (error) {
      try {
        await _feedbackStore.append(entry);
      } catch (_) {
        // Local fallback failed too; surface the server failure below.
      }
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            text.pick(
              'Feedback server unavailable; saved locally for retry.',
              '服务器暂不可用，反馈已暂存到本机，稍后可重试。',
            ),
          ),
        ),
      );
      debugPrint('StayAwake feedback submit failed: $error');
      return null;
    }
  }

  Future<void> _refreshRunningApps({bool applyRules = false}) async {
    try {
      final result = await _channel.invokeListMethod<dynamic>('getRunningApps');
      if (!mounted || result == null) return;
      setState(() {
        _runningApps = [
          for (final item in result)
            if (item is Map) RunningApp.fromJson(item),
        ];
      });
      if (applyRules) {
        await _applyAppRules();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _runningApps = const [];
      });
    }
  }

  Future<void> _refreshDownloadActivity({bool applyRules = false}) async {
    final home = Platform.environment['HOME'] ?? '';
    final downloads = Directory('$home/Downloads');
    if (home.isEmpty || !await downloads.exists()) {
      if (!mounted) return;
      setState(() => _downloadActivity = DownloadActivity.unknown());
      return;
    }

    var activeCount = 0;
    try {
      await for (final entity in downloads.list(recursive: false)) {
        final path = entity.path.toLowerCase();
        if (path.endsWith('.download') ||
            path.endsWith('.crdownload') ||
            path.endsWith('.part')) {
          activeCount += 1;
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _downloadActivity = DownloadActivity.unknown());
      return;
    }

    if (!mounted) return;
    setState(() {
      _downloadActivity = DownloadActivity(
        available: true,
        activeCount: activeCount,
        folderPath: downloads.path,
      );
    });
    if (applyRules) {
      await _applyDownloadRules();
    }
  }

  Future<void> _applyDownloadRules() async {
    if (_busy || !_settings.triggersEnabled) return;
    final downloadRule = _ruleById('download-trigger');
    if (downloadRule == null || !downloadRule.enabled) return;
    if (_downloadActivity.hasActiveDownloads && !_session.isActive) {
      await _startSession(null, source: SessionSource.automation);
    }
  }

  Future<void> _startSession(
    Duration? duration, {
    required SessionSource source,
  }) async {
    final now = DateTime.now();
    final nextSession = AwakeSession(
      id: now.millisecondsSinceEpoch.toString(),
      startedAt: now,
      endsAt: duration == null ? null : now.add(duration),
      preventDisplaySleep: _settings.preventDisplaySleep,
      allowScreenSaver: _settings.allowScreenSaver,
      source: source,
    );

    setState(() {
      _busy = true;
      _session = nextSession;
      _nativeStatus = 'Starting native assertion...';
    });

    try {
      await _channel.invokeMethod('startSession', {
        ..._nativePreferencesPayload(),
        'durationSeconds': duration?.inSeconds,
        'source': source.name,
      });
      if (!mounted) return;
      final text = AppText.of(context);
      setState(() {
        _nativeStatus = 'Native assertion active';
        _busy = false;
      });
      await _addHistory(
        SessionLogEntry(
          timestamp: now,
          title: text.pick(
            'Started ${nextSession.durationLabel}',
            '已开启 ${nextSession.durationLabel}',
          ),
          detail: text.pick(
            'Source: ${_sessionSourceLabel(text, source)}',
            '来源：${_sessionSourceLabel(text, source)}',
          ),
          kind: LogKind.start,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final text = AppText.of(context);
      setState(() {
        _session = AwakeSession.inactive();
        _nativeStatus = 'Failed to start native assertion: $error';
        _busy = false;
      });
      await _addHistory(
        SessionLogEntry(
          timestamp: DateTime.now(),
          title: text.pick('Start failed', '开启失败'),
          detail: '$error',
          kind: LogKind.error,
        ),
      );
    }
  }

  Future<void> _extendSession(Duration extension) async {
    if (!_session.isActive || _session.endsAt == null) {
      return;
    }
    final nextEndsAt = _session.endsAt!.add(extension);
    final remaining = nextEndsAt.difference(DateTime.now());
    if (remaining.isNegative) return;

    final nextSession = AwakeSession(
      id: _session.id,
      startedAt: _session.startedAt,
      endsAt: nextEndsAt,
      preventDisplaySleep: _session.preventDisplaySleep,
      allowScreenSaver: _session.allowScreenSaver,
      source: _session.source,
    );
    setState(() {
      _session = nextSession;
      _nativeStatus = 'Native assertion active';
    });

    await _channel.invokeMethod('startSession', {
      ..._nativePreferencesPayload(),
      'durationSeconds': remaining.inSeconds,
      'source': _session.source.name,
    });
    if (!mounted) return;
    final text = AppText.of(context);
    await _addHistory(
      SessionLogEntry(
        timestamp: DateTime.now(),
        title: text.pick('Extended session', '已延长会话'),
        detail: text.pick(
          'Added ${extension.inMinutes} minutes.',
          '已增加 ${extension.inMinutes} 分钟。',
        ),
        kind: LogKind.start,
      ),
    );
  }

  Future<void> _stopSession({required String reason}) async {
    final stoppedSession = _session;
    setState(() {
      _busy = true;
      _session = AwakeSession.inactive();
      _nativeStatus = 'Stopping...';
    });

    try {
      await _channel.invokeMethod('stopSession');
      if (!mounted) return;
      final text = AppText.of(context);
      setState(() {
        _nativeStatus = 'Ready';
        _busy = false;
      });
      if (stoppedSession.isActive) {
        await _addHistory(
          SessionLogEntry(
            timestamp: DateTime.now(),
            title: text.pick(
              'Stopped ${stoppedSession.durationLabel}',
              '已停止 ${stoppedSession.durationLabel}',
            ),
            detail: reason,
            kind: LogKind.stop,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      final text = AppText.of(context);
      setState(() {
        _nativeStatus = 'Stop request failed: $error';
        _busy = false;
      });
      await _addHistory(
        SessionLogEntry(
          timestamp: DateTime.now(),
          title: text.pick('Stop failed', '停止失败'),
          detail: '$error',
          kind: LogKind.error,
        ),
      );
    }
  }

  Future<void> _addHistory(SessionLogEntry entry) async {
    final nextHistory = [entry, ..._history].take(40).toList();
    setState(() {
      _history = nextHistory;
    });
    await _persist();
  }

  Future<void> _persist() {
    return _store.write(
      StoreSnapshot(settings: _settings, rules: _rules, history: _history),
    );
  }

  Future<void> _updateSettings(AppSettings settings) async {
    AppLocaleController.setLanguageMode(settings.languageMode);
    setState(() {
      _settings = settings;
    });
    await _persist();
    await _syncPreferencesToNative();
    await _applyAppRules();
  }

  Future<void> _recordGlobalHotkey() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'recordGlobalHotkey',
    );
    if (result == null) return;
    await _updateSettings(
      _settings.copyWith(
        globalHotkeyEnabled: true,
        globalHotkeyLabel:
            result['label']?.toString() ?? _settings.globalHotkeyLabel,
        globalHotkeyKeyCode: (result['keyCode'] as num?)?.round(),
        globalHotkeyModifiers: (result['modifiers'] as num?)?.round(),
      ),
    );
  }

  Future<void> _chooseDiskWakePath() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'chooseDiskWakePath',
    );
    if (result == null) return;
    await _updateSettings(
      _settings.copyWith(
        diskWakePath: result['path']?.toString() ?? '',
        diskWakeName: result['name']?.toString() ?? '',
      ),
    );
  }

  Future<void> _clearDiskWakePath() async {
    await _updateSettings(
      _settings.copyWith(diskWakePath: '', diskWakeName: ''),
    );
  }

  Future<void> _clearDeliveredNotifications() async {
    await _channel.invokeMethod('clearDeliveredNotifications');
  }

  Future<void> _installPowerProtectHelper() async {
    final text = AppText.of(context);
    setState(() => _powerProtectHelperBusy = true);
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'installPowerProtectHelper',
      );
      if (!mounted) return;
      final installed = _powerProtectHelperPresent(result);
      setState(() => _powerProtectHelperInstalled = installed);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            installed
                ? text.pick('Closed-display helper is installed.', '合盖助手已安装。')
                : text.pick(
                    'Closed-display helper was not installed.',
                    '合盖助手未安装。',
                  ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            text.pick('Helper installation failed: $error', '助手安装失败：$error'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _powerProtectHelperBusy = false);
      }
    }
  }

  Future<void> _removePowerProtectHelper() async {
    final text = AppText.of(context);
    setState(() => _powerProtectHelperBusy = true);
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'removePowerProtectHelper',
      );
      if (!mounted) return;
      final installed = _powerProtectHelperPresent(result);
      final success = result?['success'] == true;
      setState(() => _powerProtectHelperInstalled = installed);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success && !installed
                ? text.pick('Closed-display helper was removed.', '合盖助手已移除。')
                : text.pick(
                    'Closed-display helper was not removed.',
                    '合盖助手未移除。',
                  ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            text.pick('Helper removal failed: $error', '助手移除失败：$error'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _powerProtectHelperBusy = false);
      }
    }
  }

  bool _powerProtectHelperPresent(Map<String, dynamic>? result) {
    return result?['installed'] == true ||
        result?['hasLocalHelperFiles'] == true;
  }

  Future<void> _updateRule(AwakeRule rule, bool enabled) async {
    setState(() {
      _rules = [
        for (final item in _rules)
          item.id == rule.id ? item.copyWith(enabled: enabled) : item,
      ];
    });
    await _persist();
    await _syncPreferencesToNative();
    await _applyPowerRules();
    await _applyAppRules();
    if (rule.id == 'download-trigger' && enabled) {
      await _refreshDownloadActivity(applyRules: true);
    } else {
      await _applyDownloadRules();
    }
  }

  Future<void> _clearHistory() async {
    setState(() {
      _history = [];
    });
    await _persist();
  }

  Future<void> _syncPreferencesToNative() async {
    try {
      await _channel.invokeMethod(
        'syncPreferences',
        _nativePreferencesPayload(),
      );
    } catch (_) {
      // The Flutter UI remains the source of truth when the native menu is not available.
    }
  }

  Map<String, dynamic> _nativePreferencesPayload() {
    return {
      ..._settings.toJson(),
      'effectiveLanguageCode': AppLocaleController.effectiveLanguageCode(
        _settings.languageMode,
      ),
      'rules': {for (final rule in _rules) rule.id: rule.enabled},
    };
  }

  AwakeRule? _ruleById(String? id) {
    for (final rule in _rules) {
      if (rule.id == id) return rule;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final title = _navTitle(text, _selected);

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Sidebar(
              selected: _selected,
              session: _session,
              onSelect: (value) => setState(() => _selected = value),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 0, 26, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(
                      title: title,
                      session: _session,
                      nativeStatus: _nativeStatusLabel(text, _nativeStatus),
                      languageMode: _settings.languageMode,
                      powerProtectHelperInstalled: _powerProtectHelperInstalled,
                      powerProtectHelperBusy: _powerProtectHelperBusy,
                      onFeedbackPressed: () => setState(
                        () => _selected = NavigationSection.feedback,
                      ),
                      onLanguageChanged: (value) => _updateSettings(
                        _settings.copyWith(languageMode: value),
                      ),
                      onRemovePowerProtectHelper: _removePowerProtectHelper,
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: KeyedSubtree(
                        key: ValueKey(_selected),
                        child: _buildSection(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection() {
    if (_loading) {
      return const _Surface(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return switch (_selected) {
      NavigationSection.status => _StatusDashboard(
        session: _session,
        settings: _settings,
        presets: _presets,
        powerStatus: _powerStatus,
        nativeStatus: _nativeStatus,
        busy: _busy,
        onStart: (duration) =>
            _startSession(duration, source: SessionSource.manual),
        onStop: () => _stopSession(reason: 'Stopped from main window'),
        onRefreshPower: () => _refreshPowerStatus(applyRules: true),
      ),
      NavigationSection.sessions => _SessionsPage(
        presets: _presets,
        session: _session,
        settings: _settings,
        history: _history,
        busy: _busy,
        onStart: (duration) =>
            _startSession(duration, source: SessionSource.manual),
        onStop: () => _stopSession(reason: 'Stopped from sessions page'),
        onClearHistory: _clearHistory,
      ),
      NavigationSection.rules => _RulesPage(
        rules: _rules,
        settings: _settings,
        powerStatus: _powerStatus,
        frontmostApp: _frontmostApp,
        runningApps: _runningApps,
        downloadActivity: _downloadActivity,
        onChanged: _updateRule,
        onRefreshPower: () => _refreshPowerStatus(applyRules: true),
        onRefreshFrontmost: () => _refreshFrontmostApp(applyRules: true),
        onRefreshRunningApps: () => _refreshRunningApps(applyRules: true),
        onRefreshDownloads: () => _refreshDownloadActivity(applyRules: true),
        onSettingsChanged: _updateSettings,
        onUseFrontmostApp: () async {
          await _refreshFrontmostApp();
          await _updateSettings(
            _settings.copyWith(
              appTriggerName: _frontmostApp.name,
              appTriggerBundleId: _frontmostApp.bundleIdentifier,
            ),
          );
        },
        onChooseRunningApp: _chooseRunningApp,
        onClearAppTrigger: () => _updateSettings(
          _settings.copyWith(appTriggerName: '', appTriggerBundleId: ''),
        ),
      ),
      NavigationSection.settings => _SettingsPage(
        settings: _settings,
        storePath: _store.pathLabel,
        powerProtectHelperInstalled: _powerProtectHelperInstalled,
        powerProtectHelperBusy: _powerProtectHelperBusy,
        onChanged: _updateSettings,
        onRecordGlobalHotkey: _recordGlobalHotkey,
        onChooseDiskWakePath: _chooseDiskWakePath,
        onClearDiskWakePath: _clearDiskWakePath,
        onClearDeliveredNotifications: _clearDeliveredNotifications,
        onRefreshPowerProtectHelper: _refreshPowerProtectHelperStatus,
        onInstallPowerProtectHelper: _installPowerProtectHelper,
        onRemovePowerProtectHelper: _removePowerProtectHelper,
      ),
      NavigationSection.feedback => _FeedbackListPage(
        store: _remoteFeedbackStore,
        onSubmitFeedback: _submitFeedbackDraft,
      ),
      NavigationSection.promotions => const _AppPromotionPage(),
    };
  }

  Future<void> _chooseRunningApp() async {
    await _refreshRunningApps();
    if (!mounted) return;
    final text = AppText.of(context);

    var hideHelperApps = _settings.hideHelperApps;
    final selectedApp = await showDialog<RunningApp>(
      context: context,
      builder: (context) {
        var query = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredApps = _runningApps.where((app) {
              if (hideHelperApps && !app.isRegular) return false;
              final searchText = query.trim().toLowerCase();
              if (searchText.isEmpty) return true;
              return app.name.toLowerCase().contains(searchText) ||
                  app.bundleIdentifier.toLowerCase().contains(searchText);
            }).toList();

            return AlertDialog(
              title: Text(text.pick('Select running app', '选择运行中的 App')),
              content: SizedBox(
                width: 560,
                height: 520,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search_rounded),
                        hintText: text.pick('Search', '搜索'),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) => setDialogState(() => query = value),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filteredApps.isEmpty
                          ? _EmptyState(
                              icon: Icons.manage_search_rounded,
                              title: text.pick(
                                'No running apps match',
                                '没有匹配的运行中 App',
                              ),
                              detail: text.pick(
                                'Try a different search or show helpers.',
                                '换个关键词，或显示辅助进程。',
                              ),
                            )
                          : ListView.separated(
                              itemCount: filteredApps.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final app = filteredApps[index];
                                return ListTile(
                                  leading: Icon(
                                    app.isRegular
                                        ? Icons.apps_rounded
                                        : Icons.extension_rounded,
                                  ),
                                  title: Text(
                                    app.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    app.bundleIdentifier,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () => Navigator.of(context).pop(app),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: hideHelperApps,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        text.pick(
                          'Hide helper apps and processes',
                          '隐藏辅助 App 和进程',
                        ),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          hideHelperApps = value ?? true;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(text.pick('Cancel', '取消')),
                ),
              ],
            );
          },
        );
      },
    );

    await _updateSettings(_settings.copyWith(hideHelperApps: hideHelperApps));
    if (selectedApp == null) return;
    await _updateSettings(
      _settings.copyWith(
        appTriggerName: selectedApp.name,
        appTriggerBundleId: selectedApp.bundleIdentifier,
      ),
    );
  }
}

class AwakeSession {
  const AwakeSession({
    required this.id,
    required this.startedAt,
    required this.endsAt,
    required this.preventDisplaySleep,
    required this.allowScreenSaver,
    required this.source,
  });

  factory AwakeSession.inactive() {
    return const AwakeSession(
      id: '',
      startedAt: null,
      endsAt: null,
      preventDisplaySleep: true,
      allowScreenSaver: false,
      source: SessionSource.manual,
    );
  }

  final String id;
  final DateTime? startedAt;
  final DateTime? endsAt;
  final bool preventDisplaySleep;
  final bool allowScreenSaver;
  final SessionSource source;

  bool get isActive => startedAt != null;

  String get remainingLabel {
    if (!isActive) return 'Inactive';
    if (endsAt == null) return 'Indefinite';
    final remaining = endsAt!.difference(DateTime.now());
    if (remaining.isNegative) return 'Ending';
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  String get durationLabel {
    if (!isActive) return 'session';
    if (endsAt == null || startedAt == null) return 'indefinite session';
    final total = endsAt!.difference(startedAt!);
    if (total.inHours >= 1) return '${total.inHours}h session';
    return '${total.inMinutes}m session';
  }

  double get progress {
    if (!isActive || endsAt == null || startedAt == null) {
      return isActive ? 1 : 0;
    }
    final total = endsAt!.difference(startedAt!).inSeconds;
    if (total <= 0) return 0;
    final remaining = endsAt!.difference(DateTime.now()).inSeconds;
    return (remaining / total).clamp(0, 1).toDouble();
  }
}

class SessionPreset {
  const SessionPreset(this.label, this.duration);

  final String label;
  final Duration? duration;
}

enum SessionSource {
  manual('Manual'),
  menuBar('Menu bar'),
  automation('Automation');

  const SessionSource(this.label);

  final String label;
}

enum LogKind { start, stop, error }

class SessionLogEntry {
  const SessionLogEntry({
    required this.timestamp,
    required this.title,
    required this.detail,
    required this.kind,
  });

  final DateTime timestamp;
  final String title;
  final String detail;
  final LogKind kind;

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'title': title,
      'detail': detail,
      'kind': kind.name,
    };
  }

  factory SessionLogEntry.fromJson(Map<String, dynamic> json) {
    return SessionLogEntry(
      timestamp:
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      title: json['title']?.toString() ?? 'Session event',
      detail: json['detail']?.toString() ?? '',
      kind: LogKind.values.firstWhere(
        (value) => value.name == json['kind'],
        orElse: () => LogKind.start,
      ),
    );
  }
}

class AppSettings {
  const AppSettings({
    required this.preventDisplaySleep,
    required this.allowScreenSaver,
    required this.startAtLogin,
    required this.startSessionOnLaunch,
    required this.startSessionAfterWake,
    required this.showNotifications,
    required this.hideHelperApps,
    required this.hideInDock,
    required this.reduceMotion,
    required this.allowSystemSleepWhenDisplayOff,
    required this.allowScreenLock,
    required this.forceSleepEndsSession,
    required this.lockScreenAfterIdle,
    required this.lockWhenDisplayOff,
    required this.allowDisplaySleepWhenLocked,
    required this.moveCursorAfterIdle,
    required this.stopMovingCursorAfterMinutes,
    required this.endSessionOnUserSwitch,
    required this.triggersEnabled,
    required this.keepDiskAwake,
    required this.diskWakeIntervalSeconds,
    required this.diskWakePath,
    required this.diskWakeName,
    required this.globalHotkeyEnabled,
    required this.globalHotkeyKeyCode,
    required this.globalHotkeyModifiers,
    required this.globalHotkeyLabel,
    required this.showRemainingSessionTime,
    required this.showSessionDetailsInMenu,
    required this.showDiskDetailsInMenu,
    required this.dimInactiveMenuIcon,
    required this.manualMenuIconWidth,
    required this.collectStatistics,
    required this.sessionReminderMinutes,
    required this.notifyAutomationStart,
    required this.notifyAutomationEnd,
    required this.playStartStopSound,
    required this.playExtendSound,
    required this.clearDeliveredNotifications,
    required this.languageMode,
    required this.menuIconStyle,
    required this.activeSessionHotkey,
    required this.menuHotkey,
    required this.lowBatteryStopPercent,
    required this.customDurationMinutes,
    required this.appTriggerName,
    required this.appTriggerBundleId,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      preventDisplaySleep: true,
      allowScreenSaver: false,
      startAtLogin: false,
      startSessionOnLaunch: false,
      startSessionAfterWake: false,
      showNotifications: true,
      hideHelperApps: true,
      hideInDock: true,
      reduceMotion: false,
      allowSystemSleepWhenDisplayOff: true,
      allowScreenLock: false,
      forceSleepEndsSession: false,
      lockScreenAfterIdle: false,
      lockWhenDisplayOff: false,
      allowDisplaySleepWhenLocked: false,
      moveCursorAfterIdle: false,
      stopMovingCursorAfterMinutes: 30,
      endSessionOnUserSwitch: false,
      triggersEnabled: true,
      keepDiskAwake: false,
      diskWakeIntervalSeconds: 10,
      diskWakePath: '',
      diskWakeName: '',
      globalHotkeyEnabled: false,
      globalHotkeyKeyCode: 1,
      globalHotkeyModifiers: 6400,
      globalHotkeyLabel: '⌃⌥⌘S',
      showRemainingSessionTime: false,
      showSessionDetailsInMenu: true,
      showDiskDetailsInMenu: false,
      dimInactiveMenuIcon: false,
      manualMenuIconWidth: false,
      collectStatistics: true,
      sessionReminderMinutes: 60,
      notifyAutomationStart: true,
      notifyAutomationEnd: true,
      playStartStopSound: true,
      playExtendSound: true,
      clearDeliveredNotifications: true,
      languageMode: AppLocaleController.system,
      menuIconStyle: 'Pill',
      activeSessionHotkey: 'End current and start new',
      menuHotkey: 'Esc closes menu',
      lowBatteryStopPercent: 20,
      customDurationMinutes: 45,
      appTriggerName: '',
      appTriggerBundleId: '',
    );
  }

  final bool preventDisplaySleep;
  final bool allowScreenSaver;
  final bool startAtLogin;
  final bool startSessionOnLaunch;
  final bool startSessionAfterWake;
  final bool showNotifications;
  final bool hideHelperApps;
  final bool hideInDock;
  final bool reduceMotion;
  final bool allowSystemSleepWhenDisplayOff;
  final bool allowScreenLock;
  final bool forceSleepEndsSession;
  final bool lockScreenAfterIdle;
  final bool lockWhenDisplayOff;
  final bool allowDisplaySleepWhenLocked;
  final bool moveCursorAfterIdle;
  final int stopMovingCursorAfterMinutes;
  final bool endSessionOnUserSwitch;
  final bool triggersEnabled;
  final bool keepDiskAwake;
  final int diskWakeIntervalSeconds;
  final String diskWakePath;
  final String diskWakeName;
  final bool globalHotkeyEnabled;
  final int globalHotkeyKeyCode;
  final int globalHotkeyModifiers;
  final String globalHotkeyLabel;
  final bool showRemainingSessionTime;
  final bool showSessionDetailsInMenu;
  final bool showDiskDetailsInMenu;
  final bool dimInactiveMenuIcon;
  final bool manualMenuIconWidth;
  final bool collectStatistics;
  final int sessionReminderMinutes;
  final bool notifyAutomationStart;
  final bool notifyAutomationEnd;
  final bool playStartStopSound;
  final bool playExtendSound;
  final bool clearDeliveredNotifications;
  final String languageMode;
  final String menuIconStyle;
  final String activeSessionHotkey;
  final String menuHotkey;
  final int lowBatteryStopPercent;
  final int customDurationMinutes;
  final String appTriggerName;
  final String appTriggerBundleId;

  AppSettings copyWith({
    bool? preventDisplaySleep,
    bool? allowScreenSaver,
    bool? startAtLogin,
    bool? startSessionOnLaunch,
    bool? startSessionAfterWake,
    bool? showNotifications,
    bool? hideHelperApps,
    bool? hideInDock,
    bool? reduceMotion,
    bool? allowSystemSleepWhenDisplayOff,
    bool? allowScreenLock,
    bool? forceSleepEndsSession,
    bool? lockScreenAfterIdle,
    bool? lockWhenDisplayOff,
    bool? allowDisplaySleepWhenLocked,
    bool? moveCursorAfterIdle,
    int? stopMovingCursorAfterMinutes,
    bool? endSessionOnUserSwitch,
    bool? triggersEnabled,
    bool? keepDiskAwake,
    int? diskWakeIntervalSeconds,
    String? diskWakePath,
    String? diskWakeName,
    bool? globalHotkeyEnabled,
    int? globalHotkeyKeyCode,
    int? globalHotkeyModifiers,
    String? globalHotkeyLabel,
    bool? showRemainingSessionTime,
    bool? showSessionDetailsInMenu,
    bool? showDiskDetailsInMenu,
    bool? dimInactiveMenuIcon,
    bool? manualMenuIconWidth,
    bool? collectStatistics,
    int? sessionReminderMinutes,
    bool? notifyAutomationStart,
    bool? notifyAutomationEnd,
    bool? playStartStopSound,
    bool? playExtendSound,
    bool? clearDeliveredNotifications,
    String? languageMode,
    String? menuIconStyle,
    String? activeSessionHotkey,
    String? menuHotkey,
    int? lowBatteryStopPercent,
    int? customDurationMinutes,
    String? appTriggerName,
    String? appTriggerBundleId,
  }) {
    return AppSettings(
      preventDisplaySleep: preventDisplaySleep ?? this.preventDisplaySleep,
      allowScreenSaver: allowScreenSaver ?? this.allowScreenSaver,
      startAtLogin: startAtLogin ?? this.startAtLogin,
      startSessionOnLaunch: startSessionOnLaunch ?? this.startSessionOnLaunch,
      startSessionAfterWake:
          startSessionAfterWake ?? this.startSessionAfterWake,
      showNotifications: showNotifications ?? this.showNotifications,
      hideHelperApps: hideHelperApps ?? this.hideHelperApps,
      hideInDock: hideInDock ?? this.hideInDock,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      allowSystemSleepWhenDisplayOff:
          allowSystemSleepWhenDisplayOff ?? this.allowSystemSleepWhenDisplayOff,
      allowScreenLock: allowScreenLock ?? this.allowScreenLock,
      forceSleepEndsSession:
          forceSleepEndsSession ?? this.forceSleepEndsSession,
      lockScreenAfterIdle: lockScreenAfterIdle ?? this.lockScreenAfterIdle,
      lockWhenDisplayOff: lockWhenDisplayOff ?? this.lockWhenDisplayOff,
      allowDisplaySleepWhenLocked:
          allowDisplaySleepWhenLocked ?? this.allowDisplaySleepWhenLocked,
      moveCursorAfterIdle: moveCursorAfterIdle ?? this.moveCursorAfterIdle,
      stopMovingCursorAfterMinutes:
          stopMovingCursorAfterMinutes ?? this.stopMovingCursorAfterMinutes,
      endSessionOnUserSwitch:
          endSessionOnUserSwitch ?? this.endSessionOnUserSwitch,
      triggersEnabled: triggersEnabled ?? this.triggersEnabled,
      keepDiskAwake: keepDiskAwake ?? this.keepDiskAwake,
      diskWakeIntervalSeconds:
          diskWakeIntervalSeconds ?? this.diskWakeIntervalSeconds,
      diskWakePath: diskWakePath ?? this.diskWakePath,
      diskWakeName: diskWakeName ?? this.diskWakeName,
      globalHotkeyEnabled: globalHotkeyEnabled ?? this.globalHotkeyEnabled,
      globalHotkeyKeyCode: globalHotkeyKeyCode ?? this.globalHotkeyKeyCode,
      globalHotkeyModifiers:
          globalHotkeyModifiers ?? this.globalHotkeyModifiers,
      globalHotkeyLabel: globalHotkeyLabel ?? this.globalHotkeyLabel,
      showRemainingSessionTime:
          showRemainingSessionTime ?? this.showRemainingSessionTime,
      showSessionDetailsInMenu:
          showSessionDetailsInMenu ?? this.showSessionDetailsInMenu,
      showDiskDetailsInMenu:
          showDiskDetailsInMenu ?? this.showDiskDetailsInMenu,
      dimInactiveMenuIcon: dimInactiveMenuIcon ?? this.dimInactiveMenuIcon,
      manualMenuIconWidth: manualMenuIconWidth ?? this.manualMenuIconWidth,
      collectStatistics: collectStatistics ?? this.collectStatistics,
      sessionReminderMinutes:
          sessionReminderMinutes ?? this.sessionReminderMinutes,
      notifyAutomationStart:
          notifyAutomationStart ?? this.notifyAutomationStart,
      notifyAutomationEnd: notifyAutomationEnd ?? this.notifyAutomationEnd,
      playStartStopSound: playStartStopSound ?? this.playStartStopSound,
      playExtendSound: playExtendSound ?? this.playExtendSound,
      clearDeliveredNotifications:
          clearDeliveredNotifications ?? this.clearDeliveredNotifications,
      languageMode: AppLocaleController.normalized(
        languageMode ?? this.languageMode,
      ),
      menuIconStyle: menuIconStyle ?? this.menuIconStyle,
      activeSessionHotkey: activeSessionHotkey ?? this.activeSessionHotkey,
      menuHotkey: menuHotkey ?? this.menuHotkey,
      lowBatteryStopPercent:
          lowBatteryStopPercent ?? this.lowBatteryStopPercent,
      customDurationMinutes:
          customDurationMinutes ?? this.customDurationMinutes,
      appTriggerName: appTriggerName ?? this.appTriggerName,
      appTriggerBundleId: appTriggerBundleId ?? this.appTriggerBundleId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preventDisplaySleep': preventDisplaySleep,
      'allowScreenSaver': allowScreenSaver,
      'startAtLogin': startAtLogin,
      'startSessionOnLaunch': startSessionOnLaunch,
      'startSessionAfterWake': startSessionAfterWake,
      'showNotifications': showNotifications,
      'hideHelperApps': hideHelperApps,
      'hideInDock': hideInDock,
      'reduceMotion': reduceMotion,
      'allowSystemSleepWhenDisplayOff': allowSystemSleepWhenDisplayOff,
      'allowScreenLock': allowScreenLock,
      'forceSleepEndsSession': forceSleepEndsSession,
      'lockScreenAfterIdle': lockScreenAfterIdle,
      'lockWhenDisplayOff': lockWhenDisplayOff,
      'allowDisplaySleepWhenLocked': allowDisplaySleepWhenLocked,
      'moveCursorAfterIdle': moveCursorAfterIdle,
      'stopMovingCursorAfterMinutes': stopMovingCursorAfterMinutes,
      'endSessionOnUserSwitch': endSessionOnUserSwitch,
      'triggersEnabled': triggersEnabled,
      'keepDiskAwake': keepDiskAwake,
      'diskWakeIntervalSeconds': diskWakeIntervalSeconds,
      'diskWakePath': diskWakePath,
      'diskWakeName': diskWakeName,
      'globalHotkeyEnabled': globalHotkeyEnabled,
      'globalHotkeyKeyCode': globalHotkeyKeyCode,
      'globalHotkeyModifiers': globalHotkeyModifiers,
      'globalHotkeyLabel': globalHotkeyLabel,
      'showRemainingSessionTime': showRemainingSessionTime,
      'showSessionDetailsInMenu': showSessionDetailsInMenu,
      'showDiskDetailsInMenu': showDiskDetailsInMenu,
      'dimInactiveMenuIcon': dimInactiveMenuIcon,
      'manualMenuIconWidth': manualMenuIconWidth,
      'collectStatistics': collectStatistics,
      'sessionReminderMinutes': sessionReminderMinutes,
      'notifyAutomationStart': notifyAutomationStart,
      'notifyAutomationEnd': notifyAutomationEnd,
      'playStartStopSound': playStartStopSound,
      'playExtendSound': playExtendSound,
      'clearDeliveredNotifications': clearDeliveredNotifications,
      'languageMode': languageMode,
      'menuIconStyle': menuIconStyle,
      'activeSessionHotkey': activeSessionHotkey,
      'menuHotkey': menuHotkey,
      'lowBatteryStopPercent': lowBatteryStopPercent,
      'customDurationMinutes': customDurationMinutes,
      'appTriggerName': appTriggerName,
      'appTriggerBundleId': appTriggerBundleId,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings.defaults().copyWith(
      preventDisplaySleep: json['preventDisplaySleep'] == true,
      allowScreenSaver: json['allowScreenSaver'] == true,
      startAtLogin: json['startAtLogin'] == true,
      startSessionOnLaunch: json['startSessionOnLaunch'] == true,
      startSessionAfterWake: json['startSessionAfterWake'] == true,
      showNotifications: json['showNotifications'] != false,
      hideHelperApps: json['hideHelperApps'] != false,
      hideInDock: json['hideInDock'] != false,
      reduceMotion: json['reduceMotion'] == true,
      allowSystemSleepWhenDisplayOff:
          json['allowSystemSleepWhenDisplayOff'] != false,
      allowScreenLock: json['allowScreenLock'] == true,
      forceSleepEndsSession: json['forceSleepEndsSession'] == true,
      lockScreenAfterIdle: json['lockScreenAfterIdle'] == true,
      lockWhenDisplayOff: json['lockWhenDisplayOff'] == true,
      allowDisplaySleepWhenLocked: json['allowDisplaySleepWhenLocked'] == true,
      moveCursorAfterIdle: json['moveCursorAfterIdle'] == true,
      stopMovingCursorAfterMinutes:
          (json['stopMovingCursorAfterMinutes'] as num?)?.round().clamp(
            5,
            120,
          ) ??
          30,
      endSessionOnUserSwitch: json['endSessionOnUserSwitch'] == true,
      triggersEnabled: json['triggersEnabled'] != false,
      keepDiskAwake: json['keepDiskAwake'] == true,
      diskWakeIntervalSeconds:
          (json['diskWakeIntervalSeconds'] as num?)?.round().clamp(5, 120) ??
          10,
      diskWakePath: json['diskWakePath']?.toString() ?? '',
      diskWakeName: json['diskWakeName']?.toString() ?? '',
      globalHotkeyEnabled: json['globalHotkeyEnabled'] == true,
      globalHotkeyKeyCode:
          (json['globalHotkeyKeyCode'] as num?)?.round().clamp(0, 255) ?? 1,
      globalHotkeyModifiers:
          (json['globalHotkeyModifiers'] as num?)?.round() ?? 6400,
      globalHotkeyLabel: json['globalHotkeyLabel']?.toString() ?? '⌃⌥⌘S',
      showRemainingSessionTime: json['showRemainingSessionTime'] == true,
      showSessionDetailsInMenu: json['showSessionDetailsInMenu'] != false,
      showDiskDetailsInMenu: json['showDiskDetailsInMenu'] == true,
      dimInactiveMenuIcon: json['dimInactiveMenuIcon'] == true,
      manualMenuIconWidth: json['manualMenuIconWidth'] == true,
      collectStatistics: json['collectStatistics'] != false,
      sessionReminderMinutes:
          (json['sessionReminderMinutes'] as num?)?.round().clamp(5, 240) ?? 60,
      notifyAutomationStart: json['notifyAutomationStart'] != false,
      notifyAutomationEnd: json['notifyAutomationEnd'] != false,
      playStartStopSound: json['playStartStopSound'] != false,
      playExtendSound: json['playExtendSound'] != false,
      clearDeliveredNotifications: json['clearDeliveredNotifications'] != false,
      languageMode: AppLocaleController.normalized(
        json['languageMode']?.toString(),
      ),
      menuIconStyle: json['menuIconStyle']?.toString() ?? 'Pill',
      activeSessionHotkey:
          json['activeSessionHotkey']?.toString() ??
          'End current and start new',
      menuHotkey: json['menuHotkey']?.toString() ?? 'Esc closes menu',
      lowBatteryStopPercent:
          (json['lowBatteryStopPercent'] as num?)?.round().clamp(5, 80) ?? 20,
      customDurationMinutes:
          (json['customDurationMinutes'] as num?)?.round().clamp(5, 480) ?? 45,
      appTriggerName: json['appTriggerName']?.toString() ?? '',
      appTriggerBundleId: json['appTriggerBundleId']?.toString() ?? '',
    );
  }
}

class AwakeRule {
  const AwakeRule({
    required this.id,
    required this.title,
    required this.description,
    required this.enabled,
    required this.implemented,
  });

  final String id;
  final String title;
  final String description;
  final bool enabled;
  final bool implemented;

  static List<AwakeRule> defaults() {
    return const [
      AwakeRule(
        id: 'plugged-in',
        title: 'Start when plugged in',
        description: 'Automatically starts an indefinite session on AC power.',
        enabled: false,
        implemented: true,
      ),
      AwakeRule(
        id: 'low-battery',
        title: 'Stop on low battery',
        description:
            'Stops active sessions when battery drops below the limit.',
        enabled: true,
        implemented: true,
      ),
      AwakeRule(
        id: 'menu-bar-window',
        title: 'Keep menu bar control available',
        description: 'The app stays open after the main window is closed.',
        enabled: true,
        implemented: true,
      ),
      AwakeRule(
        id: 'app-trigger',
        title: 'Running app trigger',
        description: 'Start when the selected app is running.',
        enabled: false,
        implemented: true,
      ),
      AwakeRule(
        id: 'download-trigger',
        title: 'Download trigger',
        description: 'Start while browser or system download temp files exist.',
        enabled: false,
        implemented: true,
      ),
    ];
  }

  AwakeRule copyWith({bool? enabled}) {
    return AwakeRule(
      id: id,
      title: title,
      description: description,
      enabled: enabled ?? this.enabled,
      implemented: implemented,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'enabled': enabled};
  }
}

class PowerStatus {
  const PowerStatus({
    required this.source,
    required this.batteryPercent,
    required this.isPluggedIn,
    required this.available,
  });

  factory PowerStatus.unknown() {
    return const PowerStatus(
      source: 'Unknown',
      batteryPercent: null,
      isPluggedIn: false,
      available: false,
    );
  }

  factory PowerStatus.fromJson(Map<String, dynamic> json) {
    final source = json['source']?.toString() ?? 'Unknown';
    final percent = json['batteryPercent'];
    return PowerStatus(
      source: source,
      batteryPercent: percent is num ? percent.round().clamp(0, 100) : null,
      isPluggedIn: json['isPluggedIn'] == true,
      available: json['available'] == true,
    );
  }

  final String source;
  final int? batteryPercent;
  final bool isPluggedIn;
  final bool available;

  String get label {
    final percent = batteryPercent == null ? '' : ' - $batteryPercent%';
    return available ? '$source$percent' : 'Power status unavailable';
  }
}

class FrontmostApp {
  const FrontmostApp({
    required this.available,
    required this.name,
    required this.bundleIdentifier,
  });

  factory FrontmostApp.unknown() {
    return const FrontmostApp(
      available: false,
      name: 'Unknown',
      bundleIdentifier: '',
    );
  }

  factory FrontmostApp.fromJson(Map<String, dynamic> json) {
    return FrontmostApp(
      available: json['available'] == true,
      name: json['name']?.toString() ?? 'Unknown',
      bundleIdentifier: json['bundleIdentifier']?.toString() ?? '',
    );
  }

  final bool available;
  final String name;
  final String bundleIdentifier;

  String get label {
    if (!available) return 'Frontmost app unavailable';
    if (bundleIdentifier.isEmpty) return name;
    return '$name ($bundleIdentifier)';
  }
}

class RunningApp {
  const RunningApp({
    required this.name,
    required this.bundleIdentifier,
    required this.isRegular,
  });

  factory RunningApp.fromJson(Map<dynamic, dynamic> json) {
    return RunningApp(
      name: json['name']?.toString() ?? 'Unknown',
      bundleIdentifier: json['bundleIdentifier']?.toString() ?? '',
      isRegular: json['isRegular'] == true,
    );
  }

  final String name;
  final String bundleIdentifier;
  final bool isRegular;

  String get label =>
      bundleIdentifier.isEmpty ? name : '$name ($bundleIdentifier)';
}

class DownloadActivity {
  const DownloadActivity({
    required this.available,
    required this.activeCount,
    required this.folderPath,
  });

  factory DownloadActivity.unknown() {
    return const DownloadActivity(
      available: false,
      activeCount: 0,
      folderPath: '',
    );
  }

  final bool available;
  final int activeCount;
  final String folderPath;

  bool get hasActiveDownloads => activeCount > 0;

  String get label {
    if (!available) return 'Downloads folder unavailable';
    if (activeCount == 0) return 'No active browser download files';
    return '$activeCount active download file${activeCount == 1 ? '' : 's'}';
  }
}

class StoreSnapshot {
  const StoreSnapshot({
    required this.settings,
    required this.rules,
    required this.history,
  });

  factory StoreSnapshot.defaults() {
    return StoreSnapshot(
      settings: AppSettings.defaults(),
      rules: AwakeRule.defaults(),
      history: const [],
    );
  }

  final AppSettings settings;
  final List<AwakeRule> rules;
  final List<SessionLogEntry> history;
}

class LocalStore {
  String get pathLabel => _storeFile.path;

  File get _storeFile {
    final home = Platform.environment['HOME'] ?? Directory.systemTemp.path;
    return File('$home/Library/Application Support/StayAwake/state.json');
  }

  Future<StoreSnapshot> read() async {
    try {
      final file = _storeFile;
      if (!await file.exists()) return StoreSnapshot.defaults();
      final json = jsonDecode(await file.readAsString());
      if (json is! Map<String, dynamic>) return StoreSnapshot.defaults();
      final defaultRules = AwakeRule.defaults();
      final savedRules = <String, Map<String, dynamic>>{
        for (final item in (json['rules'] as List? ?? const []))
          if (item is Map<String, dynamic> && item['id'] != null)
            item['id'].toString(): item,
      };
      final rules = [
        for (final rule in defaultRules)
          rule.copyWith(
            enabled: savedRules[rule.id]?['enabled'] as bool? ?? rule.enabled,
          ),
      ];
      return StoreSnapshot(
        settings: json['settings'] is Map<String, dynamic>
            ? AppSettings.fromJson(json['settings'] as Map<String, dynamic>)
            : AppSettings.defaults(),
        rules: rules,
        history: [
          for (final item in (json['history'] as List? ?? const []))
            if (item is Map<String, dynamic>) SessionLogEntry.fromJson(item),
        ],
      );
    } catch (_) {
      return StoreSnapshot.defaults();
    }
  }

  Future<void> write(StoreSnapshot snapshot) async {
    final file = _storeFile;
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'settings': snapshot.settings.toJson(),
        'rules': [for (final rule in snapshot.rules) rule.toJson()],
        'history': [for (final entry in snapshot.history) entry.toJson()],
      }),
    );
  }
}

class StayAwakeFeedbackEntry {
  const StayAwakeFeedbackEntry({
    required this.id,
    required this.appScene,
    required this.rating,
    required this.content,
    required this.contact,
    required this.language,
    required this.platform,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String appScene;
  final int rating;
  final String content;
  final String contact;
  final String language;
  final String platform;
  final int status;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appScene': appScene,
      'title': 'StayAwake feedback',
      'rating': rating,
      'content': content,
      'contact': contact,
      'avatar': '',
      'username': '',
      'uid': '',
      'device_id': '',
      'countryCode': language,
      'language': language,
      'platform': platform,
      'market': 'Mac',
      'storeReviewPrompted': false,
      'status': status,
      'create_time': createdAt.millisecondsSinceEpoch,
      'createdAt': createdAt.toIso8601String(),
      'source': 'topRightFeedback',
    };
  }
}

class StayAwakeFeedbackRecord {
  const StayAwakeFeedbackRecord({
    required this.objectId,
    required this.appScene,
    required this.title,
    required this.content,
    required this.rating,
    required this.contact,
    required this.platform,
    required this.market,
    required this.status,
    required this.officialReply,
    required this.officialReplyAt,
    required this.handledAt,
    required this.createdAt,
  });

  factory StayAwakeFeedbackRecord.fromEntry(StayAwakeFeedbackEntry entry) {
    return StayAwakeFeedbackRecord(
      objectId: entry.id,
      appScene: entry.appScene,
      title: 'StayAwake feedback',
      content: entry.content,
      rating: entry.rating,
      contact: entry.contact,
      platform: entry.platform,
      market: 'Mac',
      status: entry.status,
      officialReply: '',
      officialReplyAt: 0,
      handledAt: 0,
      createdAt: entry.createdAt,
    );
  }

  factory StayAwakeFeedbackRecord.fromJson(Map<String, dynamic> json) {
    return StayAwakeFeedbackRecord(
      objectId: (json['_id'] ?? json['objectId'] ?? '').toString(),
      appScene: (json['appScene'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      rating: json['rating'] is int
          ? json['rating'] as int
          : int.tryParse('${json['rating']}') ?? 0,
      contact: (json['contact'] ?? '').toString(),
      platform: (json['platform'] ?? '').toString(),
      market: (json['market'] ?? '').toString(),
      status: json['status'] is int
          ? json['status'] as int
          : int.tryParse('${json['status']}') ?? 0,
      officialReply: (json['officialReply'] ?? '').toString(),
      officialReplyAt: _jsonInt(json['officialReplyAt']),
      handledAt: _jsonInt(json['handledAt']),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }

  final String objectId;
  final String appScene;
  final String title;
  final String content;
  final int rating;
  final String contact;
  final String platform;
  final String market;
  final int status;
  final String officialReply;
  final int officialReplyAt;
  final int handledAt;
  final DateTime? createdAt;
}

int _jsonInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

class RemoteFeedbackStore {
  const RemoteFeedbackStore({required this.baseUrl, required this.appScene});

  final String baseUrl;
  final String appScene;

  Uri get _commentModelUri {
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return Uri.parse(normalizedBase).replace(
      path:
          '${Uri.parse(normalizedBase).path}${Apis.commentModel.substring(1)}',
      queryParameters: const {
        '_ApplicationId': 'applicationId',
        '_RestKey': 'applicationKey',
        '_ClientVersion': 'dart1.0.0',
      },
    );
  }

  Future<void> submit(StayAwakeFeedbackEntry entry) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.postUrl(_commentModelUri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(entry.toJson()));
      final response = await request.close().timeout(
        const Duration(seconds: 12),
      );
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Feedback HTTP ${response.statusCode}: $body',
          uri: _commentModelUri,
        );
      }
      if (body.isNotEmpty) {
        final decoded = jsonDecode(body);
        if (decoded is Map && decoded['success'] == false) {
          throw StateError(decoded['message'] ?? 'Feedback submit failed');
        }
      }
    } finally {
      client.close(force: true);
    }
  }

  Future<List<StayAwakeFeedbackRecord>> list({int limit = 50}) async {
    final uri = _commentModelUri.replace(
      queryParameters: {
        ..._commentModelUri.queryParameters,
        'order': 'create_time',
        'orderValue': '-1',
        'limit': '$limit',
      },
    );
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(
        const Duration(seconds: 12),
      );
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Feedback list HTTP ${response.statusCode}: $body');
      }
      final decoded = jsonDecode(body);
      if (decoded is! Map || decoded['success'] == false) {
        throw StateError('Feedback list failed');
      }
      final data = decoded['data'];
      final results = data is Map ? data['results'] : null;
      if (results is! List) return const [];
      final records = [
        for (final item in results)
          if (item is Map<String, dynamic>)
            StayAwakeFeedbackRecord.fromJson(item),
      ].where(_isStayAwakeRecord).toList();
      return records..sort((left, right) {
        final leftTime =
            left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final rightTime =
            right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return rightTime.compareTo(leftTime);
      });
    } finally {
      client.close(force: true);
    }
  }

  bool _isStayAwakeRecord(StayAwakeFeedbackRecord record) {
    if (record.appScene == appScene) return true;
    return record.title.toLowerCase().contains('stayawake');
  }
}

class LocalFeedbackStore {
  String get pathLabel => _feedbackFile.path;

  File get _feedbackFile {
    final home = Platform.environment['HOME'] ?? Directory.systemTemp.path;
    return File('$home/Library/Application Support/StayAwake/feedback.json');
  }

  Future<void> append(StayAwakeFeedbackEntry entry) async {
    final file = _feedbackFile;
    await file.parent.create(recursive: true);
    final saved = <Map<String, dynamic>>[];

    if (await file.exists()) {
      try {
        final json = jsonDecode(await file.readAsString());
        if (json is List) {
          for (final item in json) {
            if (item is Map<String, dynamic>) {
              saved.add(item);
            }
          }
        }
      } catch (_) {
        saved.clear();
      }
    }

    saved.add(entry.toJson());
    final retained = saved.length > 200
        ? saved.sublist(saved.length - 200)
        : saved;
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(retained),
    );
  }
}

Map<String, dynamic> _decodePromotionMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return {
      for (final entry in value.entries) entry.key.toString(): entry.value,
    };
  }
  if (value is String && value.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      return _decodePromotionMap(decoded);
    } catch (_) {
      return const {};
    }
  }
  return const {};
}

List<String> _decodePromotionList(dynamic value) {
  if (value is List) return [for (final item in value) item.toString()];
  if (value is String && value.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      return _decodePromotionList(decoded);
    } catch (_) {
      return value
          .split(RegExp(r'[,，]'))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
  }
  return const [];
}

void _collectPromotionResourceMaps(
  dynamic value,
  List<Map<String, dynamic>> output,
) {
  if (value is Map) {
    final map = _decodePromotionMap(value);
    final looksLikePromotion =
        map.containsKey('resource_title') ||
        map.containsKey('delivery_name') ||
        map.containsKey('extend_params') ||
        map.containsKey('appCode');
    if (looksLikePromotion) output.add(map);
    for (final nested in map.values) {
      if (nested is Map || nested is List) {
        _collectPromotionResourceMaps(nested, output);
      }
    }
  } else if (value is List) {
    for (final item in value) {
      _collectPromotionResourceMaps(item, output);
    }
  }
}

String _currentPromotionPlatform() {
  if (Platform.isMacOS) return 'macos';
  if (Platform.isWindows) return 'windows';
  if (Platform.isAndroid) return 'android';
  if (Platform.isIOS) return 'ios';
  return 'web';
}

String _promotionPlatformTitle(String platform) {
  return switch (platform) {
    'macos' => 'macOS',
    'windows' => 'Windows',
    'android' => 'Android',
    'ios' => 'iOS',
    _ => 'Web',
  };
}

List<AppPromotionItem> _fallbackPromotionItems(AppText text) {
  return [
    AppPromotionItem(
      appCode: 'timerbell',
      appScene: 'efficientTime',
      title: 'Timerbell',
      subtitle: text.pick('Focus timer and daily planning.', '专注计时与日常计划。'),
      category: text.pick('Productivity', '效率'),
      description: text.pick(
        'Manage focus sessions, tasks, and routine planning.',
        '管理专注会话、任务和日常计划。',
      ),
      iconUrl: '',
      bannerUrl: '',
      downloadUrl: 'https://www.timerbell.com/web',
      redirectUrl: 'https://www.timerbell.com/web',
      rating: '4.8',
      fileSize: '',
      features: [
        text.pick('Focus timer', '专注计时'),
        text.pick('Task planning', '任务计划'),
        text.pick('Statistics', '统计'),
      ],
      platforms: const [
        AppPromotionPlatformLink(
          platform: 'macos',
          title: 'macOS',
          subtitle: '',
          url: 'https://www.timerbell.com/web',
        ),
        AppPromotionPlatformLink(
          platform: 'ios',
          title: 'iOS',
          subtitle: '',
          url: 'https://www.timerbell.com/web',
        ),
        AppPromotionPlatformLink(
          platform: 'android',
          title: 'Android',
          subtitle: '',
          url: 'https://www.timerbell.com/web',
        ),
        AppPromotionPlatformLink(
          platform: 'windows',
          title: 'Windows',
          subtitle: '',
          url: 'https://www.timerbell.com/web',
        ),
        AppPromotionPlatformLink(
          platform: 'web',
          title: 'Web',
          subtitle: '',
          url: 'https://www.timerbell.com/web',
        ),
      ],
      sort: 100,
      enabled: true,
    ),
  ];
}

class AppPromotionPlatformLink {
  const AppPromotionPlatformLink({
    required this.platform,
    required this.title,
    required this.subtitle,
    required this.url,
  });

  final String platform;
  final String title;
  final String subtitle;
  final String url;
}

class AppPromotionItem {
  const AppPromotionItem({
    required this.appCode,
    required this.appScene,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.description,
    required this.iconUrl,
    required this.bannerUrl,
    required this.downloadUrl,
    required this.redirectUrl,
    required this.rating,
    required this.fileSize,
    required this.features,
    required this.platforms,
    required this.sort,
    required this.enabled,
  });

  final String appCode;
  final String appScene;
  final String title;
  final String subtitle;
  final String category;
  final String description;
  final String iconUrl;
  final String bannerUrl;
  final String downloadUrl;
  final String redirectUrl;
  final String rating;
  final String fileSize;
  final List<String> features;
  final List<AppPromotionPlatformLink> platforms;
  final int sort;
  final bool enabled;

  factory AppPromotionItem.fromResource(Map<String, dynamic> json) {
    final extendParams = _decodePromotionMap(
      json['extend_params'] ??
          json['extendParams'] ??
          json['extend_params_map'] ??
          json['extendParamsMap'],
    );
    final merged = <String, dynamic>{...json, ...extendParams};
    final platformsJson = _decodePromotionMap(merged['platforms']);
    final platforms = <AppPromotionPlatformLink>[
      for (final entry in platformsJson.entries)
        if (entry.value is Map)
          AppPromotionPlatformLink(
            platform: entry.key,
            title: (entry.value['title'] ?? _promotionPlatformTitle(entry.key))
                .toString(),
            subtitle: (entry.value['subtitle'] ?? '').toString(),
            url: (entry.value['url'] ?? '').toString(),
          ),
    ];
    final features = _decodePromotionList(merged['features']);
    return AppPromotionItem(
      appCode:
          (merged['appCode'] ??
                  merged['app_code'] ??
                  merged['delivery_name'] ??
                  merged['resource_code'] ??
                  '')
              .toString(),
      appScene: (merged['appScene'] ?? merged['app_scene'] ?? '').toString(),
      title: (merged['title'] ?? merged['resource_title'] ?? '').toString(),
      subtitle: (merged['subtitle'] ?? merged['resource_content'] ?? '')
          .toString(),
      category: (merged['category'] ?? '').toString(),
      description:
          (merged['description'] ??
                  merged['resource_description'] ??
                  merged['resource_content'] ??
                  '')
              .toString(),
      iconUrl: (merged['iconUrl'] ?? merged['resource_icon_url'] ?? '')
          .toString(),
      bannerUrl: (merged['bannerUrl'] ?? merged['resource_picture_url'] ?? '')
          .toString(),
      downloadUrl:
          (merged['downloadUrl'] ??
                  merged['download_url'] ??
                  merged['primaryDownloadUrl'] ??
                  merged['primary_download_url'] ??
                  merged['resource_redirect_url'] ??
                  '')
              .toString(),
      redirectUrl:
          (merged['redirectUrl'] ?? merged['resource_redirect_url'] ?? '')
              .toString(),
      rating: (merged['rating'] ?? '').toString(),
      fileSize: (merged['fileSize'] ?? merged['file_size'] ?? '').toString(),
      features: features,
      platforms: platforms,
      sort: int.tryParse('${merged['sort'] ?? 0}') ?? 0,
      enabled: merged['enabled'] != false && merged['is_enabled'] != false,
    );
  }

  AppPromotionItem copyWith({
    String? appCode,
    String? appScene,
    String? title,
    String? subtitle,
    String? category,
    String? description,
    String? iconUrl,
    String? bannerUrl,
    String? downloadUrl,
    String? redirectUrl,
    String? rating,
    String? fileSize,
    List<String>? features,
    List<AppPromotionPlatformLink>? platforms,
    int? sort,
    bool? enabled,
  }) {
    return AppPromotionItem(
      appCode: appCode ?? this.appCode,
      appScene: appScene ?? this.appScene,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      category: category ?? this.category,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      redirectUrl: redirectUrl ?? this.redirectUrl,
      rating: rating ?? this.rating,
      fileSize: fileSize ?? this.fileSize,
      features: features ?? this.features,
      platforms: platforms ?? this.platforms,
      sort: sort ?? this.sort,
      enabled: enabled ?? this.enabled,
    );
  }

  String get downloadButtonUrl {
    if (downloadUrl.isNotEmpty) return downloadUrl;
    if (redirectUrl.isNotEmpty) return redirectUrl;
    return currentPlatformUrl;
  }

  String get currentPlatformUrl {
    final current = _currentPromotionPlatform();
    for (final platform in platforms) {
      if (platform.platform == current && platform.url.isNotEmpty) {
        return platform.url;
      }
    }
    for (final platform in platforms) {
      if (platform.url.isNotEmpty) return platform.url;
    }
    return redirectUrl;
  }
}

class RemotePromotionStore {
  const RemotePromotionStore();

  Uri get _resourceUri {
    final normalizedBase = Params.mBaseUrl.endsWith('/')
        ? Params.mBaseUrl
        : '${Params.mBaseUrl}/';
    return Uri.parse(normalizedBase).replace(
      path:
          '${Uri.parse(normalizedBase).path}${Apis.getResourceList.substring(1)}',
    );
  }

  Future<List<AppPromotionItem>> list() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.postUrl(_resourceUri);
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'scene_code': Params.appPromotionSceneCode,
          'location_code': Params.appPromotionListLocationCode,
          'appScene': Params.appScene,
        }),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 12),
      );
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Promotion HTTP ${response.statusCode}: $body',
          uri: _resourceUri,
        );
      }
      final decoded = jsonDecode(body);
      final maps = <Map<String, dynamic>>[];
      _collectPromotionResourceMaps(decoded, maps);
      final items = maps
          .map(AppPromotionItem.fromResource)
          .where(_isVisiblePromotion)
          .toList();
      items.sort((left, right) => left.sort.compareTo(right.sort));
      return items;
    } finally {
      client.close(force: true);
    }
  }

  bool _isVisiblePromotion(AppPromotionItem item) {
    if (!item.enabled || item.title.isEmpty) return false;
    if (item.appScene == Params.appScene || item.appCode == Params.appScene) {
      return false;
    }
    return true;
  }
}

class _AppPromotionPage extends StatefulWidget {
  const _AppPromotionPage();

  @override
  State<_AppPromotionPage> createState() => _AppPromotionPageState();
}

class _AppPromotionPageState extends State<_AppPromotionPage> {
  final RemotePromotionStore _store = const RemotePromotionStore();
  final List<AppPromotionItem> _serverItems = [];
  Object? _loadError;
  bool _loading = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _loadPromotions(initial: true);
  }

  Future<void> _loadPromotions({bool initial = false}) async {
    setState(() {
      _loading = initial;
      _refreshing = !initial;
      _loadError = null;
    });
    try {
      final items = await _store.list();
      if (!mounted) return;
      setState(() {
        _serverItems
          ..clear()
          ..addAll(items);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _refreshing = false;
    });
  }

  Future<void> _openPromotion(AppPromotionItem item) async {
    await _openPromotionUrl(item.downloadButtonUrl);
  }

  Future<void> _openPromotionUrl(String url) async {
    final text = AppText.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (url.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(text.pick('No download link configured.', '尚未配置下载链接。')),
        ),
      );
      return;
    }
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) {
        throw const FormatException('Invalid promotion URL');
      }
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        throw const ProcessException('url_launcher', [], 'Open returned false');
      }
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(text.pick('Open link failed.', '打开链接失败。'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final fallbackItems = _serverItems.isEmpty
        ? _fallbackPromotionItems(text)
        : const <AppPromotionItem>[];
    final items = [..._serverItems, ...fallbackItems];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Surface(
          child: Row(
            children: [
              const Icon(Icons.apps_rounded, color: Color(0xFF0F7E6E)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text.pick('Discover Apps', '发现更多应用'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text.pick(
                        'Promoted apps are loaded from the app_cross_promotion resource scene.',
                        '推广应用来自 app_cross_promotion 资源位。',
                      ),
                      style: const TextStyle(
                        color: Color(0xFF65706C),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _refreshing
                    ? null
                    : () => _loadPromotions(initial: false),
                icon: _refreshing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: Text(text.pick('Refresh', '刷新')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_loading)
          const _Surface(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else ...[
          if (_loadError != null && _serverItems.isEmpty)
            _Surface(
              child: _EmptyState(
                icon: Icons.cloud_off_rounded,
                title: text.pick('Promotion resource unavailable', '推广资源位不可用'),
                detail: text.pick(
                  'Fallback examples are shown until the resource scene is configured.',
                  '资源位配置前会显示本地示例。',
                ),
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 980;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: compact
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 14) / 2,
                      child: _PromotionCard(
                        item: item,
                        onDownload: () => _openPromotion(item),
                        onPlatformDownload: (platform) =>
                            _openPromotionUrl(platform.url),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class _PromotionCard extends StatelessWidget {
  const _PromotionCard({
    required this.item,
    required this.onDownload,
    required this.onPlatformDownload,
  });

  final AppPromotionItem item;
  final VoidCallback onDownload;
  final ValueChanged<AppPromotionPlatformLink> onPlatformDownload;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PromotionIcon(item: item),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle.isEmpty ? item.description : item.subtitle,
                      style: const TextStyle(
                        color: Color(0xFF65706C),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (item.category.isNotEmpty)
                _MetaChip(
                  label: text.pick('Category', '分类'),
                  value: item.category,
                ),
              if (item.rating.isNotEmpty)
                _MetaChip(label: text.pick('Rating', '评分'), value: item.rating),
              if (item.fileSize.isNotEmpty)
                _MetaChip(label: text.pick('Size', '大小'), value: item.fileSize),
            ],
          ),
          if (item.features.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final feature in item.features.take(6))
                  Chip(
                    label: Text(feature),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final platform in item.platforms)
                      _PlatformButton(
                        platform: platform,
                        onPressed: platform.url.isEmpty
                            ? null
                            : () => onPlatformDownload(platform),
                      ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: onDownload,
                icon: const Icon(Icons.download_rounded),
                label: Text(text.pick('Download', '下载')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromotionIcon extends StatelessWidget {
  const _PromotionIcon({required this.item});

  final AppPromotionItem item;

  @override
  Widget build(BuildContext context) {
    final icon = Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFF0F8F7C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.apps_rounded, color: Colors.white, size: 30),
    );
    if (item.iconUrl.isEmpty) return icon;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        item.iconUrl,
        width: 54,
        height: 54,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => icon,
      ),
    );
  }
}

class _PlatformButton extends StatelessWidget {
  const _PlatformButton({required this.platform, required this.onPressed});

  final AppPromotionPlatformLink platform;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final icon = switch (platform.platform) {
      'ios' => Icons.phone_iphone_rounded,
      'android' => Icons.android_rounded,
      'windows' => Icons.window_rounded,
      'macos' => Icons.desktop_mac_rounded,
      _ => Icons.public_rounded,
    };
    final label = platform.title.isEmpty
        ? _promotionPlatformTitle(platform.platform)
        : platform.title;
    final enabled = onPressed != null;
    return Tooltip(
      message: enabled ? label : '$label unavailable',
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 15),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 34),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          visualDensity: VisualDensity.compact,
          foregroundColor: const Color(0xFF0F7E6E),
          disabledForegroundColor: const Color(0xFF9AA8A1),
          side: BorderSide(
            color: enabled ? const Color(0xFFBFD8CF) : const Color(0xFFDCE5E0),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selected,
    required this.session,
    required this.onSelect,
  });

  final NavigationSection selected;
  final AwakeSession session;
  final ValueChanged<NavigationSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final items = [
      (
        Icons.bolt_rounded,
        _navTitle(text, NavigationSection.status),
        NavigationSection.status,
      ),
      (
        Icons.timer_outlined,
        _navTitle(text, NavigationSection.sessions),
        NavigationSection.sessions,
      ),
      (
        Icons.rule_folder_outlined,
        _navTitle(text, NavigationSection.rules),
        NavigationSection.rules,
      ),
      (
        Icons.settings_outlined,
        _navTitle(text, NavigationSection.settings),
        NavigationSection.settings,
      ),
      (
        Icons.feedback_outlined,
        _navTitle(text, NavigationSection.feedback),
        NavigationSection.feedback,
      ),
      (
        Icons.apps_rounded,
        _navTitle(text, NavigationSection.promotions),
        NavigationSection.promotions,
      ),
    ];

    return Container(
      width: 188,
      padding: const EdgeInsets.fromLTRB(16, 18, 14, 18),
      decoration: const BoxDecoration(
        color: Color(0xFFECEFEB),
        border: Border(right: BorderSide(color: Color(0xFFD8DDD7))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _LogoMark(),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  Params.appName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          for (final item in items)
            _NavItem(
              icon: item.$1,
              label: item.$2,
              selected: selected == item.$3,
              onTap: () => onSelect(item.$3),
            ),
          const Spacer(),
          _BatteryHint(active: session.isActive),
        ],
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFF0F7E6E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.local_cafe_rounded,
        color: Colors.white,
        size: 19,
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? const Color(0xFF0F7E6E)
                      : const Color(0xFF59635F),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected
                          ? const Color(0xFF153D37)
                          : const Color(0xFF59635F),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.session,
    required this.nativeStatus,
    required this.languageMode,
    required this.powerProtectHelperInstalled,
    required this.powerProtectHelperBusy,
    required this.onFeedbackPressed,
    required this.onLanguageChanged,
    required this.onRemovePowerProtectHelper,
  });

  final String title;
  final AwakeSession session;
  final String nativeStatus;
  final String languageMode;
  final bool? powerProtectHelperInstalled;
  final bool powerProtectHelperBusy;
  final VoidCallback onFeedbackPressed;
  final ValueChanged<String> onLanguageChanged;
  final Future<void> Function() onRemovePowerProtectHelper;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                nativeStatus,
                style: const TextStyle(color: Color(0xFF65706C), fontSize: 14),
              ),
            ],
          ),
        ),
        if (powerProtectHelperInstalled == true) ...[
          _TopBarRemoveHelperButton(
            busy: powerProtectHelperBusy,
            onPressed: onRemovePowerProtectHelper,
          ),
          const SizedBox(width: 8),
        ],
        _LanguageMenuButton(
          languageMode: languageMode,
          onChanged: onLanguageChanged,
        ),
        const SizedBox(width: 8),
        _FeedbackButton(onPressed: onFeedbackPressed),
        const SizedBox(width: 12),
        _StatusPill(isActive: session.isActive),
      ],
    );
  }
}

class _TopBarRemoveHelperButton extends StatelessWidget {
  const _TopBarRemoveHelperButton({
    required this.busy,
    required this.onPressed,
  });

  final bool busy;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final label = text.pick('Remove Helper', '移除助手');
    return Tooltip(
      message: text.pick('Remove Closed-Display Helper', '移除合盖助手'),
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: busy ? null : onPressed,
            child: Container(
              constraints: const BoxConstraints(minWidth: 118),
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF2C38B)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    busy
                        ? Icons.hourglass_top_rounded
                        : Icons.delete_outline_rounded,
                    size: 18,
                    color: const Color(0xFFB45309),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7C2D12),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final label = text.pick('Feedback', '用户反馈');
    return Tooltip(
      message: text.pick('Send feedback', '用户反馈'),
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onPressed,
            child: Container(
              constraints: const BoxConstraints(minWidth: 96),
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD7E2DC)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.feedback_outlined,
                    size: 18,
                    color: Color(0xFF0F7E6E),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF153D37),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackDraft {
  const _FeedbackDraft({
    required this.rating,
    required this.content,
    required this.contact,
  });

  final int rating;
  final String content;
  final String contact;
}

class _FeedbackDialog extends StatefulWidget {
  const _FeedbackDialog({required this.text});

  final AppText text;

  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<_FeedbackDialog> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _contentController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.text;
    return AlertDialog(
      title: Text(text.pick('Feedback', '用户反馈')),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text.pick(
                  'Tell us what happened or what you want improved.',
                  '告诉我们遇到了什么问题，或你希望改进什么。',
                ),
                style: const TextStyle(color: Color(0xFF65706C), height: 1.35),
              ),
              const SizedBox(height: 18),
              Text(
                text.pick('Rating', '评分'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (var value = 1; value <= 5; value++)
                    IconButton(
                      tooltip: '$value',
                      onPressed: () => setState(() => _rating = value),
                      icon: Icon(
                        value <= _rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: const Color(0xFFC48B2A),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _contentController,
                minLines: 4,
                maxLines: 7,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: text.pick('Content', '反馈内容'),
                  hintText: text.pick('Describe your feedback', '请描述你的反馈'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _contactController,
                decoration: InputDecoration(
                  labelText: text.pick('Contact (optional)', '联系方式（可选）'),
                  hintText: text.pick('Email or phone, optional', '邮箱或电话，可不填'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                text.pick(
                  'Feedback is saved with appScene: stayAwake.',
                  '反馈会携带 appScene: stayAwake 保存。',
                ),
                style: const TextStyle(color: Color(0xFF7A8581), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(text.pick('Cancel', '取消')),
        ),
        FilledButton(
          onPressed: () {
            final content = _contentController.text.trim();
            if (content.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    text.pick('Please enter feedback content.', '请先填写反馈内容。'),
                  ),
                ),
              );
              return;
            }
            Navigator.of(context).pop(
              _FeedbackDraft(
                rating: _rating,
                content: content,
                contact: _contactController.text.trim(),
              ),
            );
          },
          child: Text(text.pick('Submit feedback', '提交反馈')),
        ),
      ],
    );
  }
}

class _LanguageMenuButton extends StatelessWidget {
  const _LanguageMenuButton({
    required this.languageMode,
    required this.onChanged,
  });

  final String languageMode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final options = [
      (
        AppLocaleController.system,
        text.pick('Automatic', '自动'),
        Icons.language_rounded,
      ),
      (
        AppLocaleController.chinese,
        text.pick('Chinese', '中文'),
        Icons.translate_rounded,
      ),
      (AppLocaleController.english, 'English', Icons.abc_rounded),
      (
        AppLocaleController.japanese,
        text.pick('Japanese', '日语'),
        Icons.translate_rounded,
      ),
      (
        AppLocaleController.french,
        text.pick('French', '法语'),
        Icons.translate_rounded,
      ),
      (
        AppLocaleController.italian,
        text.pick('Italian', '意大利语'),
        Icons.translate_rounded,
      ),
      (
        AppLocaleController.german,
        text.pick('German', '德语'),
        Icons.translate_rounded,
      ),
      (
        AppLocaleController.spanish,
        text.pick('Spanish', '西班牙语'),
        Icons.translate_rounded,
      ),
    ];
    final selected = AppLocaleController.normalized(languageMode);
    final selectedOption = options.firstWhere(
      (option) => option.$1 == selected,
      orElse: () => options.first,
    );

    return PopupMenuButton<String>(
      tooltip: text.pick('Language', '语言'),
      initialValue: selected,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem<String>(
            value: option.$1,
            child: Row(
              children: [
                Icon(option.$3, size: 18, color: const Color(0xFF0F7E6E)),
                const SizedBox(width: 10),
                Expanded(child: Text(option.$2)),
                if (selected == option.$1)
                  const Icon(Icons.check_rounded, size: 18),
              ],
            ),
          ),
      ],
      child: Container(
        width: 112,
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD7E2DC)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.language_rounded,
              size: 18,
              color: Color(0xFF0F7E6E),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                selectedOption.$2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF153D37),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 17,
              color: Color(0xFF60706B),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackListPage extends StatefulWidget {
  const _FeedbackListPage({
    required this.store,
    required this.onSubmitFeedback,
  });

  final RemoteFeedbackStore store;
  final Future<StayAwakeFeedbackRecord?> Function(_FeedbackDraft draft)
  onSubmitFeedback;

  @override
  State<_FeedbackListPage> createState() => _FeedbackListPageState();
}

class _FeedbackListPageState extends State<_FeedbackListPage> {
  final TextEditingController _contentController = TextEditingController();
  final List<StayAwakeFeedbackRecord> _serverRecords = [];
  final List<StayAwakeFeedbackRecord> _optimisticRecords = [];
  Object? _loadError;
  bool _loadingInitial = true;
  bool _refreshing = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadRecords(initial: true);
  }

  Future<void> _loadRecords({bool initial = false}) async {
    if (initial) {
      setState(() {
        _loadingInitial = true;
        _loadError = null;
      });
    } else {
      setState(() {
        _refreshing = true;
        _loadError = null;
      });
    }
    try {
      final records = await widget.store.list();
      if (!mounted) return;
      setState(() {
        _serverRecords
          ..clear()
          ..addAll(records);
        _optimisticRecords.removeWhere(
          (localRecord) => records.any(
            (serverRecord) =>
                _isSameSubmittedFeedback(localRecord, serverRecord),
          ),
        );
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    } finally {
      if (mounted) {
        setState(() {
          _loadingInitial = false;
          _refreshing = false;
        });
      }
    }
  }

  void _refresh() {
    unawaited(_loadRecords());
  }

  bool _isSameSubmittedFeedback(
    StayAwakeFeedbackRecord left,
    StayAwakeFeedbackRecord right,
  ) {
    if (left.content != right.content) return false;
    final leftTime = left.createdAt;
    final rightTime = right.createdAt;
    if (leftTime == null || rightTime == null) return true;
    return leftTime.difference(rightTime).abs() < const Duration(minutes: 5);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitInlineFeedback() async {
    final text = AppText.of(context);
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            text.pick('Please enter feedback content.', '请先填写反馈内容。'),
          ),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    final submittedRecord = await widget.onSubmitFeedback(
      _FeedbackDraft(rating: 0, content: content, contact: ''),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (submittedRecord != null) {
      _contentController.clear();
      setState(() {
        _optimisticRecords.insert(0, submittedRecord);
      });
      unawaited(_loadRecords());
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final seen = <String>{};
    final records = <StayAwakeFeedbackRecord>[
      for (final record in [..._optimisticRecords, ..._serverRecords])
        if (seen.add(
          record.objectId.isNotEmpty
              ? record.objectId
              : '${record.createdAt?.millisecondsSinceEpoch}-${record.content}',
        ))
          record,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Surface(
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.feedback_outlined,
                      color: Color(0xFF0F7E6E),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text.pick('User Feedback', '用户反馈'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            text.pick(
                              'Server records for StayAwake feedback.',
                              '展示服务器中的 StayAwake 反馈记录。',
                            ),
                            style: const TextStyle(
                              color: Color(0xFF65706C),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _refreshing ? null : _refresh,
                icon: _refreshing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: Text(text.pick('Refresh', '刷新')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_loadingInitial && records.isEmpty)
          const _Surface(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (_loadError != null && records.isEmpty)
          _Surface(
            child: _EmptyState(
              icon: Icons.cloud_off_rounded,
              title: text.pick('Feedback server unavailable', '反馈服务器不可用'),
              detail: text.pick(
                'Start the Egg service or check the API base URL, then refresh.',
                '请启动 Egg 服务或检查 API 地址，然后刷新。',
              ),
            ),
          )
        else if (records.isEmpty)
          _Surface(
            child: _EmptyState(
              icon: Icons.forum_outlined,
              title: text.pick('No feedback yet', '暂无反馈'),
              detail: text.pick(
                'New feedback will appear here after it reaches the server.',
                '新的反馈成功提交到服务器后会显示在这里。',
              ),
            ),
          )
        else
          ...records.map((record) => _FeedbackRecordCard(record: record)),
        const SizedBox(height: 2),
        _InlineFeedbackComposer(
          controller: _contentController,
          submitting: _submitting,
          onSubmit: _submitInlineFeedback,
        ),
      ],
    );
  }
}

class _InlineFeedbackComposer extends StatelessWidget {
  const _InlineFeedbackComposer({
    required this.controller,
    required this.submitting,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  text.pick('Write feedback', '写下你的反馈'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            minLines: 3,
            maxLines: 6,
            maxLength: 500,
            enabled: !submitting,
            decoration: InputDecoration(
              hintText: text.pick('Type your feedback here...', '在这里输入你的反馈...'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  text.pick('Submits feedback to the server.', '提交反馈到服务器。'),
                  style: const TextStyle(color: Color(0xFF65706C)),
                ),
              ),
              FilledButton.icon(
                onPressed: submitting ? null : onSubmit,
                icon: submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(text.pick('Send', '发送')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeedbackRecordCard extends StatelessWidget {
  const _FeedbackRecordCard({required this.record});

  final StayAwakeFeedbackRecord record;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final createdAt = record.createdAt?.toLocal().toString().split('.').first;
    final officialReply = record.officialReply.trim();
    final replyAt = record.officialReplyAt > 0
        ? DateTime.fromMillisecondsSinceEpoch(
            record.officialReplyAt,
          ).toLocal().toString().split('.').first
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    record.content.isEmpty
                        ? text.pick('No content', '无内容')
                        : record.content,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (record.appScene.isNotEmpty)
                  _MetaChip(label: 'appScene', value: record.appScene),
                _MetaChip(
                  label: text.pick('Status', '状态'),
                  value: _feedbackStatusText(text, record.status),
                ),
                if (record.platform.isNotEmpty)
                  _MetaChip(
                    label: text.pick('Platform', '平台'),
                    value: record.platform,
                  ),
                if (record.market.isNotEmpty)
                  _MetaChip(
                    label: text.pick('Market', '市场'),
                    value: record.market,
                  ),
                if (createdAt != null)
                  _MetaChip(
                    label: text.pick('Created', '创建时间'),
                    value: createdAt,
                  ),
              ],
            ),
            if (officialReply.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFC8E8DD)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.support_agent_rounded,
                          size: 18,
                          color: Color(0xFF0F7E6E),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          text.pick('Official reply', '官方回复'),
                          style: const TextStyle(
                            color: Color(0xFF0F7E6E),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (replyAt != null) ...[
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              '${text.pick('Reply time', '回复时间')}: $replyAt',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF65706C),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      officialReply,
                      style: const TextStyle(
                        color: Color(0xFF38413E),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (record.contact.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '${text.pick('Contact', '联系方式')}: ${record.contact}',
                style: const TextStyle(color: Color(0xFF65706C)),
              ),
            ],
            if (record.objectId.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'ID: ${record.objectId}',
                style: const TextStyle(color: Color(0xFF8A9490), fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _feedbackStatusText(AppText text, int value) {
    return switch (value) {
      1 => text.pick('In progress', '处理中'),
      2 => text.pick('Developing', '开发中'),
      3 => text.pick('Done', '处理完成'),
      4 => text.pick('Declined', '不予处理'),
      _ => text.pick('Open', '未处理'),
    };
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5F1),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFD7E2DC)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Color(0xFF53615C),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusDashboard extends StatelessWidget {
  const _StatusDashboard({
    required this.session,
    required this.settings,
    required this.presets,
    required this.powerStatus,
    required this.nativeStatus,
    required this.busy,
    required this.onStart,
    required this.onStop,
    required this.onRefreshPower,
  });

  final AwakeSession session;
  final AppSettings settings;
  final List<SessionPreset> presets;
  final PowerStatus powerStatus;
  final String nativeStatus;
  final bool busy;
  final ValueChanged<Duration?> onStart;
  final VoidCallback onStop;
  final VoidCallback onRefreshPower;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 900;
            final status = _StatusPanel(
              session: session,
              busy: busy,
              onStart: () => onStart(const Duration(hours: 1)),
              onStop: onStop,
            );
            final controls = _ControlPanel(
              presets: presets,
              settings: settings,
              onStartPreset: onStart,
            );
            if (compact) {
              return Column(
                children: [status, const SizedBox(height: 16), controls],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: status),
                const SizedBox(width: 16),
                Expanded(flex: 4, child: controls),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _PowerPanel(status: powerStatus, onRefresh: onRefreshPower),
        const SizedBox(height: 16),
        _ActivityPanel(session: session, nativeStatus: nativeStatus),
      ],
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.session,
    required this.busy,
    required this.onStart,
    required this.onStop,
  });

  final AwakeSession session;
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final isActive = session.isActive;
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AwakeGauge(progress: session.progress, active: isActive),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _sessionRemainingLabel(text, session),
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isActive
                          ? text.pick(
                              'System sleep is blocked by a native macOS power assertion.',
                              '系统睡眠已被 macOS 原生防睡眠断言阻止。',
                            )
                          : text.pick(
                              'Choose a duration or start a default one-hour session.',
                              '选择一个时长，或开启默认 1 小时会话。',
                            ),
                      style: const TextStyle(
                        color: Color(0xFF60706B),
                        height: 1.35,
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(height: 8),
                      Text(
                        text.pick(
                          'Started by ${_sessionSourceLabel(text, session.source)}',
                          '由${_sessionSourceLabel(text, session.source)}开启',
                        ),
                        style: const TextStyle(
                          color: Color(0xFF0F7E6E),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: busy ? null : (isActive ? onStop : onStart),
                icon: Icon(
                  isActive ? Icons.stop_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(
                  isActive
                      ? text.pick('Stop keeping awake', '停止保持唤醒')
                      : text.pick('Start 1 hour', '开启 1 小时'),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: isActive
                      ? const Color(0xFFB94A3A)
                      : const Color(0xFF0F7E6E),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(176, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.coffee_rounded, size: 18),
                label: Text(text.pick('Menu bar controls enabled', '菜单栏控制已启用')),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(210, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.presets,
    required this.settings,
    required this.onStartPreset,
  });

  final List<SessionPreset> presets;
  final AppSettings settings;
  final ValueChanged<Duration?> onStartPreset;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text.pick('Quick sessions', '快速会话'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final preset in presets)
                ActionChip(
                  avatar: const Icon(Icons.timer_outlined, size: 17),
                  label: Text(preset.label),
                  onPressed: () => onStartPreset(preset.duration),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          _InfoRow(
            icon: Icons.desktop_mac_rounded,
            title: text.pick('Sleep behavior', '睡眠行为'),
            detail: settings.preventDisplaySleep
                ? text.pick('Display sleep is blocked.', '显示器睡眠已阻止。')
                : text.pick('Only idle system sleep is blocked.', '仅阻止系统空闲睡眠。'),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.screen_lock_portrait_rounded,
            title: text.pick('Screen saver', '屏幕保护程序'),
            detail: settings.allowScreenSaver
                ? text.pick('Screen saver may run.', '屏幕保护程序可以运行。')
                : text.pick(
                    'Screen saver policy is unchanged.',
                    '屏幕保护程序策略保持不变。',
                  ),
          ),
        ],
      ),
    );
  }
}

class _SessionsPage extends StatelessWidget {
  const _SessionsPage({
    required this.presets,
    required this.session,
    required this.settings,
    required this.history,
    required this.busy,
    required this.onStart,
    required this.onStop,
    required this.onClearHistory,
  });

  final List<SessionPreset> presets;
  final AwakeSession session;
  final AppSettings settings;
  final List<SessionLogEntry> history;
  final bool busy;
  final ValueChanged<Duration?> onStart;
  final VoidCallback onStop;
  final VoidCallback onClearHistory;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    return Column(
      children: [
        _Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text.pick('Session launcher', '会话启动器'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final preset in presets)
                    FilledButton.tonalIcon(
                      onPressed: busy ? null : () => onStart(preset.duration),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        text.pick(
                          'Start ${preset.label}',
                          '开启 ${preset.label}',
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(130, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  FilledButton.tonalIcon(
                    onPressed: busy
                        ? null
                        : () => onStart(
                            Duration(minutes: settings.customDurationMinutes),
                          ),
                    icon: const Icon(Icons.tune_rounded),
                    label: Text(
                      text.pick(
                        'Start custom ${settings.customDurationMinutes}m',
                        '开启自定义 ${settings.customDurationMinutes} 分钟',
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(170, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: session.isActive && !busy ? onStop : null,
                    icon: const Icon(Icons.stop_rounded),
                    label: Text(text.pick('Stop current', '停止当前会话')),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(140, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      text.pick('Session history', '会话历史'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: history.isEmpty ? null : onClearHistory,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text(text.pick('Clear', '清除')),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (history.isEmpty)
                _EmptyState(
                  icon: Icons.history_rounded,
                  title: text.pick('No session history yet', '还没有会话历史'),
                  detail: text.pick(
                    'Start or stop a session to create a local record.',
                    '开启或停止一次会话后，会在这里生成本地记录。',
                  ),
                )
              else
                for (final entry in history) _HistoryRow(entry: entry),
            ],
          ),
        ),
      ],
    );
  }
}

class _RulesPage extends StatelessWidget {
  const _RulesPage({
    required this.rules,
    required this.settings,
    required this.powerStatus,
    required this.frontmostApp,
    required this.runningApps,
    required this.downloadActivity,
    required this.onChanged,
    required this.onRefreshPower,
    required this.onRefreshFrontmost,
    required this.onRefreshRunningApps,
    required this.onRefreshDownloads,
    required this.onSettingsChanged,
    required this.onUseFrontmostApp,
    required this.onChooseRunningApp,
    required this.onClearAppTrigger,
  });

  final List<AwakeRule> rules;
  final AppSettings settings;
  final PowerStatus powerStatus;
  final FrontmostApp frontmostApp;
  final List<RunningApp> runningApps;
  final DownloadActivity downloadActivity;
  final void Function(AwakeRule rule, bool enabled) onChanged;
  final VoidCallback onRefreshPower;
  final VoidCallback onRefreshFrontmost;
  final VoidCallback onRefreshRunningApps;
  final VoidCallback onRefreshDownloads;
  final ValueChanged<AppSettings> onSettingsChanged;
  final VoidCallback onUseFrontmostApp;
  final VoidCallback onChooseRunningApp;
  final VoidCallback onClearAppTrigger;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    AwakeRule ruleById(String id) {
      return rules.firstWhere((rule) => rule.id == id);
    }

    final pluggedInRule = ruleById('plugged-in');
    final lowBatteryRule = ruleById('low-battery');
    final appRule = ruleById('app-trigger');
    final downloadRule = ruleById('download-trigger');
    const primaryRuleIds = {
      'plugged-in',
      'low-battery',
      'app-trigger',
      'download-trigger',
    };
    final summaryRules = rules
        .where((rule) => !primaryRuleIds.contains(rule.id))
        .toList();

    return Column(
      children: [
        _Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.power_rounded, color: Color(0xFF0F7E6E)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text.pick('Power stay-awake rules', '电源保持唤醒规则'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _powerStatusLabel(text, powerStatus),
                          style: const TextStyle(color: Color(0xFF66716C)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onRefreshPower,
                    tooltip: text.pick('Refresh power source', '刷新电源状态'),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _RuleSettingRow(
                title: _ruleTitle(text, pluggedInRule),
                subtitle: _ruleDescription(text, pluggedInRule),
                value: pluggedInRule.enabled,
                onChanged: (enabled) => onChanged(pluggedInRule, enabled),
              ),
              const Divider(height: 24),
              _RuleSettingRow(
                title: _ruleTitle(text, lowBatteryRule),
                subtitle: _ruleDescription(text, lowBatteryRule),
                value: lowBatteryRule.enabled,
                onChanged: (enabled) => onChanged(lowBatteryRule, enabled),
              ),
              const SizedBox(height: 10),
              Text(
                text.pick(
                  'Low battery stop threshold: ${settings.lowBatteryStopPercent}%',
                  '低电量停止阈值：${settings.lowBatteryStopPercent}%',
                ),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Slider(
                value: settings.lowBatteryStopPercent.toDouble(),
                min: 5,
                max: 80,
                divisions: 15,
                label: '${settings.lowBatteryStopPercent}%',
                onChanged: (value) => onSettingsChanged(
                  settings.copyWith(lowBatteryStopPercent: value.round()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.download_for_offline_rounded,
                    color: Color(0xFF0F7E6E),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text.pick('Download stay-awake rule', '下载保持唤醒规则'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _downloadActivityLabel(text, downloadActivity),
                          style: const TextStyle(color: Color(0xFF66716C)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onRefreshDownloads,
                    tooltip: text.pick('Refresh downloads', '刷新下载状态'),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _RuleSettingRow(
                title: _ruleTitle(text, downloadRule),
                subtitle: _ruleDescription(text, downloadRule),
                value: downloadRule.enabled,
                onChanged: (enabled) => onChanged(downloadRule, enabled),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      text.pick('App stay-awake rule', 'App 保持唤醒规则'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      onRefreshFrontmost();
                      onRefreshRunningApps();
                    },
                    tooltip: text.pick('Refresh apps', '刷新 App 状态'),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _RuleSettingRow(
                title: _ruleTitle(text, appRule),
                subtitle: _ruleDescription(text, appRule),
                value: appRule.enabled,
                onChanged: (enabled) => onChanged(appRule, enabled),
              ),
              const Divider(height: 24),
              _InfoRow(
                icon: Icons.ads_click_rounded,
                title: text.pick('Current frontmost app', '当前前台 App'),
                detail: _frontmostAppLabel(text, frontmostApp),
              ),
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.window_rounded,
                title: text.pick('Running apps', '运行中的 App'),
                detail: text.pick(
                  '${runningApps.where((app) => app.isRegular).length} regular apps, ${runningApps.length} total processes',
                  '${runningApps.where((app) => app.isRegular).length} 个常规 App，${runningApps.length} 个总进程',
                ),
              ),
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.flag_circle_rounded,
                title: text.pick('Trigger target', '触发目标'),
                detail: settings.appTriggerBundleId.isEmpty
                    ? text.pick('No app selected yet.', '尚未选择 App。')
                    : '${settings.appTriggerName} (${settings.appTriggerBundleId})',
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: runningApps.isEmpty ? null : onChooseRunningApp,
                    icon: const Icon(Icons.search_rounded),
                    label: Text(text.pick('Choose running app', '选择运行中的 App')),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: frontmostApp.available
                        ? onUseFrontmostApp
                        : null,
                    icon: const Icon(Icons.my_location_rounded),
                    label: Text(text.pick('Use current app', '使用当前 App')),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: settings.appTriggerBundleId.isEmpty
                        ? null
                        : onClearAppTrigger,
                    icon: const Icon(Icons.clear_rounded),
                    label: Text(text.pick('Clear target', '清除目标')),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text.pick('Other Stay Awake rules', '其他保持唤醒规则'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                text.pick(
                  'Lower-frequency behavior switches that still affect StayAwake sessions.',
                  '这些低频行为开关也会影响 StayAwake 会话。',
                ),
                style: const TextStyle(color: Color(0xFF66716C)),
              ),
              const SizedBox(height: 14),
              for (final rule in summaryRules) ...[
                _RuleRow(
                  rule: rule,
                  title: _ruleTitle(text, rule),
                  description: _ruleDescription(text, rule),
                  onChanged: rule.implemented
                      ? (enabled) => onChanged(rule, enabled)
                      : null,
                ),
                if (rule != summaryRules.last) const Divider(height: 24),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsPage extends StatefulWidget {
  const _SettingsPage({
    required this.settings,
    required this.storePath,
    required this.powerProtectHelperInstalled,
    required this.powerProtectHelperBusy,
    required this.onChanged,
    required this.onRecordGlobalHotkey,
    required this.onChooseDiskWakePath,
    required this.onClearDiskWakePath,
    required this.onClearDeliveredNotifications,
    required this.onRefreshPowerProtectHelper,
    required this.onInstallPowerProtectHelper,
    required this.onRemovePowerProtectHelper,
  });

  final AppSettings settings;
  final String storePath;
  final bool? powerProtectHelperInstalled;
  final bool powerProtectHelperBusy;
  final ValueChanged<AppSettings> onChanged;
  final Future<void> Function() onRecordGlobalHotkey;
  final Future<void> Function() onChooseDiskWakePath;
  final Future<void> Function() onClearDiskWakePath;
  final Future<void> Function() onClearDeliveredNotifications;
  final Future<void> Function() onRefreshPowerProtectHelper;
  final Future<void> Function() onInstallPowerProtectHelper;
  final Future<void> Function() onRemovePowerProtectHelper;

  @override
  State<_SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<_SettingsPage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final settings = widget.settings;
    final storePath = widget.storePath;
    final onChanged = widget.onChanged;
    final tabs = [
      (Icons.timer_outlined, text.pick('Session defaults', '会话默认设置')),
      (Icons.rocket_launch_outlined, text.pick('General', '通用')),
      (Icons.ads_click_rounded, text.pick('System controls', '系统控制')),
      (Icons.traffic_rounded, text.pick('Triggers', '触发器')),
      (Icons.album_outlined, text.pick('Disk wake', '硬盘唤醒')),
      (Icons.keyboard_command_key_rounded, text.pick('Hotkeys', '热键')),
      (Icons.notifications_outlined, text.pick('Notifications', '通知')),
      (Icons.diamond_outlined, text.pick('Appearance', '外观')),
      (Icons.bar_chart_rounded, text.pick('Statistics', '统计数据')),
    ];
    final sections = [
      _SettingsSection(
        icon: Icons.timer_outlined,
        title: text.pick('Session defaults', '会话默认设置'),
        subtitle: text.pick(
          'Default duration, display sleep, screen saver, and low battery behavior.',
          '默认时长、显示器睡眠、屏幕保护程序和低电量行为。',
        ),
        children: [
          _ChoiceRow(
            title: text.pick('Default duration', '默认时长'),
            subtitle: text.pick(
              'Used by menu bar quick start and hotkey actions.',
              '用于菜单栏快速启动和热键动作。',
            ),
            value: settings.customDurationMinutes >= 480
                ? text.indefinite
                : text.minutes(settings.customDurationMinutes),
            choices: [
              text.minutes(15),
              text.minutes(30),
              text.minutes(45),
              text.minutes(60),
              text.minutes(120),
              text.indefinite,
            ],
            onChanged: (value) {
              final minutes = switch (value) {
                final label when label == text.minutes(15) => 15,
                final label when label == text.minutes(30) => 30,
                final label when label == text.minutes(45) => 45,
                final label when label == text.minutes(60) => 60,
                final label when label == text.minutes(120) => 120,
                _ => 480,
              };
              onChanged(settings.copyWith(customDurationMinutes: minutes));
            },
          ),
          const Divider(height: 28),
          _SwitchRow(
            title: text.pick('Prevent display sleep', '阻止显示器睡眠'),
            subtitle: text.pick(
              'Use NoDisplaySleepAssertion for active sessions.',
              '活动会话使用 NoDisplaySleepAssertion。',
            ),
            value: settings.preventDisplaySleep,
            onChanged: (value) =>
                onChanged(settings.copyWith(preventDisplaySleep: value)),
          ),
          const Divider(height: 28),
          _SwitchRow(
            title: text.pick(
              'Allow system sleep when display is off',
              '显示器关闭时允许系统睡眠',
            ),
            subtitle: text.pick(
              'Matches Amphetamine display-closed mode.',
              '对应 Amphetamine 的显示器关闭模式。',
            ),
            value: settings.allowSystemSleepWhenDisplayOff,
            onChanged: (value) {
              onChanged(
                settings.copyWith(allowSystemSleepWhenDisplayOff: value),
              );
              if (value && widget.powerProtectHelperInstalled == true) {
                widget.onRemovePowerProtectHelper();
              }
            },
          ),
          const SizedBox(height: 12),
          _ClosedDisplayHelperRow(
            installed: widget.powerProtectHelperInstalled,
            busy: widget.powerProtectHelperBusy,
            onRefresh: widget.onRefreshPowerProtectHelper,
            onInstall: widget.onInstallPowerProtectHelper,
            onRemove: widget.onRemovePowerProtectHelper,
          ),
          const Divider(height: 28),
          _SwitchRow(
            title: text.pick('Allow screen saver after idle', '闲置后允许屏幕保护程序'),
            subtitle: text.pick(
              'Starts the system screen saver after 45 minutes while active.',
              '会话活动 45 分钟后启动系统屏幕保护程序。',
            ),
            value: settings.allowScreenSaver,
            onChanged: (value) =>
                onChanged(settings.copyWith(allowScreenSaver: value)),
          ),
          const Divider(height: 28),
          Text(
            text.pick(
              'Low battery stop threshold: ${settings.lowBatteryStopPercent}%',
              '低电量结束阈值：${settings.lowBatteryStopPercent}%',
            ),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          Slider(
            value: settings.lowBatteryStopPercent.toDouble(),
            min: 5,
            max: 80,
            divisions: 15,
            label: '${settings.lowBatteryStopPercent}%',
            onChanged: (value) => onChanged(
              settings.copyWith(lowBatteryStopPercent: value.round()),
            ),
          ),
        ],
      ),
      _SettingsSection(
        icon: Icons.rocket_launch_outlined,
        title: text.pick('General', '通用'),
        subtitle: text.pick(
          'Launch, wake, Dock, and motion preferences.',
          '启动、唤醒、程序坞和动态效果偏好。',
        ),
        children: [
          _ChoiceRow(
            title: text.pick('Language', '语言'),
            subtitle: text.pick(
              'Follow the system by default, or choose a fixed app language.',
              '默认跟随系统，也可以固定应用语言。',
            ),
            value: _localizedLanguageMode(text, settings.languageMode),
            choices: [
              _localizedLanguageMode(text, AppLocaleController.system),
              _localizedLanguageMode(text, AppLocaleController.chinese),
              _localizedLanguageMode(text, AppLocaleController.english),
              _localizedLanguageMode(text, AppLocaleController.japanese),
              _localizedLanguageMode(text, AppLocaleController.french),
              _localizedLanguageMode(text, AppLocaleController.italian),
              _localizedLanguageMode(text, AppLocaleController.german),
              _localizedLanguageMode(text, AppLocaleController.spanish),
            ],
            onChanged: (value) => onChanged(
              settings.copyWith(languageMode: _languageModeWire(value)),
            ),
          ),
          const Divider(height: 28),
          _SwitchRow(
            title: text.pick('Start at login', '登录时启动'),
            subtitle: text.pick(
              'Uses the native macOS Login Item service when available.',
              '可用时使用 macOS 原生登录项服务。',
            ),
            value: settings.startAtLogin,
            onChanged: (value) =>
                onChanged(settings.copyWith(startAtLogin: value)),
          ),
          const Divider(height: 28),
          _SwitchRow(
            title: text.pick(
              'Start a session when StayAwake launches',
              'StayAwake 启动时开启会话',
            ),
            subtitle: text.pick(
              'Uses the default duration selected above.',
              '使用上方选择的默认时长。',
            ),
            value: settings.startSessionOnLaunch,
            onChanged: (value) =>
                onChanged(settings.copyWith(startSessionOnLaunch: value)),
          ),
          const Divider(height: 28),
          _SwitchRow(
            title: text.pick(
              'Start a session after waking from sleep',
              '从睡眠中唤醒后开启会话',
            ),
            subtitle: text.pick(
              'Uses the native macOS wake notification.',
              '使用 macOS 原生唤醒通知触发。',
            ),
            value: settings.startSessionAfterWake,
            onChanged: (value) =>
                onChanged(settings.copyWith(startSessionAfterWake: value)),
          ),
          const Divider(height: 28),
          _SwitchRow(
            title: text.pick('Hide StayAwake in Dock', '在程序坞中隐藏 StayAwake'),
            subtitle: text.pick(
              'Keeps the product focused on the menu bar workflow.',
              '让产品更聚焦于菜单栏工作流。',
            ),
            value: settings.hideInDock,
            onChanged: (value) =>
                onChanged(settings.copyWith(hideInDock: value)),
          ),
          const Divider(height: 28),
          _SwitchRow(
            title: text.pick('Reduce motion', '减弱动态效果'),
            subtitle: text.pick(
              'Disables decorative motion in future UI surfaces.',
              '后续 UI 界面将减少装饰性动画。',
            ),
            value: settings.reduceMotion,
            onChanged: (value) =>
                onChanged(settings.copyWith(reduceMotion: value)),
          ),
        ],
      ),
      _SettingsSection(
        icon: Icons.ads_click_rounded,
        title: text.pick('System controls', '系统控制'),
        subtitle: text.pick(
          'Lock screen, cursor movement, user switching, and forced sleep options.',
          '锁定屏幕、移动光标、用户切换和强制睡眠选项。',
        ),
        children: [
          _ClosedDisplayRemovalPanel(
            installed: widget.powerProtectHelperInstalled,
            busy: widget.powerProtectHelperBusy,
            onRefresh: widget.onRefreshPowerProtectHelper,
            onRemove: widget.onRemovePowerProtectHelper,
          ),
          const Divider(height: 28),
          _SwitchRow(
            title: text.pick(
              'End session when Mac forces sleep',
              'Mac 强制睡眠时结束会话',
            ),
            subtitle: text.pick(
              'Uses the native sleep callback before the system sleeps.',
              '系统睡眠前通过原生回调结束会话。',
            ),
            value: settings.forceSleepEndsSession,
            onChanged: (value) =>
                onChanged(settings.copyWith(forceSleepEndsSession: value)),
          ),
          const Divider(height: 28),
          _SwitchRow(
            title: text.pick('Lock screen after 1 minute idle', '闲置 1 分钟后锁定屏幕'),
            subtitle: text.pick(
              'Uses the existing native lock timer while a session is active.',
              '会话活动时使用现有原生锁屏计时器。',
            ),
            value: settings.lockScreenAfterIdle,
            onChanged: (value) =>
                onChanged(settings.copyWith(lockScreenAfterIdle: value)),
          ),
          const Divider(height: 28),
          _SwitchRow(
            title: text.pick(
              'Lock immediately when display turns off',
              '显示器关闭后立即锁屏',
            ),
            subtitle: text.pick(
              'Uses the native screen-sleep notification.',
              '使用原生显示器睡眠事件触发锁屏。',
            ),
            value: settings.lockWhenDisplayOff,
            onChanged: (value) =>
                onChanged(settings.copyWith(lockWhenDisplayOff: value)),
          ),
          const Divider(height: 28),
          _SwitchRow(
            title: text.pick('Allow screen lock during sessions', '会话期间允许屏幕锁定'),
            subtitle: text.pick(
              'When off, StayAwake temporarily prevents macOS from requiring a password after the display turns off.',
              '关闭时，StayAwake 会在会话期间临时阻止显示器关闭后要求输入密码。',
            ),
            value: settings.allowScreenLock,
            onChanged: (value) =>
                onChanged(settings.copyWith(allowScreenLock: value)),
          ),
          const Divider(height: 28),
          _SwitchRow(
            title: text.pick(
              'Allow display sleep while screen is locked',
              '屏幕锁定时允许显示器睡眠',
            ),
            subtitle: text.pick(
              'Matches the Amphetamine locked-screen policy.',
              '对应 Amphetamine 的锁屏策略。',
            ),
            value: settings.allowDisplaySleepWhenLocked,
            onChanged: (value) => onChanged(
              settings.copyWith(allowDisplaySleepWhenLocked: value),
            ),
          ),
          const Divider(height: 28),
          _SwitchRow(
            title: text.pick(
              'Move cursor after 5 minutes idle',
              '闲置 5 分钟后移动光标',
            ),
            subtitle: text.pick(
              'Uses the existing native cursor nudge timer.',
              '使用现有原生光标轻微移动计时器。',
            ),
            value: settings.moveCursorAfterIdle,
            onChanged: (value) =>
                onChanged(settings.copyWith(moveCursorAfterIdle: value)),
          ),
          const Divider(height: 28),
          Text(
            text.pick(
              'Stop moving cursor after ${settings.stopMovingCursorAfterMinutes}m idle',
              '闲置 ${settings.stopMovingCursorAfterMinutes} 分钟后停止移动光标',
            ),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          Slider(
            value: settings.stopMovingCursorAfterMinutes.toDouble(),
            min: 5,
            max: 120,
            divisions: 23,
            label: '${settings.stopMovingCursorAfterMinutes}m',
            onChanged: (value) => onChanged(
              settings.copyWith(stopMovingCursorAfterMinutes: value.round()),
            ),
          ),
          const Divider(height: 28),
          _SwitchRow(
            title: text.pick('End session when switching user', '切换用户时结束会话'),
            subtitle: text.pick(
              'Uses the macOS session-resign-active notification.',
              '使用 macOS 用户会话切换通知。',
            ),
            value: settings.endSessionOnUserSwitch,
            onChanged: (value) =>
                onChanged(settings.copyWith(endSessionOnUserSwitch: value)),
          ),
        ],
      ),
      _SettingsSection(
        icon: Icons.traffic_rounded,
        title: text.pick('Triggers', '触发器'),
        subtitle: text.pick(
          'The active app, download, low battery, and power adapter rules are configured on the Stay Awake Rules page.',
          '正在运行的 App、下载、低电量和电源适配器规则在 Stay Awake Rules 页面配置。',
        ),
        children: [
          _SwitchRow(
            title: text.pick('Enable triggers', '启用触发器'),
            subtitle: text.pick(
              'Master switch for all automation rules.',
              '所有自动化规则的总开关。',
            ),
            value: settings.triggersEnabled,
            onChanged: (value) =>
                onChanged(settings.copyWith(triggersEnabled: value)),
          ),
          const Divider(height: 28),
          _InfoRow(
            icon: Icons.open_in_new_rounded,
            title: text.pick('Edit trigger targets', '编辑触发目标'),
            detail: text.pick(
              'Use Stay Awake Rules to choose a running app, inspect downloads, and verify power state.',
              '在 Stay Awake Rules 页面选择运行中的 App、检查下载状态并验证电源状态。',
            ),
          ),
        ],
      ),
      _SettingsSection(
        icon: Icons.album_outlined,
        title: text.pick('Disk wake', '硬盘唤醒'),
        subtitle: text.pick(
          'Keep selected disks warm while a session is running.',
          '会话运行时保持所选硬盘活跃。',
        ),
        children: [
          _SwitchRow(
            title: text.pick('Keep disk awake', '保持硬盘唤醒'),
            subtitle: text.pick(
              'Writes a lightweight timestamp file while the session is active.',
              '会话活动时写入轻量时间戳文件。',
            ),
            value: settings.keepDiskAwake,
            onChanged: (value) =>
                onChanged(settings.copyWith(keepDiskAwake: value)),
          ),
          const Divider(height: 28),
          _InfoRow(
            icon: Icons.folder_open_rounded,
            title: text.pick('Disk wake target', '硬盘唤醒目标'),
            detail: settings.diskWakePath.isEmpty
                ? text.pick(
                    'Default Application Support folder',
                    '默认 Application Support 目录',
                  )
                : '${settings.diskWakeName}\n${settings.diskWakePath}',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: widget.onChooseDiskWakePath,
                icon: const Icon(Icons.folder_rounded),
                label: Text(text.pick('Choose target', '选择目标')),
              ),
              OutlinedButton.icon(
                onPressed: settings.diskWakePath.isEmpty
                    ? null
                    : widget.onClearDiskWakePath,
                icon: const Icon(Icons.restart_alt_rounded),
                label: Text(text.pick('Use default', '使用默认')),
              ),
            ],
          ),
          const Divider(height: 28),
          Text(
            text.pick(
              'Disk wake interval: ${settings.diskWakeIntervalSeconds}s',
              '硬盘唤醒间隔：${settings.diskWakeIntervalSeconds} 秒',
            ),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          Slider(
            value: settings.diskWakeIntervalSeconds.toDouble(),
            min: 5,
            max: 120,
            divisions: 23,
            label: '${settings.diskWakeIntervalSeconds}s',
            onChanged: (value) => onChanged(
              settings.copyWith(diskWakeIntervalSeconds: value.round()),
            ),
          ),
        ],
      ),
      _SettingsSection(
        icon: Icons.keyboard_command_key_rounded,
        title: text.pick('Hotkeys', '热键'),
        subtitle: text.pick(
          'Native global shortcut registration and recording.',
          '原生全局快捷键注册和录制。',
        ),
        children: [
          _SwitchRow(
            title: text.pick('Enable global shortcut', '启用全局快捷键'),
            subtitle: text.pick(
              'Registers the shortcut with macOS while StayAwake is running.',
              'StayAwake 运行时向 macOS 注册该快捷键。',
            ),
            value: settings.globalHotkeyEnabled,
            onChanged: (value) =>
                onChanged(settings.copyWith(globalHotkeyEnabled: value)),
          ),
          const Divider(height: 28),
          _ChoiceRow(
            title: text.pick('When a session is running', '当会话正在运行时'),
            subtitle: text.pick(
              'Action for the open/end session shortcut.',
              '开启/结束会话快捷键的动作。',
            ),
            value: text.pick(
              settings.activeSessionHotkey,
              _localizedHotkeyAction(settings.activeSessionHotkey),
            ),
            choices: [
              text.pick('End current and start new', '结束当前会话并开启新会话'),
              text.pick('Extend current session', '延长当前会话'),
              text.pick('Ignore shortcut', '忽略快捷键'),
            ],
            onChanged: (value) => onChanged(
              settings.copyWith(activeSessionHotkey: _hotkeyActionWire(value)),
            ),
          ),
          const Divider(height: 28),
          _ChoiceRow(
            title: text.pick('Menu shortcut', '菜单快捷键'),
            subtitle: text.pick(
              'How keyboard control should close the menu.',
              '键盘控制应如何关闭菜单。',
            ),
            value: text.pick(
              settings.menuHotkey,
              _localizedMenuHotkey(settings.menuHotkey),
            ),
            choices: [
              text.pick('Esc closes menu', 'Esc 关闭菜单'),
              text.pick('Toggle menu', '切换菜单'),
              text.pick('Disabled', '禁用'),
            ],
            onChanged: (value) => onChanged(
              settings.copyWith(menuHotkey: _menuHotkeyWire(value)),
            ),
          ),
          const Divider(height: 28),
          _InfoRow(
            icon: Icons.keyboard_rounded,
            title: text.pick('Recorder', '录制器'),
            detail: text.pick(
              'Current shortcut: ${settings.globalHotkeyLabel}',
              '当前快捷键：${settings.globalHotkeyLabel}',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: widget.onRecordGlobalHotkey,
            icon: const Icon(Icons.keyboard_command_key_rounded),
            label: Text(text.pick('Record shortcut', '录制快捷键')),
          ),
        ],
      ),
      _SettingsSection(
        icon: Icons.notifications_outlined,
        title: text.pick('Notifications', '通知'),
        subtitle: text.pick(
          'Session reminders, automation notifications, sounds, and notification center cleanup.',
          '会话提醒、自动化通知、提示音和通知中心清理。',
        ),
        children: [
          _SwitchRow(
            title: text.pick('Show notifications', '显示通知'),
            subtitle: text.pick(
              'Requests macOS notification permission when enabled.',
              '开启后请求 macOS 通知权限。',
            ),
            value: settings.showNotifications,
            onChanged: (value) =>
                onChanged(settings.copyWith(showNotifications: value)),
          ),
          const Divider(height: 28),
          Text(
            text.pick(
              'Session reminder every ${settings.sessionReminderMinutes}m',
              '每 ${settings.sessionReminderMinutes} 分钟提醒一次会话',
            ),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          Slider(
            value: settings.sessionReminderMinutes.toDouble(),
            min: 5,
            max: 240,
            divisions: 47,
            label: '${settings.sessionReminderMinutes}m',
            onChanged: (value) => onChanged(
              settings.copyWith(sessionReminderMinutes: value.round()),
            ),
          ),
          const Divider(height: 28),
          _SwitchRow(
            title: text.pick(
              'Notify when trigger sessions start',
              '触发器会话开始时通知',
            ),
            subtitle: text.pick(
              'Mirrors Amphetamine trigger/plan notifications.',
              '对应 Amphetamine 的触发器/计划通知。',
            ),
            value: settings.notifyAutomationStart,
            onChanged: (value) =>
                onChanged(settings.copyWith(notifyAutomationStart: value)),
          ),
          const Divider(height: 28),
          _SwitchRow(
            title: text.pick('Notify when trigger sessions end', '触发器会话结束时通知'),
            subtitle: text.pick(
              'Useful for automation transparency.',
              '有助于提高自动化行为透明度。',
            ),
            value: settings.notifyAutomationEnd,
            onChanged: (value) =>
                onChanged(settings.copyWith(notifyAutomationEnd: value)),
          ),
          const Divider(height: 28),
          _SwitchRow(
            title: text.pick(
              'Play sound when sessions start or stop',
              '会话开始或停止时播放提示音',
            ),
            subtitle: text.pick(
              'Uses the default macOS notification sound.',
              '使用 macOS 默认通知提示音。',
            ),
            value: settings.playStartStopSound,
            onChanged: (value) =>
                onChanged(settings.copyWith(playStartStopSound: value)),
          ),
          const Divider(height: 28),
          _SwitchRow(
            title: text.pick('Play sound when sessions extend', '延长会话时播放提示音'),
            subtitle: text.pick(
              'Matches the reference notification sound behavior.',
              '对应参考应用的通知提示音行为。',
            ),
            value: settings.playExtendSound,
            onChanged: (value) =>
                onChanged(settings.copyWith(playExtendSound: value)),
          ),
          const Divider(height: 28),
          _SwitchRow(
            title: text.pick('Clear delivered notifications', '清除已展示的通知'),
            subtitle: text.pick(
              'Remove shown notifications from Notification Center.',
              '从通知中心移除已展示的通知。',
            ),
            value: settings.clearDeliveredNotifications,
            onChanged: (value) => onChanged(
              settings.copyWith(clearDeliveredNotifications: value),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: widget.onClearDeliveredNotifications,
            icon: const Icon(Icons.notifications_off_rounded),
            label: Text(text.pick('Clear now', '立即清除')),
          ),
        ],
      ),
      _SettingsSection(
        icon: Icons.diamond_outlined,
        title: text.pick('Appearance', '外观'),
        subtitle: text.pick(
          'Menu bar icon, text, and attached menu detail preferences.',
          '菜单栏图标、文本和附加菜单详情偏好。',
        ),
        children: [
          _ChoiceRow(
            title: text.pick('Menu bar icon', '菜单栏图标'),
            subtitle: text.pick(
              'Visual style for the menu bar item.',
              '菜单栏项目的视觉样式。',
            ),
            value: text.pick(
              settings.menuIconStyle,
              _localizedMenuIcon(settings.menuIconStyle),
            ),
            choices: [
              text.pick('Pill', '胶囊'),
              text.pick('Cup', '杯子'),
              text.pick('Moon', '月亮'),
              text.pick('Text only', '仅文本'),
            ],
            onChanged: (value) => onChanged(
              settings.copyWith(menuIconStyle: _menuIconWire(value)),
            ),
          ),
          const Divider(height: 28),
          _SwitchRow(
            title: text.pick('Dim inactive menu icon', '非活动时降低菜单栏图标透明度'),
            subtitle: text.pick(
              'Use lower opacity when no session is active.',
              '没有活动会话时使用较低透明度。',
            ),
            value: settings.dimInactiveMenuIcon,
            onChanged: (value) =>
                onChanged(settings.copyWith(dimInactiveMenuIcon: value)),
          ),
          const Divider(height: 28),
          _SwitchRow(
            title: text.pick('Manual menu icon width', '手动调整菜单栏图标宽度'),
            subtitle: text.pick(
              'Keeps a stable width for future custom icon assets.',
              '为后续自定义图标资源保持稳定宽度。',
            ),
            value: settings.manualMenuIconWidth,
            onChanged: (value) =>
                onChanged(settings.copyWith(manualMenuIconWidth: value)),
          ),
          const Divider(height: 28),
          _SwitchRow(
            title: text.pick(
              'Show remaining session time in menu bar',
              '在菜单栏中显示剩余会话时间',
            ),
            subtitle: text.pick(
              'Native menu bar title updates while a timed session runs.',
              '定时会话运行时更新原生菜单栏标题。',
            ),
            value: settings.showRemainingSessionTime,
            onChanged: (value) =>
                onChanged(settings.copyWith(showRemainingSessionTime: value)),
          ),
          const Divider(height: 28),
          _SwitchRow(
            title: text.pick(
              'Show current session details in attached menu',
              '在附加菜单中显示当前会话详情',
            ),
            subtitle: text.pick(
              'Controls whether future attached menus show expanded status.',
              '控制后续附加菜单是否展示展开状态。',
            ),
            value: settings.showSessionDetailsInMenu,
            onChanged: (value) =>
                onChanged(settings.copyWith(showSessionDetailsInMenu: value)),
          ),
          const Divider(height: 28),
          _SwitchRow(
            title: text.pick(
              'Show disk wake details in attached menu',
              '在附加菜单中显示硬盘唤醒详情',
            ),
            subtitle: text.pick(
              'Adds disk wake details once disk selection is available.',
              '硬盘选择能力可用后显示硬盘唤醒详情。',
            ),
            value: settings.showDiskDetailsInMenu,
            onChanged: (value) =>
                onChanged(settings.copyWith(showDiskDetailsInMenu: value)),
          ),
        ],
      ),
      _SettingsSection(
        icon: Icons.bar_chart_rounded,
        title: text.pick('Statistics', '统计数据'),
        subtitle: text.pick(
          'Local session totals and history preferences.',
          '本地会话统计和历史偏好。',
        ),
        children: [
          _SwitchRow(
            title: text.pick('Collect statistics', '收集统计数据'),
            subtitle: text.pick(
              'Uses local session history only; no backend is created.',
              '仅使用本地会话历史；不会创建后端。',
            ),
            value: settings.collectStatistics,
            onChanged: (value) =>
                onChanged(settings.copyWith(collectStatistics: value)),
          ),
          const Divider(height: 28),
          _InfoRow(
            icon: Icons.folder_outlined,
            title: text.pick('Local state file', '本地状态文件'),
            detail: storePath,
          ),
        ],
      ),
    ];

    return Column(
      children: [
        _SettingsTabs(
          tabs: tabs,
          selectedIndex: _selectedTab,
          onSelected: (index) => setState(() => _selectedTab = index),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: KeyedSubtree(
            key: ValueKey(_selectedTab),
            child: sections[_selectedTab],
          ),
        ),
      ],
    );
  }

  String _localizedHotkeyAction(String value) {
    return switch (value) {
      'Extend current session' => '延长当前会话',
      'Ignore shortcut' => '忽略快捷键',
      _ => '结束当前会话并开启新会话',
    };
  }

  String _hotkeyActionWire(String value) {
    return switch (value) {
      '延长当前会话' => 'Extend current session',
      '忽略快捷键' => 'Ignore shortcut',
      _ =>
        value == 'Extend current session' || value == 'Ignore shortcut'
            ? value
            : 'End current and start new',
    };
  }

  String _localizedMenuHotkey(String value) {
    return switch (value) {
      'Toggle menu' => '切换菜单',
      'Disabled' => '禁用',
      _ => 'Esc 关闭菜单',
    };
  }

  String _menuHotkeyWire(String value) {
    return switch (value) {
      '切换菜单' => 'Toggle menu',
      '禁用' => 'Disabled',
      _ =>
        value == 'Toggle menu' || value == 'Disabled'
            ? value
            : 'Esc closes menu',
    };
  }

  String _localizedMenuIcon(String value) {
    return switch (value) {
      'Cup' => '杯子',
      'Moon' => '月亮',
      'Text only' => '仅文本',
      _ => '胶囊',
    };
  }

  String _menuIconWire(String value) {
    return switch (value) {
      '杯子' => 'Cup',
      '月亮' => 'Moon',
      '仅文本' => 'Text only',
      _ =>
        value == 'Cup' || value == 'Moon' || value == 'Text only'
            ? value
            : 'Pill',
    };
  }

  String _localizedLanguageMode(AppText text, String value) {
    return switch (AppLocaleController.normalized(value)) {
      AppLocaleController.chinese => text.pick('Chinese', '中文'),
      AppLocaleController.english => 'English',
      AppLocaleController.japanese => text.pick('Japanese', '日语'),
      AppLocaleController.french => text.pick('French', '法语'),
      AppLocaleController.italian => text.pick('Italian', '意大利语'),
      AppLocaleController.german => text.pick('German', '德语'),
      AppLocaleController.spanish => text.pick('Spanish', '西班牙语'),
      _ => text.pick('Follow system', '跟随系统'),
    };
  }

  String _languageModeWire(String value) {
    return switch (value) {
      '中文' ||
      'Chinese' ||
      'Chinois' ||
      'Cinese' ||
      'Chinesisch' ||
      'Chino' => AppLocaleController.chinese,
      'English' => AppLocaleController.english,
      '日语' ||
      'Japanese' ||
      '日本語' ||
      'Japonais' ||
      'Giapponese' ||
      'Japanisch' ||
      'Japonés' => AppLocaleController.japanese,
      '法语' ||
      'French' ||
      'フランス語' ||
      'Français' ||
      'Francese' ||
      'Französisch' ||
      'Francés' => AppLocaleController.french,
      '意大利语' ||
      'Italian' ||
      'イタリア語' ||
      'Italien' ||
      'Italiano' ||
      'Italienisch' => AppLocaleController.italian,
      '德语' ||
      'German' ||
      'ドイツ語' ||
      'Allemand' ||
      'Tedesco' ||
      'Deutsch' ||
      'Alemán' => AppLocaleController.german,
      '西班牙语' ||
      'Spanish' ||
      'スペイン語' ||
      'Espagnol' ||
      'Spagnolo' ||
      'Spanisch' ||
      'Español' => AppLocaleController.spanish,
      _ => AppLocaleController.system,
    };
  }
}

class _SettingsTabs extends StatelessWidget {
  const _SettingsTabs({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<(IconData, String)> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < tabs.length; index++) ...[
              _SettingsTabButton(
                icon: tabs[index].$1,
                label: tabs[index].$2,
                selected: selectedIndex == index,
                onTap: () => onSelected(index),
              ),
              if (index != tabs.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsTabButton extends StatelessWidget {
  const _SettingsTabButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFE0F1EC) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          width: 118,
          height: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected
                    ? const Color(0xFF0F7E6E)
                    : const Color(0xFF6A7370),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  color: selected
                      ? const Color(0xFF0B6E5D)
                      : const Color(0xFF6A7370),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFF0F7E6E)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF66716C),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class _ClosedDisplayRemovalPanel extends StatelessWidget {
  const _ClosedDisplayRemovalPanel({
    required this.installed,
    required this.busy,
    required this.onRefresh,
    required this.onRemove,
  });

  final bool? installed;
  final bool busy;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onRemove;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final helperReady = installed == true;
    final status = switch (installed) {
      true => text.pick('Helper installed', '助手已安装'),
      false => text.pick('No helper installed', '未安装助手'),
      null => text.pick('Helper status unknown', '助手状态未知'),
    };
    final accent = helperReady
        ? const Color(0xFFB45309)
        : const Color(0xFF66716C);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: helperReady ? const Color(0xFFFFF7ED) : const Color(0xFFF6F7F4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: helperReady
              ? const Color(0xFFF2C38B)
              : const Color(0xFFDDE3DD),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final copy = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.admin_panel_settings_rounded, color: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text.pick('Closed-display helper removal', '合盖助手移除'),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status,
                      style: TextStyle(
                        color: accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      text.pick(
                        'Use this before uninstalling the app, or whenever you no longer need closed-display sessions.',
                        '卸载 App 前，或不再需要合盖防睡眠会话时，请在这里移除助手。',
                      ),
                      style: const TextStyle(
                        color: Color(0xFF66716C),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: compact ? WrapAlignment.start : WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: busy ? null : onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(text.pick('Refresh', '刷新')),
              ),
              FilledButton.icon(
                onPressed: busy || !helperReady ? null : onRemove,
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(
                  text.pick('Remove Closed-Display Helper', '移除合盖助手'),
                ),
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 12), actions],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: copy),
              const SizedBox(width: 16),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.choices,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final String value;
  final List<String> choices;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = choices.contains(value) ? value : choices.first;
    final dropdown = DropdownButtonFormField<String>(
      initialValue: selected,
      isExpanded: true,
      items: [
        for (final choice in choices)
          DropdownMenuItem(
            value: choice,
            child: Text(choice, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (next) {
        if (next != null) {
          onChanged(next);
        }
      },
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final label = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF69736F), fontSize: 13),
            ),
          ],
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              label,
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: dropdown),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: label),
            const SizedBox(width: 16),
            SizedBox(width: 230, child: dropdown),
          ],
        );
      },
    );
  }
}

class _ClosedDisplayHelperRow extends StatelessWidget {
  const _ClosedDisplayHelperRow({
    required this.installed,
    required this.busy,
    required this.onRefresh,
    required this.onInstall,
    required this.onRemove,
  });

  final bool? installed;
  final bool busy;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onInstall;
  final Future<void> Function() onRemove;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final status = switch (installed) {
      true => text.pick('Helper installed', '助手已安装'),
      false => text.pick('Helper not installed', '助手未安装'),
      null => text.pick('Helper status unknown', '助手状态未知'),
    };
    final statusColor = switch (installed) {
      true => const Color(0xFF0F7E6E),
      false => const Color(0xFF8A5D1A),
      null => const Color(0xFF66716C),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5EE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4DDC9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.admin_panel_settings_rounded, color: statusColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text.pick('Closed-display helper', '合盖助手'),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text.pick(
              'Used only for the optional closed-display mode. Removing it deletes the local helper script and sudoers rule from this Mac.',
              '仅用于可选的合盖模式。移除后会从这台 Mac 删除本地 helper 脚本和 sudoers 规则。',
            ),
            style: const TextStyle(
              color: Color(0xFF66716C),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: busy ? null : onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(text.pick('Refresh', '刷新')),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : onInstall,
                icon: const Icon(Icons.build_circle_outlined),
                label: Text(text.pick('Install / Repair', '安装/修复')),
              ),
              FilledButton.icon(
                onPressed: busy || installed != true ? null : onRemove,
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(text.pick('Remove helper', '移除助手')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PowerPanel extends StatelessWidget {
  const _PowerPanel({required this.status, required this.onRefresh});

  final PowerStatus status;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    return _Surface(
      child: Row(
        children: [
          Icon(
            status.isPluggedIn
                ? Icons.power_rounded
                : Icons.battery_4_bar_rounded,
            color: status.isPluggedIn
                ? const Color(0xFF0F7E6E)
                : const Color(0xFF8A5D1A),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text.pick('Power source', '电源来源'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  _powerStatusLabel(text, status),
                  style: const TextStyle(color: Color(0xFF66716C)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRefresh,
            tooltip: text.pick('Refresh power source', '刷新电源状态'),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    required this.rule,
    required this.title,
    required this.description,
    required this.onChanged,
  });

  final AwakeRule rule;
  final String title;
  final String description;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          rule.implemented
              ? Icons.check_circle_rounded
              : Icons.construction_rounded,
          color: rule.implemented
              ? const Color(0xFF0F7E6E)
              : const Color(0xFF9A6B12),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(color: Color(0xFF66716C), height: 1.35),
              ),
            ],
          ),
        ),
        if (onChanged == null)
          const _SmallBadge(label: 'Planned')
        else
          Switch(value: rule.enabled, onChanged: onChanged),
      ],
    );
  }
}

class _RuleSettingRow extends StatelessWidget {
  const _RuleSettingRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF66716C), height: 1.35),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF69736F), fontSize: 13),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE0F5EE) : const Color(0xFFF2E8DA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isActive ? const Color(0xFF9BD8C7) : const Color(0xFFE3CFAE),
        ),
      ),
      child: Text(
        isActive ? text.pick('ACTIVE', '开启') : text.pick('IDLE', '空闲'),
        style: TextStyle(
          color: isActive ? const Color(0xFF0B6E5D) : const Color(0xFF8A5D1A),
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _AwakeGauge extends StatelessWidget {
  const _AwakeGauge({required this.progress, required this.active});

  final double progress;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 136,
      height: 136,
      child: CustomPaint(
        painter: _GaugePainter(progress: progress, active: active),
        child: Icon(
          active ? Icons.local_cafe_rounded : Icons.nightlight_round,
          size: 44,
          color: active ? const Color(0xFF0F7E6E) : const Color(0xFF8A6B2C),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.progress, required this.active});

  final double progress;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = active ? const Color(0xFFD7EEE7) : const Color(0xFFEDE2D1);
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = active ? const Color(0xFF0F7E6E) : const Color(0xFFB9873B);
    canvas.drawCircle(center, radius, basePaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * (active ? progress : 0.18),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.active != active;
  }
}

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel({required this.session, required this.nativeStatus});

  final AwakeSession session;
  final String nativeStatus;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text.pick('Activity', '活动'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          _ActivityLine(
            label: session.isActive
                ? text.pick('Session active', '会话进行中')
                : text.pick('No active session', '没有活动会话'),
            detail: session.isActive
                ? text.pick(
                    'Started from ${_sessionSourceLabel(text, session.source)}.',
                    '由${_sessionSourceLabel(text, session.source)}开启。',
                  )
                : text.pick('Native assertion released.', '原生防睡眠断言已释放。'),
          ),
          _ActivityLine(
            label: text.pick('Native bridge', '原生桥接'),
            detail: _nativeStatusLabel(text, nativeStatus),
          ),
          _ActivityLine(
            label: text.pick('Status bar', '菜单栏'),
            detail: text.pick(
              'Menu item is available in the macOS menu bar.',
              'macOS 菜单栏中的控制项可用。',
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityLine extends StatelessWidget {
  const _ActivityLine({required this.label, required this.detail});

  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 7),
            decoration: const BoxDecoration(
              color: Color(0xFF0F7E6E),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Color(0xFF1B2521), height: 1.35),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text: detail,
                    style: const TextStyle(color: Color(0xFF66716C)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});

  final SessionLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = switch (entry.kind) {
      LogKind.start => const Color(0xFF0F7E6E),
      LogKind.stop => const Color(0xFF8A5D1A),
      LogKind.error => const Color(0xFFB94A3A),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatTime(entry.timestamp)} - ${entry.detail}',
                  style: const TextStyle(color: Color(0xFF66716C)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF0F7E6E)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(
                detail,
                style: const TextStyle(color: Color(0xFF66716C), height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE3DD)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF8A9791), size: 32),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(detail, style: const TextStyle(color: Color(0xFF66716C))),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4E8D1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF8A5D1A),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _BatteryHint extends StatelessWidget {
  const _BatteryHint({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE0F5EE) : const Color(0xFFFFF7E7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active ? const Color(0xFF9BD8C7) : const Color(0xFFEBD7A8),
        ),
      ),
      child: Text(
        active
            ? text.pick(
                'Active session: verify with pmset for system proof.',
                '会话已开启：可用 pmset 验证系统断言。',
              )
            : text.pick(
                'Battery note: long sessions can increase power usage.',
                '电池提示：长时间会话可能增加耗电。',
              ),
        style: TextStyle(
          fontSize: 12,
          color: active ? const Color(0xFF0B6E5D) : const Color(0xFF75551D),
          height: 1.3,
        ),
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE3DD)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

String _formatTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
