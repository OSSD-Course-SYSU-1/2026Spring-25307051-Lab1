import { router } from '@kit.ArkUI';
import { TimerTask, TimerTaskModel } from '../model/TimerTask';
import { VolumeSetting } from '../model/VolumeSetting';
import { TaskStatus, VolumeType, TimeMode, TaskType, LockStatus } from '../model/TaskEnums';
import { TaskGroup, GroupStatus, GroupWithTasks } from '../model/TaskGroup';
import { TimerTaskViewModel } from '../viewModel/TimerTaskViewModel';
import { TaskGroupViewModel } from '../viewModel/TaskGroupViewModel';
import { TimerTaskDatabase } from '../data/TimerTaskDatabase';
import { TimerTaskService } from '../service/TimerTaskService';
import { TaskGroupService } from '../service/TaskGroupService';
import { VolumeService } from '../service/VolumeService';
import { TimerScheduler } from '../service/TimerScheduler';
import { Logger } from '../utils/Logger';
import { TaskGroupCard } from '../components/TaskGroupCard';
import { MultiSelectBar } from '../components/MultiSelectBar';
import { CreateGroupDialog } from '../components/CreateGroupDialog';
import { TaskCardComponent } from '../components/TaskCardComponent';
import promptAction from '@ohos.promptAction';

const TAG = 'TimerTaskListPage';

@Entry
@Component
struct TimerTaskListPage {
  @State taskList: TimerTask[] = [];
  @State isLoading: boolean = true;
  @State isEmpty: boolean = false;
  @State deletingTaskId: string = '';
  @State deleteProgress: number = 0;

  // 多选模式状态
  @State isMultiSelectMode: boolean = false;
  @State selectedTaskIds: string[] = [];
  @State private refreshCounter: number = 0; // 强制刷新计数器

  // 组合体状态
  @State groupList: GroupWithTasks[] = [];
  @State expandedGroupIds: Set<string> = new Set<string>();

  // 对话框控制器
  private createGroupDialogController: CustomDialogController | null = null;

  private viewModel: TimerTaskViewModel | null = null;
  private groupViewModel: TaskGroupViewModel | null = null;
  private deleteTimer: number = -1;

  async aboutToAppear() {
    try {
      // 初始化服务
      const context = getContext(this) as Context;
      const database = new TimerTaskDatabase(context);
      await database.initialize();

      const taskService = new TimerTaskService(database);
      const groupService = new TaskGroupService(database, taskService);
      const volumeService = new VolumeService();
      const scheduler = new TimerScheduler(taskService, volumeService);

      this.viewModel = new TimerTaskViewModel(taskService, scheduler);
      this.groupViewModel = new TaskGroupViewModel(groupService, taskService);

      // 加载任务列表
      await this.loadTasks();
    } catch (error) {
      Logger.error(TAG, `Failed to initialize: ${JSON.stringify(error)}`);
      this.isLoading = false;
    }
  }

  /**
   * 页面显示时重新加载任务列表
   */
  async onPageShow() {
    await this.loadTasks();
  }

  /**
   * 加载任务列表
   */
  async loadTasks() {
    if (!this.viewModel || !this.groupViewModel) return;

    try {
      this.isLoading = true;

      // 加载组合体
      this.groupList = await this.groupViewModel.loadGroupsWithTasks();

      // 加载任务列表
      const allTasks = await this.viewModel.loadTasks();

      // 过滤掉属于组合体的任务
      this.taskList = allTasks.filter(task => !task.groupId);

      this.isEmpty = this.taskList.length === 0 && this.groupList.length === 0;
      this.isLoading = false;
      this.refreshCounter++; // 触发刷新
    } catch (error) {
      Logger.error(TAG, `Failed to load tasks: ${JSON.stringify(error)}`);
      this.isLoading = false;
    }
  }

