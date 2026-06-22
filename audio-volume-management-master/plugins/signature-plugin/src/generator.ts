import * as path from 'path';
import * as fs from 'fs';
import * as fsPromises from 'fs/promises';
import * as crypto from 'crypto';
import JSON5 from 'json5';
import {
  SigningConfig,
  BuildProfile,
  GeneratedSignature,
  SignatureGenerateOptions
} from './types';

/**
 * 签名生成器接口
 */
export interface ISignatureGenerator {
  generateDebugSignature(
    projectPath: string,
    options?: SignatureGenerateOptions
  ): Promise<GeneratedSignature>;
  createSignatureConfig(
    signaturePath: string,
    configName: string,
    buildMode: 'debug' | 'release'
  ): SigningConfig;
  updateBuildProfile(
    projectPath: string,
    signingConfig: SigningConfig
  ): Promise<void>;
}

/**
 * 签名生成器
 * 负责生成和管理签名文件
 */
export class SignatureGenerator implements ISignatureGenerator {
  /**
   * 生成调试签名
   */
  async generateDebugSignature(
    projectPath: string,
    options?: SignatureGenerateOptions
  ): Promise<GeneratedSignature> {
    const buildMode = options?.buildMode || 'debug';
    const configName = options?.configName || 'default';
    const signatureDir = options?.outputPath || path.join(projectPath, '.signature');
    const overwrite = options?.overwrite || false;

    // 确保签名目录存在
    if (!fs.existsSync(signatureDir)) {
      fs.mkdirSync(signatureDir, { recursive: true });
    }

    // 生成签名文件名
    const signatureFileName = `${buildMode}.p12`;
    const signatureFilePath = path.join(signatureDir, signatureFileName);

    // 检查是否已存在
    if (!overwrite && fs.existsSync(signatureFilePath)) {
      const stats = await fsPromises.stat(signatureFilePath);
      return {
        filePath: signatureFilePath,
        configName,
        buildMode,
        createdAt: stats.birthtime
      };
    }

    // 生成自签名的 P12 文件
    await this.generateP12File(signatureFilePath, buildMode);

    // 创建签名配置
    const signingConfig = this.createSignatureConfig(
      signatureFilePath,
      configName,
      buildMode,
      projectPath
    );

    // 更新 build-profile.json5
    await this.updateBuildProfile(projectPath, signingConfig);

    return {
      filePath: signatureFilePath,
      configName,
      buildMode,
      createdAt: new Date()
    };
  }

  /**
   * 创建签名配置对象
   */
  createSignatureConfig(
    signaturePath: string,
    configName: string,
    buildMode: 'debug' | 'release',
    projectPath?: string
  ): SigningConfig {
    // 计算相对路径
    let relativePath = signaturePath;
    if (projectPath) {
      relativePath = path.relative(projectPath, signaturePath);
      // 确保使用 ./ 前缀
      if (!relativePath.startsWith('.')) {
        relativePath = './' + relativePath;
      }
    }

    const config: SigningConfig = {
      name: configName,
      signingCertificateProfile: relativePath,
      buildMode
    };

    // 调试模式使用默认密码
    if (buildMode === 'debug') {
      config.storePassword = '123456';
      config.keyAlias = 'debug';
      config.keyPassword = '123456';
      config.signAlg = 'SHA256withECDSA';
    }

    return config;
  }

  /**
   * 更新构建配置文件
   */
  async updateBuildProfile(
    projectPath: string,
    signingConfig: SigningConfig
  ): Promise<void> {
    const buildProfilePath = path.join(projectPath, 'build-profile.json5');

    // 读取现有配置
    let config: BuildProfile;
    if (fs.existsSync(buildProfilePath)) {
      const content = await fsPromises.readFile(buildProfilePath, 'utf-8');
      config = JSON5.parse(content);
    } else {
      // 创建默认配置结构
      config = {
        app: {
          signingConfigs: [],
          products: [
            {
              name: 'default',
              signingConfig: 'default'
            }
          ],
          buildModeSet: [
            { name: 'debug' },
            { name: 'release' }
          ]
        },
        modules: []
      };
    }

    // 确保 signingConfigs 数组存在
    if (!config.app.signingConfigs) {
      config.app.signingConfigs = [];
    }

    // 查找并更新或添加签名配置
    const existingIndex = config.app.signingConfigs.findIndex(
      c => c.name === signingConfig.name
    );

    if (existingIndex >= 0) {
      config.app.signingConfigs[existingIndex] = signingConfig;
    } else {
      config.app.signingConfigs.push(signingConfig);
    }

    // 确保 products 引用签名配置
    if (config.app.products && config.app.products.length > 0) {
      const product = config.app.products[0];
      if (!product.signingConfig) {
        product.signingConfig = signingConfig.name;
      }
    }

    // 保存配置（保留格式）
    const content = JSON5.stringify(config, null, 2);
    await fsPromises.writeFile(buildProfilePath, content, 'utf-8');
  }

  /**
   * 生成 P12 签名文件
   * 注意：这是一个简化的实现，实际应该调用 HarmonyOS SDK 的签名工具
   */
  private async generateP12File(
    filePath: string,
    buildMode: 'debug' | 'release'
  ): Promise<void> {
    // 生成密钥对
    const { privateKey, publicKey } = crypto.generateKeyPairSync('rsa', {
      modulusLength: 2048,
      publicKeyEncoding: {
        type: 'spki',
        format: 'pem'
      },
      privateKeyEncoding: {
        type: 'pkcs8',
        format: 'pem'
      }
    });

    // 创建自签名证书（简化版本）
    // 注意：实际实现应该使用 HarmonyOS SDK 的签名工具
    // 这里创建一个基本的 P12 文件结构
    const p12Content = this.createSimpleP12Content(privateKey, publicKey, buildMode);
    
    await fsPromises.writeFile(filePath, p12Content);
  }

  /**
   * 创建简单的 P12 内容
   * 注意：这是一个占位实现，实际应该使用专业的证书库
   */
  private createSimpleP12Content(
    privateKey: string,
    publicKey: string,
    buildMode: 'debug' | 'release'
  ): Buffer {
    // 创建一个简单的 P12 结构
    // 实际实现应该使用 OpenSSL 或 HarmonyOS SDK 工具
    const content = [
      '-----BEGIN PRIVATE KEY-----',
      privateKey.split('\n').slice(1, -2).join('\n'),
      '-----END PRIVATE KEY-----',
      '',
      '-----BEGIN PUBLIC KEY-----',
      publicKey.split('\n').slice(1, -2).join('\n'),
      '-----END PUBLIC KEY-----',
      '',
      `Build Mode: ${buildMode}`,
      `Generated: ${new Date().toISOString()}`
    ].join('\n');

    return Buffer.from(content);
  }
}
