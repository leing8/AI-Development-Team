---
name: retro
description: 为当前需求写短复盘，记录哪条规则差点被写成第二份。
---

# 复盘

读取当次档案和 `.team/capabilities.md`。写入 `.team/engagements/<id>/retro.md`，只回答：

- 哪条规则差点被写成第二份，或这次没有这种风险。
- 影响清单漏过什么，下次搜索要加上什么。
- 哪条判断可以下次直接复用。

写完后把 `status.md` 设为 `状态: 已关闭`。不要借复盘再改功能。
