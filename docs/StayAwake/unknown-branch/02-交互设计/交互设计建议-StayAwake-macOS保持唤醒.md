创建日期：260628

# 交互设计建议：StayAwake macOS 保持唤醒

## 0. Meta

- 产品 / 功能：StayAwake macOS 保持唤醒
- 仓库 / 模块：`/Users/linzhibin/Desktop/code/StayAwake`
- 当前分支：`unknown-branch`
- 来源材料：用户提供 Amphetamine 参考截图、当前空仓库、已实现 Flutter/macOS 代码

## 1. 产品目标与用户任务

核心用户是需要临时阻止 Mac 睡眠的人。最重要的任务是一键开启和停止 awake session。辅助任务是选择持续时间、理解电池风险、确认系统层生效。

## 2. 用户路径

1. 打开 StayAwake。
2. 选择快捷时长或默认 1 小时。
3. UI 进入 ACTIVE，显示倒计时。
4. macOS Status Bar 同步状态。
5. 用户点击 Stop 或等待到期自动释放 assertion。

## 3. 核心问题分级

| 优先级 | 问题 | 方案 |
|---|---|---|
| P0 | UI 显示 active 但系统未阻止睡眠 | 必须用 IOKit assertion，并用 `pmset` 验证 |
| P0 | Stop 后 assertion 未释放 | Stop 触发 Flutter 与 native 双侧状态清理 |
| P1 | 用户不知道剩余时间 | 主卡片展示倒计时和 active/idle pill |
| P1 | 菜单栏入口不可发现 | 主窗口明确提示 menu bar controls enabled |
| P2 | 自动规则还未完整 | 先用 Planned 状态展示，不误导为已完成 |

## 4. 信息架构建议

- 左侧：Status、Sessions、Rules、Settings。
- 主区：当前 awake 状态、倒计时、Start/Stop。
- 操作区：快捷时长和系统行为开关。
- 辅助区：规则卡片和 activity log。

## 5. 给 UI 设计师的输入

- 主视觉必须突出 active/idle 状态和剩余时间。
- Start/Stop 是唯一主操作，其他 preset 是次级操作。
- 颜色使用绿色表示 active，琥珀色表示 idle/电池提醒，红色表示 stop。
- 组件需要覆盖默认、active、到期、错误、禁用状态。
- 不要把未实现的自动规则设计成已完成能力。

## 6. ImageGen Prompt 要点

macOS 原生质感、菜单栏工具、主窗口加状态栏 popover、紧凑但可读、绿色/琥珀色状态、明确 Start/Stop 与倒计时。
