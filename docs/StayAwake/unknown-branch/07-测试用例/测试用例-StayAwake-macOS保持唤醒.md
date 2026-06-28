创建日期：260628

# 测试用例：StayAwake macOS 保持唤醒

## 1. 测试目标

验证 StayAwake 可以通过 Flutter UI 调用 macOS native service，并真实阻止显示器睡眠。

## 2. 测试范围

- 页面 / 模块：Status、Sessions、Rules、Settings、macOS Status Bar
- 功能点：Start/Stop、快捷 session、native assertion、电源状态、本地 settings/rules/history
- 菜单栏功能点：`STAY` 入口、Amphetamine 风格菜单、快速设置、下载触发开关、自定义时间/直到面板
- 接口：`app.stayawake/status_bar`

## 3. 测试环境

| 项目 | 内容 |
|---|---|
| 环境名称 | 本机 macOS |
| 入口地址 | `build/macos/Build/Products/Release/StayAwake.app` |
| 登录方式 | 不涉及 |
| 数据来源 | 本机状态 |

## 4. 前置条件

- Flutter SDK 可用。
- macOS Runner 可构建。
- Computer Use 可读取本机 App。

## 5. 页面 / 接口路径

| 接口名称 | 方法 | 接口路径 | 用途 |
|---|---|---|---|
| startSession | MethodChannel | `app.stayawake/status_bar` | 开启 IOKit assertion |
| stopSession | MethodChannel | `app.stayawake/status_bar` | 释放 IOKit assertion |
| getStatus | MethodChannel | `app.stayawake/status_bar` | 查询状态 |
| getPowerStatus | MethodChannel | `app.stayawake/status_bar` | 查询电源来源、插电状态、电量 |

## 6. 操作步骤

1. 执行 `flutter analyze`。
2. 执行 `flutter test`。
3. 执行 `flutter build macos`。
4. 启动 release app。
5. 使用 Computer Use 点击 `Start 1 hour`。
6. 执行 `pmset -g assertions`。
7. 使用 Computer Use 点击 `Stop keeping awake`。
8. 再次执行 `pmset -g assertions`。
9. 点击左侧 `Sessions`，验证快捷启动按钮和 history 区域。
10. 点击左侧 `Rules`，验证电源状态、插电规则、低电量规则、当前前台 App trigger。
11. 点击左侧 `Settings`，修改低电量阈值和默认开关，重启后确认本地 JSON 可恢复。
12. 点击菜单栏 `STAY`，验证菜单出现 `开启新会话:`、`无限期`、`分钟`、`小时`、`当下载文件时...`、`快速设置`。
13. 悬停 `自定义时间 / 直到`，验证右侧出现 `持续 / 至` 二级面板。
14. 在 `持续` 模式修改小时和分钟，点击 `继续` 后 session 按换算秒数启动。
15. 在 `至` 模式选择目标时间或拖动表盘，点击 `继续` 后 session 到目标时间结束。

## 7. 预期结果

- 静态检查、单测、构建均通过。
- 点击 Start 后 UI 进入 ACTIVE。
- `pmset` 出现 StayAwake 的 `NoDisplaySleepAssertion`。
- 点击 Stop 后 UI 回到 IDLE，`pmset` 中 StayAwake assertion 消失。
- 菜单栏入口在 release app 中可见，打开菜单截图保存到 `06-UI测试/stayawake-statusbar-menu-open-260628.png`。
- `自定义时间 / 直到` 面板截图保存到 `06-UI测试/stayawake-custom-until-menu-attempt-260628.png`。

## 8. 异常场景

- MethodChannel 不可用时显示 bridge unavailable。
- IOKit 创建失败时回滚 UI active 状态。
- session 到期后自动释放。
- getPowerStatus 不可用时显示 `Power status unavailable`，不阻塞主流程。
- 本地 state JSON 读取失败时回退默认设置，不阻塞主窗口。
- 重复点击 Start/Stop 时按钮进入禁用态，避免重复请求。

## 9. 回归范围

- 主窗口布局。
- Start/Stop 行为。
- Status Bar native bridge。
- Status Bar item 创建时机和菜单可见性。
- Widget test 默认窗口宽度无溢出。
- 左侧四页导航和页面内容。
- 本地 Application Support state 文件。
- macOS release build 中 Swift `getPowerStatus` 编译。
