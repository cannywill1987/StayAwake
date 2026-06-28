创建日期：260628

# BE 白板：本机唤醒服务

## 1. 背景与目标

StayAwake MVP 不需要远程服务。后端职责由本机 native service 承担：接受 Flutter 请求、创建或释放 macOS power assertion，并返回可验证状态。

## 2. Boundary

### 允许修改

- macOS Runner 原生代码。
- Flutter MethodChannel contract。
- 本地状态和测试文档。

### 禁止修改

- 不接入远程账号、数据库、支付或云同步。
- 不写入敏感 token 或用户资料。

## 3. Contract

| 接口名称 | 路径 | 方法 | 描述 | 是否新增 |
|---|---|---|---|---|
| startSession | `app.stayawake/status_bar` | MethodChannel | 开启防睡眠 session | 是 |
| stopSession | `app.stayawake/status_bar` | MethodChannel | 停止 session | 是 |
| getStatus | `app.stayawake/status_bar` | MethodChannel | 查询 native 状态 | 是 |

## 4. 异常处理

- IOKit 创建失败：Flutter 显示 `Failed to start native assertion` 并回到 inactive。
- Flutter bridge 不可用：UI 显示 `Native bridge unavailable`。
- session 到期：Flutter timer 和 native timer 都会触发停止，保证释放。

## 5. 自测

- `flutter build macos`
- Computer Use 点击 Start/Stop。
- `pmset -g assertions` 验证 assertion 出现和释放。
