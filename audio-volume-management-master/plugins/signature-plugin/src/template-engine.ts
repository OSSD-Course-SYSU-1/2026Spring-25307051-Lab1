import * as path from 'path';
import * as fs from 'fs';
import * as fsPromises from 'fs/promises';
import { TemplateType } from './types';

/**
 * 模板引擎接口
 */
export interface ITemplateEngine {
  getTemplate(type: TemplateType): string;
  applyTemplate(type: TemplateType, targetPath: string, variables?: Record<string, string>): Promise<void>;
  customizeTemplate(type: TemplateType, customizations: Record<string, any>): string;
}

/**
 * 模板引擎
 * 负责提供和应用配置模板
 */
export class TemplateEngine implements ITemplateEngine {
  private templatesPath: string;

  constructor(templatesPath?: string) {
    this.templatesPath = templatesPath || path.join(__dirname, '..', 'templates');
  }

  /**
   * 获取配置模板
   */
  getTemplate(type: TemplateType): string {
    switch (type) {
      case 'debug':
        return this.getDebugTemplate();
      case 'release':
        return this.getReleaseTemplate();
      case 'multi-env':
        return this.getMultiEnvTemplate();
      case 'gitignore':
        return this.getGitignoreTemplate();
      case 'env':
        return this.getEnvTemplate();
      default:
        throw new Error(`未知的模板类型: ${type}`);
    }
  }

  /**
   * 应用模板到项目
   */
  async applyTemplate(
    type: TemplateType,
    targetPath: string,
    variables?: Record<string, string>
  ): Promise<void> {
    let template = this.getTemplate(type);

    // 替换变量
    if (variables) {
      for (const [key, value] of Object.entries(variables)) {
        template = template.replace(new RegExp(`\\$\\{${key}\\}`, 'g'), value);
      }
    }

    // 确保目标目录存在
    const dir = path.dirname(targetPath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }

    // 写入文件
    await fsPromises.writeFile(targetPath, template, 'utf-8');
  }

  /**
   * 自定义模板
   */
  customizeTemplate(
    type: TemplateType,
    customizations: Record<string, any>
  ): string {
    let template = this.getTemplate(type);

    // 应用自定义配置
    for (const [key, value] of Object.entries(customizations)) {
      template = template.replace(
        new RegExp(`\\$\\{${key}\\}`, 'g'),
        String(value)
      );
    }

    return template;
  }

  /**
   * 获取调试签名模板
   */
  private getDebugTemplate(): string {
    return JSON.stringify({
      name: 'default',
      signingCertificateProfile: './.signature/debug.p12',
      buildMode: 'debug',
      storePassword: '123456',
      keyAlias: 'debug',
      keyPassword: '123456',
      signAlg: 'SHA256withECDSA'
    }, null, 2);
  }

  /**
   * 获取发布签名模板
   */
  private getReleaseTemplate(): string {
    return JSON.stringify({
      name: 'release',
      signingCertificateProfile: '${HARMONYOS_SIGNATURE_PATH}',
      buildMode: 'release',
      storePassword: '${HARMONYOS_SIGNATURE_PASSWORD}',
      keyAlias: '${HARMONYOS_KEY_ALIAS}',
      keyPassword: '${HARMONYOS_KEY_PASSWORD}',
      signAlg: 'SHA256withECDSA',
      profileFile: '${HARMONYOS_PROFILE_FILE}',
      certpathFile: '${HARMONYOS_CERTPATH_FILE}'
    }, null, 2);
  }

  /**
   * 获取多环境配置模板
   */
  private getMultiEnvTemplate(): string {
    return `# HarmonyOS 多环境签名配置

## 开发环境
# .env.development
HARMONYOS_ENV=development
HARMONYOS_SIGNATURE_PATH=./.signature/debug.p12
HARMONYOS_BUILD_MODE=debug

## 测试环境
# .env.testing
HARMONYOS_ENV=testing
HARMONYOS_SIGNATURE_PATH=./.signature/testing.p12
HARMONYOS_BUILD_MODE=debug

## 生产环境
# .env.production
HARMONYOS_ENV=production
HARMONYOS_SIGNATURE_PATH=/path/to/release.p12
HARMONYOS_SIGNATURE_PASSWORD=your_password
HARMONYOS_BUILD_MODE=release
`;
  }

  /**
   * 获取 .gitignore 模板
   */
  private getGitignoreTemplate(): string {
    return `# HarmonyOS 签名文件
.signature/
*.p12
*.p7b
*.cer

# 环境配置文件（包含敏感信息）
.env.local
.env.*.local
signature-config.json5

# 不要提交签名密码到版本控制
# 如需配置，请使用环境变量或 CI/CD 密钥管理
`;
  }

  /**
   * 获取环境配置模板
   */
  private getEnvTemplate(): string {
    return `# HarmonyOS 签名配置

# 环境类型: development | testing | production
HARMONYOS_ENV=development

# 签名文件路径（相对路径或绝对路径）
HARMONYOS_SIGNATURE_PATH=./.signature/debug.p12

# 签名密码（可选，建议使用环境变量）
# HARMONYOS_SIGNATURE_PASSWORD=your_password

# 构建模式: debug | release
HARMONYOS_BUILD_MODE=debug

# 发布签名配置（仅生产环境需要）
# HARMONYOS_KEY_ALIAS=your_key_alias
# HARMONYOS_KEY_PASSWORD=your_key_password
# HARMONYOS_PROFILE_FILE=/path/to/profile.p7b
# HARMONYOS_CERTPATH_FILE=/path/to/cert.cer
`;
  }

  /**
   * 获取 README 模板
   */
  getReadmeTemplate(): string {
    return `# HarmonyOS 签名自动配置插件

## 快速开始

### 1. 安装插件
\`\`\`bash
npm install @audio-volume/signature-plugin --save-dev
\`\`\`

### 2. 配置 hvigorfile.ts
\`\`\`typescript
import { SignaturePlugin } from '@audio-volume/signature-plugin';

export default {
  plugins: [
    new SignaturePlugin({
      autoDetect: true,
      autoGenerate: true
    })
  ]
}
\`\`\`

### 3. 构建项目
\`\`\`bash
hvigorw assembleHap
\`\`\`

插件会自动检测并配置签名。

## 配置选项

- \`autoDetect\`: 自动检测签名配置（默认: true）
- \`autoGenerate\`: 自动生成调试签名（默认: true）
- \`signaturePath\`: 签名文件存储路径（默认: ./.signature）
- \`verbose\`: 显示详细日志（默认: false）

## 环境配置

支持多环境配置，创建以下文件：

- \`.env.development\` - 开发环境
- \`.env.testing\` - 测试环境
- \`.env.production\` - 生产环境

## 命令

- \`hvigorw checkSignature\` - 检查签名配置状态
- \`hvigorw generateSignature\` - 生成调试签名
- \`hvigorw configSignature\` - 配置签名参数

## 故障排查

### 签名文件缺失
运行 \`hvigorw generateSignature\` 自动生成调试签名。

### 签名配置无效
检查 \`build-profile.json5\` 中的 \`signingConfigs\` 配置。

### 环境变量未生效
确保 \`.env\` 文件在项目根目录，并重启构建。
`;
  }
}
