---
name: review
description: 对照需求、影响清单和能力登记册做评审与只读验收。
---

# 评审验收

加载 `code-review`。先写 `review.md`，再派只读的 `verifier`。

把验收结论写入 `.team/engagements/<id>/verification.md`，结论行只能是 `结论: 通过` 或 `结论: 不通过`。

不通过时列出漏改的路径或未登记的复制，打回 `implementer` 或 `test-engineer`，不要改需求。通过后更新 `.team/capabilities.md`：新规则或改变的规则要登记家和测试；没有变化要写明原因。
