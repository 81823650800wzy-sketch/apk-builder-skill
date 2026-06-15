---
name: apk-builder
description: Build native Android APKs with hardware access (vibrate, flashlight, camera, sensors). Use when user asks to create APK or Android app.
argument-hint: "<app-name> [package-name]"
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent
---

# Native APK Builder

## 关键教训（必须遵守）

1. **文件写入必须用 bash `cat >`**，Write 工具在 Windows 下路径不一致
2. **主题用 `Theme.AppCompat.NoActionBar`**，MaterialComponents 部分机型崩溃
3. **所有 Button 显式设置 `android:textColor="#FFFFFF"`**
4. **布局用 `ScrollView > LinearLayout`**，不嵌套 FrameLayout
5. **硬件初始化全部 try-catch**
6. **编译前 `rm -rf app/build build`**
7. **APK 输出到 F:\ 盘**
8. **版本号递增**才能覆盖安装

## 环境

- JDK: D:/Android_studio/jbr (Java 21)
- SDK: ~/AppData/Local/Android/Sdk
- Build Tools: 37.0.0, Compile SDK: 36

## 创建项目

```bash
bash ~/.claude/skills/apk-builder/scripts/create.sh <AppName> <PackageName>
```

## 编译

```bash
bash ~/.claude/skills/apk-builder/scripts/build.sh <项目路径>
```

## 权限

- 震动: VIBRATE
- 闪光灯: CAMERA + FLASHLIGHT
- 网络: INTERNET + ACCESS_NETWORK_STATE
- 存储: WRITE_EXTERNAL_STORAGE (API<=28)
- 安装: REQUEST_INSTALL_PACKAGES
