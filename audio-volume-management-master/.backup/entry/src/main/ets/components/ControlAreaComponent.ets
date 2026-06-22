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

import { SymbolGlyphModifier, TextModifier } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { SongData } from '../model/SongData';
import { Logger } from '../utils/Logger';
import { AudioRendererController } from '../player/AudioRendererController';
import { CommonConstants } from '../common/CommonConstants';
import { AudioName, imageList } from '../viewModel/PlayerViewModel';

@Component
export struct ControlAreaComponent {
  @StorageLink('isPlay') isPlay: boolean = false;
  @StorageLink('currentTime') currentTime: string = '00:00';
  @StorageLink('totalTime') totalTime: string = '00:00';
  @StorageLink('progress') value: number = 0;
  @StorageLink('progressMax') max: number = 0;
  @Prop songData: SongData = new SongData();
  @Prop imageColor: string = 'rgba(0, 0, 2, 1.00)';
  @State audioStreamVolumeVisible: boolean = false;
  @State applicationVolumeVisible: boolean = false;
  @State volume: number = CommonConstants.INITIAL_VOLUME;
  symbolGlyphModifier: SymbolGlyphModifier = new SymbolGlyphModifier();
  selectedOptionTextModifier: TextModifier = new TextModifier();
  private audioRendererController: AudioRendererController = new AudioRendererController();

  aboutToAppear(): void {
    this.symbolGlyphModifier
      .fontSize(12)
      .fontColor(['#999999'])

    this.selectedOptionTextModifier
      .maxLines(1)
      .fontSize(12)
      .textAlign(TextAlign.Start)
      .fontWeight(FontWeight.Bold)
      .width(160)
    this.getUIContext().getHostContext()?.resourceManager.getRawFd(this.songData.src + AudioName.PCM)
      .then((rawFileDescriptor) => {
        this.audioRendererController.initAudioRenderer(rawFileDescriptor.fd, rawFileDescriptor.offset,
          rawFileDescriptor.length);
        AppStorage.setOrCreate('audioRendererController', this.audioRendererController);
      })
      .catch((error: BusinessError) => {
        Logger.error(`resourceManager error code ${error.code} message ${error.message}`);
      });
  }

  aboutToDisappear(): void {
    this.audioRendererController.release();
    this.isPlay = false;
    AppStorage.setOrCreate('audioRendererController', undefined);
  }

  build() {
    Column() {
      Column() {
        Slider({
          min: 0,
          max: this.max,
          step: 1,
          style: SliderStyle.OutSet,
          value: this.value
        })
          .selectedColor('#DBFFFFFF')
          .trackColor($r('app.color.white_33'))
          .onChange((value: number, mode: SliderChangeMode) => {
            if (mode === SliderChangeMode.End || mode === SliderChangeMode.Begin) {
              this.audioRendererController.seek(value);
            }
          })
          .height(16)
          .hitTestBehavior(HitTestMode.Block)
        Row() {
          Text(this.currentTime)
            .fontColor($r('app.color.white_99'))
            .fontSize(10)
            .fontFamily('HarmonyHeiTi')
            .lineHeight(14)
          Text(this.totalTime)
            .fontColor($r('app.color.white_99'))
            .fontSize(10)
            .fontFamily('HarmonyHeiTi')
            .lineHeight(14)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .margin({
        top: 24,
        bottom: 12
      })

      Row() {
        Image($r('app.media.ic_public_forward'))
          .controlImageBuilder()
          .width(32)
          .onClick(() => {
            this.getUIContext().getPromptAction().openToast({ message: $r('app.string.ui_presentation') }).catch(() => {
              Logger.error('openToast error');
            })
          })
        Image(this.isPlay ? imageList[0] : imageList[1])
          .controlImageBuilder()
          .width(72)
          .onClick(() => {
            if (this.isPlay) {
              this.audioRendererController.pause();
            } else {
              this.audioRendererController.start();
            }
          })
        Image($r('app.media.ic_public_next'))
          .controlImageBuilder()
          .width(32)
          .onClick(() => {
            this.getUIContext().getPromptAction().openToast({ message: $r('app.string.ui_presentation') }).catch(() => {
              Logger.error('openToast error');
            })
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({
        left: 36,
        right: 36
      })
    }
    .padding({
      left: 24,
      right: 24
    })
  }
}

@Extend(Image)
function controlImageBuilder() {
  .aspectRatio(1)
  .opacity(0.86)
  .objectFit(ImageFit.Contain)
}
