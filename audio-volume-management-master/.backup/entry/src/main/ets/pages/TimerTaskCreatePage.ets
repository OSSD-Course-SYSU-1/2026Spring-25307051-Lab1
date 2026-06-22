import { router } from '@kit.ArkUI';
import { TimerTask, TimerTaskModel } from '../model/TimerTask';
import { VolumeSetting, VolumeSettingModel } from '../model/VolumeSetting';
import { TimeMode, VolumeType, TaskType } from '../model/TaskEnums';
import { TimerTaskViewModel } from '../viewModel/TimerTaskViewModel';
import { TimerTaskDatabase } from '../data/TimerTaskDatabase';
import { TimerTaskService } from '../service/TimerTaskService';
import { VolumeService } from '../service/VolumeService';
import { TimerScheduler } from '../service/TimerScheduler';
import { Logger } from '../utils/Logger';

const TAG = 'TimerTaskCreatePage';

/**
 * Select选项接口
 */
interface SelectOption {
  value: string;
}

/**
 * 时间模式选项接口
 */
interface TimeModeOption {
  mode: TimeMode;
  label: string;
}

@Entry
@Component
struct TimerTaskCreatePage {
  @State selectedMode: TimeMode = TimeMode.ONCE;
  @State selectedTaskType: TaskType = TaskType.INSTANT; // 新增：任务类型
  @State selectedHour: number = 12;
  @State selectedMinute: number = 0;
  @State selectedEndHour: number = 13; // 新增：结束小时
  @State selectedEndMinute: number = 0; // 新增：结束分钟
  @State selectedDayOfWeek: number = 1;
  @State selectedDayOfMonth: number = 1;
  @State selectedDate: number = 0; // 0=今天, 1=明天, ...

  @State mediaVolume: number = 50;
  @State ringtoneVolume: number = 50;
  @State notificationVolume: number = 50;
  @State alarmVolume: number = 50;

  @State enableMediaVolume: boolean = true;
  @State enableRingtoneVolume: boolean = false;
  @State enableNotificationVolume: boolean = false;
  @State enableAlarmVolume: boolean = false;

  @State mediaMute: boolean = false;
  @State ringtoneMute: boolean = false;
  @State notificationMute: boolean = false;
  @State alarmMute: boolean = false;

  @State isSaving: boolean = false;

  private viewModel: TimerTaskViewModel | null = null;
  private editTask: TimerTask | null = null;

