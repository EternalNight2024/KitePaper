# 纸鸢 · KitePaper

> 英文名：**KitePaper**　｜　中文名：**纸鸢**

面向教师组卷与学生刷题的**纯离线 Flutter 客户端**，采用 iOS 26/27 液态玻璃风格。服务端暂未接入，全部数据保存在本机，分享通过 QTI 文件完成。覆盖 Android、iOS、Web、Linux、macOS 与 Windows。

## 当前离线功能

| 角色 | 功能 |
| --- | --- |
| 教师 | 本地题库（内置示例、新增五种题型、删除）、从 QTI 导入题目、手动勾选组卷、把试卷导出为 `.qti` 文件分享 |
| 学生 | 导入他人分享的 QTI 试卷、下载试卷文件、逐题在线刷题、客观题即时判分、交卷评分、成绩记录与错题本 |

简答题标记为「待批阅」，不计入自动得分；待服务端或教师批阅接入后补齐。

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

核心依赖：`shared_preferences`、`xml`、`file_picker`、`path_provider`、`web`。

当前玻璃质感由 `lib/core/ui.dart` 自行实现（`RoundedSuperellipseBorder` 超椭圆 + `BackdropFilter` 模糊 + 高光描边/投影），**未依赖 `liquid_glass_widgets` 包**；`.codebuddy/skills/liquid-glass-widgets/` 与 `skills/apple-design/` 仅作为设计参考，编写 UI 时遵循：

- 玻璃只用于导航、卡片与悬浮控件，不在玻璃容器内再嵌套 `GlassButton` / `GlassIconButton`
- 尊重 `reduceMotion` 与 `highContrast`（高对比度时退化为实色）
- 响应式：窄屏用底部标签栏，宽屏（≥700）用侧边栏

## 目录结构

```text
.
├── lib/
│   ├── main.dart                        # 初始化着色器、加载本地仓库、wrap 应用
│   ├── app.dart                         # MaterialApp 与明暗主题
│   ├── theme/app_theme.dart             # 主题
│   ├── core/
│   │   ├── models.dart                  # Question / Paper / ExamResult 与判分
│   │   ├── qti.dart                     # KitePaper QTI 1.2 Profile 导入导出
│   │   ├── store.dart                   # ChangeNotifier + SharedPreferences 本地仓库
│   │   ├── ui.dart                      # 渐变光斑背景与共享小组件
│   │   ├── file_transfer.dart           # 按平台条件导出
│   │   ├── file_transfer_native.dart    # 桌面 / 移动端文件读写
│   │   └── file_transfer_web.dart       # Web 文件选择与浏览器下载
│   └── features/
│       ├── shell.dart                   # GlassScaffold + 四个标签页
│       ├── bank_page.dart               # 题库
│       ├── question_editor_page.dart    # 新增题目
│       ├── builder_page.dart            # 手动组卷
│       ├── papers_page.dart             # 试卷：导入、下载、练习、删除
│       ├── exam_page.dart               # 刷题与交卷评分
│       └── results_page.dart            # 成绩与错题本
├── test/widget_test.dart                # QTI 往返与判分逻辑测试
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
- CI：`.github/workflows/build-release.yml` 在 push 到 `main` 时构建 Windows + Android，并创建 GitHub Release 上传产物（Windows zip、Android APK）。workflow_dispatch 可指定 tag 与 release notes。
- 凭据：GitHub token 仅放本地 `.github_token`（已加入 `.gitignore`，**不得提交**）。`gh` 用 `gh auth login --with-token < .github_token` 配置；不要把 token 写进 remote URL 或仓库文件。

注意：推送到 CNB 与发布到 GitHub 是两步操作；任一失败都不会自动回滚另一侧，重试前先确认状态。
