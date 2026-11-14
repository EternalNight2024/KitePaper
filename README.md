# 纸鸢 · KitePaper

> 英文名：**KitePaper**　｜　中文名：**纸鸢**

一个基于 Flutter 的跨平台应用项目骨架，覆盖 Android、iOS、Web、Linux、macOS 与 Windows 六个平台。

## 环境要求

| 项目 | 版本 / 路径 |
| --- | --- |
| Flutter | 3.50.0（stable） |
| Dart | 3.14.0 |
| 本机 SDK 安装路径 | `/opt/flutter`（SDK 不在本仓库内） |

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

## 目录结构

```text
.
├── lib/
│   ├── main.dart                       # 入口，仅调用 runApp
│   ├── app.dart                        # KitePaperApp：标题、主题、首页
│   ├── theme/app_theme.dart            # 明 / 暗主题
│   └── features/home/home_page.dart    # 首页
├── test/widget_test.dart               # 组件冒烟测试
├── android/ ios/ web/ linux/ macos/ windows/   # 各平台原生工程
├── pubspec.yaml                        # 包信息、依赖与版本
├── analysis_options.yaml               # 静态分析与 lint 规则
├── .metadata                           # Flutter 项目元数据
└── README.md
```

分层约定：

- `lib/main.dart` 只负责启动，不写业务逻辑；
- `lib/app.dart` 集中应用级配置（主题、首页，后续可扩展路由）；
- `lib/theme/` 存放主题与样式；
- `lib/features/<功能>/` 按功能模块组织页面与组件。

## 快速开始

```bash
flutter pub get
flutter analyze
flutter test
flutter run                 # 选择设备；Web 可用 flutter run -d chrome
flutter build web           # 也可构建 apk / ios / linux / macos / windows
```

当前状态：`flutter analyze` 无问题，`flutter test` 的 1 个冒烟测试通过。

## Git 远程与推送

本仓库配置了两个远程，默认一次推送会同时写入两者：

| 远程 | 地址 | 说明 |
| --- | --- | --- |
| `origin` | `https://cnb.cool/infinity-quadrant/KitePaper.git` | 主仓库，fetch 与 push |
| `github` | `https://github.com/EternalNight2024/KitePaper.git` | 镜像仓库，push |

实现方式是给 `origin` 配置两条 `pushurl`，并指定 `remote.pushDefault = origin`：

```bash
git remote -v
git config --get-all remote.origin.pushurl

git push                       # 同时推送到 CNB 与 GitHub
git push github main           # 仅推送到 GitHub
```

注意：两个远程需要各自的推送凭据；Git 按顺序推送，若第二个失败会整体报错，但第一个可能已更新，重试前建议先确认两侧状态。
