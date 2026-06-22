/**
 * 设备适配工具类
 * 实现一次开发,多端部署的响应式布局
 */
import display from '@ohos.display';

/**
 * 设备类型枚举
 */
export enum DeviceType {
  PHONE = 'phone',        // 手机
  TABLET = 'tablet',      // 平板
  TV = 'tv',              // 电视
  WEARABLE = 'wearable',  // 手表
  DEFAULT = 'default'     // 默认
}

/**
 * 屏幕方向枚举
 */
export enum Orientation {
  PORTRAIT = 'portrait',   // 竖屏
  LANDSCAPE = 'landscape', // 横屏
  SQUARE = 'square'        // 方形
}

/**
 * 断点配置
 */
export interface BreakpointConfig {
  sm: number;  // 小屏断点 (手机)
  md: number;  // 中屏断点 (平板竖屏)
  lg: number;  // 大屏断点 (平板横屏/电视)
}

/**
 * 设备适配器
 */
export class DeviceAdapter {
  private static instance: DeviceAdapter;
  private screenWidth: number = 0;
  private screenHeight: number = 0;
  private deviceType: DeviceType = DeviceType.DEFAULT;
  private orientation: Orientation = Orientation.PORTRAIT;

  // 断点配置
  private breakpoints: BreakpointConfig = {
    sm: 600,   // < 600vp: 小屏
    md: 840,   // 600-840vp: 中屏
    lg: 840    // > 840vp: 大屏
  };

  private constructor() {
    this.initDevice();
  }

  /**
   * 获取单例实例
   */
  static getInstance(): DeviceAdapter {
    if (!DeviceAdapter.instance) {
      DeviceAdapter.instance = new DeviceAdapter();
    }
    return DeviceAdapter.instance;
  }

  /**
   * 初始化设备信息
   */
  private initDevice(): void {
    try {
      let displayInfo = display.getDefaultDisplaySync();
      this.screenWidth = displayInfo.width;
      this.screenHeight = displayInfo.height;

      // 判断设备类型
      this.deviceType = this.detectDeviceType();

      // 判断屏幕方向
      this.orientation = this.detectOrientation();

      // 监听屏幕变化
      this.listenScreenChange();
    } catch (error) {
      console.error('Failed to init device:', error);
    }
  }

  /**
   * 检测设备类型
   */
  private detectDeviceType(): DeviceType {
    const minSize = Math.min(this.screenWidth, this.screenHeight);
    const maxSize = Math.max(this.screenWidth, this.screenHeight);

    // 根据屏幕尺寸判断设备类型
    if (minSize < 200) {
      return DeviceType.WEARABLE;  // 手表
    } else if (maxSize < 600) {
      return DeviceType.PHONE;     // 手机
    } else if (maxSize < 900) {
      return DeviceType.TABLET;    // 平板
    } else {
      return DeviceType.TV;        // 电视
    }
  }

  /**
   * 检测屏幕方向
   */
  private detectOrientation(): Orientation {
    if (this.screenWidth === this.screenHeight) {
      return Orientation.SQUARE;
    } else if (this.screenWidth > this.screenHeight) {
      return Orientation.LANDSCAPE;
    } else {
      return Orientation.PORTRAIT;
    }
  }

  /**
   * 监听屏幕变化
   */
  private listenScreenChange(): void {
    try {
      display.on('change', (displayId: number) => {
        let displayInfo = display.getDisplayByIdSync(displayId);
        this.screenWidth = displayInfo.width;
        this.screenHeight = displayInfo.height;
        this.deviceType = this.detectDeviceType();
        this.orientation = this.detectOrientation();

        // 通知UI更新
        AppStorage.setOrCreate('screenWidth', this.screenWidth);
        AppStorage.setOrCreate('screenHeight', this.screenHeight);
        AppStorage.setOrCreate('deviceType', this.deviceType);
        AppStorage.setOrCreate('orientation', this.orientation);
      });
    } catch (error) {
      console.error('Failed to listen screen change:', error);
    }
  }

  /**
   * 获取当前断点
   */
  getCurrentBreakpoint(): string {
    const width = this.screenWidth;

    if (width < this.breakpoints.sm) {
      return 'sm';  // 小屏
    } else if (width < this.breakpoints.md) {
      return 'md';  // 中屏
    } else {
      return 'lg';  // 大屏
    }
  }

