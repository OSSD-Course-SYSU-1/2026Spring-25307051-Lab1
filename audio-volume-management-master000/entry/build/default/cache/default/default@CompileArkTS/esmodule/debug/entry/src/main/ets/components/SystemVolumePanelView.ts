if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface SystemVolumePanel_Params {
    volume?: number;
    volumeVisible?: boolean;
    minVolume?: number;
    maxVolume?: number;
    timer?: number | undefined;
    audioVolumeController?: AudioVolumeController;
}
import { AudioVolumeController } from "@normalized:N&&&entry/src/main/ets/player/AudioVolumeController&";
import { CommonConstants } from "@normalized:N&&&entry/src/main/ets/common/CommonConstants&";
export class SystemVolumePanel extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__volume = new SynchedPropertySimpleTwoWayPU(params.volume, this, "volume");
        this.__volumeVisible = new SynchedPropertySimpleTwoWayPU(params.volumeVisible, this, "volumeVisible");
        this.__minVolume = new ObservedPropertySimplePU(CommonConstants.MIX_VOLUME, this, "minVolume");
        this.__maxVolume = new ObservedPropertySimplePU(CommonConstants.MAX_VOLUME, this, "maxVolume");
        this.timer = undefined;
        this.audioVolumeController = new AudioVolumeController();
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: SystemVolumePanel_Params) {
        if (params.minVolume !== undefined) {
            this.minVolume = params.minVolume;
        }
        if (params.maxVolume !== undefined) {
            this.maxVolume = params.maxVolume;
        }
        if (params.timer !== undefined) {
            this.timer = params.timer;
        }
        if (params.audioVolumeController !== undefined) {
            this.audioVolumeController = params.audioVolumeController;
        }
    }
    updateStateVars(params: SystemVolumePanel_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__volume.purgeDependencyOnElmtId(rmElmtId);
        this.__volumeVisible.purgeDependencyOnElmtId(rmElmtId);
        this.__minVolume.purgeDependencyOnElmtId(rmElmtId);
        this.__maxVolume.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__volume.aboutToBeDeleted();
        this.__volumeVisible.aboutToBeDeleted();
        this.__minVolume.aboutToBeDeleted();
        this.__maxVolume.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __volume: SynchedPropertySimpleTwoWayPU<number>;
    get volume() {
        return this.__volume.get();
    }
    set volume(newValue: number) {
        this.__volume.set(newValue);
    }
    private __volumeVisible: SynchedPropertySimpleTwoWayPU<boolean>;
    get volumeVisible() {
        return this.__volumeVisible.get();
    }
    set volumeVisible(newValue: boolean) {
        this.__volumeVisible.set(newValue);
    }
    private __minVolume: ObservedPropertySimplePU<number>;
    get minVolume() {
        return this.__minVolume.get();
    }
    set minVolume(newValue: number) {
        this.__minVolume.set(newValue);
    }
    private __maxVolume: ObservedPropertySimplePU<number>;
    get maxVolume() {
        return this.__maxVolume.get();
    }
    set maxVolume(newValue: number) {
        this.__maxVolume.set(newValue);
    }
    private timer: number | undefined;
    private audioVolumeController: AudioVolumeController;
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
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.visibility(this.volumeVisible ? Visibility.Visible : Visibility.Hidden);
            Column.height('50%');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Stack.create({ alignContent: Alignment.Top });
            Stack.height(144);
            Stack.width(40);
            Stack.margin({ bottom: 12 });
        }, Stack);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Slider.create({
                value: this.volume,
                min: this.minVolume,
                max: this.maxVolume,
                style: SliderStyle.NONE,
                direction: Axis.Vertical,
                reverse: true
            });
            Slider.focusable(true);
            Slider.defaultFocus(true);
            Slider.focusOnTouch(true);
            Slider.trackColor('#26FFFFFF');
            Slider.trackThickness(40);
            Slider.selectedColor(Color.White);
            Slider.onChange((value: number) => {
                this.volume = value;
                this.volumeVisible = true;
                clearTimeout(this.timer);
                this.timer = setTimeout(() => {
                    this.volumeVisible = false;
                }, 3000);
            });
        }, Slider);
        Stack.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
}
