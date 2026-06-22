/**
 * HarmonyOS 自动卸载插件
 * 在安装前自动卸载旧版本应用，解决签名不一致问题
 */

import * as child_process from 'child_process';
import * as path from 'path';
import * as fs from 'fs';

export interface AutoUninstallPluginConfig {
  packageName?: string;
  hdcPath?: string;
  autoUninstall?: boolean;
  autoInstall?: boolean;
  autoStart?: boolean;
  verbose?: boolean;
}

export class AutoUninstallPlugin {
  private config: AutoUninstallPluginConfig;
  private projectPath: string;

  constructor(config: AutoUninstallPluginConfig = {}) {
    this.config = {
      packageName: 'com.example.audiostreamvolumemanagement',
      hdcPath: 'D:\\DevEco Studio\\tools\\hdc\\hdc.exe',
      autoUninstall: true,
      autoInstall: true,
      autoStart: true,
      verbose: true,
      ...config
    };
    this.projectPath = process.cwd();
  }

  /**
   * 应用插件到 Hvigor 目标
   */
  apply(target: any): void {
    // 注册 afterBuild 钩子 - 构建完成后自动部署
    if (target.afterBuild) {
      target.afterBuild(async (context: any) => {
        if (this.config.autoInstall) {
          await this.handleAfterBuild(context);
        }
      });
    }

    // 注册自定义任务
    this.registerTasks(target);
  }

  /**
   * 处理构建后逻辑
   */
  private async handleAfterBuild(context: any): Promise<void> {
    const projectPath = context?.projectPath || this.projectPath;

    if (this.config.verbose) {
      console.log('\n========================================');
      console.log('  开始自动部署流程');
      console.log('========================================\n');
    }

    // 1. 检查设备连接
    if (!await this.checkDevice()) {
      console.error('❌ 设备未连接，跳过自动部署');
      console.log('提示：请确保设备已通过USB连接并开启开发者模式\n');
      return;
    }

    // 2. 卸载旧版本
    if (this.config.autoUninstall) {
      await this.uninstallApp();
    }

    // 3. 安装新版本
    const installed = await this.installApp(projectPath);
    
    // 4. 启动应用
    if (installed && this.config.autoStart) {
      await this.startApp();
    }

    if (this.config.verbose) {
      console.log('\n========================================');
      console.log('  自动部署完成');
      console.log('========================================\n');
    }
  }

  /**
   * 注册自定义任务
   */
  private registerTasks(target: any): void {
    if (target.registerTask) {
      target.registerTask({
        name: 'uninstall',
        description: '卸载应用',
        action: async () => {
          await this.uninstallApp();
        }
      });

      target.registerTask({
        name: 'install',
        description: '安装应用',
        action: async () => {
          const projectPath = this.projectPath;
          await this.installApp(projectPath);
        }
      });

      target.registerTask({
        name: 'deploy',
        description: '完整部署（卸载+安装+启动）',
        action: async () => {
          if (!await this.checkDevice()) {
            return;
          }
          await this.uninstallApp();
          const installed = await this.installApp(this.projectPath);
          if (installed) {
            await this.startApp();
          }
        }
      });
    }
  }

  /**
   * 执行 HDC 命令
   */
  private execHdc(args: string): Promise<{ success: boolean; output: string }> {
    return new Promise((resolve) => {
      const hdcPath = this.config.hdcPath!;
      const command = `"${hdcPath}" ${args}`;
      
      child_process.exec(command, { encoding: 'utf-8' }, (error, stdout, stderr) => {
        if (error) {
          resolve({ success: false, output: stderr || error.message });
        } else {
          resolve({ success: true, output: stdout });
        }
      });
    });
  }

  /**
   * 检查设备连接
   */
  private async checkDevice(): Promise<boolean> {
    const result = await this.execHdc('list targets');
    return result.success && result.output.trim().length > 0;
  }

  /**
   * 卸载应用
   */
  private async uninstallApp(): Promise<void> {
    if (this.config.verbose) {
      console.log('📦 [步骤1] 卸载旧版本应用...');
    }

    const result = await this.execHdc(`shell bm uninstall -n ${this.config.packageName}`);
    
    if (result.success) {
      if (this.config.verbose) {
        console.log('✅ 卸载成功\n');
      }
    } else {
      if (this.config.verbose) {
        console.log('ℹ️  设备上未安装该应用，跳过卸载\n');
      }
    }
  }

  /**
   * 安装应用
   */
  private async installApp(projectPath: string): Promise<boolean> {
    if (this.config.verbose) {
      console.log('📦 [步骤2] 安装新版本应用...');
    }

    // 查找 HAP 文件
    const hapPath = this.findHapFile(projectPath);
    if (!hapPath) {
      console.error('❌ 未找到 HAP 文件');
      console.log('请先构建项目\n');
      return false;
    }

    if (this.config.verbose) {
      console.log(`📁 HAP文件: ${hapPath}`);
    }

    // 创建临时目录
    const tempDir = `data/local/tmp/deploy_${Date.now()}`;
    await this.execHdc(`shell mkdir ${tempDir}`);

    // 发送 HAP 文件
    const sendResult = await this.execHdc(`file send "${hapPath}" ${tempDir}`);
    if (!sendResult.success) {
      console.error('❌ 文件传输失败:', sendResult.output);
      await this.execHdc(`shell rm -rf ${tempDir}`);
      return false;
    }

    // 安装应用
    const installResult = await this.execHdc(`shell bm install -p ${tempDir}`);
    
    // 清理临时目录
    await this.execHdc(`shell rm -rf ${tempDir}`);

    if (installResult.success) {
      if (this.config.verbose) {
        console.log('✅ 安装成功\n');
      }
      return true;
    } else {
      console.error('❌ 安装失败:', installResult.output);
      return false;
    }
  }

  /**
   * 启动应用
   */
  private async startApp(): Promise<void> {
    if (this.config.verbose) {
      console.log('🚀 [步骤3] 启动应用...');
    }

    const result = await this.execHdc(
      `shell aa start -a EntryAbility -b ${this.config.packageName}`
    );

    if (result.success) {
      if (this.config.verbose) {
        console.log('✅ 应用已启动\n');
      }
    } else {
      console.error('❌ 启动失败:', result.output);
      console.log('请手动启动应用\n');
    }
  }

  /**
   * 查找 HAP 文件
   */
  private findHapFile(projectPath: string): string | null {
    const possiblePaths = [
      path.join(projectPath, 'entry/build/default/outputs/default/entry-default-signed.hap'),
      path.join(projectPath, 'entry/build/default/outputs/default/entry-default-unsigned.hap'),
      path.join(projectPath, 'build/default/outputs/default/entry-default-signed.hap'),
    ];

    for (const hapPath of possiblePaths) {
      if (fs.existsSync(hapPath)) {
        return hapPath;
      }
    }

    return null;
  }
}

export default AutoUninstallPlugin;
