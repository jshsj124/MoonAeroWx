# MoonAeroWx 正式验收检查清单

这份清单用于正式验收前的自检，重点覆盖提交材料、工程质量、可解释性和可运行性。

## 1. 提交材料

- [ ] 仓库地址已填写。
- [ ] 项目名称、项目标识、项目描述已填写。
- [ ] 申报书已准备为 Markdown 或 PDF。
- [ ] 如需 GitLink，再补 GitLink 链接。
- [ ] README 中能快速找到项目简介、文档和使用方式。

## 2. 工程状态

- [ ] `moon fmt` 通过。
- [ ] `moon check --warn-list +unnecessary_annotation` 通过。
- [ ] `moon test` 通过。
- [ ] `moon info` 无意外公共 API 变更。
- [ ] 仓库没有明显的构建产物、缓存或临时文件被提交。
- [ ] Git 提交作者与项目作者一致。

## 3. 功能状态

- [ ] METAR / SPECI 解析可运行。
- [ ] TAF 解析可运行。
- [ ] RVR 解析可运行。
- [ ] 批量统计可运行。
- [ ] JSON / Markdown / CSV 输出可运行。
- [ ] CLI 示例能正常运行。
- [ ] 开发历程文档已说明设计取舍。

## 4. 发布准备

- [ ] `moon.mod` 已配置正确的模块名与仓库信息。
- [ ] GitHub Actions 已覆盖 fmt / check / test / info。
- [ ] 准备好 mooncakes.io 发布步骤。
- [ ] README 中的示例和文档链接有效。
- [ ] 如果后续要打标签，版本号与仓库状态一致。

## 5. 适合继续增强的方向

- METAR / TAF 复杂边界语法。
- RMK、跑道状态、风切变、海面状态。
- 更完整的 TAF 月份跨界语义。
- Wasm 演示页面。
- 更完整的 benchmark 和 CI 覆盖。
