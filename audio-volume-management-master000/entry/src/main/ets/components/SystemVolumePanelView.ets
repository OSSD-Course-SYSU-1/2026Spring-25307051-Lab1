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

// Custom system volume bar.
import { AudioVolumeController } from '../player/AudioVolumeController';
import { CommonConstants } from '../common/CommonConstants';

@Component
export struct SystemVolumePanel {
  @Link volume: number;
  @Link volumeVisible: boolean;
  @State minVolume: number = CommonConstants.MIX_VOLUME;
  @State maxVolume: number = CommonConstants.MAX_VOLUME;
  private timer: number | undefined = undefined;
  private audioVolumeController: AudioVolumeController = new AudioVolumeController();

  aboutToAppear(): void {
    this.audioVolumeController.creatVolumeManager();
    this.audioVolumeController.getVolumeByStream();
    this.minVolume = this.audioVolumeController.getMinVolumeByStream();
    this.maxVolume = this.audioVolumeController.getMaxVolumeByStream();
  }

  aboutToDisappear(): void {
    this.audioVolumeController?.offStreamVolumeChange();
    clearTimeout(this.timer);
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.Top }) {
        Slider({
          value: this.volume,
          min: this.minVolume,
          max: this.maxVolume,
          style: SliderStyle.NONE,
          direction: Axis.Vertical,
          reverse: true
        })
          .focusable(true)
          .defaultFocus(true)
          .focusOnTouch(true)
          .trackColor('#26FFFFFF')
          .trackThickness(40)
          .selectedColor(Color.White)
          .onChange((value: number) => {
            this.volume = value;
            this.volumeVisible = true;
            clearTimeout(this.timer);
            this.timer = setTimeout(() => {
              this.volumeVisible = false;
            }, 3000);
          })
      }
      .height(144)
      .width(40)
      .margin({ bottom: 12 })
    }
    .visibility(this.volumeVisible ? Visibility.Visible : Visibility.Hidden)
    .height('50%')
  }
}