  /**
   * 是否是小屏设备
   */
  isSmallScreen(): boolean {
    return this.screenWidth < this.breakpoints.sm;
  }

  /**
   * 是否是中屏设备
   */
  isMediumScreen(): boolean {
    return this.screenWidth >= this.breakpoints.sm && this.screenWidth < this.breakpoints.md;
  }

  /**
   * 是否是大屏设备
   */
  isLargeScreen(): boolean {
    return this.screenWidth >= this.breakpoints.lg;
  }

  /**
   * 是否是横屏
   */
  isLandscape(): boolean {
    return this.orientation === Orientation.LANDSCAPE;
  }

  /**
   * 是否是竖屏
   */
  isPortrait(): boolean {
    return this.orientation === Orientation.PORTRAIT;
  }

  /**
   * 获取设备类型
   */
  getDeviceType(): DeviceType {
    return this.deviceType;
  }

  /**
   * 获取屏幕宽度
   */
  getScreenWidth(): number {
    return this.screenWidth;
  }

  /**
   * 获取屏幕高度
   */
  getScreenHeight(): number {
    return this.screenHeight;
  }

  /**
   * 根据设备类型获取列数
   */
  getGridColumns(): number {
    switch (this.deviceType) {
      case DeviceType.WEARABLE:
        return 1;  // 手表: 1列
      case DeviceType.PHONE:
        return this.isLandscape() ? 2 : 1;  // 手机: 竖屏1列,横屏2列
      case DeviceType.TABLET:
        return this.isLandscape() ? 4 : 2;  // 平板: 竖屏2列,横屏4列
      case DeviceType.TV:
        return 6;  // 电视: 6列
      default:
        return 2;
    }
  }

  /**
   * 根据设备类型获取字体缩放比例
   */
  getFontScale(): number {
    switch (this.deviceType) {
      case DeviceType.WEARABLE:
        return 0.8;  // 手表: 缩小
      case DeviceType.PHONE:
        return 1.0;  // 手机: 正常
      case DeviceType.TABLET:
        return 1.2;  // 平板: 放大
      case DeviceType.TV:
        return 1.5;  // 电视: 更大
      default:
        return 1.0;
    }
  }

  /**
   * 根据设备类型获取间距
   */
  getSpacing(): number {
    switch (this.deviceType) {
      case DeviceType.WEARABLE:
        return 8;
      case DeviceType.PHONE:
        return 16;
      case DeviceType.TABLET:
        return 24;
      case DeviceType.TV:
        return 32;
      default:
        return 16;
    }
  }

  /**
   * 是否支持某些功能
   */
  isFeatureSupported(feature: string): boolean {
    switch (feature) {
      case 'timer_task':  // 定时任务功能
        return this.deviceType !== DeviceType.WEARABLE;  // 手表不支持
      case 'task_group':  // 任务组功能
        return this.deviceType === DeviceType.PHONE || 
               this.deviceType === DeviceType.TABLET ||
               this.deviceType === DeviceType.TV;
      case 'volume_panel':  // 音量面板
        return true;  // 所有设备支持
      default:
        return true;
    }
  }
}

/**
 * 响应式布局工具函数
 */
export class ResponsiveLayout {
  /**
   * 根据断点返回不同的值
   */
  static value<T>(sm: T, md: T, lg: T): T {
    const adapter = DeviceAdapter.getInstance();
    const breakpoint = adapter.getCurrentBreakpoint();

    switch (breakpoint) {
      case 'sm':
        return sm;
      case 'md':
        return md;
      case 'lg':
        return lg;
      default:
        return md;
    }
  }

  /**
   * 根据设备类型返回不同的值
   */
  static valueByDevice<T>(phone: T, tablet: T, tv: T, wearable?: T): T {
    const adapter = DeviceAdapter.getInstance();
    const deviceType = adapter.getDeviceType();

    switch (deviceType) {
      case DeviceType.PHONE:
        return phone;
      case DeviceType.TABLET:
        return tablet;
      case DeviceType.TV:
        return tv;
      case DeviceType.WEARABLE:
        return wearable ?? phone;
      default:
        return phone;
    }
  }
}
