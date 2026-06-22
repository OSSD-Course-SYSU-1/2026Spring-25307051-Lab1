# Auto Uninstall Plugin for HarmonyOS

自动卸载插件，在安装前自动卸载旧版本应用，解决签名不一致问题。

## 功能特性

- ✅ 构建完成后自动卸载旧版本应用
- ✅ 自动安装新版本应用
- ✅ 自动启动应用
- ✅ 支持自定义 HDC 路径
- ✅ 支持自定义包名

## 使用方法

### 1. 在 hvigorfile.ts 中配置

```typescript
import { appTasks } from '@ohos/hvigor-ohos-plugin';
import { SignaturePlugin } from './plugins/signature-plugin/src/simple-plugin';
import { AutoUninstallPlugin } from './plugins/auto-uninstall-plugin/src/auto-uninstall-plugin';

export default {
  system: appTasks,
  plugins: [
    new SignaturePlugin({
      autoDetect: true,
      autoGenerate: true,
      signaturePath: './.signature',
      verbose: true
    }),
    new AutoUninstallPlugin({
      packageName: 'com.example.audiostreamvolumemanagement',
      hdcPath: 'D:\\DevEco Studio\\tools\\hdc\\hdc.exe',
      autoUninstall: true,
      autoInstall: true,
      autoStart: true,
      verbose: true
    })
  ]
}
```

### 2. 配置选项

| 选项 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| packageName | string | 'com.example.audiostreamvolumemanagement' | 应用包名 |
| hdcPath | string | 'D:\\DevEco Studio\\tools\\hdc\\hdc.exe' | HDC 工具路径 |
| autoUninstall | boolean | true | 是否自动卸载 |
| autoInstall | boolean | true | 是否自动安装 |
| autoStart | boolean | true | 是否自动启动 |
| verbose | boolean | true | 是否显示详细日志 |

### 3. 自定义任务

插件注册了以下自定义任务：

- `uninstall` - 卸载应用
- `install` - 安装应用
- `deploy` - 完整部署（卸载+安装+启动）

可以通过以下命令执行：

```bash
hvigorw uninstall
hvigorw install
hvigorw deploy
```

## 工作流程

1. **构建完成** → 触发 afterBuild 钩子
2. **检查设备** → 确认设备已连接
3. **卸载旧版本** → 解决签名不一致问题
4. **安装新版本** → 发送 HAP 文件并安装
5. **启动应用** → 自动启动应用

## 注意事项

1. 确保 HDC 工具路径正确
2. 确保设备已通过 USB 连接并开启开发者模式
3. 确保已构建项目（存在 HAP 文件）

## 故障排除

### 设备未连接

```
❌ 设备未连接，跳过自动部署
提示：请确保设备已通过USB连接并开启开发者模式
```

**解决方案：**
- 检查 USB 连接
- 确认设备已开启开发者模式
- 确认 HDC 服务正常运行

### HDC 路径错误

**解决方案：**
- 修改 `hdcPath` 配置为实际路径
- 通常位于：`DevEco Studio 安装目录\tools\hdc\hdc.exe`

### HAP 文件未找到

```
❌ 未找到 HAP 文件
请先构建项目
```

**解决方案：**
- 在 DevEco Studio 中构建项目
- 或运行 `hvigorw assembleHap`
