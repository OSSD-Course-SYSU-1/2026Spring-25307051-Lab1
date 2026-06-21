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

// set volume component.
import { AVVolumePanel } from '@kit.AudioKit';
import { CommonConstants } from '../common/CommonConstants';

@Component
export struct SetVolume {
  @Prop volume: number = CommonConstants.INITIAL_VOLUME;
  @Prop volumeVisible: boolean = false;

  build() {
    Column() {
      AVVolumePanel({
        volumeLevel: this.volume,
        volumeParameter: {
          position: {
            // Set the x value to -1 and the y value to -1. Do not display the system volume bar.
            x: -1,
            y: -1
          }
        }
      })
        .width(10)
    }
    .visibility(this.volumeVisible ? Visibility.Visible : Visibility.Hidden)
    .height('50%')
  }
}