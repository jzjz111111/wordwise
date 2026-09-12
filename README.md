# WordWise · 智慧背单词

> 一个基于 Flutter + Riverpod + Supabase 的英语单词学习 App，采用 Clean Architecture 分层设计，结合 SM-2 间隔重复算法帮助用户科学高效地记忆单词。

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![Riverpod](https://img.shields.io/badge/Riverpod-2.x-764ABC)
![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase)
![License](https://img.shields.io/badge/License-Educational-lightgrey)

---

## 📖 目录

- [功能特性](#-功能特性)
- [技术栈](#-技术栈)
- [项目架构](#-项目架构)
- [核心算法](#-核心算法)
- [快速开始](#-快速开始)
- [Supabase 表结构](#supabase-表结构)
- [目录约定](#-目录约定)


---

## 📱 功能特性

### 核心学习流程
- **学习卡片**：3D 翻转卡片记忆单词，支持「忘记 / 模糊 / 认识」三档自评
- **拼写测试**：根据释义拼写单词，检验记忆效果
- **选择测试**：四选一选择题，干扰项由算法智能生成
- **错词重测**：答错的词自动进入重测队列，直到全部答对

### 词汇管理
- **词库导入**：内置四级（CET-4）、六级（CET-6）、考研（KaoYan）词库
- **错词本**：自动收集答错的词，支持手动删除 / 清空
- **生词本**：答错的词自动加入，可手动添加 / 移除
- **收藏本**：用户主动星标收藏的重点词汇

### 数据统计
- **首页仪表盘**：学习进度环、待复习、今日新词、已掌握
- **统计数据页**：掌握程度分布、学习趋势、连续打卡天数
- **词库切换**：多个词库独立统计、独立学习进度

### 个人中心
- **账户体系**：注册 / 登录 / 修改密码（Supabase Auth）
- **资料编辑**：昵称、头像、背景图、个性签名
- **云端同步**：跨设备同步学习记录、错词、生词、收藏

### AI 智能辅助
- **AI 生成段子**：基于 DeepSeek API，用学过的单词生成趣味段落，流式输出



---

## 🛠 技术栈

| 分类 | 技术 |
|------|------|
| 框架 | Flutter |
| 语言 | Dart 3 |
| 状态管理 | Riverpod |
| 本地数据库 | SQLite (sqflite) |
| 云服务 | Supabase (Auth + Database + Storage) |
| 路由 | go_router |
| AI 服务 | DeepSeek API |
| 本地存储 | SharedPreferences |
| 图片选择 | image_picker |


---

## 🏗 项目架构

采用 **Clean Architecture（整洁架构）** + **Feature-first（按功能模块划分）** 的组织方式。

```
lib/
├── core/                          # 跨模块共享层
│   ├── constants/                 # 常量
│   ├── database/                  # 数据库核心
│   │   ├── database_helper.dart       # SQLite 单例管理
│   │   ├── word_importer.dart         # 词库导入
│   │   └── distractor_generator.dart  # 干扰项生成算法
│   ├── router/                    # 路由配置（go_router）
│   ├── services/                  # 公共服务
│   │   ├── ai_service.dart            # DeepSeek API
│   │   ├── notification_service.dart  # 每日提醒
│   │   └── sync_service.dart          # 云端同步
│   ├── theme/                     # 主题配色
│   └── utils/                     # 工具方法
│
├── features/                      # 功能模块
│   ├── auth/                      # 认证模块
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── providers/
│   │       └── screens/
│   │
│   ├── profile/                   # 个人中心模块
│   │   ├── data/repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   └── repositories/
│   │   └── presentation/
│   │       ├── providers/
│   │       └── screens/
│   │
│   └── study/                     # 学习模块（核心）
│       ├── data/
│       │   ├── datasources/           # 远程数据源
│       │   └── repositories/          # 仓库实现
│       ├── domain/
│       │   ├── entities/              # 领域实体
│       │   ├── repositories/          # 仓库接口
│       │   └── usecases/              # 算法（SM-2）
│       └── presentation/
│           ├── providers/             # 状态管理
│           ├── screens/               # 页面
│           └── widgets/               # 可复用组件
│
└── main.dart                      # 应用入口
```

### 分层依赖方向

```
presentation (UI)
    ↓ 依赖
domain (业务逻辑 + 接口)
    ↑ 实现
data (数据库 + 网络)
```

`domain` 层处于中心，不依赖任何框架；`data` 和 `presentation` 都依赖 `domain`。

---

## 🧠 核心算法

### SM-2 间隔重复算法

根据 SuperMemo 提出的经典算法，为每个单词维护：
- `easeFactor`（难易度因子，初始 2.5，下限 1.3）
- `interval`（复习间隔，单位天，上限 365）
- `reviewCount`（复习次数）

更新公式：

```
EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
```

其中 `q` 是用户自评质量（0-5）。当 `q < 3` 时，间隔重置为 1 天；否则根据复习次数决定新的间隔（第 1 次 1 天，第 2 次 6 天，之后 `interval × EF`）。

### 干扰项生成算法

为选择题生成"看起来像"的干扰项，采用启发式规则：
1. 优先选同词性（n. / v. / adj. / adv.）的词
2. 按拼写相似度排序（共同前缀占比 × 0.7 + 长度接近度 × 0.3）
3. 取前 3 个作为干扰项

---

## 🚀 快速开始

### 环境要求
- Flutter SDK `>= 3.x`
- Dart SDK `>= 3.x`
- Android Studio / VS Code
- Supabase 账号（用于后端服务）
- DeepSeek API Key（用于 AI 段子功能）

### 运行步骤

```bash
# 1. 安装依赖
flutter pub get

# 2. 运行（DeepSeek API Key 通过编译期变量传入）
flutter run --dart-define=DEEPSEEK_API_KEY=your_deepseek_api_key
```

> **说明**：Supabase 的 `url` 和 `anonKey` 在 `main.dart` 中初始化；DeepSeek 的 API Key 通过 `String.fromEnvironment` 在编译期读取，因此使用 `--dart-define` 传入。生产环境建议改用更安全的方式管理密钥。

---

## Supabase 表结构

需要创建以下数据表：

| 表名 | 用途 |
|------|------|
| `profiles` | 用户资料（昵称、头像、背景图） |
| `study_records` | 学习记录（SM-2 状态） |
| `wrong_words` | 错词本（云端） |
| `new_words` | 生词本（云端） |
| `favorite_words` | 收藏本（云端） |

Storage Bucket：`avatars`（头像）、`backgrounds`（背景图）

---

## 📦 主要依赖

```yaml
dependencies:
  flutter_riverpod:              # 状态管理
  go_router:                     # 路由
  supabase_flutter:              # 云端服务
  sqflite:                       # 本地数据库
  shared_preferences:            # 本地键值存储
  flutter_tts:                   # 语音朗读
  image_picker:                  # 图片选择
  flutter_local_notifications:   # 本地通知
  path_provider:                 # 文件路径
```


---

## 📄 目录约定

| 目录 | 存放内容 |
|------|---------|
| `domain/entities/` | 纯 Dart 数据类，不依赖 Flutter |
| `domain/repositories/` | 仓库接口（abstract class） |
| `domain/usecases/` | 业务算法（如 SM-2） |
| `data/repositories/` | 仓库实现（SQLite、Supabase） |
| `data/datasources/` | 远程数据源封装 |
| `presentation/providers/` | Riverpod Provider |
| `presentation/screens/` | 页面级组件 |
| `presentation/widgets/` | 可复用组件 |

---

## 📝 开发规范

- 状态管理统一使用 Riverpod，禁止在 Widget 内部直接操作数据库
- 所有跨层数据传输使用 `domain/entities` 定义的实体
- 用户操作采用 **乐观更新（Optimistic UI）**：先更新本地 UI，再异步同步云端
- 本地写入优先，云端作为异步备份，保证离线可用

---

## 🤝 贡献指南

本项目为个人学习项目，暂不接受外部 PR。如有建议欢迎提 Issue。

---

## 📌 版本

当前版本：**v1.0.0**

---

## 📜 许可证

本项目仅供学习交流使用，不用于商业目的。