  async aboutToAppear() {
    try {
      // 初始化服务
      const context = getContext(this) as Context;
      const database = new TimerTaskDatabase(context);
      await database.initialize();

      const taskService = new TimerTaskService(database);
      const volumeService = new VolumeService();
      const scheduler = new TimerScheduler(taskService, volumeService);

      this.viewModel = new TimerTaskViewModel(taskService, scheduler);

      Logger.info(TAG, 'ViewModel initialized successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to initialize: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 生成日期选项
   */
  private generateDayOptions(): SelectOption[] {
    const options: SelectOption[] = [];
    for (let i = 1; i <= 31; i++) {
      options.push({ value: `${i}日` });
    }
    return options;
  }

  /**
   * 生成小时选项
   */
  private generateHourOptions(): SelectOption[] {
    const options: SelectOption[] = [];
    for (let i = 0; i < 24; i++) {
      options.push({ value: `${i.toString().padStart(2, '0')}时` });
    }
    return options;
  }

  /**
   * 生成分钟选项
   */
  private generateMinuteOptions(): SelectOption[] {
    const options: SelectOption[] = [];
    for (let i = 0; i < 60; i++) {
      options.push({ value: `${i.toString().padStart(2, '0')}分` });
    }
    return options;
  }

  /**
   * 保存任务
   */
  async saveTask() {
    if (this.isSaving) return;

    try {
      this.isSaving = true;

      // 构建音量设置列表
      const volumeSettings: VolumeSetting[] = [];

      if (this.enableMediaVolume) {
        volumeSettings.push(new VolumeSettingModel(
          undefined,
          VolumeType.MEDIA,
          undefined,
          this.mediaVolume,
          this.mediaMute
        ));
      }

      if (this.enableRingtoneVolume) {
        volumeSettings.push(new VolumeSettingModel(
          undefined,
          VolumeType.RINGTONE,
          undefined,
          this.ringtoneVolume,
          this.ringtoneMute
        ));
      }

      if (this.enableNotificationVolume) {
        volumeSettings.push(new VolumeSettingModel(
          undefined,
          VolumeType.NOTIFICATION,
          undefined,
          this.notificationVolume,
          this.notificationMute
        ));
      }

      if (this.enableAlarmVolume) {
        volumeSettings.push(new VolumeSettingModel(
          undefined,
          VolumeType.ALARM,
          undefined,
          this.alarmVolume,
          this.alarmMute
        ));
      }

      // 构建任务对象
      let task: TimerTaskModel;

      if (this.selectedMode === TimeMode.ONCE) {
        // 计算执行时间
        const now = new Date();
        const executeDate = new Date(now);
        executeDate.setDate(now.getDate() + this.selectedDate);
        executeDate.setHours(this.selectedHour, this.selectedMinute, 0, 0);

        task = new TimerTaskModel(
          undefined,
          undefined,
          TimeMode.ONCE,
          this.selectedTaskType,
          this.selectedHour,
          this.selectedMinute,
          volumeSettings,
          undefined,
          undefined,
          undefined,
          this.selectedEndHour,
          this.selectedEndMinute
        );
        task.setExecuteTime(executeDate.getTime());

        // 如果是时间段锁定任务，设置结束时间
        if (this.selectedTaskType === TaskType.PERIOD) {
          task.setPeriodLock(this.selectedEndHour, this.selectedEndMinute);
        }
      } else if (this.selectedMode === TimeMode.WEEKLY) {
        task = new TimerTaskModel(
          undefined,
          undefined,
          TimeMode.WEEKLY,
          this.selectedTaskType,
          this.selectedHour,
          this.selectedMinute,
          volumeSettings,
          undefined,
          undefined,
          undefined,
          this.selectedEndHour,
          this.selectedEndMinute
        );
        task.setWeekly(this.selectedDayOfWeek);

        // 如果是时间段锁定任务，设置结束时间
        if (this.selectedTaskType === TaskType.PERIOD) {
          task.setPeriodLock(this.selectedEndHour, this.selectedEndMinute);
        }
      } else {
        task = new TimerTaskModel(
          undefined,
          undefined,
          TimeMode.MONTHLY,
          this.selectedTaskType,
          this.selectedHour,
          this.selectedMinute,
          volumeSettings,
          undefined,
          undefined,
          undefined,
          this.selectedEndHour,
          this.selectedEndMinute
        );
        task.setMonthly(this.selectedDayOfMonth);

        // 如果是时间段锁定任务，设置结束时间
        if (this.selectedTaskType === TaskType.PERIOD) {
          task.setPeriodLock(this.selectedEndHour, this.selectedEndMinute);
        }
      }

      // 保存任务
      if (this.viewModel) {
        await this.viewModel.createTask(task);
      }

      // 返回列表页
      try {
        router.back();
      } catch (err) {
        Logger.error(TAG, `Failed to go back: ${JSON.stringify(err)}`);
      }

      Logger.info(TAG, 'Task saved successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to save task: ${JSON.stringify(error)}`);
      // 显示错误提示
    } finally {
      this.isSaving = false;
    }
  }

  /**
   * 获取倒计时预览
   */
  getCountdownPreview(): string {
    if (this.selectedMode !== TimeMode.ONCE) {
      return '';
    }

    const now = new Date();
    const executeDate = new Date(now);
    executeDate.setDate(now.getDate() + this.selectedDate);
    executeDate.setHours(this.selectedHour, this.selectedMinute, 0, 0);

    const diff = executeDate.getTime() - now.getTime();
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));
    const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));

    if (days > 0) {
      return `将于 ${days}天${hours}小时 后执行`;
    } else if (hours > 0) {
      return `将于 ${hours}小时${minutes}分钟 后执行`;
    } else {
      return `将于 ${minutes}分钟 后执行`;
    }
  }

