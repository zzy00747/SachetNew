# AGENTS.md

本文件面向 AI 编码助手，汇总当前项目（Sachet）的关键信息、构建方式、代码组织与开发约定。若你首次接触本项目，请先阅读本文件。

> 注意：README 中的部分说明（特别是 `README_DEV.md` 中的 TreeView 文件树）已经过时。实际代码结构已经过重构，请以本文件和 `lib/` 下的实际源码为准。

---

## 1. 项目概述

**Sachet** 是一款面向**湘潭大学**学生的第三方校园助手应用，基于 [Flutter](https://flutter.dev) 开发，支持 Android、Windows、Linux 等桌面/移动平台。

本应用从 [wyvern1723/sachet](https://github.com/wyvern1723/sachet) Fork 而来，当前维护仓库为 [zzy00747/SachetNew](https://github.com/zzy00747/SachetNew)。

### 1.1 主要功能

- 📅 课程表：自动从正方教务系统导入，支持周/月/学期视图、.ics 导出、上课前本地通知提醒、课程配色自定义。
- 🏫 空闲教室：查询今日/明日或指定日期、自定义节次分段的空闲教室。
- 📝 考试信息：查询考试时间、考场安排与倒计时。
- 📊 成绩查询：查询各学期成绩、自动计算 GPA、查看成绩单 PDF。
- 📚 培养方案：查看个人或其他专业的培养方案。
- 🎨 个性化：Android 动态取色（Material You）、MD2/MD3 切换、多种导航方式、自定义主题色与页面过渡动画。

### 1.2 免责声明

本应用为第三方独立开发，**与湘潭大学官方机构无关**，仅用于信息查询，不主动收集个人信息。账号信息在本地加密存储，不经过任何第三方服务器。应用提供的信息仅供参考，请以官方平台为准。

---

## 2. 技术栈

| 层级 | 技术/包 |
|------|---------|
| 框架 | Flutter 3.24.5（Dart 3.5.4） |
| 状态管理 | `provider` |
| 网络请求 | `dio`、`http` |
| HTML 解析 | `html` |
| 本地存储 | `shared_preferences`、`flutter_secure_storage`、`path_provider` |
| 本地通知 | `flutter_local_notifications`、`timezone` |
| WebView | `flutter_inappwebview`（用于手动登录正方教务系统） |
| 加密 | `pointycastle`（RSA 加密登录密码） |
| 动态取色 | `dynamic_color` |
| PDF 查看 | `pdfx` |
| 其他 | `url_launcher`、`flutter_colorpicker`、`package_info_plus`、`flutter_markdown`、`uuid`、`collection` 等 |

---

## 3. 环境要求

- **Flutter**: 3.24.5（强烈建议使用 [FVM](https://fvm.app) 管理，项目根目录已提供 `.fvmrc`）
- **Dart**: 3.5.4
- **JDK**: 17
- **Android SDK**: 35（如需编译 Android）
- **Android Studio / VS Code**: 用于开发与调试
- **Visual Studio 2022 + C++ ATL**（如需编译 Windows）
- **Linux 依赖**（如需编译 Linux）：`gnome-keyring`、`libsecret-1-dev`、`libjsoncpp-dev`

VS Code 设置中已经指定了 FVM 路径：`.fvm/versions/3.24.5`。

---

## 4. 构建与运行

### 4.1 安装依赖

```bash
flutter pub get
```

### 4.2 运行应用

```bash
flutter run
```

### 4.3 构建 Release

#### Android

```bash
# 单 ABI APK（arm64）
flutter build apk --release --target-platform android-arm64

# 按 ABI 拆分 APK（同时生成 arm64-v8a / armeabi-v7a / x86_64）
flutter build apk --release --split-per-abi
```

#### Windows

```bash
flutter build windows
```

> 编译 Windows 时，`flutter_inappwebview` 与 WebView2 会抛出若干 warning（如 C4458、C4244、C4819），这些来自官方 Windows WebView2 库，可忽略，只要最终显示 `√ Built build\windows\x64\runner\Release\sachet.exe` 即可。

#### Linux

```bash
flutter build linux
```

### 4.4 签名 APK（本地）

本地签名脚本位于 `scripts/build-signed-apk-arm64-v8a.sh`：

1. 复制 `scripts/local.signing.env.example` 为 `scripts/local.signing.env`。
2. 填写 `KEYSTORE_PATH`（绝对路径）与 `KEY_ALIAS`。
3. 运行脚本，按提示输入 keystore 与 key 密码。

脚本会自动生成临时的 `android/key.properties`，构建完成后清理。

### 4.5 生成应用图标与启动页

```bash
# 生成图标
dart run flutter_launcher_icons

# 生成启动页
dart run flutter_native_splash:create
```

---

## 5. 代码组织结构

源码位于 `lib/`，按职责分层：

```
lib/
├── main.dart                 # 应用入口：初始化 AppGlobal、Provider、主题与路由
├── constants/                # 常量：URL、应用信息、主题色、课表时间、免责声明等
├── models/                   # 数据模型与枚举
│   └── enums/                # 枚举类型（导航方式、文件夹、页面过渡动画等）
├── pages/                    # 页面（按功能模块划分子目录）
│   ├── class_child_pages/    # 课程表子页面（周/月/学期视图、课程设置）
│   ├── home_child_pages/     # Home 页功能子页面（成绩、考试、空闲教室、培养方案等）
│   ├── settings_child_pages/ # 设置相关子页面
│   ├── intro_screen/         # 首次启动引导页
│   └── utilspages/           # 通用页面（登录、手动登录、PDF 查看）
├── providers/                # Provider 状态管理
├── services/                 # 业务服务层
│   └── zhengfang_jwxt/       # 正方教务系统相关服务（登录、课表、成绩、考试、空闲教室等）
├── utils/                    # 工具类与封装
│   └── storage/              # 本地文件与 SharedPreferences 读写
└── widgets/                  # 可复用组件（按页面或功能划分子目录）
```

### 5.1 服务层说明（`services/zhengfang_jwxt/`）

所有与正方教务系统交互的逻辑都集中在 `lib/services/zhengfang_jwxt/` 下，按业务模块划分：

- `login/` — 正方教务系统登录、Cookie 管理、自动重登。
- `class_schedule/` — 课程表获取、解析、学期列表、开学日期。
- `grade/` — 成绩查询。
- `gpa/` — GPA 查询与计算。
- `exam_time/` — 考试安排。
- `free_classroom/` — 空闲教室。
- `cultivation/` — 培养方案。
- `reserve_textbook/` — 教材预订信息。
- `score_pdf/` — 成绩单 PDF。
- `auto_login_retry.dart` — 登录态过期时自动尝试重新登录的通用封装。

顶层 `ZhengFangJwxt` 类（`services/zhengfang_jwxt/zhengfang_jwxt.dart`）以静态常量聚合所有服务，便于统一调用：

```dart
ZhengFangJwxt.classSchedule.getClassSchedule(...)
ZhengFangJwxt.grade.getGrade(...)
```

### 5.2 状态管理

使用 `provider` 包。主要 Provider 包括：

- `ThemeProvider` — 主题、MD2/MD3、动态取色、页面过渡动画。
- `SettingsProvider` — 应用设置（启动页、导航方式、自动检查更新等）。
- `ZhengFangUserProvider` — 正方教务系统用户信息（学号、姓名、Cookie 等）。
- `CourseCardSettingsProvider` — 课程卡片外观。
- `ScreenNavProvider` / `ClassPageProvider` — 页面导航状态。
- 各功能页面 Provider（如 `GradePageZfProvider`、`GpaPageZfProvider` 等）。

### 5.3 本地数据存储

- `shared_preferences`：应用设置、课程卡片外观等轻量配置。
- `flutter_secure_storage`：账号密码等敏感信息。
- `path_provider` + 自定义 `CachedDataStorage`：课程表、配色文件、缓存数据等 JSON 文件。

---

## 6. 代码风格与开发约定

### 6.1 语言与注释

- 源码使用**中文注释**为主，命名以英文 Dart 标识符为准。
- 对外 README/文档使用中文。
- 提交本项目的文档或注释时，保持中文。

### 6.2 Lint 配置

- 分析器配置在 `analysis_options.yaml`。
- 默认引入 `package:flutter_lints/flutter.yaml`。
- 运行静态分析：

```bash
flutter analyze --no-fatal-infos --no-fatal-warnings
```

### 6.3 代码规范

- 使用 Flutter 官方推荐的 Dart 风格。
- 不要引入不必要的复杂抽象；保持与现有 Provider + Service 分层一致。
- 涉及教务系统的请求统一走 `services/zhengfang_jwxt/` 下的服务，避免在页面中直接拼 URL。
- 本地文件路径、文件夹命名通过 `models/enums/app_folder.dart` 集中管理。
- 常量（URL、颜色、文案）放在 `lib/constants/` 下，不要硬编码在页面里。

### 6.4 版本号

版本号在 `pubspec.yaml` 中维护，格式为 `version: 0.10.0+16`。构建 Android 时，`versionCode` 与 `versionName` 会自动从 `pubspec.yaml` 读取。

---

## 7. 测试说明

### 7.1 现有测试

测试位于 `test/`：

- `widget_test.dart` — Flutter 默认的 widget 测试模板（基于旧 Counter Demo，当前已不匹配应用逻辑，属于占位/遗留文件）。
- `zhengfang_login_service_test.dart` — 正方教务系统登录测试，默认 `skip: '需要真实用户信息登录，默认跳过'`。

### 7.2 运行测试

```bash
flutter test
```

### 7.3 测试策略建议

- 本项目的业务逻辑大量依赖正方教务系统 HTML 返回与真实 Cookie，单元测试应以**解析函数**为优先测试对象（传入固定 HTML，断言解析结果）。
- 网络请求层可通过依赖注入或抽象 HTTP 客户端进行 mock 测试。
- 不建议在自动化测试中使用真实账号密码。

---

## 8. 安全与隐私

### 8.1 敏感信息

- 用户账号、密码使用 `flutter_secure_storage` 本地加密存储。
- 登录密码通过 `pointycastle` 进行 RSA 加密后发送到正方教务系统。
- GitHub Actions 签名使用的 keystore 通过 `secrets.ANDROID_KEYSTORE_BASE64` 等仓库 Secrets 注入，构建完成后会清理 `key.jks` 与 `key.properties`。

### 8.2 不应提交的内容

- keystore 文件（`*.jks`、`*.keystore`）
- `android/key.properties`
- `scripts/local.signing.env`
- 任何包含真实账号密码、Cookie、个人信息或调试输出的文件

这些已在 `.gitignore` 中排除。

### 8.3 网络通信

应用直接与湘潭大学正方教务系统服务器通信，不经过第三方代理或服务器。所有 URL 定义在 `lib/constants/url_constants.dart`。

---

## 9. CI/CD 与发布

### 9.1 GitHub Actions

工作流文件：`.github/workflows/build.yml`

触发条件：

- `workflow_dispatch`（手动触发）
- 向 `main` 分支发起 `pull_request`

构建步骤：

1. 检出代码
2. 设置 JDK 17
3. 设置 Flutter 3.24.5
4. `flutter pub get`
5. `flutter analyze --no-fatal-infos --no-fatal-warnings`
6. 配置 Android 签名
7. `flutter build apk --release --split-per-abi`
8. 重命名 APK 并上传 artifact
9. 清理签名文件

### 9.2 发布流程

- 正式 release 通过 GitHub Releases 发布。
- 应用内通过 `check_update.dart` 检查 GitHub Releases 最新版本，默认使用 `api.github.com` 渠道。
- 发布前需同步更新 `CHANGELOG.md` 与 `pubspec.yaml` 版本号。

---

## 10. 常见注意事项

1. **Flutter 版本锁定**：本项目不保证与最新 Flutter SDK 兼容，请使用 FVM 或手动切换到 3.24.5。
2. **Windows 编译警告**：见 4.3 节，可忽略。
3. **README_DEV.md 文件树过时**：实际结构以 `lib/` 和本文件为准。
4. **教务系统变更**：正方教务系统的页面结构、URL、字段可能随学校更新而变化，相关解析代码需要及时调整。
5. **新增功能**：若新增教务系统相关功能，请在 `services/zhengfang_jwxt/` 下按模块新建目录，并在 `ZhengFangJwxt` 中暴露；页面与 Provider 分别放到 `pages/` 与 `providers/`。

---

## 11. 联系方式

- 当前维护者：[@zzy00747](https://github.com/zzy00747)
- 邮箱：voidsec@126.com / voidsec@foxmail.com
- 项目仓库：[zzy00747/SachetNew](https://github.com/zzy00747/SachetNew)

---

## 12. Git Workflow

每次修改代码后，AI 助手应按以下流程操作：

1. **检查相关文档/配置一致性**
   若修改涉及功能、接口、构建方式或项目结构，应同步更新 `README.md`、`AGENTS.md`、`CHANGELOG.md`、`pubspec.yaml` 等相关文档或配置文件。

2. **运行测试**
   执行 Flutter 测试：

   ```bash
   flutter test
   ```

   若测试失败，应优先修复失败项；若失败与本次修改无关（如依赖真实教务系统登录的测试被跳过、或环境导致旧测试无法运行），应在提交信息或注释中说明。

3. **暂存更改**
   使用 `git add` 暂存所有相关改动：

   ```bash
   git add <changed-files>
   ```

4. **本地提交**
   使用 [Conventional Commits](https://www.conventionalcommits.org/) 规范创建本地提交，例如：

   ```bash
   git commit -m "feat: 新增 xxx 功能"
   git commit -m "fix: 修复 xxx 问题"
   git commit -m "docs: 更新 xxx 文档"
   git commit -m "refactor: 重构 xxx 模块"
   ```

   常见类型：`feat:`、`fix:`、`docs:`、`style:`、`refactor:`、`test:`、`chore:`。

> **注意**：除非用户明确要求，否则**不要**执行 `git push` 推送到远程仓库。

---

## 13. AI 协作原则

- 当遇到长时间无法解决的环境或构建问题时，**不要无限次尝试**，应及时把当前状况、已尝试的方案和剩下的阻塞点反馈给用户，由用户决策或提供更合适的环境/信息。
