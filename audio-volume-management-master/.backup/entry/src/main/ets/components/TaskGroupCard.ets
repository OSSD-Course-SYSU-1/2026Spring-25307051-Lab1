import { TaskGroup, GroupStatus } from '../model/TaskGroup';
import { TimerTask } from '../model/TimerTask';
import { TimeMode } from '../model/TaskEnums';

/**
 * 任务组合体卡片组件
 */
@Component
export struct TaskGroupCard {
  @Prop group: TaskGroup;
  @Prop tasks: TimerTask[];
  @Prop isExpanded: boolean;
  @Prop groupStatus: GroupStatus;

  // 回调函数
  onToggleStatus?: (groupId: string) => void;
  onDissolve?: (groupId: string) => void;
  onRemoveTask?: (groupId: string, taskId: string) => void;
  onToggleExpand?: (groupId: string) => void;

  /**
   * 获取任务描述
   */
  private getTaskDescription(task: TimerTask): string {
    const timeStr = `${task.hour.toString().padStart(2, '0')}:${task.minute.toString().padStart(2, '0')}`;

    if (task.timeMode === TimeMode.ONCE) {
      return `单次 ${timeStr}`;
    } else if (task.timeMode === TimeMode.WEEKLY) {
      const weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      return `每${weekDays[(task.dayOfWeek! - 1) % 7]} ${timeStr}`;
    } else {
      return `每月${task.dayOfMonth}日 ${timeStr}`;
    }
  }

  /**
   * 获取音量描述
   */
  private getVolumeDescription(task: TimerTask): string {
    const volumeDesc = task.volumeSettings.map(setting => {
      return `${setting.volumeValue}%`;
    }).join('、');
    return volumeDesc;
  }

  build() {
    Column() {
      // 组合体头部
      Row() {
        // 左侧：组合体名称
        Text(this.group.name)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)

        // 右侧：开关和删除按钮
        Row() {
          // 总开关
          Toggle({ type: ToggleType.Switch, isOn: this.groupStatus === GroupStatus.ENABLED })
            .selectedColor('#0A59F7')
            .onChange((isOn: boolean) => {
              if (this.onToggleStatus) {
                this.onToggleStatus(this.group.id);
              }
            })

          // 解散按钮
          Button({ type: ButtonType.Circle }) {
            Text('×')
              .fontSize(20)
              .fontColor('#FF0000')
          }
          .width(32)
          .height(32)
          .backgroundColor('#FFECEC')
          .margin({ left: 8 })
          .onClick(() => {
            if (this.onDissolve) {
              this.onDissolve(this.group.id);
            }
          })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .onClick(() => {
        if (this.onToggleExpand) {
          this.onToggleExpand(this.group.id);
        }
      })

      // 子任务列表（展开状态）
      if (this.isExpanded) {
        Column() {
          ForEach(this.tasks, (task: TimerTask) => {
            Row() {
              // 左侧：任务描述
              Column() {
                Text(this.getTaskDescription(task))
                  .fontSize(14)
                  .fontColor('#666666')

                Text(`音量: ${this.getVolumeDescription(task)}`)
                  .fontSize(12)
                  .fontColor('#999999')
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              // 右侧：移出按钮
              Button({ type: ButtonType.Circle }) {
                Text('×')
                  .fontSize(16)
                  .fontColor('#FF0000')
              }
              .width(28)
              .height(28)
              .backgroundColor('#FFECEC')
              .onClick(() => {
                if (this.onRemoveTask) {
                  this.onRemoveTask(this.group.id, task.id);
                }
              })
            }
            .width('100%')
            .padding({ left: 24, right: 16, top: 8, bottom: 8 })
            .backgroundColor('#FFFFFF')
            .borderRadius(4)
            .margin({ top: 4 })
          })
        }
        .width('100%')
        .padding({ left: 8, right: 8, bottom: 12 })
      }
    }
    .width('100%')
    .backgroundColor('#F0F0F0')
    .borderRadius(8)
    .shadow({
      radius: 4,
      color: '#1F000000',
      offsetX: 0,
      offsetY: 2
    })
  }
}
