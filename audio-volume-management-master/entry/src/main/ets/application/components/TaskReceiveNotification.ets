import { TimerTask } from '../../framework/model/TimerTask';
import { TimeMode } from '../../framework/model/TaskEnums';
import { Logger } from '../../framework/utils/Logger';
import promptAction from '@ohos.promptAction';

const TAG = 'TaskReceiveNotification';

/**
 * 任务接收通知组件
 */
@CustomDialog
export struct TaskReceiveNotification {
  @State receivedTasks: TimerTask[] = [];
  @State isExpanded: boolean = false;
  
  controller: CustomDialogController;
  onAccept?: (tasks: TimerTask[]) => void;
  onReject?: () => void;

  aboutToAppear() {
    Logger.info(TAG, `TaskReceiveNotification aboutToAppear, tasks count: ${this.receivedTasks.length}`);
  }

  build() {
    Column() {
      // 标题
      Row() {
        Text('📥')
          .fontSize(24)
          .margin({ right: 8 })
        
        Text('接收到新任务')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        
        Text(`${this.receivedTasks.length}个`)
          .fontSize(14)
          .fontColor('#007DFF')
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 任务列表预览
      Column() {
        if (this.isExpanded) {
          // 展开显示所有任务
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
            .padding(8)
            .backgroundColor(index % 2 === 0 ? '#FFFFFF' : '#F5F5F5')
            .borderRadius(4)
          })
        } else {
          // 折叠显示摘要
          Text(`来自协同组的任务分享`)
            .fontSize(14)
            .fontColor('#666666')
            .margin({ bottom: 8 })
          
          Row() {
            Text(`包含 ${this.receivedTasks.length} 个定时音量管理任务`)
              .fontSize(12)
              .fontColor('#999999')
              .layoutWeight(1)
            
            Button('查看详情')
              .fontSize(12)
              .height(28)
              .backgroundColor('#F0F0F0')
              .fontColor('#666666')
              .padding({ left: 8, right: 8 })
              .onClick(() => {
                this.isExpanded = true;
              })
          }
          .width('100%')
        }
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#F9F9F9')
      .borderRadius(8)
      .margin({ bottom: 16 })

      // 操作按钮
      Row() {
        Button('拒绝')
          .width('45%')
          .height(44)
          .backgroundColor('#F0F0F0')
          .fontColor('#666666')
          .fontSize(16)
          .onClick(() => {
            if (this.onReject) {
              this.onReject();
            }
            this.controller.close();
          })

        Button('接收')
          .width('45%')
          .height(44)
          .backgroundColor('#007DFF')
          .fontColor('#FFFFFF')
          .fontSize(16)
          .onClick(() => {
            if (this.onAccept) {
              this.onAccept(this.receivedTasks);
            }
            this.controller.close();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }

  /**
   * 获取任务描述
   */
  private getTaskDescription(task: TimerTask): string {
    const timeStr = `${task.hour.toString().padStart(2, '0')}:${task.minute.toString().padStart(2, '0')}`;
    
    if (task.timeMode === TimeMode.ONCE) {
      return `一次性任务 - ${timeStr}`;
    } else if (task.timeMode === TimeMode.WEEKLY) {
      const days = ['日', '一', '二', '三', '四', '五', '六'];
      return `每周${days[task.dayOfWeek || 0]} - ${timeStr}`;
    } else if (task.timeMode === TimeMode.MONTHLY) {
      return `每月${task.dayOfMonth}日 - ${timeStr}`;
    }
    
    return timeStr;
  }

  /**
   * 设置接收到的任务
   */
  setReceivedTasks(tasks: TimerTask[]) {
    Logger.info(TAG, `Setting received tasks: ${tasks.length}`);
    this.receivedTasks = tasks;
  }
}
