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
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo, ReadOptions } from '@kit.CoreFileKit';
import { Logger } from '../utils/Logger';
import { MediaTools } from '../utils/MediaTools';
import { AudioVolumeController } from '../player/AudioVolumeController';

const TAG = 'AudioRenderController';

// AudioRendererController methods.
export class AudioRendererController {
  private audioRenderer: audio.AudioRenderer | undefined = undefined;
  private currentOffset: number = 0;
  private offset: number = 0;
  private length: number = 0;
  private fd: number = 0;
  private curMs: number = 0;
  private audioVolumeController: AudioVolumeController = new AudioVolumeController();

  // Initialization AudioRenderer.
  public async initAudioRenderer(fd: number, offset: number, length: number): Promise<void> {
    this.fd = fd; // File descriptor.
    this.offset = offset; // Start offset.
    this.currentOffset = offset; // Current offset.
    this.length = length; // File length.
    // Audio stream information.
    let audioStreamInfo: audio.AudioStreamInfo = {
      samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_48000, // Audio file sampling rate.
      channels: audio.AudioChannel.CHANNEL_2, // Number of audio file channels.
      sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE, // Audio sampling format.
      encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW // Audio encoding format.
    };
    // AudioRenderer information.
    let audioRendererInfo: audio.AudioRendererInfo = {
      usage: audio.StreamUsage.STREAM_USAGE_MUSIC, // Audio stream usage type.
      rendererFlags: 0, // Audio renderer flag.
      volumeMode: audio.AudioVolumeMode.APP_INDIVIDUAL
    };
    // AudioRenderer options information.
    let audioRendererOptions: audio.AudioRendererOptions = {
      streamInfo: audioStreamInfo,
      rendererInfo: audioRendererInfo
    };
    // Get audio renderer.
    await audio.createAudioRenderer(audioRendererOptions).then((data) => {
      this.audioRenderer = data;
      if (this.audioRenderer) {
        try {
          // Set the focus model to independent focus mode.
          this.audioRenderer.setInterruptMode(audio.InterruptMode.INDEPENDENT_MODE);
          this.setAudioStateChangeCallBack();
          this.setWriteDataCallback(); // Write audio data.
        } catch (error) {
          Logger.error('createAudioRenderer is calling.');
        }
      }
    });
    // Convert the file length to the corresponding number of milliseconds and store it in AppStorage.
    AppStorage.setOrCreate('progressMax', MediaTools.getMsFromByteLength(this.length));
    // Convert the file length to the corresponding number of milliseconds, then convert it to a timestamp and store it in AppStorage.
    AppStorage.setOrCreate('totalTime', MediaTools.msToCountdownTime(MediaTools.getMsFromByteLength(this.length)));
  }

  // Write audio data.
  private setWriteDataCallback(): void {
    try {
      // Listening for audio data writing.
      this.audioRenderer?.on('writeData', (buffer) => {
        if (this.currentOffset - this.offset >= this.length) {
          this.currentOffset = this.offset;
          this.seek(0);
        }
        let options: ReadOptions = {
          offset: this.currentOffset,
          length: buffer.byteLength
        };
        let bufferLength = fileIo.readSync(this.fd, buffer, options);
        if (bufferLength === -1) {
          Logger.error('Read failed.');
          return;
        }
        this.currentOffset += buffer.byteLength;
        let processOffset = this.currentOffset - this.offset;

        if (this.offset + this.length <= this.currentOffset) {
          let view = new DataView(buffer);
          Logger.info('currentOffset ：' + this.currentOffset + '  endOffset:' + (this.offset + this.length) +
            ' bufferLength:' + bufferLength);
          for (let i = bufferLength - 1; i > processOffset - this.length; i--) {
            view.setUint8(i, 0);
          }
        }

        let curMs = MediaTools.getMsFromByteLength(processOffset);
        AppStorage.setOrCreate('progress', curMs);
        AppStorage.setOrCreate('currentTime', MediaTools.msToCountdownTime(curMs));
        this.audioRenderer?.start().then(() => {
          this.seek(this.curMs);
        }).catch((error: BusinessError) => {
          Logger.error(`Error code: ${error.code}, message: ${error.message}`);
        });
      })
    } catch (error) {
      Logger.error('setWriteDataCallback is failed. ' + error);
    }
  }

