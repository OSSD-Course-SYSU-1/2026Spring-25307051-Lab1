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

import { BusinessError } from '@kit.BasicServicesKit';
import { effectKit } from '@kit.ArkGraphics2D';
import { image } from '@kit.ImageKit';
import { inputConsumer, KeyEvent } from '@kit.InputKit';
import { KeyCode } from '@kit.InputKit';
import { Logger } from '../utils/Logger';
import { ControlAreaComponent } from '../components/ControlAreaComponent';
import { ColorTools } from '../utils/ColorTools';
import { SetVolume } from '../components/AVVolumePanelView';
import { VolumePanelView } from '../components/VolumePanelView';
import { SystemVolumePanel } from '../components/SystemVolumePanelView';
import { songDataList, VolumeType } from '../viewModel/PlayerViewModel';
import { CommonConstants } from '../common/CommonConstants';
import { window } from '@kit.ArkUI';
import { AudioRendererController } from '../player/AudioRendererController';

@Builder
export function PlayerBuilder(name: string, param: Object) {
  Player()
}

@Builder
function VolumeSetting() {
  Column() {
    Row() {
      Text($r('app.string.disable'))
      Toggle({ type: ToggleType.Switch, isOn: false })
        .onChange((isOn: boolean) => {
          if (isOn) {
            AppStorage.setOrCreate('isDisabled', true);
          } else {
            AppStorage.setOrCreate('isDisabled', false);
          }
        })
    }
    .padding({ left: 16, right: 16 })
    .height(48)
    .justifyContent(FlexAlign.SpaceBetween)
    .width('100%')
    .margin({ bottom: 8 })

    Divider()
      .backgroundColor('#F1F3F5')
      .padding({ left: 16, right: 16 })
      .width('100%')

    Column() {
      VolumePanelView({
        text: $r('app.string.audio_stream_volume'),
        volumeVisible: true,
        volumeType: VolumeType.AUDIOSTREAM,
        Percentage: 50
      })
      Divider()
        .backgroundColor('#F1F3F5')
        .width('100%')
      VolumePanelView({
        text: $r('app.string.application_volume'),
        volumeVisible: true,
        volumeType: VolumeType.APPVOLUME,
        Percentage: 50
      })
    }
    .padding({ left: 16, right: 16 })
    .height(160)
    .width('100%')
  }
  .backgroundColor('#FFFFFF')
  .width('100%')
  .height(372)
  .padding({
    top: 12,
    bottom: 16
  })
}

@Entry
@Component
struct Player {
  @State imageColor: string = 'rgba(0, 0, 2, 1.00)';
  @State imageLabel: PixelMap | Resource = songDataList[0].label;
  @State windowHeight: number = 300;
  @StorageLink('systemVolume') volume: number = CommonConstants.INITIAL_VOLUME;
  @State systemVolumeVisible: boolean = false;
  @StorageLink('isDisabled') isDisabled: boolean = false;
  @State sheetHeight: number = 372;
  @State isShow: boolean = false;
  private timer: number | undefined = 0;
  private volumeUpCallBackFunc: (event: KeyEvent) => void = () => {
  };
  private volumeDownCallBackFunc: (event: KeyEvent) => void = () => {
  };
  private audioRendererController: AudioRendererController | undefined = undefined;
  pageInfos: NavPathStack = new NavPathStack();
  private windowClass: window.Window | undefined = AppStorage.get('windowClass');

  aboutToAppear(): void {
    this.getImageColor();
    this.keyIntercept();
    this.audioRendererController = AppStorage.get('audioRendererController');
    let systemBarProperties: window.SystemBarProperties = {
      statusBarContentColor: '#ffffff',
      statusBarColor: this.imageColor
    };
    this.windowClass?.setWindowSystemBarProperties(systemBarProperties).catch(() => {
      Logger.error('setWindowSystemBarProperties fail ');
    }).then(() => {
      Logger.info('setWindowSystemBarProperties success ');
    })
  }

