/**
 * 设备能力管理器
 * 实现功能级一多开发
 */
import abilityAccessCtrl, { PermissionRequestResult } from '@ohos.abilityAccessCtrl';
import bundleManager from '@ohos.bundle.bundleManager';

/**
 * 系统能力定义
 */
export enum SystemCapability {
  // 音频相关
  AUDIO_VOLUME = 'SystemCapability.Multimedia.Audio.Volume',
  AUDIO_RENDERER = 'SystemCapability.Multimedia.Audio.Renderer',
  AUDIO_CAPTURE = 'SystemCapability.Multimedia.Audio.Capture',
  
  // 通信相关
  NFC_CORE = 'SystemCapability.Communication.NFC.Core',
  BLUETOOTH_CORE = 'SystemCapability.Communication.Bluetooth.Core',
  WIFI_CORE = 'SystemCapability.Communication.WiFi.Core',
  
  // 位置相关
  LOCATION_CORE = 'SystemCapability.Location.LocationCore',
  LOCATION_GEOCODE = 'SystemCapability.Location.LocationGeocode',
  
  // 相机相关
  CAMERA_CORE = 'SystemCapability.Multimedia.Camera.Core',
  
  // 传感器相关
  SENSOR_ACCELEROMETER = 'SystemCapability.SensorService.Core',
  
  // 存储相关
  FILE_MANAGER = 'SystemCapability.FileManagement.FileService',
  
  // 后台任务
  BACKGROUND_TASK = 'SystemCapability.ResourceSchedule.BackgroundTaskManager'
}

/**
 * 设备能力级别
 */
export enum CapabilityLevel {
  FULL = 'full',      // 完整支持
  PARTIAL = 'partial', // 部分支持
  NONE = 'none'       // 不支持
}

/**
 * 能力检查结果
 */
export interface CapabilityCheckResult {
  capability: SystemCapability;
  supported: boolean;
  level: CapabilityLevel;
  message?: string;
}

/**
 * 设备能力管理器
 */
export class CapabilityManager {
  private static instance: CapabilityManager;
  private capabilityCache: Map<SystemCapability, CapabilityCheckResult> = new Map();

  private constructor() {
    this.initCapabilities();
  }

  /**
   * 获取单例实例
   */
  static getInstance(): CapabilityManager {
    if (!CapabilityManager.instance) {
      CapabilityManager.instance = new CapabilityManager();
    }
    return CapabilityManager.instance;
  }

  /**
   * 初始化能力检查
   */
  private initCapabilities(): void {
    // 检查所有定义的能力
    Object.values(SystemCapability).forEach((capability) => {
      this.checkCapability(capability);
    });
  }

  /**
   * 检查设备是否支持某项能力
   */
  hasCapability(capability: SystemCapability): boolean {
    const result = this.capabilityCache.get(capability);
    return result?.supported ?? false;
  }

  /**
   * 获取能力支持级别
   */
  getCapabilityLevel(capability: SystemCapability): CapabilityLevel {
    const result = this.capabilityCache.get(capability);
    return result?.level ?? CapabilityLevel.NONE;
  }

  /**
   * 检查单个能力
   */
  private checkCapability(capability: SystemCapability): CapabilityCheckResult {
    try {
      const supported = canIUse(capability);
      const result: CapabilityCheckResult = {
        capability: capability,
        supported: supported,
        level: supported ? CapabilityLevel.FULL : CapabilityLevel.NONE,
        message: supported ? '设备支持此能力' : '设备不支持此能力'
      };
      
      this.capabilityCache.set(capability, result);
      return result;
    } catch (error) {
      const result: CapabilityCheckResult = {
        capability: capability,
        supported: false,
        level: CapabilityLevel.NONE,
        message: `能力检查失败: ${error}`
      };
      
      this.capabilityCache.set(capability, result);
      return result;
    }
  }

  /**
   * 获取所有支持的能力
   */
  getSupportedCapabilities(): SystemCapability[] {
    const supported: SystemCapability[] = [];
    
    this.capabilityCache.forEach((result, capability) => {
      if (result.supported) {
        supported.push(capability);
      }
    });
    
    return supported;
  }

  /**
   * 获取所有不支持的能力
   */
  getUnsupportedCapabilities(): SystemCapability[] {
    const unsupported: SystemCapability[] = [];
    
    this.capabilityCache.forEach((result, capability) => {
      if (!result.supported) {
        unsupported.push(capability);
      }
    });
    
    return unsupported;
  }

