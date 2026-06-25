# SUPMART 商城购物APP

基于 Flutter 构建的移动端商城应用，对接 SUPMART 开放 API。

## 特性

- 🔄 **动态配置** — APP启动时从 `/openapi/app-pack/config/0` 获取域名/主题色/名称
- 🏪 **商品浏览** — 分类筛选、商品列表、商品详情
- 🛒 **一键下单** — 选择数量、立即购买，对接 SUPMART 下单API
- 📋 **订单管理** — 全部/待处理/已完成/已退款 状态筛选，分页加载
- 👤 **个人中心** — 余额查询、订单入口、账号退出

## 快速开始

### 1. 推送到 GitHub

```bash
# 初始化 Git
cd D:\X\supmart_shop_app
git init
git add .
git commit -m "init: SUPMART 商城购物APP"

# 在 GitHub 创建仓库后推送
git remote add origin https://github.com/你的用户名/supmart-shop-app.git
git branch -M main
git push -u origin main
```

### 2. 触发自动构建

APK 在以下情况自动编译：

- **推送代码到 main 分支** → 自动构建
- **创建标签** `git tag v1.0.0 && git push --tags` → 构建并发布 Release
- **手动触发** → 在 GitHub 仓库 Actions 页面点击 "Run workflow"

构建完成后，在 Actions 页面 Artifacts 区下载 `supmart-shop-apk`。

### 3. 上传 APK

下载 APK 后上传到服务器，在后台 APP打包页面填写 `download_url`。

## 项目结构

```
lib/
├── main.dart                     # 入口
├── models/                       # 数据模型
│   ├── app_pack_config.dart      # APP打包配置
│   ├── product.dart              # 商品
│   ├── category.dart             # 分类
│   └── order.dart                # 订单
├── services/                     # API服务
│   ├── config_service.dart       # 动态配置加载
│   └── api_service.dart          # 开放API调用
├── providers/                    # 状态管理
│   ├── auth_provider.dart        # 登录状态
│   ├── product_provider.dart     # 商品状态
│   └── order_provider.dart       # 订单状态
└── screens/                      # 页面
    ├── splash_screen.dart        # 启动页
    ├── login_screen.dart         # 登录页
    ├── home_screen.dart          # 商城首页
    ├── product_detail_screen.dart # 商品详情
    ├── order_list_screen.dart    # 订单列表
    ├── order_detail_screen.dart  # 订单详情
    └── profile_screen.dart       # 个人中心
```

## 本地编译 (需要 Android SDK)

```bash
flutter pub get
flutter build apk --release --split-per-abi
```

编译产物在 `build/app/outputs/flutter-apk/`。
