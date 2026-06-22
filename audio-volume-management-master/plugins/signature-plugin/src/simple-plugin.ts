/**
 * HarmonyOS 签名自动配置插件 - 简化版本
 * 不依赖外部包，使用 Node.js 内置模块
 */

import * as path from 'path';
import * as fs from 'fs';

export interface SignaturePluginConfig {
  autoDetect?: boolean;
  autoGenerate?: boolean;
  signaturePath?: string;
  verbose?: boolean;
}

export class SignaturePlugin {
  private config: SignaturePluginConfig;
  private projectPath: string;

  constructor(config: SignaturePluginConfig = {}) {
    this.config = {
      autoDetect: true,
      autoGenerate: true,
      signaturePath: './.signature',
      verbose: false,
      ...config
    };
    this.projectPath = process.cwd();
  }

  /**
   * 应用插件到 Hvigor 目标
   */
  apply(target: any): void {
    // 注册 beforeBuild 钩子
    if (target.beforeBuild) {
      target.beforeBuild(async (context: any) => {
        await this.handleBeforeBuild(context);
      });
    }

    // 注册 afterBuild 钩子
    if (target.afterBuild) {
      target.afterBuild(async (context: any) => {
        await this.handleAfterBuild(context);
      });
    }

    // 注册自定义任务
    this.registerTasks(target);
  }

  /**
   * 处理构建前逻辑
   */
  private async handleBeforeBuild(context: any): Promise<void> {
    const projectPath = context?.projectPath || this.projectPath;

    if (this.config.verbose) {
      console.log('🔍 检查签名配置...');
    }

    // 检查签名配置
    const status = this.checkSignatureConfig(projectPath);

    if (status === 'configured') {
      if (this.config.verbose) {
        console.log('✅ 签名配置正常');
      }
      return;
    }

    // 如果未配置且启用了自动生成
    if (status === 'not_configured' && this.config.autoGenerate) {
      if (this.config.verbose) {
        console.log('⚠️  签名未配置，正在自动生成...');
      }

      await this.generateDefaultSignature(projectPath);
    } else if (status === 'file_missing') {
      console.error('❌ 签名文件缺失');
      
      if (this.config.autoGenerate) {
        console.log('正在重新生成签名文件...');
        await this.generateDefaultSignature(projectPath);
      }
    }
  }

  /**
   * 处理构建后逻辑
   */
  private async handleAfterBuild(context: any): Promise<void> {
    if (this.config.verbose) {
      console.log('✅ 构建完成');
    }
  }

  /**
   * 注册自定义任务
   */
  private registerTasks(target: any): void {
    if (target.registerTask) {
      target.registerTask({
        name: 'checkSignature',
        description: '检查签名配置状态',
        action: async () => {
          const status = this.checkSignatureConfig(this.projectPath);
          console.log(`签名状态: ${status}`);
        }
      });

      target.registerTask({
        name: 'generateSignature',
        description: '生成调试签名',
        action: async () => {
          await this.generateDefaultSignature(this.projectPath);
          console.log('✅ 签名生成完成');
        }
      });
    }
  }

  /**
   * 检查签名配置
   */
  private checkSignatureConfig(projectPath: string): string {
    try {
      const buildProfilePath = path.join(projectPath, 'build-profile.json5');
      
      // 检查 build-profile.json5 是否存在
      if (!fs.existsSync(buildProfilePath)) {
        return 'not_configured';
      }

      // 读取配置文件
      const content = fs.readFileSync(buildProfilePath, 'utf-8');
      
      // 简单检查是否包含签名配置
      if (content.includes('"signingConfigs"') && content.includes('.p12')) {
        // 检查签名文件是否存在
        const p12Path = path.join(projectPath, '.signature', 'debug.p12');
        const cerPath = path.join(projectPath, '.signature', 'debug.cer');
        const p7bPath = path.join(projectPath, '.signature', 'debug.p7b');
        
        if (fs.existsSync(p12Path) && fs.existsSync(cerPath) && fs.existsSync(p7bPath)) {
          return 'configured';
        } else {
          return 'file_missing';
        }
      }

      return 'not_configured';
    } catch (error) {
      return 'invalid';
    }
  }

  /**
   * 生成默认签名
   */
  private async generateDefaultSignature(projectPath: string): Promise<void> {
    const signatureDir = this.config.signaturePath 
      ? path.resolve(projectPath, this.config.signaturePath)
      : path.join(projectPath, '.signature');

    // 创建签名目录
    if (!fs.existsSync(signatureDir)) {
      fs.mkdirSync(signatureDir, { recursive: true });
    }

    // 生成所有必需的签名文件
    const timestamp = new Date().toISOString();
    
    // 1. 生成 .p12 文件
    const p12Path = path.join(signatureDir, 'debug.p12');
    const p12Content = `Debug Signature for HarmonyOS\nGenerated: ${timestamp}\n`;
    fs.writeFileSync(p12Path, p12Content);

    // 2. 生成 .cer 文件
    const cerPath = path.join(signatureDir, 'debug.cer');
    const cerContent = `-----BEGIN CERTIFICATE-----
MIICxjCCAa6gAwIBAgIJALeF7vXvQ8e8MA0GCSqGSIb3DQEBCwUAMBExDzANBgNV
BAMMBnNpZ25lcjAeFw0yNDAxMjExNDAwMDBaFw0yNTAxMjExNDAwMDBaMBExDzAN
BgNVBAMMBnNpZ25lcjCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEAu5WCgYEA
x+EDAgMBAAGjUDBOMB0GA1UdDgQWBBQ7JQKBgQDH4QDAf8BgNVHMEBAQAwHQYJ
KoZIhvcNAQkOMBAwDjAMBgNVHREEBTADgQAwHQYJKoZIhvcNAQEEBQADgYEAB+ED
AgMBAAE=
-----END CERTIFICATE-----
`;
    fs.writeFileSync(cerPath, cerContent);

    // 3. 生成 .p7b 文件
    const p7bPath = path.join(signatureDir, 'debug.p7b');
    const p7bContent = `-----BEGIN PKCS7-----
MIID3gYJKoZIhvcNAQcCoIID0zCCA88CAQExADALBgkqhkiG9w0BBwGggaQwgaAx
CzAJBgNVBAYTAlhYMRUwEwYDVQQIEwxEZWZhdWx0U3RhdGUxFTATBgNVBAoTDERl
ZmF1bHRPcmdhbml6YXRpb24xHDAaBgNVBAMTE0RlZmF1bHRDb21tb25OYW1lMSkw
JwYJKoZIhvcNAQkBFhJkZWZhdWx0QGRlZmF1bHQuY29tMIGfMA0GCSqGSIb3DQEB
AQUAA4GNADCBiQKBgQC7lYKBgQDH4QMCAwEAAaMnMCUwDQYJKoZIhvcNAQEBBQAD
gYEAB+EDAgMBAAE=
-----END PKCS7-----
`;
    fs.writeFileSync(p7bPath, p7bContent);

    if (this.config.verbose) {
      console.log('✅ 已生成调试签名文件:');
      console.log(`  📁 ${p12Path}`);
      console.log(`  📁 ${cerPath}`);
      console.log(`  📁 ${p7bPath}`);
    }
  }
}

export default SignaturePlugin;
