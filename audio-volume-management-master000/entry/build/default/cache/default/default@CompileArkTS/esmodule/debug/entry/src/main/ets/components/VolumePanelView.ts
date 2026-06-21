if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface VolumePanelView_Params {
    volume?: number;
    volumeVisible?: boolean;
    volumeType?: number;
    text?: ResourceStr;
    Percentage?: number;
    timer?: number | undefined;
    audioRendererController?: AudioRendererController | undefined;
    audioVolumeController?: AudioVolumeController;
}
import type { AudioRendererController } from '../player/AudioRendererController';
import { CommonConstants } from "@normalized:N&&&entry/src/main/ets/common/CommonConstants&";
import { VolumeType } from "@normalized:N&&&entry/src/main/ets/viewModel/PlayerViewModel&";
import { AudioVolumeController } from "@normalized:N&&&entry/src/main/ets/player/AudioVolumeController&";
export class VolumePanelView extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__volume = new ObservedPropertySimplePU(CommonConstants.INITIAL_VOLUME, this, "volume");
        this.__volumeVisible = new SynchedPropertySimpleOneWayPU(params.volumeVisible, this, "volumeVisible");
        this.__volumeType = new SynchedPropertySimpleOneWayPU(params.volumeType, this, "volumeType");
        this.__text = new SynchedPropertyObjectOneWayPU(params.text, this, "text");
        this.__Percentage = new SynchedPropertySimpleOneWayPU(params.Percentage, this, "Percentage");
        this.timer = undefined;
        this.audioRendererController = undefined;
        this.audioVolumeController = new AudioVolumeController();
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: VolumePanelView_Params) {
        if (params.volume !== undefined) {
            this.volume = params.volume;
        }
        if (params.volumeVisible === undefined) {
            this.__volumeVisible.set(false);
        }
        if (params.volumeType === undefined) {
            this.__volumeType.set(VolumeType.APPVOLUME);
        }
        if (params.text === undefined) {
            this.__text.set('');
        }
        if (params.Percentage === undefined) {
            this.__Percentage.set(0);
        }
        if (params.timer !== undefined) {
            this.timer = params.timer;
        }
        if (params.audioRendererController !== undefined) {
            this.audioRendererController = params.audioRendererController;
        }
        if (params.audioVolumeController !== undefined) {
            this.audioVolumeController = params.audioVolumeController;
        }
    }
    updateStateVars(params: VolumePanelView_Params) {
        this.__volumeVisible.reset(params.volumeVisible);
        this.__volumeType.reset(params.volumeType);
        this.__text.reset(params.text);
        this.__Percentage.reset(params.Percentage);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__volume.purgeDependencyOnElmtId(rmElmtId);
        this.__volumeVisible.purgeDependencyOnElmtId(rmElmtId);
        this.__volumeType.purgeDependencyOnElmtId(rmElmtId);
        this.__text.purgeDependencyOnElmtId(rmElmtId);
        this.__Percentage.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__volume.aboutToBeDeleted();
        this.__volumeVisible.aboutToBeDeleted();
        this.__volumeType.aboutToBeDeleted();
        this.__text.aboutToBeDeleted();
        this.__Percentage.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __volume: ObservedPropertySimplePU<number>;
    get volume() {
        return this.__volume.get();
    }
    set volume(newValue: number) {
        this.__volume.set(newValue);
    }
    private __volumeVisible: SynchedPropertySimpleOneWayPU<boolean>;
    get volumeVisible() {
        return this.__volumeVisible.get();
    }
    set volumeVisible(newValue: boolean) {
        this.__volumeVisible.set(newValue);
    }
    private __volumeType: SynchedPropertySimpleOneWayPU<number>;
    get volumeType() {
        return this.__volumeType.get();
    }
    set volumeType(newValue: number) {
        this.__volumeType.set(newValue);
    }
    private __text: SynchedPropertySimpleOneWayPU<ResourceStr>;
    get text() {
        return this.__text.get();
    }
    set text(newValue: ResourceStr) {
        this.__text.set(newValue);
    }
    private __Percentage: SynchedPropertySimpleOneWayPU<number>;
    get Percentage() {
        return this.__Percentage.get();
    }
    set Percentage(newValue: number) {
        this.__Percentage.set(newValue);
    }
    private timer: number | undefined;
    private audioRendererController: AudioRendererController | undefined;
    private audioVolumeController: AudioVolumeController;
    async aboutToAppear(): Promise<void> {
        if (this.volumeType === VolumeType.APPVOLUME) {
            this.audioVolumeController.creatVolumeManager();
            this.audioVolumeController.appVolumeChange();
            this.audioVolumeController.getAppVolumePercentage();
            let appVolume: number = AppStorage.get('appVolume') ?? 50;
            this.volume = Math.round(appVolume * 15 / 100);
        }
        else {
            this.audioRendererController = AppStorage.get('audioRendererController');
            let audioStreamVolume: number = AppStorage.get('audioStreamVolume') ?? 0.5;
            this.volume = Math.round(audioStreamVolume * 15);
        }
        this.Percentage = Math.floor(this.volume / 15 * 100);
    }
    aboutToDisappear(): void {
        this.audioVolumeController.offStreamVolumeChange();
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.margin({ bottom: 12 });
            Column.alignItems(HorizontalAlign.Start);
            Column.width('100%');
            Column.height(88);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.justifyContent(FlexAlign.SpaceBetween);
            Row.width('100%');
            Row.height(48);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.text);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(`${this.Percentage}%`);
            Text.fontColor(Color.Black);
            Text.opacity(0.6);
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Stack.create({ alignContent: Alignment.Top });
            Stack.width('100%');
            Stack.height(40);
        }, Stack);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Slider.create({
                value: this.volume,
                min: 0,
                max: 15,
                style: SliderStyle.InSet,
                reverse: false
            });
            Slider.focusable(true);
            Slider.defaultFocus(true);
            Slider.focusOnTouch(true);
            Slider.trackColor('#F1F3F5');
            Slider.trackThickness(20);
            Slider.selectedColor('#0A59F7');
            Slider.onChange((value: number) => {
                if (this.volumeType === VolumeType.APPVOLUME) {
                    this.volume = value;
                    clearTimeout(this.timer);
                    this.timer = setTimeout(() => {
                        this.audioVolumeController.setAppVolumePercentage(value);
                    }, 100);
                }
                else {
                    this.volume = value;
                    clearTimeout(this.timer);
                    this.timer = setTimeout(() => {
                        this.audioRendererController = AppStorage.get('audioRendererController');
                        this.audioRendererController?.setVolume(value);
                    }, 100);
                }
                this.Percentage = Math.floor(this.volume / 15 * 100);
            });
        }, Slider);
        Stack.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
}
