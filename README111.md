# Audio Volume Management 项目详解  （原始项目）

## 一、功能介绍

本项目是一个基于 **HarmonyOS** 开发的音频流音量管理示例应用，展示了多种音量控制功能的实现。

### 核心功能

#### 1. 自定义系统音量面板
替代系统默认的音量条UI，提供自定义的音量调节面板。通过将 `AVVolumePanel` 组件位置设置为屏幕外(-1, -1)来隐藏系统默认音量条，创建自定义垂直滑块组件显示音量，通过手势或音量键触发显示，3秒后自动隐藏。

#### 2. 手势调节系统音量
支持通过上下滑动手势来调节系统音量。使用 `PanGesture` 手势识别器检测垂直滑动，根据滑动距离计算音量变化值，向上滑动增加音量，向下滑动减少音量。

#### 3. 应用音量调节
独立于系统音量，可以单独调节当前应用的音量大小。使用 `AudioVolumeManager.setAppVolumePercentage()` 设置应用音量（0-100百分比），应用音量 × 系统音量 = 实际播放音量。

#### 4. 音频流音量调节
通过 AudioRenderer 控制音频流的音量，实现更精细的音频播放控制。使用 `AudioRenderer.setVolume()` 设置音频流音量（0.0-1.0范围），仅影响当前音频渲染器的音量。

#### 5. 音量键拦截与禁用
可以拦截系统的音量键事件，并支持禁用音量键功能。使用 `inputConsumer.on('keyPressed')` 注册音量键监听，优先消费按键事件，阻止系统默认行为。

---

## 二、项目文件结构及功能说明

### 核心源代码文件

#### 1. CommonConstants.ets
**路径**: `entry/src/main/ets/common/CommonConstants.ets`
**功能**: 定义应用中使用的常量值，包括初始音量值、应用初始音量值、最小和最大音量值等，便于统一管理和维护。

#### 2. EntryAbility.ets
**路径**: `entry/src/main/ets/entryability/EntryAbility.ets`
**功能**: 应用的入口Ability，负责应用生命周期管理和窗口初始化。在 `onCreate` 中设置颜色模式，在 `onWindowStageCreate` 中加载首页并设置全屏显示，将窗口对象存储到AppStorage供全局使用。

#### 3. Index.ets
**路径**: `entry/src/main/ets/pages/Index.ets`
**功能**: 应用首页，展示功能介绍和进入播放页的入口。使用 `NavPathStack` 导航栈管理页面跳转，通过 `ForEach` 循环渲染功能介绍列表。

#### 4. Player.ets
**路径**: `entry/src/main/ets/pages/Player.ets`
**功能**: 音频播放和音量控制的核心页面，实现所有音量管理功能。包括音量键拦截、手势调节音量、禁用音量键开关等核心功能。

#### 5. AudioRendererController.ets
**路径**: `entry/src/main/ets/player/AudioRendererController.ets`
**功能**: 控制音频播放的核心类，负责音频数据的读取、播放控制和音量设置。包括初始化音频渲染器、写入音频数据、播放控制方法（开始、暂停、跳转、停止、释放资源、设置音量）等。

#### 6. AudioVolumeController.ets
**路径**: `entry/src/main/ets/player/AudioVolumeController.ets`
**功能**: 管理系统音量和应用音量的核心类。提供创建音量管理器、系统音量操作、监听音量变化、应用音量操作等功能。

#### 7. VolumePanelView.ets
**路径**: `entry/src/main/ets/components/VolumePanelView.ets`
**功能**: 通用的音量调节滑块组件，支持应用音量和音频流音量两种类型。使用 `@State` 和 `@Prop` 装饰器管理状态，通过 `setTimeout` 防抖避免频繁调用API。

#### 8. ControlAreaComponent.ets
**路径**: `entry/src/main/ets/components/ControlAreaComponent.ets`
**功能**: 音频播放控制区域，包含播放进度条、播放/暂停按钮等。通过 `@StorageLink` 连接AppStorage中的数据，使用 `getRawFd` 获取资源文件的文件描述符。

#### 9. MediaTools.ets
**路径**: `entry/src/main/ets/utils/MediaTools.ets`
**功能**: 提供媒体相关的工具方法，主要用于时间和字节转换。包括毫秒转倒计时格式、字节长度转毫秒时间、时间转字节偏移等方法。
## 项目结构

