创建日期：260628

# StayAwake 技术实现流程图

## 代码依据
- Flutter 主入口：[lib/main.dart](/Users/linzhibin/Desktop/code/StayAwake/lib/main.dart)
- macOS 状态栏与系统能力：[macos/Runner/AppDelegate.swift](/Users/linzhibin/Desktop/code/StayAwake/macos/Runner/AppDelegate.swift)
- 通信通道：`MethodChannel('app.stayawake/status_bar')`
- 核心 native 能力：`IOPMAssertionCreateWithName` / `IOPMAssertionRelease`

## 1. 总架构

```mermaid
flowchart LR
  User["用户操作\n页面按钮 / 菜单栏菜单 / 快捷入口"]
  Flutter["Flutter UI + 状态机\nlib/main.dart\n_StayAwakeHomePageState"]
  Store["本地持久化\nLocalStore\nsettings / rules / history"]
  Channel["MethodChannel\napp.stayawake/status_bar"]
  Native["macOS AppDelegate.swift\nNSStatusItem / NSMenu"]
  Assertion["macOS Power Assertion\nIOPMAssertionCreateWithName\nIOPMAssertionRelease"]
  System["系统睡眠策略\n显示器睡眠 / 系统空闲睡眠"]

  User --> Flutter
  Flutter <--> Store
  Flutter <--> Channel
  Channel <--> Native
  Native <--> Assertion
  Assertion --> System
  Native -- nativeStatusChanged --> Channel
  Channel -- 刷新会话状态 --> Flutter
```

## 2. 手动开启或结束会话

```mermaid
flowchart TD
  A["用户选择时长\nStatus 快捷按钮 / Sessions 页面 / 菜单栏分钟小时"]
  B["Flutter _startSession(duration, source)\n创建 AwakeSession\n设置 _busy=true"]
  C["MethodChannel.startSession\n参数: durationSeconds,\npreventDisplaySleep,\nallowScreenSaver"]
  D["AppDelegate.handle(startSession)\n读取参数并更新 native 偏好"]
  E{"preventDisplaySleep?"}
  F["kIOPMAssertionTypeNoDisplaySleep\n阻止显示器睡眠"]
  G["kIOPMAssertionTypeNoIdleSleep\n阻止系统空闲睡眠"]
  H["IOPMAssertionCreateWithName\n保存 assertionID"]
  I{"是否有 durationSeconds?"}
  J["scheduleStopTimer\n到点自动 stopSession"]
  K["rebuildMenu\n更新菜单标题和结束时间"]
  L["nativeStatusChanged\n回调 Flutter"]
  M["Flutter _syncFromNative\n刷新 UI 状态"]
  N["用户结束会话"]
  O["Flutter _stopSession\nMethodChannel.stopSession"]
  P["AppDelegate.stopSession\nIOPMAssertionRelease\n清理 Timer"]

  A --> B --> C --> D --> E
  E -- 是 --> F --> H
  E -- 否 --> G --> H
  H --> I
  I -- 有时长 --> J --> K
  I -- 无限期 --> K
  K --> L --> M
  N --> O --> P --> L
```

## 3. 菜单栏与快速设置

```mermaid
flowchart TD
  A["AppDelegate.applicationDidFinishLaunching"]
  B["configureStatusItem\n创建 NSStatusItem\n标题 STAY"]
  C["rebuildMenu\n重建 NSMenu"]
  D["开始新会话\n无限期 / 分钟 / 小时 / 自定义时间"]
  E["快速设置\nQuickSettingsMenuView"]
  F["设置 / 规则入口\nopenSection: settings/rules"]
  G["用户点击菜单项"]
  H{"菜单动作类型"}
  I["startPreset / stopSession\nNative -> Flutter"]
  J["toggleSetting / toggleRule\nNative -> Flutter"]
  K["Flutter 更新 AppSettings 或 AwakeRule"]
  L["LocalStore 保存"]
  M["syncPreferences\nFlutter -> Native"]
  N["Native 更新本地变量\nconfigureSessionAuxiliaryTimers\nrebuildMenu"]

  A --> B --> C
  C --> D
  C --> E
  C --> F
  D --> G
  E --> G
  F --> G
  G --> H
  H -- 会话动作 --> I
  H -- 设置/规则开关 --> J --> K --> L --> M --> N --> C
```

