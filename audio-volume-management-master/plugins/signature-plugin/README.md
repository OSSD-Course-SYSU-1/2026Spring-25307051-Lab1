# HarmonyOS 签名自动配置插件

## 功能特性

✅ **自动检测签名配置** - 智能检测项目签名配置状态  
✅ **自动生成调试签名** - 一键生成调试签名文件  
✅ **多环境支持** - 支持开发、测试、生产环境配置  
✅ **零配置使用** - 开箱即用，无需手动配置  
✅ **构建集成** - 无缝集成到 Hvigor 构建流程  
✅ **安全可靠** - 自动添加 .gitignore，防止敏感信息泄露

## 快速开始

### 1. 插件已集成

插件已自动集成到项目中，查看 `hvigorfile.ts`:

```typescript
import { appTasks } from '@ohos/hvigor-ohos-plugin';
import { SignaturePlugin } from './plugins/signature-plugin/src';

export default {
  system: appTasks,
  plugins: [
    new SignaturePlugin({
      autoDetect: true,      // 自动检测签名配置
      autoGenerate: true,    // 自动生成调试签名
      signaturePath: './.signature',  // 签名文件存储路径
      verbose: true          // 显示详细日志
    })
  ]
}
```

### 2. 构建项目

```bash
# 清理项目
hvigorw clean

# 构建应用（插件会自动检测并配置签名）
hvigorw assembleHap
```

### 3. 检查签名状态

```bash
# 检查签名配置状态
hvigorw checkSignature

# 手动生成签名
hvigorw generateSignature
```

## 配置选项

| 选项 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `autoDetect` | boolean | `true` | 自动检测签名配置 |
| `autoGenerate` | boolean | `true` | 自动生成调试签名 |
| `signaturePath` | string | `'./.signature'` | 签名文件存储路径 |
| `verbose` | boolean | `false` | 显示详细日志 |
| `environments` | array | `[]` | 多环境配置 |

## 环境配置

### 开发环境（默认）

`.env.development` 文件：
```bash
HARMONYOS_ENV=development
HARMONYOS_SIGNATURE_PATH=./.signature/debug.p12
HARMONYOS_BUILD_MODE=debug
```

### 生产环境

`.env.production` 文件：
```bash
HARMONYOS_ENV=production
HARMONYOS_SIGNATURE_PATH=/path/to/release.p12
HARMONYOS_SIGNATURE_PASSWORD=your_password
HARMONYOS_BUILD_MODE=release
```

### 环境变量

也可以通过环境变量配置：

```bash
# 设置环境
export HARMONYOS_ENV=production

# 设置签名路径
export HARMONYOS_SIGNATURE_PATH=/path/to/release.p12

# 设置签名密码
export HARMONYOS_SIGNATURE_PASSWORD=your_password
```

## 项目结构

```
project/
├── .signature/              # 签名文件目录（自动生成）
│   ├── debug.p12           # 调试签名
│   └── release.p12         # 发布签名（需手动配置）
├── .env.development        # 开发环境配置
├── .env.production         # 生产环境配置
├── build-profile.json5     # 构建配置（自动更新）
└── plugins/
    └── signature-plugin/   # 签名插件
        ├── src/
        │   ├── index.ts           # 插件主类
        │   ├── detector.ts        # 签名检测器
        │   ├── generator.ts       # 签名生成器
        │   ├── config-manager.ts  # 配置管理器
        │   ├── env-manager.ts     # 环境管理器
        │   └── template-engine.ts # 模板引擎
        └── templates/             # 配置模板
```

## 工作原理

### 1. 构建前检查

插件在构建前自动执行：
- 检查 `build-profile.json5` 中的签名配置
- 验证签名文件是否存在
- 如果未配置，自动生成调试签名
- 更新构建配置文件

### 2. 签名生成

调试签名生成流程：
1. 创建 `.signature/` 目录
2. 生成自签名的 P12 文件
3. 创建签名配置对象
4. 更新 `build-profile.json5`

### 3. 环境管理

环境配置优先级：
1. 环境变量（最高优先级）
2. `.env.{environment}` 文件
3. 默认配置（最低优先级）

## 故障排查

### 问题 1: 签名文件缺失

**错误信息**: `error: no signature file`

**解决方案**:
```bash
# 方法 1: 自动生成
hvigorw generateSignature

# 方法 2: 重新构建（插件会自动生成）
hvigorw clean && hvigorw assembleHap
```

### 问题 2: 签名配置无效

**错误信息**: `签名配置无效`

**解决方案**:
```bash
# 检查签名状态
hvigorw checkSignature

# 查看详细信息
hvigorw checkSignature --verbose
```

### 问题 3: 环境变量未生效

**解决方案**:
1. 确保 `.env` 文件在项目根目录
2. 重启构建进程
3. 检查环境变量名称是否正确

### 问题 4: 权限错误

**解决方案**:
```bash
# Linux/Mac
chmod 600 .signature/*.p12

# Windows
# 检查文件属性，确保有读取权限
```

## API 文档

### SignaturePlugin

主插件类：

```typescript
const plugin = new SignaturePlugin({
  autoDetect: true,
  autoGenerate: true,
  signaturePath: './.signature',
  verbose: true
});
```

### SignatureDetector

签名检测器：

```typescript
const detector = new SignatureDetector();
const status = await detector.checkSignatureConfig(projectPath);
```

### SignatureGenerator

签名生成器：

```typescript
const generator = new SignatureGenerator();
const signature = await generator.generateDebugSignature(projectPath, {
  buildMode: 'debug',
  configName: 'default'
});
```

## 最佳实践

### 1. 开发环境

- 使用自动生成的调试签名
- 不要提交 `.signature/` 目录到版本控制
- 使用 `.env.development` 配置

### 2. 生产环境

- 使用正式的发布签名
- 通过环境变量配置签名路径和密码
- 不要在代码中硬编码密码

### 3. CI/CD 集成

```yaml
# GitHub Actions 示例
- name: Build HarmonyOS App
  env:
    HARMONYOS_ENV: production
    HARMONYOS_SIGNATURE_PATH: ${{ secrets.SIGNATURE_PATH }}
    HARMONYOS_SIGNATURE_PASSWORD: ${{ secrets.SIGNATURE_PASSWORD }}
  run: |
    hvigorw assembleHap
```

## 更新日志

### v1.0.0 (2024-01-21)

- ✨ 初始版本发布
- ✨ 支持自动检测签名配置
- ✨ 支持自动生成调试签名
- ✨ 支持多环境配置
- ✨ 集成到 Hvigor 构建流程

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！
