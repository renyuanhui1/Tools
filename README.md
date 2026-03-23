# 习惯打卡应用

一个支持自定义习惯、每日打卡、连续天数统计的习惯养成工具，支持 Web 网页和 Windows 桌面软件两种使用方式。

---

## 功能介绍

- **今日打卡**：查看所有习惯，一键打卡或取消打卡，显示连续打卡天数
- **添加习惯**：自定义习惯名称、图标（18 个可选）、备注说明
- **习惯详情**：日历视图查看每月打卡记录，统计连续天数和本月次数，支持删除习惯
- **本地存储**：数据保存在本地，无需注册账号，无需网络

---

## 技术栈

| 技术 | 用途 |
|------|------|
| **React 19** | UI 框架，构建页面组件 |
| **React Router** | 前端路由，管理页面跳转 |
| **Vite** | 构建工具，提供开发服务器和打包 |
| **Electron 41** | 将网页打包为 Windows 桌面应用 |
| **localStorage** | 本地数据存储，保存习惯和打卡记录 |
| **CSS** | 页面样式，绿色主题设计 |

---

## 项目结构

```
habit-app/
├── electron.cjs              # Electron 主进程，负责创建窗口
├── vite.config.js            # Vite 构建配置
├── package.json              # 项目依赖和脚本
├── index.html                # HTML 入口模板
├── src/
│   ├── main.jsx              # React 应用入口，挂载到 DOM
│   ├── App.jsx               # 根组件，配置路由
│   ├── App.css               # 全局样式
│   ├── utils/
│   │   └── storage.js        # 本地存储工具，封装习惯和打卡记录的增删改查
│   └── pages/
│       ├── Index/
│       │   ├── Index.jsx     # 今日打卡页，展示所有习惯和打卡状态
│       │   └── Index.css     # 今日打卡页样式
│       ├── Add/
│       │   ├── Add.jsx       # 添加习惯页，支持自定义名称、图标、备注
│       │   └── Add.css       # 添加习惯页样式
│       └── Detail/
│           ├── Detail.jsx    # 习惯详情页，日历视图 + 统计 + 删除
│           └── Detail.css    # 习惯详情页样式
└── public/
    └── favicon.svg           # 应用图标
```

---

## 开发与运行

### 安装依赖
```bash
npm install
```

### 启动网页开发服务器
```bash
npm run dev
```
访问 http://localhost:5173

### 构建网页
```bash
npm run build
```

### 打包 Windows 桌面软件
```bash
npm run build
npx @electron/packager . 习惯打卡 --platform=win32 --arch=x64 --out=release-pkg --overwrite --electron-version=41.0.3 --ignore='node_modules|\.git|src|public|release-pkg|release'
```
打包完成后，运行 `release-pkg/习惯打卡-win32-x64/习惯打卡.exe` 即可。