## 4. Stay Awake Rules 自动规则

```mermaid
flowchart TD
  A["启动 _bootstrap\n读取 settings/rules/history"]
  B["初始同步 native 状态"]
  C["刷新电源 / 前台 App / 运行 App / 下载状态"]
  D["Timer 每秒 _tick"]
  E{"每 30 秒?"}
  F["刷新 getPowerStatus\ngetFrontmostApp\ngetRunningApps\n扫描 ~/Downloads"]
  G{"triggersEnabled?"}
  H["跳过自动规则"]
  I{"plugged-in 规则开启\n且接入电源\n且当前无会话?"}
  J["自动 _startSession(null)\n无限期会话"]
  K{"low-battery 规则开启\n且电量 <= 阈值\n且正在电池供电?"}
  L["自动 _stopSession\nStopped by low battery rule"]
  M{"app-trigger 开启\n目标 bundleId 正在运行?"}
  N["自动 _startSession(null)"]
  O{"download-trigger 开启\n存在 .download/.crdownload/.part?"}
  P["自动 _startSession(null)"]

  A --> B --> C --> D
  D --> E
  E -- 否 --> D
  E -- 是 --> F --> G
  G -- 否 --> H --> D
  G -- 是 --> I
  I -- 是 --> J --> D
  I -- 否 --> K
  K -- 是 --> L --> D
  K -- 否 --> M
  M -- 是 --> N --> D
  M -- 否 --> O
  O -- 是 --> P --> D
  O -- 否 --> D
```

## 5. 设置页与国际化

```mermaid
flowchart LR
  A["Settings 页面\nTab 切换 General / Session defaults / System controls / ..."]
  B["用户切换控件\nSwitch / Slider / Dropdown"]
  C["AppSettings.copyWith\n生成新设置"]
  D["_updateSettings\nsetState + LocalStore 保存"]
  E["syncPreferences\n推送给 AppDelegate"]
  F["AppDelegate.syncPreferences\n更新 native 变量"]
  G["configureSessionAuxiliaryTimers\n锁屏 / 移动光标 / 硬盘唤醒等辅助 Timer"]
  H["rebuildMenu\n菜单栏快速设置同步显示"]
  I["AppText / AppTextDelegate\n根据 Locale 取中文或英文文案"]

  A --> B --> C --> D --> E --> F --> G --> H
  I --> A
```

## 6. 一句话理解每个页面

| 页面 | 技术职责 |
|---|---|
| Status | 显示当前 native assertion 和快速开始入口，核心调用 `_startSession` / `_stopSession`。 |
| Sessions | 展示预设时长和会话历史，本质仍然走同一条会话控制链路。 |
| Stay Awake Rules | 配置电源、低电量、App、下载触发规则，定时刷新状态后决定是否自动 start/stop。 |
| Settings | 管理默认会话、系统控制、触发器、硬盘唤醒、热键、通知、外观、统计数据等偏好，并同步给 native。 |
| 菜单栏 | Swift 原生 `NSStatusItem + NSMenu`，可不打开主窗口直接控制会话和快速设置。 |

## 7. 最重要的技术边界

- Flutter 不是直接阻止系统睡眠；真正生效的是 macOS native 的 `IOPMAssertionCreateWithName`。
- `MethodChannel` 是 Flutter 和 Swift 的唯一桥，所有真实系统能力都从这里过。
- 自动规则目前是本地规则，不需要后端，也没有账号同步。
- 下载规则通过扫描 `~/Downloads` 下的临时后缀判断：`.download`、`.crdownload`、`.part`。
- 设置和规则先保存在本地，再同步给 native 菜单和辅助 timer。
