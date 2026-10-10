# AI 研发团队

在 Cursor 里打开本仓库后，对话由一个接口人接待。接口人识别意图并指定本次主人，再按大厂式门禁实现：需求没写清不动手，一条业务规则只有一个实现，写代码的人不能给自己签完成。

用法、编制和档案见 [AGENTS.md](AGENTS.md) 与 [.team/README.md](.team/README.md)。

常用命令：`/team`、`/clarify`、`/implement`、`/review`、`/retro`。

本仓库同时是名为 `ai-dev-team` 的 Cursor Plugin。规则、技能、Agent、命令和钩子都在 `.cursor/`，由 `.cursor-plugin/plugin.json` 指向它们。不内置 MCP，也不在仓库里放密钥。需要 GitHub 或文档查询时，在 Cursor 里另行配置。
