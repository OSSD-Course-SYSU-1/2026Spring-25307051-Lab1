import { TimerTask } from '../model/TimerTask';
import { TaskStatus, VolumeType, TaskType, TimeMode } from '../model/TaskEnums';

/**
 * 任务卡片组件
 */
@Component
export struct TaskCardComponent {
  @Prop task: TimerTask;
  @Link isMultiSelectMode: boolean;
  @Link isSelected: boolean;
  @Prop deletingTaskId: string = '';
  @Prop deleteProgress: number = 0;

  onToggleSelection?: (taskId: string) => void;
  onToggleStatus?: (taskId: string) => void;
  onEnterMultiSelect?: (taskId: string) => void;
  onStartDelete?: (taskId: string) => void;
  onCancelDelete?: () => void;

  build() {
    Row() {
      // 多选模式下显示复选框
      if (this.isMultiSelectMode) {
        Row() {
          Checkbox()
            .select(this.isSelected)
            .selectedColor('#0A59F7')
            .shape(CheckBoxShape.CIRCLE)
            .margin({ right: 8 })

          Text('选择')
            .fontSize(12)
            .fontColor('#666666')
        }
        .margin({ right: 12 })
      }

      // 任务描述
      Column() {
        // 第一行：时间描述
        Text(this.getTimeDescription())
          .fontSize(14)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 第二行：音量设置
        if (this.task.volumeSettings && this.task.volumeSettings.length > 0) {
          Text(this.getVolumeDescription())
            .fontSize(12)
            .fontColor('#666666')
            .margin({ top: 4 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Blank().width(16)

      // 开关按钮（非多选模式）
      if (!this.isMultiSelectMode) {
        Toggle({ type: ToggleType.Switch, isOn: this.task.status === TaskStatus.ENABLED })
          .width(50)
          .height(26)
          .selectedColor('#007DFF')
          .onChange((isOn: boolean) => {
            if (this.onToggleStatus) {
              this.onToggleStatus(this.task.id);
            }
          })

        Blank().width(12)

        // 删除按钮
        Stack() {
          // 进度圈
          if (this.deletingTaskId === this.task.id) {
            Progress({ value: this.deleteProgress, total: 100, type: ProgressType.Ring })
              .width(32)
              .height(32)
              .color('#FF0000')
          }

          // 删除图标
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize(24)
            .fontColor(['#FF0000'])
        }
        .width(32)
        .height(32)
        .gesture(
          LongPressGesture({ repeat: true })
            .onAction(() => {
              if (this.deletingTaskId !== this.task.id && this.onStartDelete) {
                this.onStartDelete(this.task.id);
              }
            })
            .onActionEnd(() => {
              if (this.onCancelDelete) {
                this.onCancelDelete();
              }
            })
        )
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .shadow({ radius: 2, color: '#1A000000', offsetX: 0, offsetY: 1 })
    .onClick(() => {
      // 多选模式下，点击整个卡片切换选择状态
      if (this.isMultiSelectMode && this.onToggleSelection) {
        this.onToggleSelection(this.task.id);
      }
    })
    .gesture(
      LongPressGesture({ duration: 500 })
        .onAction(() => {
          // 非多选模式下，长按进入多选模式
          if (!this.isMultiSelectMode && this.onEnterMultiSelect) {
            this.onEnterMultiSelect(this.task.id);
          }
        })
    )
  }

  /**
   * 获取时间描述（只显示时间部分）
   */
  private getTimeDescription(): string {
    const timeStr = `${this.task.hour.toString().padStart(2, '0')}:${this.task.minute.toString().padStart(2, '0')}`;

    if (this.task.timeMode === TimeMode.ONCE) {
      return `${timeStr} 一次性`;
    } else if (this.task.timeMode === TimeMode.WEEKLY) {
      const weekDays = ['日', '一', '二', '三', '四', '五', '六'];
      if (this.task.dayOfWeek !== undefined) {
        return `${timeStr} 每周${weekDays[this.task.dayOfWeek]}`;
      }
      return `${timeStr} 每周`;
    } else if (this.task.timeMode === TimeMode.MONTHLY) {
      return `${timeStr} 每月${this.task.dayOfMonth}日`;
    }

    return timeStr;
  }

  /**
   * 获取音量描述
   */
  private getVolumeDescription(): string {
    if (!this.task.volumeSettings || this.task.volumeSettings.length === 0) {
      return '';
    }

    const volumeTypes: string[] = [];
    for (const setting of this.task.volumeSettings) {
      switch (setting.volumeType) {
        case VolumeType.MEDIA:
          volumeTypes.push(`媒体音量: ${setting.volumeValue}%`);
          break;
        case VolumeType.RINGTONE:
          volumeTypes.push(`铃声: ${setting.volumeValue}%`);
          break;
        case VolumeType.NOTIFICATION:
          volumeTypes.push(`通知音量: ${setting.volumeValue}%`);
          break;
        case VolumeType.ALARM:
          volumeTypes.push(`闹钟音量: ${setting.volumeValue}%`);
          break;
      }
    }

    return volumeTypes.join(' | ');
  }
}
