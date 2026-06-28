创建日期：260628

# StayAwake 项目索引

## 本次产物

1. 需求文档：`01-需求/需求文档-StayAwake-macOS保持唤醒.md`
2. 交互设计：`02-交互设计/交互设计建议-StayAwake-macOS保持唤醒.md`
3. UI 设计：`03-UI设计/设计说明-StayAwake-macOS保持唤醒.md`
4. 前端规划：`04-前端规划/FE-Whiteboard-StayAwake-macOS保持唤醒.md`
5. StatusBar 方案：`04-前端规划/桌面组件实现方案-260628.md`
6. 后端白板：`05-后端规划/BE-白板-本机唤醒服务.md`
7. UI QA：`06-UI测试/UI审核报告-260628.md`
8. 测试用例：`07-测试用例/测试用例-StayAwake-macOS保持唤醒.md`
9. 流程图：`08-流程图/架构流程-StayAwake-macOS保持唤醒.md`

## 当前状态

- Flutter macOS 工程已初始化。
- 主控制台 UI 已实现，左侧 `Status / Sessions / Rules / Settings` 已可真实切换。
- macOS 原生 Status Bar 已实现。
- IOKit `NoDisplaySleepAssertion` 已通过 `pmset -g assertions` 验证。
- Computer Use 已完成真实窗口读取和按钮点击自测。
- 本轮新增本地 settings/rules/history 持久化。
- 本轮新增 `getPowerStatus` 原生桥接和电源规则。
- 本轮 release app 真实截图：`06-UI测试/stayawake-after-260628.png`。
- 最新验证：`flutter analyze`、`flutter test`、`flutter build macos`。

## 待确认

- 是否需要 App Store 发行所需的 bundle id、图标、签名和沙盒策略。
- 指定 App 触发已支持选择当前前台 App 作为触发目标。
- 开机登录 native Login Item 暂未接入。
- 是否需要远程账号、云同步或团队策略后台。
