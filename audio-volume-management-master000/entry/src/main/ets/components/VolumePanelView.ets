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

// Custom volume bar
import { AudioRendererController } from '../player/AudioRendererController';
import { CommonConstants } from '../common/CommonConstants';
import { VolumeType } from '../viewModel/PlayerViewModel';
import { AudioVolumeController } from '../player/AudioVolumeController';

@Component
export struct VolumePanelView {
  @State volume: number = CommonConstants.INITIAL_VOLUME;
  @Prop volumeVisible: boolean = false;
  @Prop volumeType: number = VolumeType.APPVOLUME;
  @Prop text: ResourceStr = '';
  @Prop Percentage: number = 0;
  private timer: number | undefined = undefined;
  private audioRendererController: AudioRendererController | undefined = undefined;
  private audioVolumeController: AudioVolumeController = new AudioVolumeController();

  async aboutToAppear(): Promise<void> {
    if (this.volumeType === VolumeType.APPVOLUME) {
      this.audioVolumeController.creatVolumeManager();
      this.audioVolumeController.appVolumeChange();
      this.audioVolumeController.getAppVolumePercentage();
      let appVolume: number = AppStorage.get('appVolume') ?? 50;
      this.volume = Math.round(appVolume * 15 / 100);
    } else {
      this.audioRendererController = AppStorage.get('audioRendererController');
      let audioStreamVolume: number = AppStorage.get('audioStreamVolume') ?? 0.5;
      this.volume = Math.round(audioStreamVolume * 15);
    }
    this.Percentage = Math.floor(this.volume / 15 * 100);
  }

  aboutToDisappear(): void {
    this.audioVolumeController.offStreamVolumeChange();
  }

  build() {
    Column() {
      Row() {
        Text(this.text)
        Text(`${this.Percentage}%`)
          .fontColor(Color.Black)
          .opacity(0.6)
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')
      .height(48)

      Stack({ alignContent: Alignment.Top }) {
        Slider({
          value: this.volume,
          min: 0,
          max: 15,
          style: SliderStyle.InSet,
          reverse: false
        })
          .focusable(true)
          .defaultFocus(true)
          .focusOnTouch(true)
          .trackColor('#F1F3F5')
          .trackThickness(20)
          .selectedColor('#0A59F7')
          .onChange((value: number) => {
            if (this.volumeType === VolumeType.APPVOLUME) {
              this.volume = value;
              clearTimeout(this.timer);
              this.timer = setTimeout(() => {
                this.audioVolumeController.setAppVolumePercentage(value);
              }, 100);
            } else {
              this.volume = value;
              clearTimeout(this.timer);
              this.timer = setTimeout(() => {
                this.audioRendererController = AppStorage.get('audioRendererController');
                this.audioRendererController?.setVolume(value);
              }, 100);
            }
            this.Percentage = Math.floor(this.volume / 15 * 100);
          })
      }
      .width('100%')
      .height(40)
    }
    .margin({ bottom: 12 })
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .height(88)
  }
}