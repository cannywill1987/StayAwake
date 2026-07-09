创建日期：260709

# App Store 5.2.5 Mac 术语复核 - NoSleepy

## 复核结论

这条没有完全解决。

App Store Connect 顶部 App 菜单当前显示为 `NoSleepy - Wake Keeper`，说明全局 App 名大概率已经不是旧名。但 Apple 2026-07-09 07:39 的最新审核消息仍明确点名：

```text
NoSleepy - MacWaker
Terms for Mac in the app name in an inappropriate manner.
```

结合本地素材复核，当前风险不只可能来自 App 名字段，也可能来自已上传或准备上传的截图、描述、副标题、推广文本和旧审核附件。

## 现场 App Store Connect 状态

- App ID：`6786129358`
- Submission ID：`0e9dd12a-41fb-4963-96d9-0dabe3aabcda`
- 当前 App 菜单显示：`NoSleepy - Wake Keeper`
- 当前提交状态：`问题未解决`
- 被拒绝项目：`macOS App 1.0` / `1.0.0 (3)`
- 当前仍显示审核问题：
  - `2.1.0 Performance: App Completeness (macOS)`
  - `5.2.5 Legal: Intellectual Property - Apple Products (macOS)`

## 本地发现的高风险残留

### 1. App Store 描述文档仍有营销性 Mac 文案

文件：`docs/StayAwake/main/12-运营素材/AppStore描述-260701.md`

高风险示例：

- 中文副标题：`让 Mac 保持唤醒`
- 中文推广文本：`一键保持 Mac 唤醒`
- 英文副标题：`Keep your Mac awake`
- 英文推广文本：`Keep your Mac awake during...`
- 多语言描述和关键词中仍多次使用 `Mac`

如果这些字段仍在 ASC 当前版本页或本地化页面中，Apple 会继续认为 metadata 仍包含不合适的 Apple 产品术语。

### 2. App Store 截图仍把 Mac 当作标题/卖点

文件：

- `docs/StayAwake/main/12-运营素材/final/nosleepy-appstore-01-cn.png`
- `docs/StayAwake/main/12-运营素材/final/selected-generated-cn-appstore-2880x1800.png`

截图可见风险文字：

- `让你的 Mac 保持唤醒，专注高效`
- `让 Mac 始终在线`
- 右下角黑色下载牌：`Mac App Store`

即使 App 名已改，截图也属于 App Store metadata。Apple 的拒审文案写的是 `metadata includes`，所以截图文字同样可能触发 5.2.5。

### 3. 截图生成脚本仍会生成 Mac 风险词

文件：`scripts/build_app_store_screenshots.py`

高风险示例：

- `Mac 保持唤醒工具`
- `让 Mac 保持唤醒`
- `StayAwake for macOS`

如果后续继续用该脚本生成并上传素材，风险会重新出现。

### 4. 旧审核附件和文件名仍含 MacWaker

文件：

- `docs/StayAwake/main/12-运营素材/review/NoSleepy-MacWaker-AppReview-2.1-260702.mov`
- `docs/StayAwake/main/12-运营素材/review/NoSleepy-MacWaker-AppReview-2.1-clean-260702.mov`
- `docs/StayAwake/main/12-运营素材/review/AppReview-Guideline-2.1-Reply-260702.md`

如果这些附件或引用曾经作为 App Review 信息发送，Apple 可能仍能在审核上下文里看到旧名。它们不一定是当前版本页元数据，但会增加审核员判断混淆的概率。

## 判断

- `NoSleepy - Wake Keeper` 这个主 App 名看起来已经处理过。
- 但当前不能说 5.2.5 已解决，因为 ASC 最新拒审仍点名 `NoSleepy - MacWaker`，且本地可提交素材中仍存在大量营销性 `Mac` 文案。
- 最大嫌疑不是顶部 App 菜单名，而是：截图、各语言本地化字段、旧附件或版本元数据里还有 `MacWaker` / `Mac`。

## 建议修复范围

### 必须检查 ASC 当前页面

逐个语言检查：

- App Name
- Subtitle
- Promotional Text
- Description
- Keywords
- What’s New
- Screenshots
- App Preview / review attachment

### 建议替换文案

| 风险文案 | 建议替换 |
|---|---|
| Keep your Mac awake | Keep your computer awake |
| 让 Mac 保持唤醒 | 让电脑保持唤醒 |
| helps your Mac stay awake | helps your computer stay awake |
| Mac 用户 | desktop users |
| Mac App Store 下载牌 | 删除下载牌或改为中性 App Store 截图说明 |
| MacWaker | 全部删除，不能作为名称或文件展示文字 |

必要的平台说明可以保留 `macOS`，但不要放在 App 名、副标题或大标题营销语里。

## 回复 Apple 前的完成口径

只有同时满足以下条件，才建议回复 Apple 说已修复 5.2.5：

- ASC 所有语言 App Name 都是 `NoSleepy - Wake Keeper` 或更中性的名字。
- 所有可见截图不再出现 `MacWaker`、`Mac App Store` 下载牌、`Keep your Mac awake`、`让 Mac 保持唤醒` 这类营销性表达。
- 描述、副标题、关键词、推广文本不再把 `Mac` 作为卖点。
- 如需说明平台，只使用必要的 `macOS` 平台兼容描述。

## 当前状态

本轮只做复核和证据整理，未修改 ASC，未保存线上字段，未重新提交审核。
