# Time Tracker

一个简洁的时间追踪 Flutter 应用。

## 功能

- 计时记录
- 分类管理
- 事件模板
- 快捷启动

## 开始使用

```bash
flutter pub get
flutter run
```

## 安全说明

本应用数据存储在本地 SQLite 数据库中，**未加密**。请注意：

- 数据存储在应用私有目录，其他应用通常无法访问
- 在 root/越狱设备上，数据可能被其他应用读取
- 设备备份可能包含未加密的数据库文件
- 如需存储敏感信息，建议自行评估风险

## 开发

```bash
# 生成数据库代码
flutter pub run build_runner build --delete-conflicting-outputs
```