  build() {
    Column() {
      // 顶部空白区域，避免被摄像头遮挡
      Blank()
        .height(32)

      // 导航栏
      Row() {
        Image($r('app.media.chevron_left'))
          .width(24)
          .height(24)
          .onClick(() => {
            // 返回上一页
            try {
              router.back();
            } catch (err) {
              Logger.error(TAG, `Failed to go back: ${JSON.stringify(err)}`);
            }
          })

        Text('创建任务')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank()
          .width(24)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })

      // 内容区域
      Scroll() {
        Column({ space: 24 }) {
          // 时间模式选择
          Column({ space: 12 }) {
            Text('时间模式')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .width('100%')

            Row({ space: 12 }) {
              ForEach([
                { mode: TimeMode.ONCE, label: '未来15天' },
                { mode: TimeMode.WEEKLY, label: '每周循环' },
                { mode: TimeMode.MONTHLY, label: '每月循环' }
              ] as TimeModeOption[], (item: TimeModeOption) => {
                Button(item.label)
                  .fontSize(14)
                  .height(36)
                  .layoutWeight(1)
                  .backgroundColor(this.selectedMode === item.mode ? '#007DFF' : '#F0F0F0')
                  .fontColor(this.selectedMode === item.mode ? Color.White : '#333333')
                  .onClick(() => {
                    this.selectedMode = item.mode;
                  })
              })
            }
            .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(8)

          // 任务类型选择（新增）
          Column({ space: 12 }) {
            Text('任务类型')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .width('100%')

            Row({ space: 12 }) {
              Button('瞬时设置')
                .fontSize(14)
                .height(36)
                .layoutWeight(1)
                .backgroundColor(this.selectedTaskType === TaskType.INSTANT ? '#007DFF' : '#F0F0F0')
                .fontColor(this.selectedTaskType === TaskType.INSTANT ? Color.White : '#333333')
                .onClick(() => {
                  this.selectedTaskType = TaskType.INSTANT;
                })

              Button('时间段锁定')
                .fontSize(14)
                .height(36)
                .layoutWeight(1)
                .backgroundColor(this.selectedTaskType === TaskType.PERIOD ? '#007DFF' : '#F0F0F0')
                .fontColor(this.selectedTaskType === TaskType.PERIOD ? Color.White : '#333333')
                .onClick(() => {
                  this.selectedTaskType = TaskType.PERIOD;
                })
            }
            .width('100%')

            // 时间段锁定说明
            if (this.selectedTaskType === TaskType.PERIOD) {
              Text('在设定的时间段内，系统音量将被锁定在设定值，防止被修改')
                .fontSize(12)
                .fontColor('#999999')
                .width('100%')
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(8)

          // 时间选择
          Column({ space: 12 }) {
            Text('执行时间')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .width('100%')

            if (this.selectedMode === TimeMode.ONCE) {
              // 未来15天模式
              Row({ space: 12 }) {
                Text('日期:')
                  .fontSize(14)

                Select([
                  { value: '今天' },
                  { value: '明天' },
                  { value: '后天' },
                  { value: '3天后' },
                  { value: '4天后' },
                  { value: '5天后' },
                  { value: '6天后' },
                  { value: '7天后' },
                  { value: '8天后' },
                  { value: '9天后' },
                  { value: '10天后' },
                  { value: '11天后' },
                  { value: '12天后' },
                  { value: '13天后' },
                  { value: '14天后' }
                ] as SelectOption[])
                  .selected(this.selectedDate)
                  .value(['今天', '明天', '后天', '3天后', '4天后', '5天后', '6天后', '7天后', '8天后', '9天后', '10天后', '11天后', '12天后', '13天后', '14天后'][this.selectedDate])
                  .onSelect((index: number) => {
                    this.selectedDate = index;
                  })
              }
              .width('100%')
            } else if (this.selectedMode === TimeMode.WEEKLY) {
              // 每周循环模式
              Row({ space: 12 }) {
                Text('星期:')
                  .fontSize(14)

                Select([
                  { value: '周一' },
                  { value: '周二' },
                  { value: '周三' },
                  { value: '周四' },
                  { value: '周五' },
                  { value: '周六' },
                  { value: '周日' }
                ] as SelectOption[])
                  .selected(this.selectedDayOfWeek - 1)
                  .value(['周一', '周二', '周三', '周四', '周五', '周六', '周日'][this.selectedDayOfWeek - 1])
                  .onSelect((index: number) => {
                    this.selectedDayOfWeek = index + 1;
                  })
              }
              .width('100%')
            } else {
              // 每月循环模式
              Row({ space: 12 }) {
                Text('日期:')
                  .fontSize(14)

                Select(this.generateDayOptions())
                  .selected(this.selectedDayOfMonth - 1)
                  .value(`${this.selectedDayOfMonth}日`)
                  .onSelect((index: number) => {
                    this.selectedDayOfMonth = index + 1;
                  })
              }
              .width('100%')
            }

            // 小时和分钟选择
            Row({ space: 12 }) {
              Text('时间:')
                .fontSize(14)

              Select(this.generateHourOptions())
                .selected(this.selectedHour)
                .value(`${this.selectedHour.toString().padStart(2, '0')}时`)
                .onSelect((index: number) => {
                  this.selectedHour = index;
                })

              Select(this.generateMinuteOptions())
                .selected(this.selectedMinute)
                .value(`${this.selectedMinute.toString().padStart(2, '0')}分`)
                .onSelect((index: number) => {
                  this.selectedMinute = index;
                })
            }
            .width('100%')

            // 倒计时预览
            if (this.selectedMode === TimeMode.ONCE) {
              Text(this.getCountdownPreview())
                .fontSize(12)
                .fontColor('#999999')
                .width('100%')
            }

            // 结束时间选择（仅时间段锁定任务显示）
            if (this.selectedTaskType === TaskType.PERIOD) {
              Row({ space: 12 }) {
                Text('结束时间:')
                  .fontSize(14)

                Select(this.generateHourOptions())
                  .selected(this.selectedEndHour)
                  .value(`${this.selectedEndHour.toString().padStart(2, '0')}时`)
                  .onSelect((index: number) => {
                    this.selectedEndHour = index;
                  })

                Select(this.generateMinuteOptions())
                  .selected(this.selectedEndMinute)
                  .value(`${this.selectedEndMinute.toString().padStart(2, '0')}分`)
                  .onSelect((index: number) => {
                    this.selectedEndMinute = index;
                  })
              }
              .width('100%')

              // 时间段预览
              Text(`锁定时间段: ${this.selectedHour.toString().padStart(2, '0')}:${this.selectedMinute.toString().padStart(2, '0')} - ${this.selectedEndHour.toString().padStart(2, '0')}:${this.selectedEndMinute.toString().padStart(2, '0')}`)
                .fontSize(12)
                .fontColor('#007DFF')
                .width('100%')
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(8)

          // 系统音量设置
          Column({ space: 12 }) {
            Text('系统音量')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .width('100%')

            // 媒体音量
            Row({ space: 12 }) {
              Checkbox({ name: 'media', group: 'volume' })
                .select(this.enableMediaVolume)
                .onChange((isChecked: boolean) => {
                  this.enableMediaVolume = isChecked;
                })

              Text('媒体音量')
                .fontSize(14)
                .layoutWeight(1)

              if (this.enableMediaVolume) {
                Toggle({ type: ToggleType.Switch, isOn: this.mediaMute })
                  .width(50)
                  .height(26)
                  .selectedColor('#FF0000')
                  .onChange((isOn: boolean) => {
                    this.mediaMute = isOn;
                  })

                Text(this.mediaMute ? '静音' : `${this.mediaVolume}%`)
                  .fontSize(14)
                  .fontColor(this.mediaMute ? '#FF0000' : '#007DFF')
              }
            }
            .width('100%')

            if (this.enableMediaVolume && !this.mediaMute) {
              Slider({
                value: this.mediaVolume,
                min: 0,
                max: 100,
                step: 1
              })
                .width('100%')
                .blockColor('#007DFF')
                .trackColor('#E0E0E0')
                .selectedColor('#007DFF')
                .onChange((value: number) => {
                  this.mediaVolume = Math.round(value);
                })
            }

            // 铃声音量
            Row({ space: 12 }) {
              Checkbox({ name: 'ringtone', group: 'volume' })
                .select(this.enableRingtoneVolume)
                .onChange((isChecked: boolean) => {
                  this.enableRingtoneVolume = isChecked;
                })

              Text('铃声音量')
                .fontSize(14)
                .layoutWeight(1)

              if (this.enableRingtoneVolume) {
                Toggle({ type: ToggleType.Switch, isOn: this.ringtoneMute })
                  .width(50)
                  .height(26)
                  .selectedColor('#FF0000')
                  .onChange((isOn: boolean) => {
                    this.ringtoneMute = isOn;
                  })

                Text(this.ringtoneMute ? '静音' : `${this.ringtoneVolume}%`)
                  .fontSize(14)
                  .fontColor(this.ringtoneMute ? '#FF0000' : '#007DFF')
              }
            }
            .width('100%')

            if (this.enableRingtoneVolume && !this.ringtoneMute) {
              Slider({
                value: this.ringtoneVolume,
                min: 0,
                max: 100,
                step: 1
              })
                .width('100%')
                .blockColor('#007DFF')
                .trackColor('#E0E0E0')
                .selectedColor('#007DFF')
                .onChange((value: number) => {
                  this.ringtoneVolume = Math.round(value);
                })
            }

            // 通知音量
            Row({ space: 12 }) {
              Checkbox({ name: 'notification', group: 'volume' })
                .select(this.enableNotificationVolume)
                .onChange((isChecked: boolean) => {
                  this.enableNotificationVolume = isChecked;
                })

              Text('通知音量')
                .fontSize(14)
                .layoutWeight(1)

              if (this.enableNotificationVolume) {
                Toggle({ type: ToggleType.Switch, isOn: this.notificationMute })
                  .width(50)
                  .height(26)
                  .selectedColor('#FF0000')
                  .onChange((isOn: boolean) => {
                    this.notificationMute = isOn;
                  })

                Text(this.notificationMute ? '静音' : `${this.notificationVolume}%`)
                  .fontSize(14)
                  .fontColor(this.notificationMute ? '#FF0000' : '#007DFF')
              }
            }
            .width('100%')

            if (this.enableNotificationVolume && !this.notificationMute) {
              Slider({
                value: this.notificationVolume,
                min: 0,
                max: 100,
                step: 1
              })
                .width('100%')
                .blockColor('#007DFF')
                .trackColor('#E0E0E0')
                .selectedColor('#007DFF')
                .onChange((value: number) => {
                  this.notificationVolume = Math.round(value);
                })
            }

            // 闹钟音量
            Row({ space: 12 }) {
              Checkbox({ name: 'alarm', group: 'volume' })
                .select(this.enableAlarmVolume)
                .onChange((isChecked: boolean) => {
                  this.enableAlarmVolume = isChecked;
                })

              Text('闹钟音量')
                .fontSize(14)
                .layoutWeight(1)

              if (this.enableAlarmVolume) {
                Toggle({ type: ToggleType.Switch, isOn: this.alarmMute })
                  .width(50)
                  .height(26)
                  .selectedColor('#FF0000')
                  .onChange((isOn: boolean) => {
                    this.alarmMute = isOn;
                  })

                Text(this.alarmMute ? '静音' : `${this.alarmVolume}%`)
                  .fontSize(14)
                  .fontColor(this.alarmMute ? '#FF0000' : '#007DFF')
              }
            }
            .width('100%')

            if (this.enableAlarmVolume && !this.alarmMute) {
              Slider({
                value: this.alarmVolume,
                min: 0,
                max: 100,
                step: 1
              })
                .width('100%')
                .blockColor('#007DFF')
                .trackColor('#E0E0E0')
                .selectedColor('#007DFF')
                .onChange((value: number) => {
                  this.alarmVolume = Math.round(value);
                })
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(8)
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)

      // 保存按钮
      Button('保存')
        .width('90%')
        .height(48)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .backgroundColor('#007DFF')
        .margin({ bottom: 24 })
        .enabled(!this.isSaving)
        .onClick(() => {
          this.saveTask();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
