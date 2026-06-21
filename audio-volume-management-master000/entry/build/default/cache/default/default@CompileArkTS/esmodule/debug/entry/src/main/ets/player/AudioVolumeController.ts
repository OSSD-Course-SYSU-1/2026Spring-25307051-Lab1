import audio from "@ohos:multimedia.audio";
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
        this.audioVolumeManager?.on('streamVolumeChange', audio.StreamUsage.STREAM_USAGE_MUSIC, (streamVolumeEvent: audio.StreamVolumeEvent) => {
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
        });
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
