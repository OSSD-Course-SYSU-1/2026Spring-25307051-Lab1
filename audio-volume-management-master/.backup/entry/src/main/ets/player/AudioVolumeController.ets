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

import { audio } from '@kit.AudioKit';

// AudioVolumeController methods.
export class AudioVolumeController {
  private audioVolumeManager: audio.AudioVolumeManager | undefined = undefined;

  public creatVolumeManager(): void {
    let audioManager = audio.getAudioManager();
    this.audioVolumeManager = audioManager.getVolumeManager();
    this.onStreamVolumeChange();
  }

  // Get the current volume of the audio stream.
  public getVolumeByStream(): number {
    let volume = this.audioVolumeManager?.getVolumeByStream(audio.StreamUsage.STREAM_USAGE_MUSIC) ?? 0;
    AppStorage.setOrCreate('systemVolume', volume);
    return volume;
  }

  // Get the minimum volume for the audio stream.
  public getMinVolumeByStream(): number {
    let volume = this.audioVolumeManager?.getMinVolumeByStream(audio.StreamUsage.STREAM_USAGE_MUSIC) ?? 0;
    return volume;
  }

  // Get the maximum volume for the audio stream.
  public getMaxVolumeByStream(): number {
    let volume = this.audioVolumeManager?.getMaxVolumeByStream(audio.StreamUsage.STREAM_USAGE_MUSIC) ?? 0;
    return volume;
  }

  // Monitor changes in audio volume.
  public onStreamVolumeChange(): void {
    this.audioVolumeManager?.on('streamVolumeChange', audio.StreamUsage.STREAM_USAGE_MUSIC,
      (streamVolumeEvent: audio.StreamVolumeEvent) => {
        let volume = streamVolumeEvent.volume;
        AppStorage.setOrCreate('volume', volume);
        if (streamVolumeEvent.updateUi) {
          AppStorage.setOrCreate('volumeVisible', false);
        }
      });
  }

  // Cancel monitoring.
  public offStreamVolumeChange(): void {
    this.audioVolumeManager?.off('streamVolumeChange');
  }

  // Get the current volume of the application.
  public getAppVolumePercentage(): void {
    this.audioVolumeManager?.getAppVolumePercentage().then((value: number) => {
      AppStorage.setOrCreate('appVolume', value);
    });
  }

  // Monitor the changes in the application volume.
  public appVolumeChange(): void {
    this.audioVolumeManager?.on('appVolumeChange', (volumeEvent: audio.VolumeEvent) => {
      AppStorage.setOrCreate('appVolume', volumeEvent.volume);
    })
  }

  // Cancel monitoring.
  public offAppVolumeChange(): void {
    this.audioVolumeManager?.off('appVolumeChange');
  }

  // Set application volume.
  public setAppVolumePercentage(value: number): void {
    this.audioVolumeManager?.setAppVolumePercentage(Math.round(value * 100 / 15));
  }
}