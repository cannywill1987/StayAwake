import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stay_awake/main.dart';

void main() {
  setUp(() {
    AppLocaleController.setLanguageMode(AppLocaleController.system);
    _mockStatusBarChannel();
  });

  testWidgets('StayAwake renders and switches the main pages', (tester) async {
    await tester.pumpWidget(const StayAwakeApp());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text(Params.appName), findsOneWidget);
    expect(find.text('Status'), findsWidgets);
    expect(find.text('Quick sessions'), findsOneWidget);
    expect(find.byIcon(Icons.local_cafe_rounded), findsWidgets);

    await tester.tap(find.text('Sessions').first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Session launcher'), findsOneWidget);
    expect(find.text('Session history'), findsOneWidget);

    await tester.tap(find.text('Stay Awake Rules').first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Stay Awake Rules'), findsWidgets);
    expect(find.text('Power stay-awake rules'), findsOneWidget);
    expect(find.text('Download stay-awake rule'), findsOneWidget);
    expect(find.text('App stay-awake rule'), findsOneWidget);
    expect(find.text('Other Stay Awake rules'), findsOneWidget);
    expect(find.text('Start when plugged in'), findsOneWidget);
    expect(find.text('Use current app'), findsOneWidget);
    expect(find.text('Choose running app'), findsOneWidget);
    expect(find.text('Running app trigger'), findsOneWidget);

    await tester.tap(find.text('Settings').first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Session defaults'), findsWidgets);
    expect(find.text('Low battery stop threshold: 20%'), findsWidgets);
    expect(find.text('Default duration'), findsOneWidget);
    expect(find.text('General'), findsOneWidget);
    expect(find.text('System controls'), findsOneWidget);
    expect(find.text('Disk wake'), findsOneWidget);
    expect(find.text('Hotkeys'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Statistics'), findsOneWidget);

    await tester.tap(find.text('General'));
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Follow system'), findsOneWidget);
    expect(find.text('Start at login'), findsOneWidget);
    expect(find.text('Hide ${Params.appName} in Dock'), findsOneWidget);
    expect(find.text('Default duration'), findsNothing);
  });

  testWidgets('Settings page supports Chinese localization', (tester) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('zh');
    tester.binding.platformDispatcher.localesTestValue = const [Locale('zh')];
    addTearDown(() {
      tester.binding.platformDispatcher.clearLocaleTestValue();
      tester.binding.platformDispatcher.clearLocalesTestValue();
    });

    await tester.pumpWidget(const StayAwakeApp());
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('设置').first);
    await tester.pumpAndSettle();

    expect(find.text('状态'), findsWidgets);
    expect(find.text('会话默认设置'), findsWidgets);
    expect(find.text('默认时长'), findsOneWidget);
    expect(find.text('通用'), findsOneWidget);
    expect(find.text('系统控制'), findsOneWidget);
    expect(find.text('硬盘唤醒'), findsOneWidget);

    await tester.tap(find.text('通用'));
    await tester.pumpAndSettle();
    expect(find.text('语言'), findsOneWidget);
    expect(find.text('跟随系统'), findsOneWidget);
    expect(find.text('登录时启动'), findsOneWidget);
    expect(find.text('在程序坞中隐藏 ${Params.appName}'), findsOneWidget);
    expect(find.text('默认时长'), findsNothing);

    await tester.tap(find.text('跟随系统'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Follow system'), findsNothing);
  });
}

void _mockStatusBarChannel() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('app.stayawake/status_bar'),
        (call) async {
          switch (call.method) {
            case 'getStatus':
              return {
                'active': false,
                'preventDisplaySleep': true,
                'allowScreenSaver': false,
              };
            case 'getPowerStatus':
              return {
                'available': true,
                'source': 'AC Power',
                'isPluggedIn': true,
                'batteryPercent': 100,
              };
            case 'getFrontmostApp':
              return {
                'available': true,
                'name': 'Xcode',
                'bundleIdentifier': 'com.apple.dt.Xcode',
              };
            case 'getRunningApps':
              return [
                {
                  'name': 'Xcode',
                  'bundleIdentifier': 'com.apple.dt.Xcode',
                  'isRegular': true,
                },
                {
                  'name': 'StayAwake Helper',
                  'bundleIdentifier': 'app.stayawake.helper',
                  'isRegular': false,
                },
              ];
            case 'syncPreferences':
              return {'active': false};
            case 'startSession':
            case 'stopSession':
              return {'active': false};
          }
          return null;
        },
      );
}
