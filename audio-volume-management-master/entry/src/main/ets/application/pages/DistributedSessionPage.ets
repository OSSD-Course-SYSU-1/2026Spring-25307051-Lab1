import { Logger } from '../../framework/utils/Logger';
import { TimerTask } from '../../framework/model/TimerTask';
import { DistributedShareService } from '../../framework/service/DistributedShareService';
import { TimerTaskViewModel } from '../viewModel/TimerTaskViewModel';
import { DeviceInfo } from '../../framework/service/TaskDistributedManager';
import { DeviceAdapter, DeviceType } from '../../framework/utils/DeviceAdapter';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import EntryAbility from '../../entryability/EntryAbility';
import common from '@ohos.app.ability.common';

const TAG = 'DistributedSessionPage';

/**
 * 分布式协同会话页面
 * 显示当前会话状态和接收到的任务
 */
@Entry
@Component
struct DistributedSessionPage {
  @State currentSessionId: string = '';
  @State deviceId: string = '';
  @State sessionIdInput: string = '';
  @State receivedTasks: TimerTask[] = [];
  @State isConnected: boolean = false;
  @State deviceList: DeviceInfo[] = []; // 设备列表
  @State isLargeScreen: boolean = false; // 是否大屏设备
  @State contentPadding: number = 16; // 内容边距
  
  private distributedShareService: DistributedShareService = new DistributedShareService();
  private viewModel: TimerTaskViewModel | null = null;
  private deviceAdapter: DeviceAdapter = DeviceAdapter.getInstance();
  
