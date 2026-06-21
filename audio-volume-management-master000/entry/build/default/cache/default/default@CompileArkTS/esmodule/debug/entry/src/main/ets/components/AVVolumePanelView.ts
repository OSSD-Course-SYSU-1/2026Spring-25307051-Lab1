if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface SetVolume_Params {
    volume?: number;
    volumeVisible?: boolean;
}
import { AVVolumePanel } from "@ohos:multimedia.avVolumePanel";
import { CommonConstants } from "@normalized:N&&&entry/src/main/ets/common/CommonConstants&";
export class SetVolume extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__volume = new SynchedPropertySimpleOneWayPU(params.volume, this, "volume");
        this.__volumeVisible = new SynchedPropertySimpleOneWayPU(params.volumeVisible, this, "volumeVisible");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: SetVolume_Params) {
        if (params.volume === undefined) {
            this.__volume.set(CommonConstants.INITIAL_VOLUME);
        }
        if (params.volumeVisible === undefined) {
            this.__volumeVisible.set(false);
        }
    }
    updateStateVars(params: SetVolume_Params) {
        this.__volume.reset(params.volume);
        this.__volumeVisible.reset(params.volumeVisible);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__volume.purgeDependencyOnElmtId(rmElmtId);
        this.__volumeVisible.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__volume.aboutToBeDeleted();
        this.__volumeVisible.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __volume: SynchedPropertySimpleOneWayPU<number>;
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
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.visibility(this.volumeVisible ? Visibility.Visible : Visibility.Hidden);
            Column.height('50%');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            __Common__.create();
            __Common__.width(10);
        }, __Common__);
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new AVVolumePanel(this, {
                        volumeLevel: this.volume,
                        volumeParameter: {
                            position: {
                                // Set the x value to -1 and the y value to -1. Do not display the system volume bar.
                                x: -1,
                                y: -1
                            }
                        }
                    }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/components/AVVolumePanelView.ets", line: 27, col: 7 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            volumeLevel: this.volume,
                            volumeParameter: {
                                position: {
                                    // Set the x value to -1 and the y value to -1. Do not display the system volume bar.
                                    x: -1,
                                    y: -1
                                }
                            }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        volumeLevel: this.volume,
                        volumeParameter: {
                            position: {
                                // Set the x value to -1 and the y value to -1. Do not display the system volume bar.
                                x: -1,
                                y: -1
                            }
                        }
                    });
                }
            }, { name: "AVVolumePanel" });
        }
        __Common__.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
}