  aboutToDisappear(): void {
    AppStorage.setOrCreate('progress', undefined);
    AppStorage.setOrCreate('currentTime', undefined);
    this.audioRendererController?.release();
    let sysBarProps: window.SystemBarProperties = {
      statusBarContentColor: '#000000'
    };
    this.windowClass?.setWindowSystemBarProperties(sysBarProps).catch((error: BusinessError) => {
      Logger.error('ImageSwitch', `setWindowSystemBarProperties failed. code=${error.code}, message=${error.message}`);
    });
  }

  keyIntercept(): void {
    try {
      let options1: inputConsumer.KeyPressedConfig = {
        key: KeyCode.KEYCODE_VOLUME_UP,
        action: 1, // The act of pressing the button.
        isRepeat: false, // Prioritize the consumption of key events and do not report them.
      };
      let options2: inputConsumer.KeyPressedConfig = {
        key: KeyCode.KEYCODE_VOLUME_DOWN,
        action: 1, // The act of pressing the button.
        isRepeat: false, // Prioritize the consumption of key events and do not report them.
      };

      // Clicked the event callback on the volume button.
      this.volumeUpCallBackFunc = (event: KeyEvent) => {
        if (this.isDisabled) {
          this.getUIContext().getPromptAction().showToast({ message: $r('app.string.volume_key_up') });
          return;
        }
        this.systemVolumeVisible = true;
        this.volume = this.volume + 1;
        clearTimeout(this.timer);
        this.timer = setTimeout(() => {
          this.systemVolumeVisible = false;
        }, 3000);
      };

      // Clicked the volume button and triggered the event callback.
      this.volumeDownCallBackFunc = (event: KeyEvent) => {
        if (this.isDisabled) {
          this.getUIContext().getPromptAction().showToast({ message: $r('app.string.volume_key_down') });
          return;
        }
        this.systemVolumeVisible = true;
        this.volume = this.volume - 1;
        clearTimeout(this.timer);
        this.timer = setTimeout(() => {
          this.systemVolumeVisible = false;
        }, 3000);
      };
      inputConsumer.off('keyPressed');
      // Register for event listening.
      inputConsumer.on('keyPressed', options1, this.volumeUpCallBackFunc);
      inputConsumer.on('keyPressed', options2, this.volumeDownCallBackFunc);
    } catch (error) {
      Logger.error(`Subscribe execute failed, error: ${JSON.stringify(error, [`code`, `message`])}`);
    }
  }

  build() {
    NavDestination() {
      Stack() {
        // Do not display the system volume bar.
        SetVolume({ volume: this.volume })
        Column() {
          // Use the custom volume bar.
          SystemVolumePanel({
            volume: this.volume,
            volumeVisible: this.systemVolumeVisible
          })
        }
        .padding({ right: 16 })
        .alignItems(HorizontalAlign.End)
        .gesture(
          PanGesture({ direction: PanDirection.Vertical })
            .onActionUpdate((event: GestureEvent) => {
              this.systemVolumeVisible = true;
              let curVolume = this.volume - this.getUIContext().vp2px(event.offsetY) / this.windowHeight;
              curVolume = curVolume >= 15.0 ? 15.0 : curVolume;
              curVolume = curVolume <= 0.0 ? 0.0 : curVolume;
              this.volume = curVolume;
              clearTimeout(this.timer);
              this.timer = setTimeout(() => {
                this.systemVolumeVisible = false;
              }, 3000);
            })
        )
        .zIndex(5)
        .height(280)
        .width('100%')
        .margin({ bottom: 200 })

        Image(this.imageLabel)
          .size({ height: '120%' })
          .aspectRatio(1)
          .objectFit(ImageFit.Cover)
          .opacity(0.5)

        Column() {
          this.NavDestinationTitle()
          this.CoverInfo()
          this.MusicInfo()
          Blank()
          ControlAreaComponent({ songData: songDataList[0], imageColor: this.imageColor })
        }
        .height('100%')
        .width('100%')
        .padding({ top: 12, bottom: 36 })
      }
      .height('100%')
      .width('100%')
    }
    .hideTitleBar(true)
    .backgroundColor(this.imageColor)
    .hideBackButton(true)
    .height('100%')
    .width('100%')
    .onReady((context: NavDestinationContext) => {
      this.pageInfos = context.pathStack;
    })
  }