  /**
   * 切换任务状态
   */
  async toggleTaskStatus(taskId: string) {
    if (!this.viewModel) return;

    try {
      await this.viewModel.toggleTaskStatus(taskId);
      await this.loadTasks();
    } catch (error) {
      Logger.error(TAG, `Failed to toggle task status: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 开始删除任务（长按）
   */
  startDelete(taskId: string) {
    this.deletingTaskId = taskId;
    this.deleteProgress = 0;

    // 启动进度动画
    this.deleteTimer = setInterval(() => {
      this.deleteProgress += 10;
      if (this.deleteProgress >= 100) {
        this.executeDelete(taskId);
      }
    }, 15); // 1.5秒完成
  }

  /**
   * 取消删除
   */
  cancelDelete() {
    if (this.deleteTimer !== -1) {
      clearInterval(this.deleteTimer);
      this.deleteTimer = -1;
    }
    this.deletingTaskId = '';
    this.deleteProgress = 0;
  }

  /**
   * 执行删除
   */
  async executeDelete(taskId: string) {
    if (!this.viewModel) return;

    try {
      await this.viewModel.deleteTask(taskId);
      await this.loadTasks();
    } catch (error) {
      Logger.error(TAG, `Failed to delete task: ${JSON.stringify(error)}`);
    } finally {
      this.cancelDelete();
    }
  }

  /**
   * 进入多选模式
   */
  enterMultiSelectMode(taskId: string) {
    Logger.info(TAG, `enterMultiSelectMode: ${taskId}`);
    this.isMultiSelectMode = true;
    this.selectedTaskIds = [taskId];
    this.refreshCounter++; // 触发刷新
    Logger.info(TAG, `isMultiSelectMode: ${this.isMultiSelectMode}, selectedTaskIds: ${JSON.stringify(this.selectedTaskIds)}`);
  }

  /**
   * 退出多选模式
   */
  exitMultiSelectMode() {
    Logger.info(TAG, `exitMultiSelectMode`);
    this.isMultiSelectMode = false;
    this.selectedTaskIds = [];
    this.refreshCounter++; // 触发刷新
  }

  /**
   * 切换任务选中状态
   */
  toggleTaskSelection(taskId: string) {
    Logger.info(TAG, `toggleTaskSelection: ${taskId}, current: ${JSON.stringify(this.selectedTaskIds)}`);
    const index = this.selectedTaskIds.indexOf(taskId);
    if (index >= 0) {
      this.selectedTaskIds.splice(index, 1);
    } else {
      this.selectedTaskIds.push(taskId);
    }
    // 触发状态更新
    this.selectedTaskIds = [...this.selectedTaskIds];
    this.refreshCounter++; // 触发刷新
    Logger.info(TAG, `after toggle: ${JSON.stringify(this.selectedTaskIds)}`);
  }

  /**
   * 创建组合体
   */
  async createGroup() {
    if (!this.groupViewModel) return;

    try {
      // 使用自定义对话框
      this.createGroupDialogController = new CustomDialogController({
        builder: CreateGroupDialog({
          onConfirm: (name: string) => {
            this.doCreateGroup(name);
          }
        }),
        autoCancel: true,
        alignment: DialogAlignment.Center,
        customStyle: true
      });
      this.createGroupDialogController.open();
    } catch (error) {
      Logger.error(TAG, `Failed to show create dialog: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 执行创建组合体
   */
  async doCreateGroup(name: string) {
    if (!this.groupViewModel) return;

    try {
      const taskIds = this.selectedTaskIds;
      await this.groupViewModel.createGroup(name, taskIds);
      await this.loadTasks();
      this.exitMultiSelectMode();
      promptAction.showToast({ message: '组合体创建成功' });
    } catch (error) {
      Logger.error(TAG, `Failed to create group: ${JSON.stringify(error)}`);
      promptAction.showToast({ message: `创建失败: ${error.message}` });
    }
  }

  /**
   * 移入现有组合体
   */
  async addTasksToExistingGroup(groupId: string) {
    if (!this.groupViewModel) return;

    try {
      const taskIds = this.selectedTaskIds;
      await this.groupViewModel.addTasksToGroup(groupId, taskIds);
      await this.loadTasks();
      this.exitMultiSelectMode();
      promptAction.showToast({ message: '任务已移入组合体' });
    } catch (error) {
      Logger.error(TAG, `Failed to add tasks to group: ${JSON.stringify(error)}`);
      promptAction.showToast({ message: `移入失败: ${error.message}` });
    }
  }

  /**
   * 切换组合体状态
   */
  async toggleGroupStatus(groupId: string) {
    if (!this.groupViewModel) return;

    try {
      await this.groupViewModel.toggleGroupStatus(groupId);
      await this.loadTasks();
    } catch (error) {
      Logger.error(TAG, `Failed to toggle group status: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 解散组合体
   */
  async dissolveGroup(groupId: string) {
    if (!this.groupViewModel) return;

    try {
      promptAction.showDialog({
        title: '解散组合体',
        message: '确定解散该组合体？解散后子任务将恢复为独立任务。',
        buttons: [
          { text: '取消', color: '#999999' },
          { text: '确定', color: '#FF0000' }
        ]
      }, async (error, data) => {
        if (data.index === 1) {
          await this.groupViewModel!.dissolveGroup(groupId);
          await this.loadTasks();
          promptAction.showToast({ message: '组合体已解散' });
        }
      });
    } catch (error) {
      Logger.error(TAG, `Failed to show dissolve dialog: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 从组合体移出任务
   */
  async removeTaskFromGroup(groupId: string, taskId: string) {
    if (!this.groupViewModel) return;

    try {
      promptAction.showDialog({
        title: '移出任务',
        message: '确定将该任务从组合体中移出？',
        buttons: [
          { text: '取消', color: '#999999' },
          { text: '确定', color: '#FF0000' }
        ]
      }, async (error, data) => {
        if (data.index === 1) {
          await this.groupViewModel!.removeTaskFromGroup(groupId, taskId);
          await this.loadTasks();
          promptAction.showToast({ message: '任务已移出' });
        }
      });
    } catch (error) {
      Logger.error(TAG, `Failed to show remove dialog: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 切换组合体展开状态
   */
  async toggleGroupExpanded(groupId: string) {
    if (!this.groupViewModel) return;

    try {
      await this.groupViewModel.toggleGroupExpanded(groupId);

      // 更新本地展开状态
      const newSet = new Set<string>(this.expandedGroupIds);
      if (newSet.has(groupId)) {
        newSet.delete(groupId);
      } else {
        newSet.add(groupId);
      }
      this.expandedGroupIds = newSet;
    } catch (error) {
      Logger.error(TAG, `Failed to toggle group expanded: ${JSON.stringify(error)}`);
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

        Text('定时音量管理')
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
      if (this.isLoading) {
        // 加载状态
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color('#007DFF')

          Text('加载中...')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 16 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.isEmpty) {
        // 空状态
        Column() {
          SymbolGlyph($r('sys.symbol.circle'))
            .fontSize(120)
            .fontColor(['#999999'])

          Text('暂无定时任务')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 16 })

          Text('点击下方按钮创建任务')
            .fontSize(14)
            .fontColor('#CCCCCC')
            .margin({ top: 8 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        // 任务列表
        List({ space: 12 }) {
          // 组合体列表
          ForEach(this.groupList, (groupWithTasks: GroupWithTasks) => {
            ListItem() {
              TaskGroupCard({
                group: groupWithTasks.group,
                tasks: groupWithTasks.tasks,
                isExpanded: this.expandedGroupIds.has(groupWithTasks.group.id),
                groupStatus: groupWithTasks.group.status,
                onToggleStatus: (groupId: string) => {
                  this.toggleGroupStatus(groupId);
                },
                onDissolve: (groupId: string) => {
                  this.dissolveGroup(groupId);
                },
                onRemoveTask: (groupId: string, taskId: string) => {
                  this.removeTaskFromGroup(groupId, taskId);
                },
                onToggleExpand: (groupId: string) => {
                  this.toggleGroupExpanded(groupId);
                }
              })
            }
          }, (groupWithTasks: GroupWithTasks) => `${groupWithTasks.group.id}_${this.refreshCounter}`)

          // 普通任务列表
          ForEach(this.taskList, (task: TimerTask, index: number) => {
            ListItem() {
              Row() {
                // 多选模式下显示复选框
                if (this.isMultiSelectMode) {
                  Row() {
                    Checkbox()
                      .select(this.selectedTaskIds.includes(task.id))
                      .selectedColor('#0A59F7')
                      .shape(CheckBoxShape.CIRCLE)
                      .margin({ right: 8 })
                      .onChange((isSelected: boolean) => {
                        Logger.info(TAG, `Checkbox onChange: ${task.id}, isSelected: ${isSelected}`);
                        this.toggleTaskSelection(task.id);
                      })

                    Text('选择')
                      .fontSize(12)
                      .fontColor('#666666')
                  }
                  .margin({ right: 12 })
                }

                // 任务描述
                Column() {
                  // 第一行：时间描述
                  Text(this.getTimeDescription(task))
                    .fontSize(14)
                    .fontColor('#333333')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  // 第二行：音量设置
                  if (task.volumeSettings && task.volumeSettings.length > 0) {
                    Text(this.getVolumeDescription(task))
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
                  Toggle({ type: ToggleType.Switch, isOn: task.status === TaskStatus.ENABLED })
                    .width(50)
                    .height(26)
                    .selectedColor('#007DFF')
                    .onChange((isOn: boolean) => {
                      this.toggleTaskStatus(task.id);
                    })

                  Blank().width(12)

                  // 删除按钮
                  Stack() {
                    // 进度圈
                    if (this.deletingTaskId === task.id) {
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
                        if (this.deletingTaskId !== task.id) {
                          this.startDelete(task.id);
                        }
                      })
                      .onActionEnd(() => {
                        this.cancelDelete();
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
                if (this.isMultiSelectMode) {
                  this.toggleTaskSelection(task.id);
                }
              })
              .gesture(
                LongPressGesture({ duration: 500 })
                  .onAction(() => {
                    // 非多选模式下，长按进入多选模式
                    if (!this.isMultiSelectMode) {
                      this.enterMultiSelectMode(task.id);
                    }
                  })
              )
            }
          }, (task: TimerTask) => `${task.id}_${this.refreshCounter}`)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 12, bottom: 80 })
      }

      // 悬浮按钮
      if (!this.isMultiSelectMode) {
        Button() {
          SymbolGlyph($r('sys.symbol.plus'))
            .fontSize(24)
            .fontColor([Color.White])
        }
        .width(56)
        .height(56)
        .borderRadius(28)
        .backgroundColor('#007DFF')
        .position({ x: '50%', y: '100%' })
        .translate({ x: '-50%', y: '-72' })
        .onClick(() => {
          // 跳转到创建页面
          try {
            router.pushUrl({
              url: 'pages/TimerTaskCreatePage'
            });
          } catch (err) {
            Logger.error(TAG, `Failed to navigate to create page: ${JSON.stringify(err)}`);
          }
        })
      }

      // 多选操作栏
      if (this.isMultiSelectMode) {
        Column() {
          Blank().layoutWeight(1)

          MultiSelectBar({
            selectedCount: this.selectedTaskIds.length,
            existingGroups: this.groupList.map(g => g.group),
            onCreateGroup: () => {
              this.createGroup();
            },
            onAddToGroup: (groupId: string) => {
              this.addTasksToExistingGroup(groupId);
            },
            onCancel: () => {
              this.exitMultiSelectMode();
            }
          })
        }
        .width('100%')
        .height('100%')
        .position({ x: 0, y: 0 })
        .hitTestBehavior(HitTestMode.Transparent)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  /**
   * 页面销毁时清理
   */
  aboutToDisappear() {
    if (this.deleteTimer !== -1) {
      clearInterval(this.deleteTimer);
    }
  }

  /**
   * 任务卡片Builder（直接访问父组件状态）
   */
  @Builder
  TaskCardBuilder(task: TimerTask, index: number) {
    Row() {
      // 多选模式下显示复选框
      if (this.isMultiSelectMode) {
        Row() {
          Checkbox()
            .select(this.selectedTaskIds.includes(task.id))
            .selectedColor('#0A59F7')
            .shape(CheckBoxShape.CIRCLE)
            .margin({ right: 8 })
            .onChange((isSelected: boolean) => {
              Logger.info(TAG, `Checkbox onChange: ${task.id}, isSelected: ${isSelected}`);
              this.toggleTaskSelection(task.id);
            })

          Text('选择')
            .fontSize(12)
            .fontColor('#666666')
        }
        .margin({ right: 12 })
      }

      // 任务描述
      Column() {
        // 第一行：时间描述
        Text(this.getTimeDescription(task))
          .fontSize(14)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 第二行：音量设置
        if (task.volumeSettings && task.volumeSettings.length > 0) {
          Text(this.getVolumeDescription(task))
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
        Toggle({ type: ToggleType.Switch, isOn: task.status === TaskStatus.ENABLED })
          .width(50)
          .height(26)
          .selectedColor('#007DFF')
          .onChange((isOn: boolean) => {
            this.toggleTaskStatus(task.id);
          })

        Blank().width(12)

        // 删除按钮
        Stack() {
          // 进度圈
          if (this.deletingTaskId === task.id) {
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
              if (this.deletingTaskId !== task.id) {
                this.startDelete(task.id);
              }
            })
            .onActionEnd(() => {
              this.cancelDelete();
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
      if (this.isMultiSelectMode) {
        this.toggleTaskSelection(task.id);
      }
    })
    .gesture(
      LongPressGesture({ duration: 500 })
        .onAction(() => {
          // 非多选模式下，长按进入多选模式
          if (!this.isMultiSelectMode) {
            this.enterMultiSelectMode(task.id);
          }
        })
    )
  }

  /**
   * 获取时间描述（只显示时间部分）
   */
  private getTimeDescription(task: TimerTask): string {
    const timeStr = `${task.hour.toString().padStart(2, '0')}:${task.minute.toString().padStart(2, '0')}`;

    if (task.timeMode === TimeMode.ONCE) {
      return `${timeStr} 一次性`;
    } else if (task.timeMode === TimeMode.WEEKLY) {
      const weekDays = ['日', '一', '二', '三', '四', '五', '六'];
      if (task.dayOfWeek !== undefined) {
        return `${timeStr} 每周${weekDays[task.dayOfWeek]}`;
      }
      return `${timeStr} 每周`;
    } else if (task.timeMode === TimeMode.MONTHLY) {
      return `${timeStr} 每月${task.dayOfMonth}日`;
    }

    return timeStr;
  }

  /**
   * 获取音量描述
   */
  private getVolumeDescription(task: TimerTask): string {
    if (!task.volumeSettings || task.volumeSettings.length === 0) {
      return '';
    }

    const volumeTypes: string[] = [];
    for (const setting of task.volumeSettings) {
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