  async aboutToAppear() {
    Logger.info(TAG, 'DistributedSessionPage aboutToAppear');
    
    try {
      // 初始化设备适配
      this.isLargeScreen = this.deviceAdapter.isLargeScreen();
      this.contentPadding = this.deviceAdapter.getSpacing();
      Logger.info(TAG, `Device adaptation: isLargeScreen=${this.isLargeScreen}, padding=${this.contentPadding}`);
      
      // 初始化服务
      const context = EntryAbility.context as common.UIAbilityContext;
      await this.distributedShareService.initialize(context);
      
      // 获取当前状态
      this.currentSessionId = this.distributedShareService.getSessionId();
      this.deviceId = this.distributedShareService.getDeviceId();
      this.isConnected = !!this.currentSessionId;
      
      // 注册任务接收回调
      this.distributedShareService.setTasksReceivedCallback((tasks: TimerTask[]) => {
        this.onTasksReceived(tasks);
      });
      
      // 注册设备列表更新回调
      this.distributedShareService.setDeviceListCallback((devices: DeviceInfo[]) => {
        this.onDeviceListUpdated(devices);
      });
      
      Logger.info(TAG, `Initial state: sessionId=${this.currentSessionId}, connected=${this.isConnected}`);
    } catch (error) {
      Logger.error(TAG, `Failed to initialize: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 设备列表更新
   */
  private onDeviceListUpdated(devices: DeviceInfo[]) {
    Logger.info(TAG, `=== DEVICE LIST UPDATED ===`);
    Logger.info(TAG, `Devices count: ${devices.length}`);
    
    this.deviceList = devices;
    
    for (let i = 0; i < devices.length; i++) {
      const device = devices[i];
      Logger.info(TAG, `Device ${i}: ${device.deviceId}, joinTime: ${device.joinTime}`);
    }
    
    promptAction.showToast({
      message: `协同组有 ${devices.length} 个设备`,
      duration: 2000
    });
  }
  
  build() {
    Column() {
      // 顶部空白区域，避免被摄像头遮挡
      Blank()
        .height(32)
      
      // 顶部导航栏
      Row() {
        Button('返回')
          .fontSize(16)
          .backgroundColor('#F0F0F0')
          .fontColor('#333333')
          .onClick(() => {
            router.back();
          })
        
        Text('自由流转协同')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        
        Blank().width(60)
      }
      .width('100%')
      .height(56)
      .padding({ left: this.contentPadding, right: this.contentPadding })
      
      Scroll() {
        Column() {
          // 设备信息卡片
          this.DeviceInfoCard()
          
          // 会话状态卡片
          if (this.isConnected) {
            this.ConnectedSessionCard()
          } else {
            this.ConnectSessionCard()
          }
          
          // 接收到的任务列表
          if (this.receivedTasks.length > 0) {
            this.ReceivedTasksCard()
          }
          
          // 使用说明
          this.UsageGuideCard()
        }
        .width('100%')
        .padding({ left: this.contentPadding, right: this.contentPadding, top: this.contentPadding, bottom: this.contentPadding })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
      .align(Alignment.Top)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
  }
  
  // 设备信息卡片
  @Builder
  DeviceInfoCard() {
    Column() {
      Row() {
        Text('📱')
          .fontSize(24)
          .margin({ right: 12 })
        
        Column() {
          Text('当前设备')
            .fontSize(14)
            .fontColor('#999999')
          
          Text(this.deviceId || '未初始化')
            .fontSize(12)
            .fontColor('#666666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 16 })
  }
  
  // 连接会话卡片（未连接状态）
  @Builder
  ConnectSessionCard() {
    Column() {
      Text('创建或加入协同组')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })
      
      // 创建新会话
      Button('创建新协同组')
        .width('100%')
        .height(50)
        .backgroundColor('#007DFF')
        .fontColor('#FFFFFF')
        .fontSize(16)
        .margin({ bottom: 20 })
        .onClick(() => {
          this.createSession();
        })
      
      // 分隔线
      Row() {
        Divider().layoutWeight(1)
        Text('或').fontSize(14).fontColor('#999999').margin({ left: 16, right: 16 })
        Divider().layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 20 })
      
      // 加入已有会话
      Text('加入已有协同组')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ bottom: 12 })
      
      TextInput({ placeholder: '请输入SessionId' })
        .width('100%')
        .height(50)
        .fontSize(16)
        .type(InputType.Normal)
        .enterKeyType(EnterKeyType.Done)
        .maxLength(100)
        .placeholderColor('#999999')
        .placeholderFont({ size: 16 })
        .caretColor('#007DFF')
        .onChange((value: string) => {
          this.sessionIdInput = value;
        })
        .onSubmit(() => {
          if (this.sessionIdInput) {
            this.joinSession(this.sessionIdInput);
          }
        })
        .margin({ bottom: 12 })
      
      Button('加入协同组')
        .width('100%')
        .height(50)
        .backgroundColor(this.sessionIdInput ? '#007DFF' : '#CCCCCC')
        .fontColor('#FFFFFF')
        .fontSize(16)
        .enabled(!!this.sessionIdInput)
        .onClick(() => {
          if (this.sessionIdInput) {
            this.joinSession(this.sessionIdInput);
          }
        })
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 16 })
  }
  
  // 已连接会话卡片
  @Builder
  ConnectedSessionCard() {
    Column() {
      Row() {
        Text('✅')
          .fontSize(24)
          .margin({ right: 12 })
        
        Column() {
          Text('已连接协同组')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#4CAF50')
          
          Text(this.currentSessionId)
            .fontSize(12)
            .fontColor('#666666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        
        Button('复制')
          .fontSize(12)
          .height(32)
          .backgroundColor('#F0F0F0')
          .fontColor('#666666')
          .onClick(() => {
            this.copySessionId();
          })
      }
      .width('100%')
      .margin({ bottom: 16 })
      
      // 已连接设备信息
      Column() {
        Text('协同组设备')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ bottom: 8 })
        
        // 显示所有设备
        ForEach(this.deviceList, (device: DeviceInfo, index: number) => {
          Row() {
            Text('📱')
              .fontSize(20)
              .margin({ right: 8 })
            
            Column() {
              Text(device.deviceId === this.deviceId ? '当前设备' : `设备 ${index + 1}`)
                .fontSize(13)
                .fontColor('#333333')
              
              Text(device.deviceId.substring(0, 20) + '...')
                .fontSize(11)
                .fontColor('#999999')
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            
            if (device.deviceId === this.deviceId) {
              Text('本机')
                .fontSize(12)
                .fontColor('#4CAF50')
                .backgroundColor('#E8F5E9')
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .borderRadius(4)
            } else {
              Text('在线')
                .fontSize(12)
                .fontColor('#2196F3')
                .backgroundColor('#E3F2FD')
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .borderRadius(4)
            }
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .margin({ bottom: index < this.deviceList.length - 1 ? 8 : 0 })
        }, (device: DeviceInfo) => device.deviceId)
        
        // 如果没有设备列表，显示当前设备
        if (this.deviceList.length === 0) {
          Row() {
            Text('📱')
              .fontSize(20)
              .margin({ right: 8 })
            
            Column() {
              Text('当前设备')
                .fontSize(13)
                .fontColor('#333333')
              
              Text(this.deviceId.substring(0, 20) + '...')
                .fontSize(11)
                .fontColor('#999999')
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            
            Text('本机')
              .fontSize(12)
              .fontColor('#4CAF50')
              .backgroundColor('#E8F5E9')
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .borderRadius(4)
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
        }
      }
      .width('100%')
      .margin({ bottom: 16 })
      
      Button('离开协同组')
        .width('100%')
        .height(44)
        .backgroundColor('#FF5722')
        .fontColor('#FFFFFF')
        .fontSize(16)
        .onClick(() => {
          this.leaveSession();
        })
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#E8F5E9')
    .borderRadius(12)
    .margin({ bottom: 16 })
  }
  
  // 接收到的任务卡片
  @Builder
  ReceivedTasksCard() {
    Column() {
      Row() {
        Text('📥')
          .fontSize(24)
          .margin({ right: 12 })
        
        Text(`接收到 ${this.receivedTasks.length} 个任务`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 16 })
      
      // 任务列表
      ForEach(this.receivedTasks, (task: TimerTask, index: number) => {
        Row() {
          Text(`${index + 1}.`)
            .fontSize(14)
            .fontColor('#999999')
            .width(30)
          
          Column() {
            Text(task.name || '未命名任务')
              .fontSize(14)
              .fontColor('#333333')
              .fontWeight(FontWeight.Medium)
            
            Text(this.getTaskDescription(task))
              .fontSize(12)
              .fontColor('#999999')
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding(12)
        .backgroundColor(index % 2 === 0 ? '#FFFFFF' : '#F9F9F9')
        .borderRadius(8)
        .margin({ bottom: 8 })
      })
      
      // 操作按钮
      Row() {
        Button('全部拒绝')
          .width('45%')
          .height(44)
          .backgroundColor('#F0F0F0')
          .fontColor('#666666')
          .onClick(() => {
            this.receivedTasks = [];
            promptAction.showToast({ message: '已拒绝所有任务', duration: 2000 });
          })
        
        Button('全部接收')
          .width('45%')
          .height(44)
          .backgroundColor('#007DFF')
          .fontColor('#FFFFFF')
          .onClick(() => {
            this.acceptAllTasks();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 16 })
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 16 })
  }
  
  // 使用说明卡片
  @Builder
  UsageGuideCard() {
    Column() {
      Text('使用说明')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 12 })
      
      Text('1. 在设备A点击"创建新协同组"')
        .fontSize(13)
        .fontColor('#666666')
        .margin({ bottom: 8 })
      
      Text('2. 复制SessionId到设备B，点击"加入协同组"')
        .fontSize(13)
        .fontColor('#666666')
        .margin({ bottom: 8 })
      
      Text('3. 在任一设备分享任务，另一设备将在此页面显示')
        .fontSize(13)
        .fontColor('#666666')
        .margin({ bottom: 8 })
      
      Text('4. 点击"全部接收"保存任务到本地')
        .fontSize(13)
        .fontColor('#666666')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFF9E6')
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
  }
  
  /**
   * 复制SessionId
   */
  private copySessionId() {
    promptAction.showDialog({
      title: 'SessionId',
      message: this.currentSessionId,
      buttons: [{ text: '已复制', color: '#007DFF' }]
    });
  }
  
  /**
   * 获取任务描述
   */
  private getTaskDescription(task: TimerTask): string {
    const timeStr = `${task.hour.toString().padStart(2, '0')}:${task.minute.toString().padStart(2, '0')}`;
    return `执行时间: ${timeStr}`;
  }
  
  /**
   * 创建会话
   */
  private createSession() {
    try {
      Logger.info(TAG, 'Creating session...');
      
      const sessionId = this.distributedShareService.generateSessionId();
      if (!sessionId) {
        promptAction.showToast({ message: '创建失败', duration: 2000 });
        return;
      }
      
      this.distributedShareService.setSessionId(sessionId);
      this.currentSessionId = sessionId;
      this.deviceId = this.distributedShareService.getDeviceId();
      this.isConnected = true;
      
      promptAction.showToast({
        message: `已创建协同组`,
        duration: 2000
      });
      
      Logger.info(TAG, `Session created: ${sessionId}`);
    } catch (error) {
      Logger.error(TAG, `Failed to create session: ${JSON.stringify(error)}`);
      promptAction.showToast({ message: `创建失败: ${error}`, duration: 2000 });
    }
  }
  
  /**
   * 加入会话
   */
  private joinSession(sessionId: string) {
    try {
      Logger.info(TAG, `Joining session: ${sessionId}`);
      
      this.distributedShareService.setSessionId(sessionId);
      this.currentSessionId = sessionId;
      this.deviceId = this.distributedShareService.getDeviceId();
      this.isConnected = true;
      
      promptAction.showToast({
        message: `已加入协同组`,
        duration: 2000
      });
      
      Logger.info(TAG, `Session joined: ${sessionId}`);
    } catch (error) {
      Logger.error(TAG, `Failed to join session: ${JSON.stringify(error)}`);
      promptAction.showToast({ message: `加入失败: ${error}`, duration: 2000 });
    }
  }
  
  /**
   * 离开会话
   */
  private leaveSession() {
    try {
      Logger.info(TAG, 'Leaving session...');
      
      this.distributedShareService.leaveSession();
      this.currentSessionId = '';
      this.isConnected = false;
      
      promptAction.showToast({
        message: '已离开协同组',
        duration: 2000
      });
      
      Logger.info(TAG, 'Session left');
    } catch (error) {
      Logger.error(TAG, `Failed to leave session: ${JSON.stringify(error)}`);
      promptAction.showToast({ message: `离开失败: ${error}`, duration: 2000 });
    }
  }
  
  /**
   * 接收到任务
   */
  private onTasksReceived(tasks: TimerTask[]) {
    Logger.info(TAG, `=== RECEIVED ${tasks.length} TASKS ===`);
    Logger.info(TAG, `Current receivedTasks count: ${this.receivedTasks.length}`);
    
    // 添加新任务到列表
    this.receivedTasks = [...this.receivedTasks, ...tasks];
    
    Logger.info(TAG, `New receivedTasks count: ${this.receivedTasks.length}`);
    
    // 记录任务详情
    for (let i = 0; i < tasks.length; i++) {
      const task = tasks[i];
      Logger.info(TAG, `Task ${i}: id=${task.id}, name=${task.name || 'unnamed'}`);
    }
    
    promptAction.showToast({
      message: `接收到 ${tasks.length} 个任务，请在下方查看`,
      duration: 3000
    });
  }
  
  /**
   * 接收所有任务
   */
  private async acceptAllTasks() {
    try {
      Logger.info(TAG, `Accepting ${this.receivedTasks.length} tasks`);
      
      // TODO: 保存任务到数据库
      // 这里需要从主页面传递viewModel或者重新初始化
      
      promptAction.showToast({
        message: `成功接收 ${this.receivedTasks.length} 个任务`,
        duration: 2000
      });
      
      this.receivedTasks = [];
      Logger.info(TAG, 'All tasks accepted');
    } catch (error) {
      Logger.error(TAG, `Failed to accept tasks: ${JSON.stringify(error)}`);
      promptAction.showToast({ message: `接收失败: ${error}`, duration: 2000 });
    }
  }
}