  @Builder
  NavDestinationTitle() {
    Column() {
      Row() {
        Row() {
          Image($r('app.media.chevron_left'))
            .width(20)
            .height(20)
        }
        .width(42)
        .height(42)
        .borderRadius(42)
        .backgroundColor('#19FFFFFF')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.pageInfos.pop();
        })

        Row() {
          Image($r('app.media.slider_horizontal_2'))
            .width(24)
            .height(24)
        }
        .width(42)
        .height(42)
        .borderRadius(42)
        .backgroundColor('#19FFFFFF')
        .justifyContent(FlexAlign.Center)
        .bindSheet($$this.isShow, VolumeSetting(), {
          height: this.sheetHeight,
          backgroundColor: '#FFFFFF',
          title: { title: $r('app.string.setting') }
        })
        .onClick(() => {
          this.isShow = true;
        })
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')
    }
    .alignItems(HorizontalAlign.End)
    .padding({
      top: 36,
      right: 16,
      left: 16
    })
    .width('100%')
  }

  @Builder
  CoverInfo() {
    Row() {
      Image(songDataList[0].label)
        .height('100%')
        .aspectRatio(1)
        .borderRadius(8)
        .shadow({
          radius: 12,
          color: '#66000000',
          offsetX: 0,
          offsetY: 8
        })
        .margin(3)
    }
    .height('40%')
    .padding({ top: 24 })
  }

  @Builder
  MusicInfo() {
    Column() {
      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Text(songDataList[0].title)
          .fontSize(20)
          .fontColor(Color.White)
          .opacity(0.86)
          .fontWeight(FontWeight.Bold)
          .fontFamily('HarmonyHeiTi-Bold')
      }

      Text(songDataList[0].singer)
        .textAlign(TextAlign.Start)
        .fontSize(14)
        .fontColor('#99FFFFFF')
        .fontFamily('HarmonyHeiTi')
        .width('100%')
        .fontWeight(FontWeight.Regular)
    }
    .padding({
      right: 24,
      left: 24
    })
    .margin({ top: 24 })
  }

  getImageColor() {
    this.getUIContext().getHostContext()!.resourceManager.getMediaContent(songDataList[0].label.id)
      .then((value: Uint8Array) => {
        let buffer = value.buffer as ArrayBuffer;
        let imageSource: image.ImageSource = image.createImageSource(buffer);
        let currentPixelMap: image.PixelMap;
        imageSource.createPixelMap().then((pixelMap) => {
          effectKit.createColorPicker(pixelMap, (error, colorPicker) => {
            if (error) {
              Logger.error(`Failed to create color picker. Error: ${error.code}, message: ${error.message}`);
            } else {
              currentPixelMap = pixelMap;
              let color: effectKit.Color = colorPicker.getLargestProportionColor();
              let colorArr: number[] = ColorTools.dealColor(color.red, color.green, color.blue);
              this.imageColor = `rgba(${colorArr[0]}, ${colorArr[1]}, ${colorArr[2]}, 1)`;
            }
          })
          let headFilter = effectKit.createEffect(pixelMap);
          if (headFilter !== null) {
            headFilter.blur(15);
            headFilter.getEffectPixelMap().then((value) => {
              this.imageLabel = value;
            });
          }
        })
          .finally(() => {
            imageSource?.release();
            currentPixelMap?.release();
          })
          .catch((error: BusinessError) => {
            Logger.error(`createPixelMap error: ${error.code}, message: ${error.message}`);
          })
      })
      .catch((error: BusinessError) => {
        Logger.error(`getMediaContent error: ${error.code}, message: ${error.message}`);
      })
  }
}