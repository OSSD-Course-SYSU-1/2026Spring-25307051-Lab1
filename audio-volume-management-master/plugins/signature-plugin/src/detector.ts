import * as path from 'path';
import * as fs from 'fs';
import * as fsPromises from 'fs/promises';
import JSON5 from 'json5';
import {
  SignatureStatus,
  SignatureStatusType,
  BuildProfile,
  DiagnosticInfo,
  EnvironmentType
} from './types';

/**
 * 签名检测器接口
 */
export interface ISignatureDetector {
  checkSignatureConfig(projectPath: string): Promise<SignatureStatus>;
  validateSignatureFile(filePath: string): Promise<boolean>;
  getDiagnosticInfo(projectPath: string): Promise<DiagnosticInfo>;
}

/**
 * 签名检测器
 * 负责检测和验证签名配置状态
 */
export class SignatureDetector implements ISignatureDetector {
  /**
   * 检查签名配置状态
   */
  async checkSignatureConfig(projectPath: string): Promise<SignatureStatus> {
    try {
      const buildProfilePath = path.join(projectPath, 'build-profile.json5');
      
      // 检查 build-profile.json5 是否存在
      if (!fs.existsSync(buildProfilePath)) {
        return {
          status: 'not_configured',
          message: 'build-profile.json5 文件不存在',
          details: {
            configPath: buildProfilePath
          }
        };
      }

      // 读取配置文件
      const content = await fsPromises.readFile(buildProfilePath, 'utf-8');
      const config: BuildProfile = JSON5.parse(content);

      // 检查 signingConfigs 数组
      if (!config.app?.signingConfigs || config.app.signingConfigs.length === 0) {
        return {
          status: 'not_configured',
          message: '签名配置为空，需要配置签名',
          details: {
            configPath: buildProfilePath
          }
        };
      }

      // 检查签名文件是否存在
      const missingFiles: string[] = [];
      for (const signingConfig of config.app.signingConfigs) {
        if (signingConfig.signingCertificateProfile) {
          const signaturePath = path.resolve(
            projectPath,
            signingConfig.signingCertificateProfile
          );
          
          if (!fs.existsSync(signaturePath)) {
            missingFiles.push(signaturePath);
          }
        }
      }

      if (missingFiles.length > 0) {
        return {
          status: 'file_missing',
          message: '签名文件缺失',
          details: {
            configPath: buildProfilePath,
            missingFiles
          }
        };
      }

      // 验证签名文件有效性
      for (const signingConfig of config.app.signingConfigs) {
        if (signingConfig.signingCertificateProfile) {
          const signaturePath = path.resolve(
            projectPath,
            signingConfig.signingCertificateProfile
          );
          
          const isValid = await this.validateSignatureFile(signaturePath);
          if (!isValid) {
            return {
              status: 'invalid',
              message: '签名文件无效',
              details: {
                configPath: buildProfilePath,
                signaturePath
              }
            };
          }
        }
      }

      return {
        status: 'configured',
        message: '签名配置正常',
        details: {
          configPath: buildProfilePath
        }
      };

    } catch (error) {
      return {
        status: 'invalid',
        message: `检查签名配置时发生错误: ${error}`,
        details: {
          errors: [String(error)]
        }
      };
    }
  }

  /**
   * 验证签名文件有效性
   */
  async validateSignatureFile(filePath: string): Promise<boolean> {
    try {
      // 检查文件是否存在
      if (!fs.existsSync(filePath)) {
        return false;
      }

      // 检查文件扩展名
      const ext = path.extname(filePath).toLowerCase();
      if (ext !== '.p12' && ext !== '.p7b' && ext !== '.cer') {
        return false;
      }

      // 检查文件大小（签名文件至少应该有几百字节）
      const stats = await fsPromises.stat(filePath);
      if (stats.size < 100) {
        return false;
      }

      return true;
    } catch (error) {
      return false;
    }
  }

  /**
   * 获取诊断信息
   */
  async getDiagnosticInfo(projectPath: string): Promise<DiagnosticInfo> {
    const buildProfilePath = path.join(projectPath, 'build-profile.json5');
    const signatureStatus = await this.checkSignatureConfig(projectPath);
    
    // 检测环境
    const env = this.detectEnvironment();
    
    // 生成建议
    const recommendations: string[] = [];
    
    if (signatureStatus.status === 'not_configured') {
      recommendations.push('建议使用签名插件自动生成调试签名');
      recommendations.push('运行: hvigorw generateSignature');
    } else if (signatureStatus.status === 'file_missing') {
      recommendations.push('签名文件缺失，请重新生成签名文件');
      recommendations.push('或检查签名文件路径配置是否正确');
    } else if (signatureStatus.status === 'invalid') {
      recommendations.push('签名文件无效，请检查文件格式和完整性');
    }

    return {
      projectPath,
      buildProfilePath,
      signatureStatus,
      environment: env,
      recommendations
    };
  }

  /**
   * 检测当前环境
   */
  private detectEnvironment(): EnvironmentType {
    const env = process.env.HARMONYOS_ENV || process.env.NODE_ENV;
    
    if (env === 'production') {
      return 'production';
    } else if (env === 'testing' || env === 'test') {
      return 'testing';
    }
    
    return 'development';
  }
}