```
audio-volume-management-master/
├── entry/                              # 主模块目录
│   ├── src/main/
│   │   ├── ets/                        # ArkTS源代码目录
│   │   │   ├── common/                 # 公共常量模块
│   │   │   │   └── CommonConstants.ets # 常量定义类
│   │   │   ├── components/             # UI组件模块
│   │   │   │   ├── AVVolumePanelView.ets        # 系统音量条组件(隐藏系统默认)
│   │   │   │   ├── ControlAreaComponent.ets     # 播放控制区域组件
│   │   │   │   ├── SystemVolumePanelView.ets   # 自定义系统音量条组件
│   │   │   │   └── VolumePanelView.ets         # 音量调节面板组件
│   │   │   ├── entryability/
│   │   │   │   └── EntryAbility.ets   # 应用入口Ability
│   │   │   ├── entrybackupability/
│   │   │   │   └── EntryBackupAbility.ets # 备份Ability
│   │   │   ├── model/
│   │   │   │   └── SongData.ets        # 歌曲数据模型
│   │   │   ├── pages/
│   │   │   │   ├── Index.ets           # 首页
│   │   │   │   └── Player.ets          # 播放页
│   │   │   ├── player/                 # 音频播放控制模块
│   │   │   │   ├── AudioRendererController.ets  # 音频渲染控制器
│   │   │   │   └── AudioVolumeController.ets    # 音量管理控制器
│   │   │   ├── utils/                  # 工具类模块
│   │   │   │   ├── ColorTools.ets      # 颜色处理工具
│   │   │   │   ├── Logger.ets          # 日志工具
│   │   │   │   └── MediaTools.ets      # 媒体处理工具
│   │   │   └── viewModel/
│   │   │       └── PlayerViewModel.ets # 播放页视图模型
│   │   ├── resources/                  # 资源文件目录
│   │   │   ├── base/                   # 基础资源
│   │   │   │   ├── element/            # 字符串、颜色等资源
│   │   │   │   ├── media/              # 图片、图标资源
│   │   │   │   └── profile/            # 配置文件
│   │   │   ├── rawfile/                # 原始文件(音频文件)
│   │   │   ├── en_US/                  # 英文资源
│   │   │   └── zh_CN/                  # 中文资源
│   │   └── module.json5                # 模块配置文件
│   ├── build-profile.json5             # 构建配置
│   └── oh-package.json5                # 包依赖配置
├── AppScope/                           # 应用全局配置
├── hvigor/                             # 构建工具配置
├── screenshots/                        # 截图目录
├── build-profile.json5                 # 项目构建配置
├── oh-package.json5                    # 项目包配置
└── README.md                           # 项目说明文档
```
---

## 三、代码实现逻辑详解

### 1. 音量管理实现流程

#### 系统音量管理流程
整个流程分为三个阶段：
- **初始化阶段**：在 `SystemVolumePanel` 组件的 `aboutToAppear` 生命周期中创建音量管理器
```typescript
public creatVolumeManager(): void {
  let audioManager = audio.getAudioManager();
  this.audioVolumeManager = audioManager.getVolumeManager();
  this.onStreamVolumeChange(); // 注册音量变化监听
}
```

- **音量调节阶段**：通过 `Player.ets` 中的 `keyIntercept()` 方法拦截按键事件或 `PanGesture` 手势识别滑动操作，更新 `volume` 状态变量

- **UI更新阶段**：通过 `@StorageLink` 装饰器自动监听 AppStorage 中的变化，UI组件自动重新渲染显示最新音量值

#### 应用音量管理流程
`VolumePanelView` 组件创建时判断音量类型，如果是 `APPVOLUME` 类型则调用 `getAppVolumePercentage()` 获取当前应用音量并注册应用音量变化监听器。用户拖动滑块触发 `onChange` 回调，使用 `setTimeout` 防抖100ms后执行音量设置：
```typescript
.onChange((value: number) => {
  this.volume = value;
  clearTimeout(this.timer);
  this.timer = setTimeout(() => {
    this.audioVolumeController.setAppVolumePercentage(value);
  }, 100);
})
```
应用音量使用百分比表示（0-100），滑块值为0-15，需要转换为百分比：`value * 100 / 15`。

#### 音频流音量管理流程
`AudioRendererController.setVolume(value)` 接收0-15的音量值，转换为0-1的范围：
```typescript
public setVolume(value: number): void {
  this.audioRenderer?.setVolume(value / 15);
  AppStorage.setOrCreate('audioStreamVolume', value / 15);
}
```
音频流音量仅影响当前音频渲染器的音量，与系统音量（影响整个系统的所有音频）和应用音量（影响当前应用的所有音频流）不同。

### 2. 音频播放实现流程

应用启动后通过 `EntryAbility.onCreate()` 加载首页 `Index.ets`，用户点击进入播放页导航到 `Player.ets`，在 `Player.aboutToAppear()` 中初始化音频控制器。`ControlAreaComponent.aboutToAppear()` 通过 `getRawFd` 获取音频文件的文件描述符，然后调用 `AudioRendererController.initAudioRenderer()` 创建音频渲染器，配置音频参数：
```typescript
let audioStreamInfo: audio.AudioStreamInfo = {
  samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_48000,  // 48kHz采样率
  channels: audio.AudioChannel.CHANNEL_2,                   // 双声道
  sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE, // 16位小端
  encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW   // 原始PCM数据
};
```

