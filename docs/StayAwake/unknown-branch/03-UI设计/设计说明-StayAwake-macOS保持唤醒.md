创建日期：260628

# UI 设计说明：StayAwake macOS 保持唤醒

## 设计资产

- 设计图路径：`docs/StayAwake/unknown-branch/03-UI设计/设计图-StayAwake-macOS保持唤醒.png`
- 生成状态：已生成
- 真实页面截图：`docs/StayAwake/unknown-branch/06-UI测试/screenshots/status-main-after.png`

## 设计来源区分

- 用户参考图：Amphetamine 相关截图，仅作为功能和信息结构参考。
- AI 参考图：本目录中的 `设计图-StayAwake-macOS保持唤醒.png`，用于视觉方向。
- 真实实现截图：UI QA 目录中的 screenshot，作为实现完成口径。

## 交互建议落实矩阵

| UX 建议 | UI 落地 |
|---|---|
| P0 系统状态必须可信 | Header 显示 native assertion 状态，activity log 记录 bridge 状态 |
| P0 Stop 必须释放 assertion | Active 时主按钮变红色 Stop |
| P1 剩余时间可见 | 主卡片大号倒计时 |
| P1 菜单栏入口可发现 | 主卡片次按钮显示 Menu bar controls enabled |
| P2 自动规则诚实表达 | 未实现规则用 Planned 标识 |

## 前端落地验收清单

- [x] 主窗口可读，无 800px 默认测试宽度溢出。
- [x] Active/Idle 状态颜色和文案明确。
- [x] Start/Stop 主操作清晰。
- [x] 快捷时长按钮可见。
- [x] 系统层验证不依赖 AI 设计图。
