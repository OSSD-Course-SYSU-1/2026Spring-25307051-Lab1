import { Logger } from '../../framework/utils/Logger';
import promptAction from '@ohos.promptAction';

const TAG = 'SessionInputDialog';

/**
 * 会话输入对话框
 * 用于手动输入SessionId加入协同组
 */
@CustomDialog
export struct SessionInputDialog {
  @State sessionIdInput: string = '';
  @State currentSessionId: string = '';
  @State deviceId: string = '';
  @State refreshFlag: number = 0;
  
  controller: CustomDialogController;
  onCreateSession?: () => void;
  onJoinSession?: (sessionId: string) => void;
  onLeaveSession?: () => void;

  aboutToAppear() {
    Logger.info(TAG, 'SessionInputDialog aboutToAppear');
  }
  
  aboutToDisappear() {
    Logger.info(TAG, 'SessionInputDialog aboutToDisappear');
  }

  build() {
    Column() {
      // 标题
      Text('自由流转协同设置')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      // 当前设备信息
      Column() {
        Text('当前设备')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ bottom: 8 })

        Text(this.deviceId || '未初始化')
          .fontSize(12)
          .fontColor('#666666')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(12)
      .backgroundColor('#F5F5F5')
      .borderRadius(8)
      .margin({ bottom: 16 })

      // 当前会话状态
      if (this.currentSessionId) {
        Column() {
          Row() {
            Text('当前会话')
              .fontSize(14)
              .fontColor('#333333')
              .layoutWeight(1)

            Text('已连接')
              .fontSize(12)
              .fontColor('#4CAF50')
          }
          .width('100%')
          .margin({ bottom: 8 })

          Row() {
            Text(this.currentSessionId)
              .fontSize(12)
              .fontColor('#666666')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
            
            // 复制按钮
            Button('复制')
              .fontSize(12)
              .height(28)
              .backgroundColor('#007DFF')
              .fontColor('#FFFFFF')
              .padding({ left: 8, right: 8 })
              .onClick(() => {
                this.copySessionId();
              })
          }
          .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(12)
        .backgroundColor('#E8F5E9')
        .borderRadius(8)
        .margin({ bottom: 16 })
      }

      // 操作区域
      Column() {
        // 创建新会话
        Button('创建新协同组')
          .width('100%')
          .height(44)
          .backgroundColor('#007DFF')
          .fontColor('#FFFFFF')
          .fontSize(16)
          .margin({ bottom: 12 })
          .onClick(() => {
            if (this.onCreateSession) {
              this.onCreateSession();
            }
          })

        // 加入已有会话
        Column() {
          Text('或加入已有协同组')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ bottom: 8 })

          TextInput({ placeholder: '请输入SessionId', text: this.sessionIdInput })
            .width('100%')
            .height(44)
            .fontSize(14)
            .padding({ left: 12, right: 12 })
            .onChange((value: string) => {
              this.sessionIdInput = value;
            })
            .margin({ bottom: 12 })
            .type(InputType.Normal)
            .enterKeyType(EnterKeyType.Done)

          Button('加入协同组')
            .width('100%')
            .height(44)
            .backgroundColor(this.sessionIdInput ? '#007DFF' : '#CCCCCC')
            .fontColor('#FFFFFF')
            .fontSize(16)
            .enabled(!!this.sessionIdInput)
            .onClick(() => {
              if (this.onJoinSession && this.sessionIdInput) {
                this.onJoinSession(this.sessionIdInput);
              }
            })
        }
        .width('100%')
        .margin({ bottom: 16 })

        // 离开会话
        if (this.currentSessionId) {
          Button('离开协同组')
            .width('100%')
            .height(44)
            .backgroundColor('#FF5722')
            .fontColor('#FFFFFF')
            .fontSize(16)
            .onClick(() => {
              if (this.onLeaveSession) {
                this.onLeaveSession();
              }
            })
        }
      }
      .width('100%')

      // 说明文字
      Column() {
        Text('使用说明')
          .fontSize(14)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 8 })

        Text('1. 在设备A点击"创建新协同组"，获取SessionId')
          .fontSize(12)
          .fontColor('#666666')
          .margin({ bottom: 4 })

        Text('2. 将SessionId复制到设备B，点击"加入协同组"')
          .fontSize(12)
          .fontColor('#666666')
          .margin({ bottom: 4 })

        Text('3. 在任一设备分享任务，另一设备将自动接收')
          .fontSize(12)
          .fontColor('#666666')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(12)
      .backgroundColor('#FFF9E6')
      .borderRadius(8)
      .margin({ top: 16 })

      // 关闭按钮
      Button('关闭')
        .width('100%')
        .height(44)
        .backgroundColor('#F0F0F0')
        .fontColor('#666666')
        .fontSize(16)
        .margin({ top: 16 })
        .onClick(() => {
          this.controller.close();
        })
    }
    .width('90%')
    .constraintSize({ minWidth: 280, maxWidth: 360 })
    .alignItems(HorizontalAlign.Center)
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }

  /**
   * 更新会话信息
   */
  updateSessionInfo(sessionId: string, deviceId: string) {
    Logger.info(TAG, `updateSessionInfo called: sessionId=${sessionId}, deviceId=${deviceId}`);
    this.currentSessionId = sessionId;
    this.deviceId = deviceId;
    this.refreshFlag++; // 触发UI刷新
  }
  
  /**
   * 复制SessionId到剪贴板
   */
  private copySessionId() {
    try {
      // 显示SessionId供用户手动复制
      promptAction.showDialog({
        title: 'SessionId',
        message: this.currentSessionId,
        buttons: [
          { text: '已复制', color: '#007DFF' }
        ]
      });
      
      Logger.info(TAG, 'SessionId displayed for manual copy');
    } catch (error) {
      Logger.error(TAG, `Failed to show sessionId: ${JSON.stringify(error)}`);
      promptAction.showToast({
        message: '显示失败，请查看日志',
        duration: 2000
      });
    }
  }
}
