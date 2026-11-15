# Flutter Agent Plugins — 技能库

来源：https://github.com/flutter/agent-plugins （BSD-3-Clause，Flutter 团队维护）

把 **Skills（技能）**、**MCP 服务器配置**、**Rules（规则）** 打包给 AI 编码代理，提供 Flutter 领域知识与可复用工作流。
MCP 提供**工具**；Skill 教会代理**如何**使用工具。

## 安装方式

仓库通过 `.claude-plugin/`、`.codex-plugin/`、`.cursor-plugin/` 提供各代理插件清单，具体安装见官方 *Get started developing with AI* 文档。

## 11 个技能

| 技能 | 用途 |
| --- | --- |
| `flutter-add-integration-test` | 配置 Flutter Driver，把 MCP 操作转成永久集成测试 |
| `flutter-add-widget-preview` | 用 `previews.dart` 体系添加可交互 Widget 预览 |
| `flutter-add-widget-test` | 用 `WidgetTester` 验证渲染与交互 |
| `flutter-apply-architecture-best-practices` | 按 UI / Logic / Data 分层组织应用 |
| `flutter-build-responsive-layout` | `LayoutBuilder` / `MediaQuery` / `Expanded` 做自适应布局 |
| `flutter-fix-layout-issues` | 修复溢出、无界约束等布局错误 |
| `flutter-implement-json-serialization` | 手写 `fromJson` / `toJson` |
| `flutter-setup-declarative-routing` | `go_router` + `MaterialApp.router` |
| `flutter-setup-localization` | `flutter_localizations` + `intl` + `l10n.yaml` |
| `flutter-use-http-package` | `http` 包发起 REST 请求 |

---

## flutter-build-responsive-layout（实现自适应布局）

**空间测量**
- 用 `MediaQuery.sizeOf(context)` 获取应用窗口尺寸。
- 用 `LayoutBuilder` 的 `constraints.maxWidth` 做布局决策。
- 不要在组件树顶部用 `MediaQuery.orientationOf` / `OrientationBuilder` 切换布局。
- 不要按硬件类型（手机/平板）分支——必须严格基于**可用窗口空间**。

**尺寸与约束**（约束向下传递，尺寸向上返回，父组件决定位置）
- `Expanded` 强制填满剩余空间；`Flexible` 允许在上限内自行定尺寸。
- 大屏防止过度拉伸：`ConstrainedBox(maxWidth: …)` 包 `ListView` / `GridView`，外层再 `Center`。
- 数量未知的列表一律用 `ListView.builder` / `GridView.builder`。

**设备与方向**
- 不要锁定屏幕方向。
- 支持鼠标、触控板、键盘快捷键；保证触摸目标尺寸与键盘可达性。

**工作流**
1. 包 `LayoutBuilder`
2. 取 `constraints.maxWidth`
3. 定义断点（示例 `largeScreenMinWidth = 600`）
4. 大屏返回 `Row`（侧边栏 + 内容）；小屏返回 `Column`
5. 改变窗口尺寸验证过渡与溢出

**大屏优化**：表单/文本块 `ConstrainedBox(maxWidth: 800)` + `Center`；列表用 `SliverGridDelegateWithMaxCrossAxisExtent`。

```dart
const double largeScreenMinWidth = 600.0;

class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > largeScreenMinWidth) {
          return Row(
            children: const [
              SizedBox(width: 250, child: Placeholder(color: Colors.blue)),
              VerticalDivider(width: 1),
              Expanded(child: Placeholder(color: Colors.green)),
            ],
          );
        }
        return const Placeholder(color: Colors.green);
      },
    );
  }
}
```

```dart
Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 800.0),
    child: ListView.builder(itemCount: 50, itemBuilder: (context, index) => ListTile(title: Text('Item $index'))),
  ),
)
```

---

## flutter-fix-layout-issues（修复布局错误）

**诊断特征**

| 错误 | 成因 |
| --- | --- |
| `Vertical viewport was given unbounded height` | 可滚动组件放进无约束垂直父级（`Column`） |
| `An InputDecorator...cannot have an unbounded width` | `TextField` 放进无约束水平父级（`Row`） |
| `RenderFlex overflowed` | `Row`/`Column` 子组件超出分配约束 |
| `Incorrect use of ParentData widget` | `Expanded`/`Positioned` 不是所需父级的直接子级 |
| `RenderBox was not laid out` | 级联错误，忽略它向上找主因 |

**修法**
- 无界高度 → `Expanded` 或 `SizedBox`
- 无界宽度 → `Expanded` / `Flexible`
- 溢出 → 给子组件 `Expanded`（强制适配）或 `Flexible`
- ParentData 误用 → 调整层级

**流程**：调试运行 → 抓主错误 → 套用修法 → 热重载 → 目视确认溢出条纹消失 → 循环。

```dart
// 修复前：Vertical viewport was given unbounded height
Column(children: [const Text('Header'), ListView(children: const [])])

// 修复后
Column(children: [const Text('Header'), Expanded(child: ListView(children: const []))])
```

```dart
// 修复前：RenderFlex overflowed
Row(children: const [Icon(Icons.info), Text('很长的文本…')])

// 修复后
Row(children: const [Icon(Icons.info), Expanded(child: Text('很长的文本…'))])
```
