import { TimerTask, OnceMode } from '../../framework/model/TimerTask';
import { TimeMode } from '../../framework/model/TaskEnums';
import { TaskGroup, GroupStatus } from '../../framework/model/TaskGroup';
import { formatOnceTaskTime } from '../../framework/utils/DateUtils';

/**
 * 任务组合体卡片组件
 */
@Component
export struct TaskGroupCard {
  @Prop group: TaskGroup;
  @Prop tasks: TimerTask[];
  @Prop isExpanded: boolean;
  @Prop groupStatus: GroupStatus;
  @Prop isMultiSelectMode: boolean = false;
  @Prop isSelected: boolean = false;

  // 回调函数
  onToggleStatus?: (groupId: string) => void;
  onDissolve?: (groupId: string) => void;
  onRemoveTask?: (groupId: string, taskId: string) => void;
  onToggleExpand?: (groupId: string) => void;
  onToggleSelection?: (groupId: string) => void;
  onEnterMultiSelect?: (groupId: string) => void;

  /**
   * 获取任务描述
   */
  private getTaskDescription(task: TimerTask): string {
    const timeStr = `${task.hour.toString().padStart(2, '0')}:${task.minute.toString().padStart(2, '0')}`;

    if (task.timeMode === TimeMode.ONCE) {
      const dateStr = formatOnceTaskTime(task.executeTime, task.hour, task.minute);
      // 添加一次性/重复利用标识
      const modeTag = this.getOnceModeTag(task);
      return modeTag ? `${dateStr} [${modeTag}]` : dateStr;
    } else if (task.timeMode === TimeMode.WEEKLY) {
      const weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      return `每${weekDays[(task.dayOfWeek! - 1) % 7]} ${timeStr}`;
    } else {
      return `每月${task.dayOfMonth}日 ${timeStr}`;
    }
  }

  /**
   * 获取一次性模式标识
   */
  private getOnceModeTag(task: TimerTask): string {
    if (task.timeMode !== TimeMode.ONCE) {
      return '';
    }

    // 如果 onceMode 字段不存在，默认显示"一次性"
    if (!task.onceMode) {
      return '一次性';
    }

    if (task.onceMode === OnceMode.DISPOSABLE) {
      return '一次性';
    } else if (task.onceMode === OnceMode.REUSABLE) {
      return '重复利用';
    }

    return '一次性';
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
        // 多选模式下显示复选框
        if (this.isMultiSelectMode) {
          Row() {
            Checkbox()
              .select(this.isSelected)
              .selectedColor('#0A59F7')
              .shape(CheckBoxShape.CIRCLE)
              .margin({ right: 8 })
              .onChange((isSelected: boolean) => {
                if (this.onToggleSelection) {
                  this.onToggleSelection(this.group.id);
                }
              })

            Text('选择')
              .fontSize(12)
              .fontColor('#666666')
          }
          .margin({ right: 12 })
        }

        // 左侧：组合体名称
        Text(this.group.name)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)

        // 右侧：开关和删除按钮（非多选模式）
        if (!this.isMultiSelectMode) {
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
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .onClick(() => {
        // 多选模式下，点击整个卡片切换选择状态
        if (this.isMultiSelectMode && this.onToggleSelection) {
          this.onToggleSelection(this.group.id);
        } else if (this.onToggleExpand) {
          this.onToggleExpand(this.group.id);
        }
      })
      .gesture(
        LongPressGesture({ duration: 500 })
          .onAction(() => {
            // 非多选模式下，长按进入多选模式
            if (!this.isMultiSelectMode && this.onEnterMultiSelect) {
              this.onEnterMultiSelect(this.group.id);
            }
          })
      )

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
