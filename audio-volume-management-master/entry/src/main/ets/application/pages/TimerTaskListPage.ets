import { router } from '@kit.ArkUI';
import { TimerTask, TimerTaskModel, OnceMode } from '../../framework/model/TimerTask';
import { VolumeSetting } from '../../framework/model/VolumeSetting';
import { TaskStatus, VolumeType, TimeMode, TaskType, LockStatus } from '../../framework/model/TaskEnums';
import { TaskGroup, GroupStatus, GroupWithTasks } from '../../framework/model/TaskGroup';
import { TimerTaskViewModel } from '../viewModel/TimerTaskViewModel';
import { TaskGroupViewModel } from '../viewModel/TaskGroupViewModel';
import { TimerTaskDatabase } from '../../framework/data/TimerTaskDatabase';
import { TimerTaskService } from '../../framework/service/TimerTaskService';
import { TaskGroupService } from '../../framework/service/TaskGroupService';
import { VolumeService } from '../../framework/service/VolumeService';
import { TimerScheduler } from '../../framework/service/TimerScheduler';
import { Logger } from '../../framework/utils/Logger';
import { formatOnceTaskTime } from '../../framework/utils/DateUtils';
import { TaskShareService } from '../../framework/service/TaskShareService';
import { DistributedShareService, DeviceInfo } from '../../framework/service/DistributedShareService';
import { BackgroundService } from '../../framework/service/BackgroundService';
import { DeviceSelectDialog } from '../components/DeviceSelectDialog';
import { BackgroundCropComponent } from '../components/BackgroundCropComponent';
import { TaskGroupCard } from '../components/TaskGroupCard';
import { SessionInputDialog } from '../components/SessionInputDialog';
import { TaskReceiveNotification } from '../components/TaskReceiveNotification';
import picker from '@ohos.file.picker';
import { MultiSelectBar } from '../components/MultiSelectBar';
import { CreateGroupDialog } from '../components/CreateGroupDialog';
import { TaskCardComponent } from '../components/TaskCardComponent';
import promptAction from '@ohos.promptAction';
import EntryAbility from '../../entryability/EntryAbility';
import common from '@ohos.app.ability.common';

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
  @State selectedGroupIds: string[] = []; // 新增：选中的组合体ID列表
  @State private refreshCounter: number = 0; // 强制刷新计数器

  // 组合体状态
  @State groupList: GroupWithTasks[] = [];
  @State expandedGroupIds: Set<string> = new Set<string>();

  // 对话框控制器
  private createGroupDialogController: CustomDialogController | null = null;

  private viewModel: TimerTaskViewModel | null = null;
  private groupViewModel: TaskGroupViewModel | null = null;
  private deleteTimer: number = -1;
  private shareService: TaskShareService = new TaskShareService();
  private distributedShareService: DistributedShareService = new DistributedShareService();
  private backgroundService: BackgroundService | null = null;
  
  // 背景图片路径
  @State backgroundImagePath: string = '';
  
  // 设备选择对话框控制器
  private deviceSelectDialogController: CustomDialogController | null = null;
  // 图片裁剪对话框控制器
  private cropDialogController: CustomDialogController | null = null;
  // 会话输入对话框控制器
  private sessionInputDialogController: CustomDialogController | null = null;
  // 任务接收通知对话框控制器
  private taskReceiveNotificationController: CustomDialogController | null = null;
  // 当前会话ID
  @State currentSessionId: string = '';
  @State currentDeviceId: string = '';
  // 待接收的任务
  @State pendingReceivedTasks: TimerTask[] = [];

  async aboutToAppear() {
    try {
      // 初始化服务
      // 升级说明: 使用EntryAbility.context替代getContext(this),避免弃用API警告
      const context = EntryAbility.context;
      const database = new TimerTaskDatabase(context);
      await database.initialize();

      const taskService = new TimerTaskService(database);
      const groupService = new TaskGroupService(database, taskService);
      const volumeService = new VolumeService();
      const scheduler = new TimerScheduler(taskService, volumeService);

      this.viewModel = new TimerTaskViewModel(taskService, scheduler);
      this.groupViewModel = new TaskGroupViewModel(groupService, taskService);
      
      // 初始化背景服务
      this.backgroundService = new BackgroundService(context);
      await this.backgroundService.initialize();
      
      // 加载背景图片
      await this.loadBackgroundImage();

      // 初始化分布式分享服务
      await this.distributedShareService.initialize(context as common.UIAbilityContext);
      
      // 注册任务接收回调
      this.distributedShareService.setTasksReceivedCallback((tasks: TimerTask[]) => {
        this.onTasksReceivedFromRemote(tasks);
      });
      
      // 获取当前设备信息
      this.currentDeviceId = this.distributedShareService.getDeviceId();
      this.currentSessionId = this.distributedShareService.getSessionId();

      // 加载任务列表
      await this.loadTasks();
    } catch (error) {
      Logger.error(TAG, `Failed to initialize: ${JSON.stringify(error)}`);
      this.isLoading = false;
    }
  }

  /**
   * 页面显示时重新加载任务列表和会话状态
   */
  async onPageShow() {
    // 重新获取会话状态（用户可能在其他页面创建了会话）
    this.currentSessionId = this.distributedShareService.getSessionId();
    this.currentDeviceId = this.distributedShareService.getDeviceId();
    Logger.info(TAG, `Page show - sessionId: ${this.currentSessionId}, deviceId: ${this.currentDeviceId}`);
    
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

      // 加载任务列表（显示所有任务，不过滤组合体任务）
      this.taskList = await this.viewModel.loadTasks();

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
    this.selectedGroupIds = []; // 清空组合体选择
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
   * 切换组合体选中状态
   */
  toggleGroupSelection(groupId: string) {
    Logger.info(TAG, `toggleGroupSelection: ${groupId}, current: ${JSON.stringify(this.selectedGroupIds)}`);
    const index = this.selectedGroupIds.indexOf(groupId);
    if (index >= 0) {
      this.selectedGroupIds.splice(index, 1);
    } else {
      this.selectedGroupIds.push(groupId);
    }
    // 触发状态更新
    this.selectedGroupIds = [...this.selectedGroupIds];
    this.refreshCounter++; // 触发刷新
    Logger.info(TAG, `after toggle group: ${JSON.stringify(this.selectedGroupIds)}`);
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
   * 分享选中的任务和组合体
   */
  async shareSelectedTasks() {
    try {
      Logger.info(TAG, '=== SHARE SELECTED TASKS ===');
      Logger.info(TAG, `Current session ID: ${this.currentSessionId}`);
      
      // 检查是否已加入协同组
      if (!this.currentSessionId) {
        Logger.error(TAG, 'No session ID, cannot share');
        promptAction.showToast({ message: '请先加入协同组' });
        this.showSessionInputDialog();
        return;
      }

      // 获取选中的任务
      const selectedTasks = this.taskList.filter(task =>
        this.selectedTaskIds.includes(task.id)
      );

      // 获取选中组合体的所有任务
      const selectedGroupTasks: TimerTask[] = [];
      for (const groupId of this.selectedGroupIds) {
        const groupWithTasks = this.groupList.find(g => g.group.id === groupId);
        if (groupWithTasks) {
          selectedGroupTasks.push(...groupWithTasks.tasks);
        }
      }

      // 合并所有要分享的任务
      const allTasksToShare = [...selectedTasks, ...selectedGroupTasks];

      if (allTasksToShare.length === 0) {
        promptAction.showToast({ message: '请先选择要分享的任务或组合体' });
        return;
      }

      Logger.info(TAG, `Sharing ${allTasksToShare.length} tasks`);
      Logger.info(TAG, `Tasks count: ${allTasksToShare.length}`);
      
      // 使用分布式数据对象分享任务
      const success = await this.distributedShareService.shareTasksToDevice(
        allTasksToShare,
        'distributed'
      );

      Logger.info(TAG, `Share result: ${success}`);

      if (success) {
        const taskCount = selectedTasks.length;
        const groupCount = this.selectedGroupIds.length;
        let message = '';
        if (taskCount > 0 && groupCount > 0) {
          message = `成功分享 ${taskCount} 个任务和 ${groupCount} 个组合体到协同组`;
        } else if (taskCount > 0) {
          message = `成功分享 ${taskCount} 个任务到协同组`;
        } else {
          message = `成功分享 ${groupCount} 个组合体到协同组`;
        }
        promptAction.showToast({
          message: message,
          duration: 2000
        });
        this.exitMultiSelectMode();
      } else {
        promptAction.showToast({ message: '分享失败，请重试' });
      }

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to share: ${errorMessage}`);
      promptAction.showToast({ message: `分享失败: ${errorMessage}` });
    }
  }

  /**
   * 批量删除选中的任务和组合体
   */
  async deleteSelectedTasks() {
    const totalSelected = this.selectedTaskIds.length + this.selectedGroupIds.length;
    Logger.info(TAG, `deleteSelectedTasks: ${this.selectedTaskIds.length} tasks, ${this.selectedGroupIds.length} groups`);

    if (totalSelected === 0) {
      promptAction.showToast({ message: '请先选择要删除的任务或组合体' });
      return;
    }

    // 显示确认对话框
    promptAction.showDialog({
      title: '确认删除',
      message: `确定要删除选中的 ${this.selectedTaskIds.length} 个任务和 ${this.selectedGroupIds.length} 个组合体吗？`,
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '删除', color: '#FF3B30' }
      ]
    }).then(async (result) => {
      if (result.index === 1) {
        // 用户点击了删除按钮
        try {
          // 保存选中数量
          const deletedTaskCount = this.selectedTaskIds.length;
          const deletedGroupCount = this.selectedGroupIds.length;

          // 删除选中的任务
          for (const taskId of this.selectedTaskIds) {
            await this.viewModel!.deleteTask(taskId);
            Logger.info(TAG, `Deleted task: ${taskId}`);
          }

          // 删除选中的组合体（解散组合体）
          for (const groupId of this.selectedGroupIds) {
            await this.groupViewModel!.dissolveGroup(groupId);
            Logger.info(TAG, `Dissolved group: ${groupId}`);
          }

          // 退出多选模式
          this.exitMultiSelectMode();

          // 刷新列表
          await this.loadTasks();

          // 显示删除结果
          let message = '';
          if (deletedTaskCount > 0 && deletedGroupCount > 0) {
            message = `成功删除 ${deletedTaskCount} 个任务和 ${deletedGroupCount} 个组合体`;
          } else if (deletedTaskCount > 0) {
            message = `成功删除 ${deletedTaskCount} 个任务`;
          } else {
            message = `成功删除 ${deletedGroupCount} 个组合体`;
          }

          promptAction.showToast({
            message: message,
            duration: 2000
          });
        } catch (error) {
          const errorMessage = error instanceof Error ? error.message : 'Unknown error';
          Logger.error(TAG, `Failed to delete: ${errorMessage}`);
          promptAction.showToast({ message: `删除失败: ${errorMessage}` });
        }
      }
    });
  }

  /**
   * 加载可用设备列表
   */
  private async loadAvailableDevices() {
    try {
      const devices = await this.distributedShareService.getAvailableDevices();
      
      // 更新对话框中的设备列表
      if (this.deviceSelectDialogController) {
        // 注意：这里需要通过状态更新来刷新对话框
        // 由于CustomDialogController的限制，可能需要其他方式传递数据
        Logger.info(TAG, `Found ${devices.length} available devices for sharing`);
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to load devices: ${errorMessage}`);
    }
  }

  /**
   * 加载背景图片
   */
  private async loadBackgroundImage() {
    try {
      if (this.backgroundService) {
        const path = await this.backgroundService.getBackgroundPath();
        if (path) {
          this.backgroundImagePath = path;
          Logger.info(TAG, `Background image loaded: ${path}`);
        }
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to load background: ${errorMessage}`);
    }
  }

  /**
   * 选择背景图片
   */
  async selectBackgroundImage() {
    try {
      // 创建图片选择器
      const photoViewPicker = new picker.PhotoViewPicker();
      const pickerResult = await photoViewPicker.select({
        maxSelectNumber: 1,
        MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE
      });

      if (pickerResult && pickerResult.photoUris && pickerResult.photoUris.length > 0) {
        const imageUri = pickerResult.photoUris[0];
        Logger.info(TAG, `Selected image: ${imageUri}`);

        // 显示裁剪对话框
        this.showCropDialog(imageUri);
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to select image: ${errorMessage}`);
      promptAction.showToast({ message: `选择图片失败: ${errorMessage}` });
    }
  }

  /**
   * 显示裁剪对话框
   */
  private showCropDialog(imageUri: string) {
    this.cropDialogController = new CustomDialogController({
      builder: BackgroundCropComponent({
        imageUri: imageUri,
        screenRatio: 9 / 16, // 手机屏幕比例
        onCropComplete: async (cropX: number, cropY: number, cropWidth: number, cropHeight: number) => {
          // 裁剪完成，保存背景
          await this.saveCroppedBackground(imageUri, cropX, cropY, cropWidth, cropHeight);
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center,
      customStyle: true
    });

    this.cropDialogController.open();
  }

  /**
   * 保存裁剪后的背景图片
   */
  private async saveCroppedBackground(
    imageUri: string,
    cropX: number,
    cropY: number,
    cropWidth: number,
    cropHeight: number
  ) {
    try {
      if (!this.backgroundService) {
        return;
      }

      // 复制图片到私有目录
      const privatePath = await this.backgroundService.copyToPrivateDirectory(imageUri);
      if (!privatePath) {
        promptAction.showToast({ message: '保存图片失败' });
        return;
      }

      // 裁剪图片
      const croppedPath = await this.backgroundService.cropImage(
        privatePath,
        cropX,
        cropY,
        cropWidth,
        cropHeight
      );

      if (croppedPath) {
        // 保存背景路径
        await this.backgroundService.saveBackgroundPath(croppedPath);
        
        // 更新UI
        this.backgroundImagePath = croppedPath;
        
        promptAction.showToast({ message: '背景图片已设置' });
        Logger.info(TAG, `Background saved: ${croppedPath}`);
      } else {
        promptAction.showToast({ message: '裁剪图片失败' });
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to save cropped background: ${errorMessage}`);
      promptAction.showToast({ message: `保存失败: ${errorMessage}` });
    }
  }

  /**
   * 清除背景图片
   */
  async clearBackground() {
    try {
      if (this.backgroundService) {
        await this.backgroundService.clearBackground();
        this.backgroundImagePath = '';
        promptAction.showToast({ message: '背景已清除' });
        Logger.info(TAG, 'Background cleared');
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to clear background: ${errorMessage}`);
    }
  }

  /**
   * 显示背景编辑菜单
   */
  private showBackgroundMenu() {
    promptAction.showDialog({
      title: '设置',
      buttons: [
        { text: '选择背景图片', color: '#007DFF' },
        { text: '清除背景', color: '#FF0000' },
        { text: '自由流转设置', color: '#4CAF50' },
        { text: '取消', color: '#666666' }
      ]
    }).then((result) => {
      switch (result.index) {
        case 0:
          // 选择背景图片
          this.selectBackgroundImage();
          break;
        case 1:
          // 清除背景
          this.clearBackground();
          break;
        case 2:
          // 自由流转设置
          this.showSessionInputDialog();
          break;
        case 3:
          // 取消
          break;
      }
    }).catch((error: Error) => {
      Logger.error(TAG, `Dialog error: ${error.message}`);
    });
  }

  /**
   * 显示会话输入对话框
   */
  private showSessionInputDialog() {
    // 直接跳转到分布式会话页面
    Logger.info(TAG, 'Navigating to DistributedSessionPage');
    router.pushUrl({
      url: 'application/pages/DistributedSessionPage'
    }).catch((error: Error) => {
      Logger.error(TAG, `Failed to navigate: ${error.message}`);
    });
  }
  
  /**
   * 更新会话对话框状态
   */
  private updateSessionDialog() {
    Logger.info(TAG, `Updating session dialog: sessionId=${this.currentSessionId}, deviceId=${this.currentDeviceId}`);
    // 对话框会自动读取最新的状态值
  }

  /**
   * 创建新会话
   */
  private createSession() {
    try {
      Logger.info(TAG, 'Creating session...');
      
      const sessionId = this.distributedShareService.generateSessionId();
      if (!sessionId) {
        Logger.error(TAG, 'Failed to generate session ID');
        promptAction.showToast({
          message: '创建协同组失败：无法生成SessionId',
          duration: 2000
        });
        return;
      }
      
      Logger.info(TAG, `Generated session ID: ${sessionId}`);
      
      this.distributedShareService.setSessionId(sessionId);
      this.currentSessionId = sessionId;
      this.currentDeviceId = this.distributedShareService.getDeviceId();
      
      Logger.info(TAG, `Session created successfully, deviceId: ${this.currentDeviceId}`);
      
      promptAction.showToast({
        message: `已创建协同组\nSessionId: ${sessionId}`,
        duration: 3000
      });
    } catch (error) {
      Logger.error(TAG, `Failed to create session: ${JSON.stringify(error)}`);
      promptAction.showToast({
        message: `创建协同组失败: ${error}`,
        duration: 2000
      });
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
      this.currentDeviceId = this.distributedShareService.getDeviceId();
      
      Logger.info(TAG, `Joined session successfully, deviceId: ${this.currentDeviceId}`);
      
      promptAction.showToast({
        message: `已加入协同组`,
        duration: 2000
      });
    } catch (error) {
      Logger.error(TAG, `Failed to join session: ${JSON.stringify(error)}`);
      promptAction.showToast({
        message: `加入协同组失败: ${error}`,
        duration: 2000
      });
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
      
      Logger.info(TAG, 'Left session successfully');
      
      promptAction.showToast({
        message: '已离开协同组',
        duration: 2000
      });
    } catch (error) {
      Logger.error(TAG, `Failed to leave session: ${JSON.stringify(error)}`);
      promptAction.showToast({
        message: `离开协同组失败: ${error}`,
        duration: 2000
      });
    }
  }

  /**
   * 接收到远程任务
   */
  private async onTasksReceivedFromRemote(tasks: TimerTask[]) {
    try {
      Logger.info(TAG, `=== RECEIVED TASKS FROM REMOTE ===`);
      Logger.info(TAG, `Tasks count: ${tasks.length}`);
      Logger.info(TAG, `Tasks data: ${JSON.stringify(tasks)}`);
      
      // 显示任务接收通知对话框
      this.pendingReceivedTasks = tasks;
      
      Logger.info(TAG, 'Calling showTaskReceiveNotification...');
      this.showTaskReceiveNotification(tasks);
      
      Logger.info(TAG, 'showTaskReceiveNotification called successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to handle received tasks: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 显示任务接收通知
   */
  private showTaskReceiveNotification(tasks: TimerTask[]) {
    Logger.info(TAG, `=== SHOWING TASK RECEIVE NOTIFICATION ===`);
    Logger.info(TAG, `Creating dialog for ${tasks.length} tasks`);
    
    this.taskReceiveNotificationController = new CustomDialogController({
      builder: TaskReceiveNotification({
        receivedTasks: tasks,
        onAccept: async (acceptedTasks: TimerTask[]) => {
          Logger.info(TAG, 'User accepted tasks');
          await this.acceptReceivedTasks(acceptedTasks);
        },
        onReject: () => {
          Logger.info(TAG, 'User rejected received tasks');
          promptAction.showToast({
            message: '已拒绝接收任务',
            duration: 2000
          });
        }
      }),
      autoCancel: false,
      alignment: DialogAlignment.Center,
      customStyle: true
    });
    
    Logger.info(TAG, 'Opening task receive notification dialog...');
    this.taskReceiveNotificationController.open();
    Logger.info(TAG, 'Dialog opened successfully');
  }
  
  /**
   * 接收任务
   */
  private async acceptReceivedTasks(tasks: TimerTask[]) {
    try {
      Logger.info(TAG, `Accepting ${tasks.length} tasks`);
      
      if (!this.viewModel) {
        Logger.error(TAG, 'ViewModel not initialized');
        return;
      }

      // 保存接收到的任务
      for (const task of tasks) {
        await this.viewModel.createTask(task);
      }

      // 重新加载任务列表
      await this.loadTasks();

      promptAction.showToast({
        message: `成功接收 ${tasks.length} 个任务`,
        duration: 2000
      });
      
      Logger.info(TAG, `Successfully accepted ${tasks.length} tasks`);
    } catch (error) {
      Logger.error(TAG, `Failed to accept tasks: ${JSON.stringify(error)}`);
      promptAction.showToast({
        message: `接收任务失败: ${error}`,
        duration: 2000
      });
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
    Stack() {
      // 背景图片层
      if (this.backgroundImagePath) {
        Image('file://' + this.backgroundImagePath)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .blur(10) // 添加模糊效果，提高文字可读性
      }

      // 内容层
      Column() {
        // 顶部空白区域，避免被摄像头遮挡
        Blank()
          .height(32)

      // 导航栏
      Row() {
        // 返回按钮
        Row() {
          Image($r('app.media.chevron_left'))
            .width(20)
            .height(20)
            .fillColor('#FFFFFF')
        }
        .width(36)
        .height(36)
        .borderRadius(18)
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .justifyContent(FlexAlign.Center)
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

        // 编辑按钮（背景设置）
        Row() {
          Image($r('app.media.gearshape'))
            .width(20)
            .height(20)
            .fillColor('#FFFFFF')
        }
        .width(36)
        .height(36)
        .borderRadius(18)
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          // 显示背景编辑菜单
          this.showBackgroundMenu();
        })
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
                isMultiSelectMode: this.isMultiSelectMode,
                isSelected: this.selectedGroupIds.includes(groupWithTasks.group.id),
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
                },
                onToggleSelection: (groupId: string) => {
                  this.toggleGroupSelection(groupId);
                },
                onEnterMultiSelect: (groupId: string) => {
                  this.isMultiSelectMode = true;
                  this.selectedGroupIds = [groupId];
                  this.refreshCounter++;
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
              url: 'application/pages/TimerTaskCreatePage'
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
            onShare: () => {
              this.shareSelectedTasks();
            },
            onDelete: () => {
              this.deleteSelectedTasks();
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
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.backgroundImagePath ? 'transparent' : '#F5F5F5')
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
   * 获取一次性模式标识
   */
  private getOnceModeTag(task: TimerTask): string {
    // 非单次任务不显示标识
    if (task.timeMode !== TimeMode.ONCE) {
      return '';
    }

    // 添加调试日志
    Logger.info(TAG, `getOnceModeTag: task.id=${task.id}, timeMode=${task.timeMode}, onceMode=${task.onceMode}`);

    // onceMode 不存在，默认显示"一次性"
    if (!task.onceMode) {
      Logger.info(TAG, `onceMode is undefined, returning default "一次性"`);
      return '一次性';
    }

    // 根据 onceMode 类型返回对应标识
    if (task.onceMode === OnceMode.DISPOSABLE) {
      Logger.info(TAG, `onceMode is DISPOSABLE, returning "一次性"`);
      return '一次性';
    } else if (task.onceMode === OnceMode.REUSABLE) {
      Logger.info(TAG, `onceMode is REUSABLE, returning "重复利用"`);
      return '重复利用';
    }

    // 其他情况默认显示"一次性"
    Logger.info(TAG, `onceMode is unknown value: ${task.onceMode}, returning default "一次性"`);
    return '一次性';
  }

  /**
   * 获取时间描述（只显示时间部分）
   */
  private getTimeDescription(task: TimerTask): string {
    const timeStr = `${task.hour.toString().padStart(2, '0')}:${task.minute.toString().padStart(2, '0')}`;

    let timeDescription: string;

    if (task.timeMode === TimeMode.ONCE) {
      timeDescription = formatOnceTaskTime(task.executeTime, task.hour, task.minute);
    } else if (task.timeMode === TimeMode.WEEKLY) {
      const weekDays = ['日', '一', '二', '三', '四', '五', '六'];
      if (task.dayOfWeek !== undefined) {
        timeDescription = `${timeStr} 每周${weekDays[task.dayOfWeek]}`;
      } else {
        timeDescription = `${timeStr} 每周`;
      }
    } else if (task.timeMode === TimeMode.MONTHLY) {
      timeDescription = `${timeStr} 每月${task.dayOfMonth}日`;
    } else {
      timeDescription = timeStr;
    }

    // 添加一次性模式标识
    const onceModeTag = this.getOnceModeTag(task);
    Logger.info(TAG, `getTimeDescription: task.id=${task.id}, timeDescription="${timeDescription}", onceModeTag="${onceModeTag}"`);
    if (onceModeTag) {
      const result = `${timeDescription} [${onceModeTag}]`;
      Logger.info(TAG, `Returning with tag: "${result}"`);
      return result;
    }

    Logger.info(TAG, `Returning without tag: "${timeDescription}"`);
    return timeDescription;
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
          if (setting.mute) {
            volumeTypes.push('媒体音量: 静音');
          } else {
            volumeTypes.push(`媒体音量: ${setting.volumeValue}%`);
          }
          break;
        case VolumeType.RINGTONE:
          if (setting.mute) {
            volumeTypes.push('铃声: 静音');
          } else {
            volumeTypes.push(`铃声: ${setting.volumeValue}%`);
          }
          break;
        case VolumeType.NOTIFICATION:
          if (setting.mute) {
            volumeTypes.push('通知音量: 静音');
          } else {
            volumeTypes.push(`通知音量: ${setting.volumeValue}%`);
          }
          break;
        case VolumeType.ALARM:
          if (setting.mute) {
            volumeTypes.push('闹钟音量: 静音');
          } else {
            volumeTypes.push(`闹钟音量: ${setting.volumeValue}%`);
          }
          break;
      }
    }

    return volumeTypes.join(' | ');
  }
}
