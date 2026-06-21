import type { SongData } from '../model/SongData';
export const songDataList: SongData[] = [{
        id: 1,
        title: 'Dream It Possible',
        singer: 'Delacey',
        label: { "id": 16777248, "type": 20000, params: [], "bundleName": "com.example.audiostreamvolumemanagement", "moduleName": "entry" },
        src: 'Delacey - Dream It Possible',
        index: 0,
        isDarkBackground: true,
        mark: { "id": 16777253, "type": 20000, params: [], "bundleName": "com.example.audiostreamvolumemanagement", "moduleName": "entry" }
    }];
export enum AudioName {
    PCM = ".pcm"
}
export enum VolumeType {
    APPVOLUME = 1,
    AUDIOSTREAM = 2
}
export const imageList: ResourceStr[] = [
    { "id": 16777252, "type": 20000, params: [], "bundleName": "com.example.audiostreamvolumemanagement", "moduleName": "entry" },
    { "id": 16777251, "type": 20000, params: [], "bundleName": "com.example.audiostreamvolumemanagement", "moduleName": "entry" }
];
