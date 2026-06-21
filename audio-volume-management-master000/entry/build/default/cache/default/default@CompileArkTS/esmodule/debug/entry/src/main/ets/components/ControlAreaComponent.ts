if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface ControlAreaComponent_Params {
    isPlay?: boolean;
    currentTime?: string;
    totalTime?: string;
    value?: number;
    max?: number;
    songData?: SongData;
    imageColor?: string;
    audioStreamVolumeVisible?: boolean;
    applicationVolumeVisible?: boolean;
    volume?: number;
    symbolGlyphModifier?: SymbolGlyphModifier;
    selectedOptionTextModifier?: TextModifier;
    audioRendererController?: AudioRendererController;
}
import { SymbolGlyphModifier } from "@ohos:arkui.modifier";
import { TextModifier } from "@ohos:arkui.modifier";
import type { BusinessError } from "@ohos:base";
import { SongData } from "@normalized:N&&&entry/src/main/ets/model/SongData&";
import { Logger } from "@normalized:N&&&entry/src/main/ets/utils/Logger&";
import { AudioRendererController } from "@normalized:N&&&entry/src/main/ets/player/AudioRendererController&";
import { CommonConstants } from "@normalized:N&&&entry/src/main/ets/common/CommonConstants&";
import { AudioName, imageList } from "@normalized:N&&&entry/src/main/ets/viewModel/PlayerViewModel&";
export class ControlAreaComponent extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__isPlay = this.createStorageLink('isPlay', false, "isPlay");
        this.__currentTime = this.createStorageLink('currentTime', '00:00', "currentTime");
        this.__totalTime = this.createStorageLink('totalTime', '00:00', "totalTime");
        this.__value = this.createStorageLink('progress', 0, "value");
        this.__max = this.createStorageLink('progressMax', 0, "max");
        this.__songData = new SynchedPropertyObjectOneWayPU(params.songData, this, "songData");
        this.__imageColor = new SynchedPropertySimpleOneWayPU(params.imageColor, this, "imageColor");
        this.__audioStreamVolumeVisible = new ObservedPropertySimplePU(false, this, "audioStreamVolumeVisible");
        this.__applicationVolumeVisible = new ObservedPropertySimplePU(false, this, "applicationVolumeVisible");
        this.__volume = new ObservedPropertySimplePU(CommonConstants.INITIAL_VOLUME, this, "volume");
        this.symbolGlyphModifier = new SymbolGlyphModifier();
        this.selectedOptionTextModifier = new TextModifier();
        this.audioRendererController = new AudioRendererController();
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: ControlAreaComponent_Params) {
        if (params.songData === undefined) {
            this.__songData.set(new SongData());
        }
        if (params.imageColor === undefined) {
            this.__imageColor.set('rgba(0, 0, 2, 1.00)');
        }
        if (params.audioStreamVolumeVisible !== undefined) {
            this.audioStreamVolumeVisible = params.audioStreamVolumeVisible;
        }
        if (params.applicationVolumeVisible !== undefined) {
            this.applicationVolumeVisible = params.applicationVolumeVisible;
        }
        if (params.volume !== undefined) {
            this.volume = params.volume;
        }
        if (params.symbolGlyphModifier !== undefined) {
            this.symbolGlyphModifier = params.symbolGlyphModifier;
        }
        if (params.selectedOptionTextModifier !== undefined) {
            this.selectedOptionTextModifier = params.selectedOptionTextModifier;
        }
        if (params.audioRendererController !== undefined) {
            this.audioRendererController = params.audioRendererController;
        }
    }
    updateStateVars(params: ControlAreaComponent_Params) {
        this.__songData.reset(params.songData);
        this.__imageColor.reset(params.imageColor);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__isPlay.purgeDependencyOnElmtId(rmElmtId);
        this.__currentTime.purgeDependencyOnElmtId(rmElmtId);
        this.__totalTime.purgeDependencyOnElmtId(rmElmtId);
        this.__value.purgeDependencyOnElmtId(rmElmtId);
        this.__max.purgeDependencyOnElmtId(rmElmtId);
        this.__songData.purgeDependencyOnElmtId(rmElmtId);
        this.__imageColor.purgeDependencyOnElmtId(rmElmtId);
        this.__audioStreamVolumeVisible.purgeDependencyOnElmtId(rmElmtId);
        this.__applicationVolumeVisible.purgeDependencyOnElmtId(rmElmtId);
        this.__volume.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__isPlay.aboutToBeDeleted();
        this.__currentTime.aboutToBeDeleted();
        this.__totalTime.aboutToBeDeleted();
        this.__value.aboutToBeDeleted();
        this.__max.aboutToBeDeleted();
        this.__songData.aboutToBeDeleted();
        this.__imageColor.aboutToBeDeleted();
        this.__audioStreamVolumeVisible.aboutToBeDeleted();
        this.__applicationVolumeVisible.aboutToBeDeleted();
        this.__volume.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __isPlay: ObservedPropertyAbstractPU<boolean>;
    get isPlay() {
        return this.__isPlay.get();
    }
    set isPlay(newValue: boolean) {
        this.__isPlay.set(newValue);
    }
    private __currentTime: ObservedPropertyAbstractPU<string>;
    get currentTime() {
        return this.__currentTime.get();
    }
    set currentTime(newValue: string) {
        this.__currentTime.set(newValue);
    }
    private __totalTime: ObservedPropertyAbstractPU<string>;
    get totalTime() {
        return this.__totalTime.get();
    }
    set totalTime(newValue: string) {
        this.__totalTime.set(newValue);
    }
    private __value: ObservedPropertyAbstractPU<number>;
    get value() {
        return this.__value.get();
    }
    set value(newValue: number) {
        this.__value.set(newValue);
    }
    private __max: ObservedPropertyAbstractPU<number>;
    get max() {
        return this.__max.get();
    }
    set max(newValue: number) {
        this.__max.set(newValue);
    }
    private __songData: SynchedPropertySimpleOneWayPU<SongData>;
    get songData() {
        return this.__songData.get();
    }
    set songData(newValue: SongData) {
        this.__songData.set(newValue);
    }
    private __imageColor: SynchedPropertySimpleOneWayPU<string>;
    get imageColor() {
        return this.__imageColor.get();
    }
    set imageColor(newValue: string) {
        this.__imageColor.set(newValue);
    }
    private __audioStreamVolumeVisible: ObservedPropertySimplePU<boolean>;
    get audioStreamVolumeVisible() {
        return this.__audioStreamVolumeVisible.get();
    }
    set audioStreamVolumeVisible(newValue: boolean) {
        this.__audioStreamVolumeVisible.set(newValue);
    }
    private __applicationVolumeVisible: ObservedPropertySimplePU<boolean>;
    get applicationVolumeVisible() {
        return this.__applicationVolumeVisible.get();
    }
    set applicationVolumeVisible(newValue: boolean) {
        this.__applicationVolumeVisible.set(newValue);
    }
    private __volume: ObservedPropertySimplePU<number>;
    get volume() {
        return this.__volume.get();
    }
    set volume(newValue: number) {
        this.__volume.set(newValue);
    }
    private symbolGlyphModifier: SymbolGlyphModifier;
    private selectedOptionTextModifier: TextModifier;
    private audioRendererController: AudioRendererController;
    aboutToAppear(): void {
        this.symbolGlyphModifier
            .fontSize(12)
            .fontColor(['#999999']);
        this.selectedOptionTextModifier
            .maxLines(1)
            .fontSize(12)
            .textAlign(TextAlign.Start)
            .fontWeight(FontWeight.Bold)
            .width(160);
        this.getUIContext().getHostContext()?.resourceManager.getRawFd(this.songData.src + AudioName.PCM)
            .then((rawFileDescriptor) => {
            this.audioRendererController.initAudioRenderer(rawFileDescriptor.fd, rawFileDescriptor.offset, rawFileDescriptor.length);
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
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.padding({
                left: 24,
                right: 24
            });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.margin({
                top: 24,
                bottom: 12
            });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Slider.create({
                min: 0,
                max: this.max,
                step: 1,
                style: SliderStyle.OutSet,
                value: this.value
            });
            Slider.selectedColor('#DBFFFFFF');
            Slider.trackColor({ "id": 16777241, "type": 10001, params: [], "bundleName": "com.example.audiostreamvolumemanagement", "moduleName": "entry" });
            Slider.onChange((value: number, mode: SliderChangeMode) => {
                if (mode === SliderChangeMode.End || mode === SliderChangeMode.Begin) {
                    this.audioRendererController.seek(value);
                }
            });
            Slider.height(16);
            Slider.hitTestBehavior(HitTestMode.Block);
        }, Slider);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
            Row.justifyContent(FlexAlign.SpaceBetween);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.currentTime);
            Text.fontColor({ "id": 16777242, "type": 10001, params: [], "bundleName": "com.example.audiostreamvolumemanagement", "moduleName": "entry" });
            Text.fontSize(10);
            Text.fontFamily('HarmonyHeiTi');
            Text.lineHeight(14);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.totalTime);
            Text.fontColor({ "id": 16777242, "type": 10001, params: [], "bundleName": "com.example.audiostreamvolumemanagement", "moduleName": "entry" });
            Text.fontSize(10);
            Text.fontFamily('HarmonyHeiTi');
            Text.lineHeight(14);
        }, Text);
        Text.pop();
        Row.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
            Row.justifyContent(FlexAlign.SpaceBetween);
            Row.padding({
                left: 36,
                right: 36
            });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 16777249, "type": 20000, params: [], "bundleName": "com.example.audiostreamvolumemanagement", "moduleName": "entry" });
            __Image__controlImageBuilder();
            Image.width(32);
            Image.onClick(() => {
                this.getUIContext().getPromptAction().openToast({ message: { "id": 16777237, "type": 10003, params: [], "bundleName": "com.example.audiostreamvolumemanagement", "moduleName": "entry" } }).catch(() => {
                    Logger.error('openToast error');
                });
            });
        }, Image);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create(this.isPlay ? imageList[0] : imageList[1]);
            __Image__controlImageBuilder();
            Image.width(72);
            Image.onClick(() => {
                if (this.isPlay) {
                    this.audioRendererController.pause();
                }
                else {
                    this.audioRendererController.start();
                }
            });
        }, Image);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 16777250, "type": 20000, params: [], "bundleName": "com.example.audiostreamvolumemanagement", "moduleName": "entry" });
            __Image__controlImageBuilder();
            Image.width(32);
            Image.onClick(() => {
                this.getUIContext().getPromptAction().openToast({ message: { "id": 16777237, "type": 10003, params: [], "bundleName": "com.example.audiostreamvolumemanagement", "moduleName": "entry" } }).catch(() => {
                    Logger.error('openToast error');
                });
            });
        }, Image);
        Row.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
}
function __Image__controlImageBuilder(): void {
    Image.aspectRatio(1);
    Image.opacity(0.86);
    Image.objectFit(ImageFit.Contain);
}
