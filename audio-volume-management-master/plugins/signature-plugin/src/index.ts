import * as path from 'path';
import { SignatureDetector } from './detector';
import { SignatureGenerator } from './generator';
import { ConfigManager } from './config-manager';
import { EnvironmentManager } from './env-manager';
import { TemplateEngine } from './template-engine';
import { SignaturePluginConfig, SignatureStatus } from './types';

/**
 * HarmonyOS 签名自动配置插件
 */
export class SignaturePlugin {
  private config: SignaturePluginConfig;
  private detector: SignatureDetector;
  private generator: SignatureGenerator;
  private configManager: ConfigManager;
  private envManager: EnvironmentManager | null = null;
  private templateEngine: TemplateEngine;
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
    this.detector = new SignatureDetector();
    this.generator = new SignatureGenerator();
    this.configManager = new ConfigManager();
    this.templateEngine = new TemplateEngine();
  }

  /**
   * 应用插件到 Hvigor 目标
   * 注意：这是一个简化的实现，实际需要根据 Hvigor API 调整
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

    // 检测签名配置
    const status = await this.detector.checkSignatureConfig(projectPath);

    if (status.status === 'configured') {
      if (this.config.verbose) {
        console.log('✅ 签名配置正常');
      }
      return;
    }

    // 如果未配置且启用了自动生成
    if (status.status === 'not_configured' && this.config.autoGenerate) {
      if (this.config.verbose) {
        console.log('⚠️  签名未配置，正在自动生成...');
      }

      await this.generateDefaultSignature(projectPath);
    } else if (status.status === 'file_missing') {
      console.error('❌ 签名文件缺失:', status.details?.missingFiles);
      
      if (this.config.autoGenerate) {
        console.log('正在重新生成签名文件...');
        await this.generateDefaultSignature(projectPath);
      }
    } else {
      console.error('❌ 签名配置无效:', status.message);
    }
  }

  /**
   * 处理构建后逻辑
   */
  private async handleAfterBuild(context: any): Promise<void> {
    if (this.config.verbose) {
      const projectPath = context?.projectPath || this.projectPath;
      const status = await this.detector.checkSignatureConfig(projectPath);
      
      console.log('📊 签名状态:', status.message);
    }
  }

  /**
   * 注册自定义任务
   */
  private registerTasks(target: any): void {
    // 检查签名任务
    if (target.registerTask) {
      target.registerTask({
        name: 'checkSignature',
        description: '检查签名配置状态',
        action: async () => {
          await this.checkSignature();
        }
      });

      // 生成签名任务
      target.registerTask({
        name: 'generateSignature',
        description: '生成调试签名',
        action: async () => {
          await this.generateSignature();
        }
      });

      // 配置签名任务
      target.registerTask({
        name: 'configSignature',
        description: '配置签名参数',
        action: async (options: any) => {
          await this.configSignature(options);
        }
      });
    }
  }

  /**
   * 检查签名配置
   */
  async checkSignature(): Promise<SignatureStatus> {
    const status = await this.detector.checkSignatureConfig(this.projectPath);
    
    console.log('\n📋 签名配置检查结果:');
    console.log(`状态: ${this.getStatusEmoji(status.status)} ${status.status}`);
    console.log(`消息: ${status.message}`);

    if (status.details?.missingFiles) {
      console.log('\n缺失的文件:');
      status.details.missingFiles.forEach(file => {
        console.log(`  - ${file}`);
      });
    }

    const diagnostic = await this.detector.getDiagnosticInfo(this.projectPath);
    
    if (diagnostic.recommendations.length > 0) {
      console.log('\n💡 建议:');
      diagnostic.recommendations.forEach(rec => {
        console.log(`  - ${rec}`);
      });
    }

    console.log('');
    return status;
  }

  /**
   * 生成签名
   */
  async generateSignature(): Promise<void> {
    console.log('\n🔐 生成签名文件...');
    
    await this.generateDefaultSignature(this.projectPath);
    
    console.log('✅ 签名生成完成\n');
  }

  /**
   * 配置签名
   */
  async configSignature(options: any): Promise<void> {
    console.log('\n⚙️  配置签名参数...');
    
    // 实现配置逻辑
    if (options.env) {
      this.envManager = new EnvironmentManager(this.projectPath);
      await this.envManager.createEnvFile(options.env, {
        signaturePath: options.signaturePath,
        signaturePassword: options.signaturePassword,
        buildMode: options.buildMode
      });
      
      console.log(`✅ 已创建 ${options.env} 环境配置文件`);
    }
    
    console.log('');
  }

  /**
   * 生成默认签名
   */
  private async generateDefaultSignature(projectPath: string): Promise<void> {
    const signatureDir = this.config.signaturePath 
      ? path.resolve(projectPath, this.config.signaturePath)
      : path.join(projectPath, '.signature');

    await this.generator.generateDebugSignature(projectPath, {
      buildMode: 'debug',
      configName: 'default',
      outputPath: signatureDir,
      overwrite: false
    });

    if (this.config.verbose) {
      console.log('✅ 已生成调试签名');
      console.log(`📁 签名文件位置: ${signatureDir}`);
    }
  }

  /**
   * 获取状态表情符号
   */
  private getStatusEmoji(status: string): string {
    switch (status) {
      case 'configured':
        return '✅';
      case 'not_configured':
        return '⚠️';
      case 'file_missing':
        return '❌';
      case 'invalid':
        return '❌';
      default:
        return '❓';
    }
  }
}

// 导出所有类型和类
export * from './types';
export { SignatureDetector } from './detector';
export { SignatureGenerator } from './generator';
export { ConfigManager } from './config-manager';
export { EnvironmentManager } from './env-manager';
export { TemplateEngine } from './template-engine';
