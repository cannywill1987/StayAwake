创建日期：260628

# FE Whiteboard - StayAwake macOS 保持唤醒

## 0.1 背景与目标

用 Flutter 实现 macOS 主窗口控制台，承接 UI 设计并通过 MethodChannel 调用原生 Status Bar / IOKit 服务。

## 0.2 UI/UX 设计输入

- 交互设计文档：`02-交互设计/交互设计建议-StayAwake-macOS保持唤醒.md`
- UI 设计说明：`03-UI设计/设计说明-StayAwake-macOS保持唤醒.md`
- 设计图：`03-UI设计/设计图-StayAwake-macOS保持唤醒.png`
- 设计输入闭环状态：已完成

## 1. Boundary

### 允许修改

- `lib/main.dart`
- `test/widget_test.dart`
- `macos/Runner/AppDelegate.swift`
- `macos/Runner/MainFlutterWindow.swift`
- `macos/Runner/Configs/AppInfo.xcconfig`

### 禁止修改

- 不引入远程后台。
- 不新增账号、支付、云同步。
- 不为 Status Bar 新建多个 channel。

## 2. 页面状态

- 初始态：Ready / IDLE / Inactive。
- Active：倒计时、ACTIVE pill、Stop 按钮。
- 异常态：native bridge unavailable 或 failed to start。
- 禁用态：start/stop 请求中禁用主按钮，避免重复点击。

## 2.1 本轮页面范围

| 页面 | 入口 | 本轮状态 | 说明 |
|---|---|---:|---|
| Status | 左侧 Status | 已实现 | 主状态、快捷 session、电源状态、Activity |
| Sessions | 左侧 Sessions | 已实现 | 快捷启动、停止当前 session、本地 history、清空 history |
| Rules | 左侧 Rules | 已实现 | 插电自动启动、低电量自动停止、菜单栏控制状态、前台 App trigger |
| Settings | 左侧 Settings | 已实现 | session 默认项、自定义时长、低电量阈值、通知偏好、本地状态文件路径 |

## 2.2 本地状态

| 状态 | 位置 | 持久化 | 说明 |
|---|---|---:|---|
| AppSettings | `lib/main.dart` | 是 | 写入 `~/Library/Application Support/StayAwake/state.json` |
| AwakeRule | `lib/main.dart` | 是 | 保存规则 enabled 状态；未实现规则不可开启 |
| SessionLogEntry | `lib/main.dart` | 是 | 最多保留 40 条本地记录 |
| PowerStatus | `lib/main.dart` + native | 否 | 通过 `getPowerStatus` 读取实时系统状态 |
| FrontmostApp | `lib/main.dart` + native | 否 | 通过 `getFrontmostApp` 读取当前前台 App |

## 3. 接口依赖

| 接口 | 方法 | 用途 |
|---|---|---|
| `app.stayawake/status_bar` | `startSession` | 开启 native assertion |
| `app.stayawake/status_bar` | `stopSession` | 释放 native assertion |
| `app.stayawake/status_bar` | `getStatus` | 获取 native 状态 |
| `app.stayawake/status_bar` | `getPowerStatus` | 获取电源来源、插电状态和电量 |
| `app.stayawake/status_bar` | `getFrontmostApp` | 获取当前前台 App 名称和 bundle id |
| `app.stayawake/status_bar` | `syncPreferences` | Flutter 将 settings/rules 同步给原生菜单栏 |

## 4. Acceptance

- [x] UI 实现设计主结构。
- [x] Flutter analyze 通过。
- [x] Widget test 通过。
- [x] macOS release build 通过。
- [x] Computer Use 点击 Start/Stop 通过。
- [x] `pmset` 验证 native assertion 生效和释放。
- [x] 左侧四个页面可真实切换。
- [x] 本地 settings/rules/history 可持久化。
- [x] 菜单栏包含 Start New Session、Session Settings、Rules 子菜单。
- [x] Rules 页面可选择当前前台 App 作为 trigger 目标。
- [x] Settings 页面可设置自定义 session 时长并同步菜单栏。
- [x] release app 可打开并保存真实 UI QA 截图。