  /**
   * 批量检查能力
   */
  checkCapabilities(capabilities: SystemCapability[]): Map<SystemCapability, boolean> {
    const results = new Map<SystemCapability, boolean>();
    
    capabilities.forEach((capability) => {
      results.set(capability, this.hasCapability(capability));
    });
    
    return results;
  }

  /**
   * 是否支持音量控制
   */
  hasVolumeControl(): boolean {
    return this.hasCapability(SystemCapability.AUDIO_VOLUME);
  }

  /**
   * 是否支持音频播放
   */
  hasAudioRenderer(): boolean {
    return this.hasCapability(SystemCapability.AUDIO_RENDERER);
  }

  /**
   * 是否支持NFC
   */
  hasNFC(): boolean {
    return this.hasCapability(SystemCapability.NFC_CORE);
  }

  /**
   * 是否支持蓝牙
   */
  hasBluetooth(): boolean {
    return this.hasCapability(SystemCapability.BLUETOOTH_CORE);
  }

  /**
   * 是否支持位置服务
   */
  hasLocation(): boolean {
    return this.hasCapability(SystemCapability.LOCATION_CORE);
  }

  /**
   * 是否支持相机
   */
  hasCamera(): boolean {
    return this.hasCapability(SystemCapability.CAMERA_CORE);
  }

  /**
   * 是否支持后台任务
   */
  hasBackgroundTask(): boolean {
    return this.hasCapability(SystemCapability.BACKGROUND_TASK);
  }

  /**
   * 获取能力报告
   */
  getCapabilityReport(): string {
    const supported = this.getSupportedCapabilities();
    const unsupported = this.getUnsupportedCapabilities();
    
    let report = '=== 设备能力报告 ===\n';
    report += `\n支持的能力 (${supported.length}):\n`;
    supported.forEach((cap) => {
      report += `  ✓ ${cap}\n`;
    });
    
    report += `\n不支持的能力 (${unsupported.length}):\n`;
    unsupported.forEach((cap) => {
      report += `  ✗ ${cap}\n`;
    });
    
    return report;
  }

  /**
   * 打印能力报告
   */
  printCapabilityReport(): void {
    console.info(this.getCapabilityReport());
  }
}

/**
 * 功能降级策略
 */
export class FallbackStrategy {
  /**
   * 执行功能,支持降级
   */
  static executeWithFallback<T>(
    capability: SystemCapability,
    primaryAction: () => T,
    fallbackAction?: () => T,
    unsupportedMessage?: string
  ): T | undefined {
    const capabilityManager = CapabilityManager.getInstance();
    
    if (capabilityManager.hasCapability(capability)) {
      try {
        return primaryAction();
      } catch (error) {
        console.error(`Primary action failed: ${error}`);
        if (fallbackAction) {
          return fallbackAction();
        }
        return undefined;
      }
    } else {
      console.warn(unsupportedMessage ?? `设备不支持 ${capability}`);
      if (fallbackAction) {
        return fallbackAction();
      }
      return undefined;
    }
  }

  /**
   * 异步执行功能,支持降级
   */
  static async executeAsyncWithFallback<T>(
    capability: SystemCapability,
    primaryAction: () => Promise<T>,
    fallbackAction?: () => Promise<T>,
    unsupportedMessage?: string
  ): Promise<T | undefined> {
    const capabilityManager = CapabilityManager.getInstance();
    
    if (capabilityManager.hasCapability(capability)) {
      try {
        return await primaryAction();
      } catch (error) {
        console.error(`Primary action failed: ${error}`);
        if (fallbackAction) {
          return await fallbackAction();
        }
        return undefined;
      }
    } else {
      console.warn(unsupportedMessage ?? `设备不支持 ${capability}`);
      if (fallbackAction) {
        return await fallbackAction();
      }
      return undefined;
    }
  }
}

/**
 * 条件执行装饰器
 */
export function requireCapability(capability: SystemCapability, fallbackMessage?: string) {
  return function (
    target: Object,
    propertyKey: string,
    descriptor: PropertyDescriptor
  ) {
    const originalMethod = descriptor.value;
    
    descriptor.value = function (...args: any[]) {
      const capabilityManager = CapabilityManager.getInstance();
      
      if (capabilityManager.hasCapability(capability)) {
        return originalMethod.apply(this, args);
      } else {
        console.warn(fallbackMessage ?? `方法 ${propertyKey} 需要 ${capability} 能力支持`);
        return null;
      }
    };
    
    return descriptor;
  };
}
