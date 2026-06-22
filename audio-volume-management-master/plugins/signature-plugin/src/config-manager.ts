import * as path from 'path';
import * as fs from 'fs';
import * as fsPromises from 'fs/promises';
import JSON5 from 'json5';
import { BuildProfile, SigningConfig } from './types';

/**
 * 配置管理器接口
 */
export interface IConfigManager {
  loadConfig(configPath: string): Promise<BuildProfile>;
  saveConfig(configPath: string, config: BuildProfile): Promise<void>;
  mergeConfig(base: BuildProfile, override: Partial<BuildProfile>): BuildProfile;
  validateConfig(config: BuildProfile): boolean;
}

/**
 * 配置管理器
 * 负责读写和验证配置文件
 */
export class ConfigManager implements IConfigManager {
  /**
   * 加载 JSON5 配置文件
   */
  async loadConfig(configPath: string): Promise<BuildProfile> {
    try {
      if (!fs.existsSync(configPath)) {
        throw new Error(`配置文件不存在: ${configPath}`);
      }

      const content = await fsPromises.readFile(configPath, 'utf-8');
      const config = JSON5.parse(content);

      // 验证配置结构
      if (!this.validateConfig(config)) {
        throw new Error('配置文件格式无效');
      }

      return config;
    } catch (error) {
      throw new Error(`加载配置文件失败: ${error}`);
    }
  }

  /**
   * 保存配置文件（保留格式）
   */
  async saveConfig(configPath: string, config: BuildProfile): Promise<void> {
    try {
      // 验证配置
      if (!this.validateConfig(config)) {
        throw new Error('配置格式无效');
      }

      // 读取现有文件以保留注释和格式
      let existingContent = '';
      if (fs.existsSync(configPath)) {
        existingContent = await fsPromises.readFile(configPath, 'utf-8');
      }

      // 使用 JSON5.stringify 保留格式
      const content = JSON5.stringify(config, null, 2);
      
      await fsPromises.writeFile(configPath, content, 'utf-8');
    } catch (error) {
      throw new Error(`保存配置文件失败: ${error}`);
    }
  }

  /**
   * 合并多个配置源
   */
  mergeConfig(
    base: BuildProfile,
    override: Partial<BuildProfile>
  ): BuildProfile {
    const merged: BuildProfile = {
      app: {
        ...base.app,
        ...override.app,
        signingConfigs: [
          ...(base.app.signingConfigs || []),
          ...(override.app?.signingConfigs || [])
        ],
        products: override.app?.products || base.app.products,
        buildModeSet: override.app?.buildModeSet || base.app.buildModeSet
      },
      modules: override.modules || base.modules
    };

    return merged;
  }

  /**
   * 验证配置有效性
   */
  validateConfig(config: BuildProfile): boolean {
    try {
      // 检查必需的字段
      if (!config.app) {
        return false;
      }

      // 检查 products 数组
      if (!Array.isArray(config.app.products) || config.app.products.length === 0) {
        return false;
      }

      // 检查 signingConfigs 数组（可以为空）
      if (config.app.signingConfigs && !Array.isArray(config.app.signingConfigs)) {
        return false;
      }

      return true;
    } catch (error) {
      return false;
    }
  }

  /**
   * 添加签名配置
   */
  async addSigningConfig(
    configPath: string,
    signingConfig: SigningConfig
  ): Promise<void> {
    const config = await this.loadConfig(configPath);

    // 确保 signingConfigs 数组存在
    if (!config.app.signingConfigs) {
      config.app.signingConfigs = [];
    }

    // 检查是否已存在同名配置
    const existingIndex = config.app.signingConfigs.findIndex(
      c => c.name === signingConfig.name
    );

    if (existingIndex >= 0) {
      // 更新现有配置
      config.app.signingConfigs[existingIndex] = signingConfig;
    } else {
      // 添加新配置
      config.app.signingConfigs.push(signingConfig);
    }

    await this.saveConfig(configPath, config);
  }

  /**
   * 移除签名配置
   */
  async removeSigningConfig(
    configPath: string,
    configName: string
  ): Promise<void> {
    const config = await this.loadConfig(configPath);

    if (!config.app.signingConfigs) {
      return;
    }

    // 过滤掉要移除的配置
    config.app.signingConfigs = config.app.signingConfigs.filter(
      c => c.name !== configName
    );

    await this.saveConfig(configPath, config);
  }

  /**
   * 获取签名配置
   */
  async getSigningConfig(
    configPath: string,
    configName: string
  ): Promise<SigningConfig | undefined> {
    const config = await this.loadConfig(configPath);

    if (!config.app.signingConfigs) {
      return undefined;
    }

    return config.app.signingConfigs.find(c => c.name === configName);
  }
}
