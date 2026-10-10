---
name: implement
description: 在需求就绪且影响清单已写好之后，拆任务并实现，禁止平行复制已有规则。
---

# 实现

按顺序检查，缺任何一项就停下并说明缺什么：

1. `.team/engagements/<id>/prd.md` 有成功标准和非目标。错别字级改动除外。
2. 已读 `.team/capabilities.md`。
3. 可能碰到已登记规则或共享逻辑时，`impact.md` 已写完，且规则冲突已有用户裁决。

然后加载 `tech-lead`。先派只读的 `planner`，由你把任务写入 `tasks.md`。再派 `implementer`。行为有变化时派 `test-engineer`。涉及输入、权限、密钥或外部调用时派 `security-auditor`。

会改同一条规则的任务不要并行。不要在没有 `verification.md` 通过结论时告诉用户已完成。
