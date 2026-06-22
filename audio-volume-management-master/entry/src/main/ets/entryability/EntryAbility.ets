/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { Logger } from '../framework/utils/Logger';
import { common } from '@kit.AbilityKit';
import { TimerTaskDatabase } from '../framework/data/TimerTaskDatabase';
import { TimerTaskService } from '../framework/service/TimerTaskService';
import { VolumeService } from '../framework/service/VolumeService';
import { TimerScheduler } from '../framework/service/TimerScheduler';

const DOMAIN = 0x0000;
const TAG = 'EntryAbility';

export default class EntryAbility extends UIAbility {
  // 全局context,供非UI组件使用
  // 升级说明: 替代getContext(this) as Context,避免弃用API警告
  static context: common.Context;
  
  // 全局调度器
  static scheduler: TimerScheduler | null = null;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 保存全局context
    EntryAbility.context = this.context;

    // 处理分享数据
    this.handleShareData(want);

    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  /**
   * 处理接收到的分享数据
   */
  private handleShareData(want: Want): void {
    try {
      if (want.parameters) {
        const shareType = want.parameters['share_type'] as string;
        const shareData = want.parameters['share_data'] as string;

        if (shareType === 'timer_tasks' && shareData) {
          Logger.info(TAG, 'Received shared timer tasks');
          
          // 保存分享数据到AppStorage，供UI处理
          AppStorage.setOrCreate('pendingShareData', shareData);
          
          Logger.info(TAG, 'Share data saved to AppStorage');
        }
      }
    } catch (error) {
      Logger.error(TAG, `Failed to handle share data: ${JSON.stringify(error)}`);
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('application/pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      windowStage.getMainWindow().then((window: window.Window) => {
        window.setWindowLayoutFullScreen(true).catch(() => {
          Logger.error('setWindowLayoutFullScreen error!');
        });
        AppStorage.setOrCreate('windowClass', window);
      }).catch(() => {
        Logger.error('getMainWindow error!');
      })
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
    Logger.info(TAG, 'onForeground called');
    
    // 初始化任务调度器并恢复所有任务
    (async () => {
      try {
        Logger.info(TAG, 'Starting to initialize task scheduler');
        
        if (!EntryAbility.scheduler) {
          Logger.info(TAG, 'Creating database instance');
          const database = new TimerTaskDatabase(this.context);
          await database.initialize();
          Logger.info(TAG, 'Database initialized');
          
          Logger.info(TAG, 'Creating task service');
          const taskService = new TimerTaskService(database);
          
          Logger.info(TAG, 'Creating volume service');
          const volumeService = new VolumeService();
          
          Logger.info(TAG, 'Creating scheduler');
          const scheduler = new TimerScheduler(taskService, volumeService);
          
          EntryAbility.scheduler = scheduler;
          Logger.info(TAG, 'Scheduler created');
          
          // 恢复所有启用的任务
          Logger.info(TAG, 'Rescheduling all tasks');
          await scheduler.rescheduleAllTasks();
          
          Logger.info(TAG, 'Task scheduler initialized and all tasks rescheduled');
        } else {
          Logger.info(TAG, 'Scheduler already initialized');
        }
      } catch (error) {
        Logger.error(TAG, `Failed to initialize scheduler: ${JSON.stringify(error)}`);
      }
    })();
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}