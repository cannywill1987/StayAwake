创建日期：260628

# 需求文档：StayAwake macOS 保持唤醒

## 背景与目标

用户希望模仿 Amphetamine 的核心场景，做一个 macOS 保持 awake 工具。MVP 目标是让用户通过主窗口或菜单栏快速开启防睡眠 session，并能确认原生系统层真的生效。

## 用户故事

- 作为 macOS 用户，我想一键让 Mac 在演示、下载、远程连接时保持唤醒。
- 作为轻量工具用户，我希望可以从菜单栏直接开启 15 分钟、1 小时或无限期 session。
- 作为谨慎用户，我希望看到剩余时间、当前状态和电池提醒。

## 功能范围

### MVP 已实现

- Flutter macOS 工程：`lib/main.dart`
- 原生 Status Bar：`macos/Runner/AppDelegate.swift`
- Flutter/native bridge：`app.stayawake/status_bar`
- 原生防睡眠：`IOPMAssertionCreateWithName`
- 快捷时长：15m、30m、1h、2h、Indefinite
- 启停状态、倒计时、activity log
- `pmset -g assertions` 系统层验证

### 本轮补齐功能

- 左侧 `Status / Sessions / Rules / Settings` 已变成真实页面切换，不再只是选中态。
- `Sessions` 页支持启动快捷 session、停止当前 session、查看和清空本地 session history。
- `Rules` 页支持电源状态读取、插电自动开启、低电量自动停止、菜单栏控制保持可用。
- `Rules` 页支持选择当前前台 App 作为触发目标，并在该 App 成为前台时自动开启 session。
- `Rules` 页支持下载文件触发规则，用于浏览器和系统下载临时文件存在时自动开启 session。
- `Settings` 页支持 session 默认项、自定义 session 时长、本地状态文件、低电量阈值配置，并持久化到本机 Application Support。
- 原生 bridge 新增 `getPowerStatus` 与 `getFrontmostApp`，用于返回电源状态和前台 App。
- 菜单栏新增可见 `STAY` / `STAY ON` 入口和 Amphetamine 风格中文子菜单，并能同步 Flutter 设置。
- 菜单栏启动 / 停止动作避免 Flutter 与 native 双侧重复启动。

### 仍在规划

- 状态栏自定义 popover 暂未实现，当前仍使用原生 NSMenu。
- 开机登录 native Login Item 暂未接入，Settings 中仅保存本地偏好。

### 非目标

- 当前不做账号系统、云同步、团队策略后台。
- 当前不做 App Store 上架素材和签名发布。

## 本机后端 / 服务层定义

本项目的“后端”在 MVP 中不是远程服务，而是本机服务层：

| 层级 | 文件 | 职责 |
|---|---|---|
| UI 状态 | `lib/main.dart` | session 状态、倒计时、开关、activity 展示 |
| Bridge Contract | `app.stayawake/status_bar` | Flutter 与原生通信 |
| Native Service | `macos/Runner/AppDelegate.swift` | Status Bar、菜单、IOKit assertion |
| System Proof | `pmset -g assertions` | 验证 macOS power assertion |

## 验收标准

- `flutter analyze` 无问题。
- `flutter test` 通过。
- `flutter build macos` 成功。
- Computer Use 能看到 StayAwake 主窗口并点击 Start/Stop。
- 点击 Start 后 `pmset -g assertions` 出现 `NoDisplaySleepAssertion named: "StayAwake active session"`。
- 点击 Stop 后该 assertion 消失。
- Widget test 覆盖 Status、Sessions、Rules、Settings 页面切换。
- Release App 可打开并保存真实 UI QA 截图。
- 菜单栏 `STAY` 入口可见，点击后能打开包含 `开启新会话`、`分钟`、`小时`、`快速设置` 等项目的 NSMenu。
