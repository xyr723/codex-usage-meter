# AGENTS.md

总是使用中文回答。

## 项目约束

- 本项目采用 SwiftUI 原生实现，优先 Apple 官方组件和 Human Interface Guidelines。
- 不引入第三方 UI 框架，除非有明确收益并经过确认。
- UI 高保真参考：`docs/ui-reference.md`。
- 5 小时与 7 天额度必须来自精确数据源，不允许估算冒充精确值。
- 绝不硬编码密钥、令牌、密码。
- 绝不未经确认删除文件或执行破坏性操作。
- 绝不主动执行 git commit 或 push，除非明确要求。

## 验证命令

- `swift test`
- `swift build`
