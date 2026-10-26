# 项目级 DSH 配置

## skills/

本目录下的 Dart / Flutter 技能供本项目的 DSH 会话加载（DSH 的本地技能发现规则：项目根目录下的
`.dsh/skills/<name>/SKILL.md`，项目根 = 最近的含 `.git` 的祖先目录）。

- 每个技能是一个目录，内含 `SKILL.md`（YAML frontmatter 必须有 `name` 与 `description`）。
- 技能清单：

| 分类 | 技能 |
|---|---|
| Dart | `dart-add-unit-test`、`dart-build-cli-app`、`dart-collect-coverage`、`dart-fix-runtime-errors`、`dart-generate-test-mocks`、`dart-migrate-to-checks-package`、`dart-resolve-package-conflicts`、`dart-run-static-analysis`、`dart-setup-ffi-assets`、`dart-use-doc-examples`、`dart-use-ffigen`、`dart-use-path-package`、`dart-use-pattern-matching`、`dart-use-primary-constructors`、`dart-write-documentation` |
| Flutter | `flutter-add-integration-test`、`flutter-add-widget-preview`、`flutter-add-widget-test`、`flutter-apply-architecture-best-practices`、`flutter-build-responsive-layout`、`flutter-fix-layout-issues`、`flutter-implement-json-serialization`、`flutter-setup-declarative-routing`、`flutter-setup-localization`、`flutter-use-http-package` |

共 25 个技能，来源为 `%USERPROFILE%\.dsh\skills`（用户级技能根）的副本。

## 维护

- **新增/更新技能**：把技能目录拷进 `skills/` 即可，DSH 会监视该目录，无需重启。
  从用户级根目录整体同步：

  ```powershell
  Copy-Item "$env:USERPROFILE\.dsh\skills\dart-*" .dsh\skills -Recurse -Force
  Copy-Item "$env:USERPROFILE\.dsh\skills\flutter-*" .dsh\skills -Recurse -Force
  ```

- **不要**在 `skills/` 根下放 `README.md` 之类的散装 `.md` 文件：根目录下的顶层 `<name>.md`
  会被当作扁平技能去解析 frontmatter，缺少 frontmatter 会触发告警。文档放在本文件里。

- **是否提交到 git**：`.dsh/` 当前未被 `.gitignore` 忽略，会作为未跟踪文件出现。若希望技能随仓库
  共享给团队，直接提交；若只想本机使用，把它加入 `.gitignore`。
