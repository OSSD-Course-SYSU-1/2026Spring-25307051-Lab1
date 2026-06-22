import { DeviceInfo } from '../../framework/service/DistributedShareService';
import { Logger } from '../../framework/utils/Logger';

const TAG = 'DeviceSelectDialog';

/**
 * 设备选择对话框
 */
@CustomDialog
export struct DeviceSelectDialog {
  @State devices: DeviceInfo[] = [];
  @State isLoading: boolean = true;
  @State selectedDeviceId: string = '';
  
  controller: CustomDialogController;
  onDeviceSelected?: (deviceId: string) => void;

  aboutToAppear() {
    Logger.info(TAG, 'DeviceSelectDialog aboutToAppear');
  }

  build() {
    Column() {
      // 标题
      Text('选择分享设备')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })

      if (this.isLoading) {
        // 加载中
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color('#007DFF')
          
          Text('正在搜索设备...')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 12 })
        }
        .width('100%')
        .height(200)
        .justifyContent(FlexAlign.Center)
      } else if (this.devices.length === 0) {
        // 无设备
        Column() {
          Text('📱')
            .fontSize(48)
          
          Text('未发现可用设备')
            .fontSize(16)
            .fontColor('#666666')
            .margin({ top: 12 })
          
          Text('请确保其他设备已开启并登录同一华为账号')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 8 })
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .height(200)
        .justifyContent(FlexAlign.Center)
      } else {
        // 设备列表
        List() {
          ForEach(this.devices, (device: DeviceInfo) => {
            ListItem() {
              Row() {
                // 设备图标
                Text(this.getDeviceIcon(device.deviceType))
                  .fontSize(32)
                  .margin({ right: 12 })

                // 设备信息
                Column() {
                  Text(device.deviceName)
                    .fontSize(16)
                    .fontColor('#333333')
                    .fontWeight(FontWeight.Medium)

                  Text(`${device.deviceType} · ${device.networkId.substring(0, 8)}...`)
                    .fontSize(12)
                    .fontColor('#999999')
                    .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                // 选中状态
                if (this.selectedDeviceId === device.deviceId) {
                  Text('✓')
                    .fontSize(20)
                    .fontColor('#007DFF')
                }
              }
              .width('100%')
              .padding(12)
              .backgroundColor(this.selectedDeviceId === device.deviceId ? '#E8F4FF' : '#FFFFFF')
              .borderRadius(8)
              .margin({ bottom: 8 })
              .onClick(() => {
                this.selectedDeviceId = device.deviceId;
              })
            }
          })
        }
        .width('100%')
        .height(280)
        .divider({ strokeWidth: 1, color: '#F0F0F0' })
      }

      // 操作按钮
      Row() {
        Button('取消')
          .width('45%')
          .backgroundColor('#F0F0F0')
          .fontColor('#666666')
          .onClick(() => {
            this.controller.close();
          })

        Button('分享')
          .width('45%')
          .backgroundColor('#007DFF')
          .enabled(this.selectedDeviceId !== '')
          .onClick(() => {
            if (this.onDeviceSelected && this.selectedDeviceId) {
              this.onDeviceSelected(this.selectedDeviceId);
            }
            this.controller.close();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 16 })
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }

  /**
   * 获取设备图标
   */
  private getDeviceIcon(deviceType: string): string {
    switch (deviceType) {
      case '手机':
        return '📱';
      case '平板':
        return '📲';
      case '电视':
        return '📺';
      case '电脑':
        return '💻';
      case '手表':
        return '⌚';
      case '车机':
        return '🚗';
      default:
        return '📱';
    }
  }

  /**
   * 更新设备列表
   */
  updateDevices(devices: DeviceInfo[]) {
    this.devices = devices;
    this.isLoading = false;
  }

  /**
   * 设置加载状态
   */
  setLoading(loading: boolean) {
    this.isLoading = loading;
  }
}
