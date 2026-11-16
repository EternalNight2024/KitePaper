# 纸鸢 · KitePaper

> 英文名：**KitePaper**　｜　中文名：**纸鸢**

面向教师组卷与学生刷题的**纯离线 Flutter 客户端**，采用 iOS 26/27 液态玻璃风格。服务端暂未接入，全部数据保存在本机，分享通过 QTI 文件完成。覆盖 Android、iOS、Web、Linux、macOS 与 Windows。

## 当前离线功能

顶部「教师 / 学生」分段控件可随时切换模式，两种身份各有独立标签页；内置教程数据覆盖全部五种题型，可在「指引」页一键恢复。

| 角色 | 标签页 | 功能 |
| --- | --- | --- |
| 教师 | 题库 / 组卷 / 试卷 / 指引 | 本地题库（内置教程、新增五种题型、删除）、从 QTI 导入题目、手动勾选组卷、导出 `.qti` 分享、删除试卷；新增题目采用「点选优先」表单：题型/答案/分值/知识点点击选择，选项用按钮逐条增删 |
| 学生 | 练习 / 成绩 / 指引 | 导入他人分享的 QTI 试卷、下载试卷文件、逐题刷题、客观题即时判分、交卷评分、成绩记录与错题本 |

简答题标记为「待批阅」，不计入自动得分；待服务端或教师批阅接入后补齐。云端同步、在线批阅、班级分发与智能组卷在「指引」页以「预留」卡片占位。

## 环境要求

| 项目 | 版本 / 路径 |
| --- | --- |
| Flutter | 3.50.0（stable） |
| Dart | 3.14.0 |
| 本机 SDK 安装路径 | `/opt/flutter`（SDK 不在本仓库内） |
| 液态玻璃 | `liquid_glass_widgets` 1.17.3 |

Linux x86_64 下从零安装：

```bash
curl -fL -o /tmp/flutter.tar.xz \
  https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.50.0-stable.tar.xz
sudo tar -xJf /tmp/flutter.tar.xz -C /opt
echo 'export PATH="/opt/flutter/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc

flutter --version
flutter doctor
```

若官方源访问较慢，可按需设置 `FLUTTER_STORAGE_BASE_URL` 与 `PUB_HOSTED_URL` 指向镜像站。

## 依赖与 UI 实现

核心依赖：`liquid_glass_widgets`、`shared_preferences`、`xml`、`file_picker`、`path_provider`、`web`。

UI 已全面改用 **`liquid_glass_widgets` 1.17.x**（`GlassScaffold`、`GlassAppBar`、`GlassTabBar`、`GlassLargeTitle`、`GlassSegmentedControl`、`GlassPullDownButton`、`GlassContainer.card`、`GlassGroupedSection`、`GlassListTile`、`GlassTextField/TextArea`、`GlassButton/IconButton`、`GlassToast`、`GlassDialog`、`GlassPageRoute`）。`main.dart` 先 `LiquidGlassWidgets.initialize()` 再用 `LiquidGlassWidgets.wrap()` 包裹应用，并接入 `GlassNavigationShell` 与 ios27 主题。

关键实现约定（均已踩坑验证）：

- **Material 桥接**：该库是 Material-free 的，`MaterialApp.builder` 必须包一层 `Material(type: transparency)`，并提供与 Material 主题同步的 `CupertinoTheme`，否则输入框 / 列表文字 / 对话框在暗色模式下不跟随主题
- **玻璃只用于导航与浮层**：滚动列表内的卡片与输入使用 `GlassSurfaceStyle.solid`，不在玻璃容器内嵌套折射玻璃按钮
- **背景必须有层次**：`GlassScaffold` 传入 `background` 后会自动开启 `enableBackgroundSampling`，玻璃的颜色吸收依赖背后的纹理，纯色平涂会让玻璃显得灰平；`lib/core/app_background.dart` 用灰白渐变 + 柔光光斑提供层次，同时让白色实色卡片能从背景中浮出
- **body 不含导航栏留白**：`GlassScaffold` 的 body 铺满全屏并由边缘渐隐处理，页面需自行补足「状态栏 + 导航栏」高度（`layout.dart` 的 `appBarSafeTop`）
- **无界宽度约束**：`RenderFlex` 给非 flex 子项无界主轴宽度，`GlassSegmentedControl`（内部用 `Expanded`）必须显式约束宽度；导航栏 `actions` 槽位同样无界，故窄屏的身份切换改用 `GlassPullDownButton`
- **响应式**：窄屏用 `GlassTabBar.bottom` + `GlassLargeTitle` 大标题折叠，宽屏（≥700）用玻璃侧边栏 + 页内头部
- 由库自动尊重减弱动效 / 减弱透明等系统无障碍设置
- **原生鼠标动效（无自绘动画）**：不自行包 `AnimatedScale`，而是用库原生的 `GlassMotionScope` —— `lib/core/glass_motion.dart` 把桌面鼠标横向位置映射为光源角度流（量化降频），由 shader 直接重算全站玻璃控件的高光方向，鼠标移动时高光在玻璃上流动；按压弹性由 `GlassThemeData.ios27(interaction: GlassInteractionSettings(...))` 全局配置；侧边栏导航用 `GlassButton.custom` 获得库自带 hover + 果冻按压。窄屏与「减弱动态效果」时自动关闭
- **按钮高度**：`GlassButton.custom` 的 `height` 只约束外层 `SizedBox`，内部 `Align` 会放松子项约束，实心胶囊需由内容 `SizedBox(height:)` 撑满，否则会塌缩得比玻璃按钮矮
- **克制的色彩**：整体仍是灰白玻璃骨架，教师用低饱和靛蓝、学生用青绿作为身份色（导航/分段/主按钮），题型用五色小点区分（蓝/紫/绿/琥珀/玫红），背景壁纸带极淡蓝青光斑供玻璃折射