用户点击播放后调用 `AudioRendererController.start()`，触发 `audioRenderer.start()` 并启动 `writeData` 回调。音频渲染器不断触发 `writeData` 回调要求填充音频数据：
```typescript
this.audioRenderer?.on('writeData', (buffer) => {
  // 从文件读取数据到buffer
  let options: ReadOptions = {
    offset: this.currentOffset,
    length: buffer.byteLength
  };
  fileIo.readSync(this.fd, buffer, options);
  this.currentOffset += buffer.byteLength;

  // 更新播放进度
  let curMs = MediaTools.getMsFromByteLength(this.currentOffset - this.offset);
  AppStorage.setOrCreate('progress', curMs);
})
```
当播放到文件末尾时自动循环到开头。

播放控制包括开始播放（设置音量并启动渲染器）、暂停播放（暂停渲染器）、跳转播放（计算文件偏移并更新 `currentOffset`）等操作。

### 3. 音量键拦截实现

使用 `inputConsumer` 模块注册按键事件监听器，优先消费音量键事件，阻止系统默认行为。配置 `KeyPressedConfig` 指定要监听的按键类型：
```typescript
let options1: inputConsumer.KeyPressedConfig = {
  key: KeyCode.KEYCODE_VOLUME_UP,  // 音量加键
  action: 1,                        // 按下动作
  isRepeat: false                   // 不重复上报
};

this.volumeUpCallBackFunc = (event: KeyEvent) => {
  if (this.isDisabled) {
    // 已禁用，显示提示
    this.getUIContext().getPromptAction().showToast({ message: '音量键已禁用' });
    return;
  }
  // 未禁用，调节音量
  this.volume = this.volume + 1;
  this.systemVolumeVisible = true;
};

inputConsumer.on('keyPressed', options1, this.volumeUpCallBackFunc);
```
如果 `isDisabled` 为 true 则只显示提示不调节音量，实现了禁用音量键的功能。

### 4. 手势调节音量实现

使用 `PanGesture` 手势识别器检测垂直滑动，通过 `PanDirection.Vertical` 限制只识别垂直滑动：
```typescript
.gesture(
  PanGesture({ direction: PanDirection.Vertical })
    .onActionUpdate((event: GestureEvent) => {
      this.systemVolumeVisible = true;

      // 计算新音量（向上滑动增加，向下滑动减少）
      let curVolume = this.volume - this.getUIContext().vp2px(event.offsetY) / this.windowHeight;

      // 限制范围
      curVolume = curVolume >= 15.0 ? 15.0 : curVolume;
      curVolume = curVolume <= 0.0 ? 0.0 : curVolume;

      this.volume = curVolume;

      // 3秒后自动隐藏
      clearTimeout(this.timer);
      this.timer = setTimeout(() => {
        this.systemVolumeVisible = false;
      }, 3000);
    })
)
```
`event.offsetY` 是滑动的垂直偏移量（向上滑动为负值，向下滑动为正值），通过 `vp2px` 转换确保在不同屏幕密度下表现一致。

### 5. 隐藏系统音量条实现

使用系统提供的 `AVVolumePanel` 组件，但将其位置设置为屏幕外坐标(-1, -1)，使其不可见：
```typescript
AVVolumePanel({
  volumeLevel: this.volume,
  volumeParameter: {
    position: {
      x: -1,  // 屏幕外
      y: -1
    }
  }
})
```
同时创建自定义的垂直滑块组件 `SystemVolumePanel` 显示音量，通过手势或音量键触发显示，3秒后自动隐藏。

### 6. 核心技术点

**AppStorage 状态管理**：使用 `@StorageLink`（双向绑定，组件可修改值）和 `@StorageProp`（单向绑定，组件只读）装饰器实现跨组件状态共享。

**AudioKit 音频框架**：`AudioVolumeManager` 用于音量管理，`AudioRenderer` 用于音频渲染播放，`AVVolumePanel` 用于系统音量面板。通过 `audio.getAudioManager()` 获取音频管理器，然后通过 `getVolumeManager()` 获取音量管理器。

**InputKit 输入框架**：`inputConsumer.on('keyPressed')` 用于按键事件监听，`KeyCode` 是按键码枚举。

**手势识别**：`PanGesture` 用于滑动手势，`GestureEvent` 是手势事件。

**文件操作**：`resourceManager.getRawFd()` 用于获取资源文件描述符，`fileIo.readSync()` 用于同步读取文件。
