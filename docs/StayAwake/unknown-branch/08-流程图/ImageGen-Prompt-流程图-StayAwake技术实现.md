创建日期：260628

# ImageGen Prompt - 流程图-StayAwake技术实现

## 生成目标
- 图名：StayAwake 技术实现总览
- 读者：产品、设计、Flutter/macOS 开发、测试
- 用途：解释菜单栏、页面、规则、设置和 macOS 防睡眠断言之间的真实技术链路。

## 真实代码依据
- Flutter 文件：lib/main.dart
- macOS 文件：macos/Runner/AppDelegate.swift
- 通信通道：MethodChannel("app.stayawake/status_bar")
- Native 能力：IOPMAssertionCreateWithName / IOPMAssertionRelease
- 本地状态：LocalStore，保存 settings / rules / history

## 必须展示的流程
- 用户从 Flutter 页面或 macOS 状态栏菜单开始/结束会话。
- Flutter 调用 startSession / stopSession / syncPreferences / getStatus。
- AppDelegate 创建或释放 IOPMAssertion。
- Native 通过 nativeStatusChanged 回调 Flutter，Flutter 刷新 UI。
- 电源、App、下载文件规则通过轮询状态触发自动会话。

## 必须展示的标志位
- preventDisplaySleep：true 时使用 NoDisplaySleep，false 时使用 NoIdleSleep。
- allowScreenSaver：保存到会话设置，作为屏保策略状态。
- triggersEnabled：总开关，关闭后自动规则不启动。
- plugged-in：接入电源时自动开启无限期会话。
- low-battery：低电量时结束当前会话。
- app-trigger：目标 App 运行时自动开启会话。
- download-trigger：下载临时文件存在时自动开启会话。

## 右侧总解释
- StayAwake 的核心不是后端服务，而是 Flutter 状态机 + Swift 状态栏菜单 + macOS power assertion。
- 真正阻止睡眠的是 AppDelegate.swift 里的 IOPMAssertion。
- Flutter 负责页面、规则、持久化和用户可见状态。
- MethodChannel 是两边唯一的同步桥。

## 本次生成状态
- 生成工具：image_gen
- 生成图路径：Codex 对话内生成；工程内保存 Mermaid 可编辑版
- 状态：已生成对话图片，已保存可编辑 Mermaid 文档
