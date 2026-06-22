import { Logger } from '../utils/Logger';
import preferences from '@ohos.data.preferences';
import { common } from '@kit.AbilityKit';
import fs from '@ohos.file.fs';
import image from '@ohos.multimedia.image';

const TAG = 'BackgroundService';
const PREF_NAME = 'background_settings';
const KEY_BACKGROUND_PATH = 'background_image_path';

/**
 * 背景图片管理服务
 */
export class BackgroundService {
  private context: common.Context;
  private preferences: preferences.Preferences | null = null;

  constructor(context: common.Context) {
    this.context = context;
  }

  /**
   * 初始化Preferences
   */
  async initialize(): Promise<void> {
    try {
      this.preferences = await preferences.getPreferences(this.context, PREF_NAME);
      Logger.info(TAG, 'BackgroundService initialized');
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to initialize: ${errorMessage}`);
    }
  }

  /**
   * 保存背景图片路径
   */
  async saveBackgroundPath(imagePath: string): Promise<boolean> {
    try {
      if (!this.preferences) {
        await this.initialize();
      }

      if (this.preferences) {
        await this.preferences.put(KEY_BACKGROUND_PATH, imagePath);
        await this.preferences.flush();
        Logger.info(TAG, `Background image saved: ${imagePath}`);
        return true;
      }

      return false;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to save background: ${errorMessage}`);
      return false;
    }
  }

  /**
   * 获取背景图片路径
   */
  async getBackgroundPath(): Promise<string> {
    try {
      if (!this.preferences) {
        await this.initialize();
      }

      if (this.preferences) {
        const path = await this.preferences.get(KEY_BACKGROUND_PATH, '') as string;
        Logger.info(TAG, `Background image path: ${path}`);
        return path;
      }

      return '';
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to get background: ${errorMessage}`);
      return '';
    }
  }

  /**
   * 清除背景图片
   */
  async clearBackground(): Promise<boolean> {
    try {
      if (!this.preferences) {
        await this.initialize();
      }

      if (this.preferences) {
        await this.preferences.delete(KEY_BACKGROUND_PATH);
        await this.preferences.flush();
        Logger.info(TAG, 'Background cleared');
        return true;
      }

      return false;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to clear background: ${errorMessage}`);
      return false;
    }
  }

  /**
   * 复制图片到应用私有目录
   */
  async copyToPrivateDirectory(sourceUri: string): Promise<string> {
    try {
      // 获取应用私有目录
      const privateDir = this.context.filesDir;
      const fileName = `background_${Date.now()}.jpg`;
      const destPath = `${privateDir}/${fileName}`;

      // 复制文件
      const sourceFile = fs.openSync(sourceUri, fs.OpenMode.READ_ONLY);
      const destFile = fs.openSync(destPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);

      const stat = fs.statSync(sourceUri);
      const bufferSize = 4096;
      const totalSize = stat.size;
      let readSize = 0;

      while (readSize < totalSize) {
        const buffer = new ArrayBuffer(bufferSize);
        const readLen = fs.readSync(sourceFile.fd, buffer);
        if (readLen === 0) break;
        
        fs.writeSync(destFile.fd, buffer, { length: readLen });
        readSize += readLen;
      }

      fs.closeSync(sourceFile);
      fs.closeSync(destFile);

      Logger.info(TAG, `Image copied to: ${destPath}`);
      return destPath;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to copy image: ${errorMessage}`);
      return '';
    }
  }

  /**
   * 裁剪图片
   */
  async cropImage(
    sourcePath: string,
    cropX: number,
    cropY: number,
    cropWidth: number,
    cropHeight: number
  ): Promise<string> {
    try {
      // 创建图片源
      const imageSource = image.createImageSource(sourcePath);
      const imageInfo = await imageSource.getImageInfo();

      // 设置裁剪参数
      const decodingOptions: image.DecodingOptions = {
        desiredRegion: {
          x: Math.floor(cropX),
          y: Math.floor(cropY),
          size: {
            width: Math.floor(cropWidth),
            height: Math.floor(cropHeight)
          }
        }
      };

      // 解码裁剪后的图片
      const pixelMap = await imageSource.createPixelMap(decodingOptions);

      // 编码保存
      const imagePackerApi = image.createImagePacker();
      const packOpts: image.PackingOption = {
        format: 'image/jpeg',
        quality: 90
      };

      const packedData = await imagePackerApi.packing(pixelMap, packOpts);

      // 保存到文件
      const privateDir = this.context.filesDir;
      const fileName = `background_cropped_${Date.now()}.jpg`;
      const destPath = `${privateDir}/${fileName}`;

      const file = fs.openSync(destPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
      fs.writeSync(file.fd, packedData);
      fs.closeSync(file);

      // 释放资源
      pixelMap.release();
      imagePackerApi.release();
      imageSource.release();

      Logger.info(TAG, `Image cropped and saved to: ${destPath}`);
      return destPath;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to crop image: ${errorMessage}`);
      return '';
    }
  }
}
