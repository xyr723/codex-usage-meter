# Codex Usage Meter

Codex Usage Meter 是一个原生 macOS 菜单栏应用，用于实时查看 Codex 用量状态。

第一版目标：

- 在 macOS 顶部栏直接展示 Codex、5 小时额度、7 天额度和同步状态。
- 通过 Codex OAuth 凭据调用精确额度接口，不使用估算值。
- 扫描本机 Codex JSONL 会话日志统计今日 token。
- 提供按视觉原型实现的下拉详情面板。
- 提供 Apple Watch SwiftUI glance / complication 预留视图。
- 通过 `UsageProvider` 预留 Claude Code 等其他 AI 工具 Provider 扩展接口。

## 数据来源

精确额度来自 Codex 使用的 ChatGPT 后端接口：

```text
GET https://chatgpt.com/backend-api/wham/usage
```

应用会读取本机已有的 Codex 登录文件：

```text
~/.codex/auth.json
```

如果设置了 `CODEX_HOME`，则读取：

```text
$CODEX_HOME/auth.json
```

今日 token 来自本机 Codex 会话日志：

```text
~/.codex/sessions/YYYY/MM/DD/*.jsonl
~/.codex/archived_sessions/*.jsonl
```

## 隐私

- 不硬编码、不上传、不展示用户 token。
- 不上传本地 Codex 日志。
- 只保存派生后的用量快照和非敏感设置。
- 不扫描无关目录。

## 开发

```bash
swift test
swift build
swift run CodexUsageMeter
```

运行后应用会以 macOS accessory app 形式进入顶部栏。顶部栏按钮会直接显示：

```text
Codex  5h 62%  7d 41%  Sync 2m
```

如果还没有成功拿到精确接口数据，会显示 `--%`，不会用估算值冒充额度。

如果当前网络不能直连 `https://chatgpt.com/backend-api/wham/usage`，可以用完整精确接口地址覆盖：

```bash
CODEX_USAGE_URL="https://your-proxy.example/backend-api/wham/usage" swift run CodexUsageMeter
```

这个地址必须返回和 Codex `wham/usage` 一致的 JSON；应用不会从非精确来源估算 5 小时或 7 天额度。

## 模块

- `CodexUsageMeterCore`: 精确额度、token 扫描、模型、格式化和 Provider 协议。
- `CodexUsageMeterApp`: macOS 顶部栏和下拉详情面板。
- `CodexUsageMeterWatch`: Apple Watch glance 和圆形/矩形复杂功能预留视图。

## UI 参考

高保真视觉参考见：`docs/ui-reference.md`。