## 目录结构

```text
.
├── lib/
│   ├── main.dart                        # 初始化着色器、加载本地仓库、wrap 应用
│   ├── app.dart                         # MaterialApp 与明暗主题
│   ├── theme/app_theme.dart             # 主题
│   ├── core/
│   │   ├── models.dart                  # AppMode / Question / Paper / ExamResult 与判分
│   │   ├── qti.dart                     # KitePaper QTI 1.2 Profile 导入导出
│   │   ├── store.dart                   # ChangeNotifier + SharedPreferences 本地仓库
│   │   └── layout.dart                  # 响应式布局辅助（玻璃组件统一来自官方库）
│   │   ├── file_transfer.dart           # 按平台条件导出
│   │   ├── file_transfer_native.dart    # 桌面 / 移动端文件读写
│   │   └── file_transfer_web.dart       # Web 文件选择与浏览器下载
│   └── features/
│       ├── shell.dart                   # 响应式外壳 + 教师/学生模式切换
│       ├── bank_page.dart               # 题库
│       ├── question_editor_page.dart    # 新增题目
│       ├── builder_page.dart            # 手动组卷
│       ├── papers_page.dart             # 试卷：按模式区分导入/下载/练习/导出
│       ├── exam_page.dart               # 刷题与交卷评分
│       ├── results_page.dart            # 成绩与错题本
│       ├── guide_page.dart              # 教程数据与在线功能预留
│       └── shared_widgets.dart          # 基于官方库的共用按钮与信息卡
├── test/widget_test.dart                # QTI 往返与判分逻辑测试
├── tool/screenshot_test.dart            # 视觉回归截图（注入中文字体后渲染 PNG）
├── .codebuddy/skills/liquid-glass-widgets/  # 官方液态玻璃 skill
├── webtest.sh                           # 编译 Web 并启动静态服务器
└── android/ ios/ web/ linux/ macos/ windows/
```

数据层与 UI 层解耦：未来接服务端时只需替换 `core/store.dart` 的数据来源，页面无需改动。

## QTI Profile

采用 QTI 1.2 单文件子集（`questestinterop` → `assessment` → `section` → `item`），便于离线分享：

- 支持单选、多选、判断、填空、简答五种题型
- 标准结构：`presentation` / `response_lid` / `response_str` / `resprocessing` / `varequal` / `itemfeedback`
- 扩展字段：`assessment` 上的 `kp_profile`、`kp_duration`、`kp_description`，以及 `itemmetadata/qtimetadata` 中的 `kp_type`、`kp_score`、`kp_knowledge`、`kp_analysis`、`kp_answers`
- 第三方工具会忽略 `kp_*` 扩展；本客户端用它们保证导入导出无损

## 快速开始

```bash
flutter pub get
flutter analyze
flutter test
flutter run                 # 选择设备；Web 可用 flutter run -d chrome
flutter build web           # 也可构建 apk / ios / linux / macos / windows
```

构建脚本 `scripts/build-windows.sh` / `scripts/build-android.sh` 会先执行 analyze 与 test，**失败即中止**（不再用 `|| true` 吞掉错误）。产物：

- Windows：`build/windows/kitepaper.zip`
- Android：`build/app/outputs/flutter-apk/app-release.apk` 与 `build/app/outputs/bundle/release/app-release.aab`

### Web 本地测试

仓库根目录的 `webtest.sh` 会编译 release 版 Web 产物，并用 `python3 -m http.server` 启动静态服务器：

```bash
./webtest.sh            # 默认 8080 端口
./webtest.sh 8099       # 指定端口
```

打开 `http://localhost:8080/` 查看，`Ctrl+C` 停止服务器；产物位于 `build/web/`（已被 Git 忽略）。

## Git 远程、构建与发布

| 远程 | 地址 | 说明 |
| --- | --- | --- |
| `origin` | `https://cnb.cool/infinity-quadrant/KitePaper.git` | 主仓库，fetch 与 push |
| GitHub 镜像 | `https://github.com/EternalNight2024/KitePaper.git` | Release 发布目标 |

- 本地构建：`./scripts/build-windows.sh`、`./scripts/build-android.sh`。两者都会先跑 analyze/test，失败即中止。
- CI：`.github/workflows/build-release.yml` 在 push 到 `main` 时构建 Windows + Android，并创建 GitHub Release 上传产物（Windows zip、Android APK 与 AAB）。workflow_dispatch 可指定 tag 与 release notes。
- 凭据：GitHub token 仅放本地 `.github_token`（已加入 `.gitignore`，**不得提交**）。`gh` 用 `gh auth login --with-token < .github_token` 配置；不要把 token 写进 remote URL 或仓库文件。

注意：推送到 CNB 与发布到 GitHub 是两步操作；任一失败都不会自动回滚另一侧，重试前先确认状态。
