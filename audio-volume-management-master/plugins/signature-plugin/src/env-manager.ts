import * as path from 'path';
import * as fs from 'fs';
import * as fsPromises from 'fs/promises';
import dotenv from 'dotenv';
import { EnvironmentType, EnvironmentConfig, SigningConfig } from './types';

/**
 * 环境管理器接口
 */
export interface IEnvironmentManager {
  detectEnvironment(): EnvironmentType;
  loadEnvConfig(envFile?: string): Promise<EnvironmentConfig>;
  resolveConfig(projectPath: string): Promise<SigningConfig>;
}

/**
 * 环境管理器
 * 负责管理多环境配置
 */
export class EnvironmentManager implements IEnvironmentManager {
  private projectPath: string;

  constructor(projectPath: string) {
    this.projectPath = projectPath;
  }

  /**
   * 检测当前环境
   */
  detectEnvironment(): EnvironmentType {
    // 优先级：环境变量 > .env 文件 > 默认值
    
    // 1. 检查环境变量
    const env = process.env.HARMONYOS_ENV || process.env.NODE_ENV;
    if (env === 'production') {
      return 'production';
    } else if (env === 'testing' || env === 'test') {
      return 'testing';
    }

    // 2. 检查 .env 文件
    const envPath = path.join(this.projectPath, '.env');
    if (fs.pathExistsSync(envPath)) {
      const envConfig = dotenv.parse(fs.readFileSync(envPath, 'utf-8'));
      if (envConfig.HARMONYOS_ENV === 'production') {
        return 'production';
      } else if (envConfig.HARMONYOS_ENV === 'testing') {
        return 'testing';
      }
    }

    // 3. 默认为开发环境
    return 'development';
  }

  /**
   * 加载环境配置文件
   */
  async loadEnvConfig(envFile?: string): Promise<EnvironmentConfig> {
    const env = this.detectEnvironment();
    
    // 确定环境文件路径
    let envPath: string;
    if (envFile) {
      envPath = path.isAbsolute(envFile) 
        ? envFile 
        : path.join(this.projectPath, envFile);
    } else {
      // 按优先级查找环境文件
      const envFiles = [
        `.env.${env}.local`,
        `.env.${env}`,
        '.env.local',
        '.env'
      ];

      envPath = '';
      for (const file of envFiles) {
        const filePath = path.join(this.projectPath, file);
        if (fs.existsSync(filePath)) {
          envPath = filePath;
          break;
        }
      }
    }

    // 如果没有找到环境文件，返回默认配置
    if (!envPath || !fs.existsSync(envPath)) {
      return {
        type: env,
        signaturePath: './.signature/debug.p12',
        buildMode: 'debug'
      };
    }

    // 解析环境文件
    const content = await fsPromises.readFile(envPath, 'utf-8');
    const envVars = dotenv.parse(content);

    return {
      type: env,
      signaturePath: envVars.HARMONYOS_SIGNATURE_PATH,
      signaturePassword: envVars.HARMONYOS_SIGNATURE_PASSWORD,
      buildMode: envVars.HARMONYOS_BUILD_MODE === 'release' ? 'release' : 'debug'
    };
  }

  /**
   * 按优先级解析最终配置
   */
  async resolveConfig(projectPath: string): Promise<SigningConfig> {
    // 1. 检查环境变量（最高优先级）
    const envSignaturePath = process.env.HARMONYOS_SIGNATURE_PATH;
    const envSignaturePassword = process.env.HARMONYOS_SIGNATURE_PASSWORD;
    const envBuildMode = process.env.HARMONYOS_BUILD_MODE;

    if (envSignaturePath) {
      return {
        name: 'default',
        signingCertificateProfile: envSignaturePath,
        storePassword: envSignaturePassword,
        buildMode: envBuildMode === 'release' ? 'release' : 'debug'
      };
    }

    // 2. 检查项目配置文件
    const envConfig = await this.loadEnvConfig();
    
    if (envConfig.signaturePath) {
      return {
        name: 'default',
        signingCertificateProfile: envConfig.signaturePath,
        storePassword: envConfig.signaturePassword,
        buildMode: envConfig.buildMode || 'debug'
      };
    }

    // 3. 使用默认配置（最低优先级）
    const env = this.detectEnvironment();
    return {
      name: 'default',
      signingCertificateProfile: `./.signature/${env === 'production' ? 'release' : 'debug'}.p12`,
      buildMode: env === 'production' ? 'release' : 'debug'
    };
  }

  /**
   * 创建环境配置文件
   */
  async createEnvFile(
    env: EnvironmentType,
    config: Partial<EnvironmentConfig>
  ): Promise<void> {
    const envFileName = `.env.${env}`;
    const envPath = path.join(this.projectPath, envFileName);

    const lines: string[] = [
      `# HarmonyOS 签名配置 - ${env} 环境`,
      `HARMONYOS_ENV=${env}`,
      ''
    ];

    if (config.signaturePath) {
      lines.push(`HARMONYOS_SIGNATURE_PATH=${config.signaturePath}`);
    }

    if (config.signaturePassword) {
      lines.push(`HARMONYOS_SIGNATURE_PASSWORD=${config.signaturePassword}`);
    }

    if (config.buildMode) {
      lines.push(`HARMONYOS_BUILD_MODE=${config.buildMode}`);
    }

    await fsPromises.writeFile(envPath, lines.join('\n'), 'utf-8');
  }

  /**
   * 获取所有环境配置
   */
  async getAllEnvConfigs(): Promise<Map<EnvironmentType, EnvironmentConfig>> {
    const configs = new Map<EnvironmentType, EnvironmentConfig>();

    const envs: EnvironmentType[] = ['development', 'testing', 'production'];

    for (const env of envs) {
      const envPath = path.join(this.projectPath, `.env.${env}`);
      
      if (fs.existsSync(envPath)) {
        const config = await this.loadEnvConfig(`.env.${env}`);
        configs.set(env, config);
      }
    }

    return configs;
  }
}
