# pvm 快速开始指南

本指南将帮助您在 5 分钟内开始使用 pvm (Pod Version Manager)。

## 前置要求

在安装 pvm 之前，请确保您的系统已安装：

- **Ruby** 2.6.0 或更高版本
- **Git**（如果使用安装脚本）
- **bash** 或 **zsh** shell

检查 Ruby 是否已安装：

```bash
ruby --version
gem --version
```

## 安装 pvm

使用以下命令安装 pvm：

```bash
curl -o- https://raw.githubusercontent.com/mohuwamg/pvm/master/install.sh | bash
```

或使用 wget：

```bash
wget -qO- https://raw.githubusercontent.com/mohuwamg/pvm/master/install.sh | bash
```

安装完成后，重新加载 shell 配置：

```bash
source ~/.bashrc  # 或 source ~/.zshrc
```

验证安装：

```bash
pvm --help
```

## 基本使用

### 1. 安装 CocoaPods 版本

```bash
# 安装特定版本
pvm install 1.12.0

# 或安装最新版本
pvm install latest
```

### 2. 切换版本

```bash
pvm use 1.12.0
```

### 3. 验证版本

```bash
pod --version
```

### 4. 查看已安装的版本

```bash
pvm ls
```

## 项目中使用

在项目根目录创建 `.pvmrc` 文件：

```bash
echo "1.12.0" > .pvmrc
```

进入项目目录后，运行：

```bash
pvm use
```

pvm 会自动读取 `.pvmrc` 并切换到指定版本。

## 常用命令速查

| 命令 | 说明 |
|------|------|
| `pvm install <version>` | 安装指定版本 |
| `pvm use <version>` | 切换到指定版本 |
| `pvm ls` | 列出已安装版本 |
| `pvm ls-remote` | 列出可用版本 |
| `pvm current` | 显示当前版本 |
| `pvm uninstall <version>` | 卸载指定版本 |
| `pvm alias <name> <version>` | 创建版本别名 |
| `pvm --help` | 显示帮助信息 |

## 下一步

- 阅读 [README.md](README.md) 了解更多功能
- 查看 [EXAMPLES.md](EXAMPLES.md) 获取详细使用示例
- 阅读 [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) 了解技术细节

## 获取帮助

如果遇到问题，请：

1. 运行 `pvm --help` 查看命令说明
2. 查看项目文档
3. 在 GitHub 上提交 issue

开始享受 pvm 带来的便利吧！