  private setAudioStateChangeCallBack() {
    if (!this.audioRenderer) {
      Logger.info(TAG, 'state change callback failed, audioRenderer is null.');
      return;
    }
    this.audioRenderer.on('stateChange', async (state: audio.AudioState) => {
      switch (state) {
        case audio.AudioState.STATE_RUNNING:
          Logger.info('AudioRender running state.');
          AppStorage.setOrCreate('isPlay', true);
          break;
        case audio.AudioState.STATE_PAUSED:
          Logger.info('AudioRender paused state.');
          AppStorage.setOrCreate('isPlay', false);
          break;
        case audio.AudioState.STATE_STOPPED:
          Logger.info('AudioRender stopped state.');
          AppStorage.setOrCreate('isPlay', false);
          break;
        default:
          Logger.info('AudioRender other state.');
          break;
      }
    });
  }

  public async start(): Promise<void> {
    if (this.audioRenderer !== undefined) {
      // Audio state.
      let stateGroup = [audio.AudioState.STATE_PREPARED, audio.AudioState.STATE_PAUSED, audio.AudioState.STATE_STOPPED];
      if (stateGroup.indexOf(this.audioRenderer.state.valueOf()) === -1) {
        return;
      }
      // Set the volume.
      this.audioVolumeController.getAppVolumePercentage();
      let appVolume: number = AppStorage.get('appVolume') ?? 100;
      this.audioVolumeController.setAppVolumePercentage(appVolume);
      let audioStreamVolume: number = AppStorage.get('audioStreamVolume') ?? 0.5;
      this.setVolume(audioStreamVolume * 15);
      // Starting the AudioRenderer.
      this.audioRenderer.start((err: BusinessError) => {
        if (err) {
          Logger.error('Renderer start failed.');
        } else {
          Logger.info('Renderer start success.');
        }
      });
    }
  }

  public pause(): void {
    if (this.audioRenderer !== undefined) {
      if (this.audioRenderer.state.valueOf() !== audio.AudioState.STATE_RUNNING) {
        return;
      }
      // Pause Audio rendering.
      this.audioRenderer.pause((err: BusinessError) => {
        if (err) {
          Logger.error('Renderer pause failed.');
        } else {
          Logger.info('Renderer pause success.');
        }
      });
    }
  }

  // Jump to playback.
  public seek(ms: number): void {
    if (ms < 0 || ms > MediaTools.getMsFromByteLength(this.length)) {
      Logger.error('Invalid seek position');
      return;
    }
    this.curMs = ms;
    AppStorage.setOrCreate('progress', this.curMs);
    AppStorage.setOrCreate('currentTime', MediaTools.msToCountdownTime(this.curMs));
    this.currentOffset = this.offset + MediaTools.getOffsetFromTime(this.curMs);
  }

  // Stop play
  public stop(): void {
    if (this.audioRenderer !== undefined) {

      if (this.audioRenderer.state.valueOf() !== audio.AudioState.STATE_RUNNING &&
        this.audioRenderer.state.valueOf() !== audio.AudioState.STATE_PAUSED) {
        return;
      }

      this.audioRenderer.stop(() => {
        Logger.error('audioRenderer stop failed.');
      });
    }
  }

  public release(): void {
    try {
      if (this.audioRenderer !== undefined) {
        if (this.audioRenderer.state.valueOf() === audio.AudioState.STATE_RELEASED) {
          return;
        }

        this.audioRenderer.off('writeData');
        this.audioRenderer.release();
      }
    } catch (error) {
      Logger.info('Renderer release fail.');
    }
  }

  reset(fd: number, offset: number, length: number): void {
    this.fd = fd;
    this.offset = offset;
    this.length = length;
    this.curMs = 0;
    AppStorage.setOrCreate('progress', 0);
    AppStorage.setOrCreate('currentTime', MediaTools.msToCountdownTime(this.curMs));
  }

  public getVolume(): number {
    let volume = this.audioRenderer?.getVolume() ?? 1;
    return volume;
  }

  public setVolume(value: number): void {
    this.audioRenderer?.setVolume(value / 15);
    AppStorage.setOrCreate('audioStreamVolume', value / 15);
  }
}