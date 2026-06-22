/**
 * 签名状态类型
 */
export type SignatureStatusType = 
  | 'not_configured'      // 未配置
  | 'configured'          // 已配置
  | 'file_missing'        // 签名文件缺失
  | 'invalid';            // 无效配置

/**
 * 签名状态信息
 */
export interface SignatureStatus {
  status: SignatureStatusType;
  message: string;
  details?: {
    configPath?: string;
    signaturePath?: string;
    missingFiles?: string[];
    errors?: string[];
  };
}

/**
 * 签名配置
 */
export interface SigningConfig {
  name: string;
  signingCertificateProfile?: string;
  buildMode?: 'debug' | 'release';
  storePassword?: string;
  keyAlias?: string;
  keyPassword?: string;
  signAlg?: string;
  profileFile?: string;
  certpathFile?: string;
}

/**
 * 构建配置
 */
export interface BuildProfile {
  app: {
    signingConfigs: SigningConfig[];
    products: Array<{
      name: string;
      signingConfig?: string;
      [key: string]: any;
    }>;
    buildModeSet?: Array<{
      name: string;
      [key: string]: any;
    }>;
    [key: string]: any;
  };
  modules?: any[];
  [key: string]: any;
}

/**
 * 生成的签名信息
 */
export interface GeneratedSignature {
  filePath: string;
  configName: string;
  buildMode: 'debug' | 'release';
  createdAt: Date;
}

/**
 * 签名生成选项
 */
export interface SignatureGenerateOptions {
  buildMode?: 'debug' | 'release';
  configName?: string;
  outputPath?: string;
  overwrite?: boolean;
}

/**
 * 环境类型
 */
export type EnvironmentType = 'development' | 'testing' | 'production';

/**
 * 环境配置
 */
export interface EnvironmentConfig {
  type: EnvironmentType;
  signaturePath?: string;
  signaturePassword?: string;
  buildMode?: 'debug' | 'release';
  [key: string]: any;
}

/**
 * 插件配置
 */
export interface SignaturePluginConfig {
  autoDetect?: boolean;        // 自动检测签名配置
  autoGenerate?: boolean;      // 自动生成调试签名
  signaturePath?: string;      // 签名文件存储路径
  verbose?: boolean;           // 详细日志
  environments?: EnvironmentConfig[]; // 多环境配置
}

/**
 * 模板类型
 */
export type TemplateType = 
  | 'debug' 
  | 'release' 
  | 'multi-env' 
  | 'gitignore'
  | 'env';

/**
 * 诊断信息
 */
export interface DiagnosticInfo {
  projectPath: string;
  buildProfilePath: string;
  signatureStatus: SignatureStatus;
  environment: EnvironmentType;
  recommendations: string[];
}
