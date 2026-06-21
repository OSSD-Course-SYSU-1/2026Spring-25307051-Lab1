if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface Player_Params {
    imageColor?: string;
    imageLabel?: PixelMap | Resource;
    windowHeight?: number;
    volume?: number;
    systemVolumeVisible?: boolean;
    isDisabled?: boolean;
    sheetHeight?: number;
    isShow?: boolean;
    timer?: number | undefined;
    volumeUpCallBackFunc?: (event: KeyEvent) => void;
    volumeDownCallBackFunc?: (event: KeyEvent) => void;
    audioRendererController?: AudioRendererController | undefined;
    pageInfos?: NavPathStack;
    windowClass?: window.Window | undefined;
}
import type { BusinessError } from "@ohos:base";
import effectKit from "@ohos:effectKit";
import image from "@ohos:multimedia.image";
import inputConsumer from "@ohos:multimodalInput.inputConsumer";
import type { KeyEvent } from "@ohos:multimodalInput.keyEvent";
import { KeyCode } from "@ohos:multimodalInput.keyCode";
import { Logger } from "@normalized:N&&&entry/src/main/ets/utils/Logger&";
import { ControlAreaComponent } from "@normalized:N&&&entry/src/main/ets/components/ControlAreaComponent&";
import { ColorTools } from "@normalized:N&&&entry/src/main/ets/utils/ColorTools&";
import { SetVolume } from "@normalized:N&&&entry/src/main/ets/components/AVVolumePanelView&";
import { VolumePanelView } from "@normalized:N&&&entry/src/main/ets/components/VolumePanelView&";
import { SystemVolumePanel } from "@normalized:N&&&entry/src/main/ets/components/SystemVolumePanelView&";
import { songDataList, VolumeType } from "@normalized:N&&&entry/src/main/ets/viewModel/PlayerViewModel&";
import { CommonConstants } from "@normalized:N&&&entry/src/main/ets/common/CommonConstants&";
import type window from "@ohos:window";
import type { AudioRendererController } from '../player/AudioRendererController';
export function PlayerBuilder(name: string, param: Object, parent = null) {
    {
        (parent ? parent : this).observeComponentCreation2((elmtId, isInitialRender) => {
            if (isInitialRender) {
                let componentCall = new Player(parent ? parent : this, {}, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/Player.ets", line: 34, col: 3 });
                ViewPU.create(componentCall);
                let paramsLambda = () => {
                    return {};
                };
                componentCall.paramsGenerator_ = paramsLambda;
            }
            else {
                (parent ? parent : this).updateStateVarsOfChildByElmtId(elmtId, {});
            }
        }, { name: "Player" });
    }
}
function VolumeSetting(parent = null) {
    (parent ? parent : this).observeComponentCreation2((elmtId, isInitialRender) => {
        Column.create();
        Column.backgroundColor('#FFFFFF');
        Column.width('100%');
        Column.height(372);
        Column.padding({
            top: 12,
            bottom: 16
        });
    }, Column);
    (parent ? parent : this).observeComponentCreation2((elmtId, isInitialRender) => {
        Row.create();
        Row.padding({ left: 16, right: 16 });
        Row.height(48);
        Row.justifyContent(FlexAlign.SpaceBetween);
        Row.width('100%');
        Row.margin({ bottom: 8 });
    }, Row);
    (parent ? parent : this).observeComponentCreation2((elmtId, isInitialRender) => {
        Text.create({ "id": 16777225, "type": 10003, params: [], "bundleName": "com.example.audiostreamvolumemanagement", "moduleName": "entry" });
    }, Text);
    Text.pop();
    (parent ? parent : this).observeComponentCreation2((elmtId, isInitialRender) => {
        Toggle.create({ type: ToggleType.Switch, isOn: false });
        Toggle.onChange((isOn: boolean) => {
            if (isOn) {
                AppStorage.setOrCreate('isDisabled', true);
            }
            else {
                AppStorage.setOrCreate('isDisabled', false);
            }
        });
    }, Toggle);
    Toggle.pop();
    Row.pop();
    (parent ? parent : this).observeComponentCreation2((elmtId, isInitialRender) => {
        Divider.create();
        Divider.backgroundColor('#F1F3F5');
        Divider.padding({ left: 16, right: 16 });
        Divider.width('100%');
    }, Divider);
    (parent ? parent : this).observeComponentCreation2((elmtId, isInitialRender) => {
        Column.create();
        Column.padding({ left: 16, right: 16 });
        Column.height(160);
        Column.width('100%');
    }, Column);
    {
        (parent ? parent : this).observeComponentCreation2((elmtId, isInitialRender) => {
            if (isInitialRender) {
                let componentCall = new VolumePanelView(parent ? parent : this, {
                    text: { "id": 16777223, "type": 10003, params: [], "bundleName": "com.example.audiostreamvolumemanagement", "moduleName": "entry" },
                    volumeVisible: true,
                    volumeType: VolumeType.AUDIOSTREAM,
                    Percentage: 50
                }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/Player.ets", line: 63, col: 7 });
                ViewPU.create(componentCall);
                let paramsLambda = () => {
                    return {
                        text: { "id": 16777223, "type": 10003, params: [], "bundleName": "com.example.audiostreamvolumemanagement", "moduleName": "entry" },
                        volumeVisible: true,
                        volumeType: VolumeType.AUDIOSTREAM,
                        Percentage: 50
                    };
                };
                componentCall.paramsGenerator_ = paramsLambda;
            }
            else {
                (parent ? parent : this).updateStateVarsOfChildByElmtId(elmtId, {
                    text: { "id": 16777223, "type": 10003, params: [], "bundleName": "com.example.audiostreamvolumemanagement", "moduleName": "entry" },
                    volumeVisible: true,
                    volumeType: VolumeType.AUDIOSTREAM,
                    Percentage: 50
                });
            }
        }, { name: "VolumePanelView" });
    }
    (parent ? parent : this).observeComponentCreation2((elmtId, isInitialRender) => {
        Divider.create();
        Divider.backgroundColor('#F1F3F5');
        Divider.width('100%');
    }, Divider);
    {
        (parent ? parent : this).observeComponentCreation2((elmtId, isInitialRender) => {
            if (isInitialRender) {
                let componentCall = new VolumePanelView(parent ? parent : this, {
                    text: { "id": 16777222, "type": 10003, params: [], "bundleName": "com.example.audiostreamvolumemanagement", "moduleName": "entry" },
                    volumeVisible: true,
                    volumeType: VolumeType.APPVOLUME,
                    Percentage: 50
                }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/Player.ets", line: 72, col: 7 });
                ViewPU.create(componentCall);
                let paramsLambda = () => {
                    return {
                        text: { "id": 16777222, "type": 10003, params: [], "bundleName": "com.example.audiostreamvolumemanagement", "moduleName": "entry" },
                        volumeVisible: true,
                        volumeType: VolumeType.APPVOLUME,
                        Percentage: 50
                    };
                };
                componentCall.paramsGenerator_ = paramsLambda;
            }
            else {
                (parent ? parent : this).updateStateVarsOfChildByElmtId(elmtId, {
                    text: { "id": 16777222, "type": 10003, params: [], "bundleName": "com.example.audiostreamvolumemanagement", "moduleName": "entry" },
                    volumeVisible: true,
                    volumeType: VolumeType.APPVOLUME,
                    Percentage: 50
                });
            }
        }, { name: "VolumePanelView" });
    }
    Column.pop();
    Column.pop();
}
class Player extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__imageColor = new ObservedPropertySimplePU('rgba(0, 0, 2, 1.00)', this, "imageColor");
        this.__imageLabel = new ObservedPropertyObjectPU(songDataList[0].label, this, "imageLabel");
        this.__windowHeight = new ObservedPropertySimplePU(300, this, "windowHeight");
        this.__volume = this.createStorageLink('systemVolume', CommonConstants.INITIAL_VOLUME, "volume");
        this.__systemVolumeVisible = new ObservedPropertySimplePU(false, this, "systemVolumeVisible");
        this.__isDisabled = this.createStorageLink('isDisabled', false, "isDisabled");
        this.__sheetHeight = new ObservedPropertySimplePU(372, this, "sheetHeight");
        this.__isShow = new ObservedPropertySimplePU(false, this, "isShow");
        this.timer = 0;
        this.volumeUpCallBackFunc = () => {
        };
        this.volumeDownCallBackFunc = () => {
        };
        this.audioRendererController = undefined;
        this.pageInfos = new NavPathStack();
        this.windowClass = AppStorage.get('windowClass');
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: Player_Params) {
        if (params.imageColor !== undefined) {
            this.imageColor = params.imageColor;
        }
        if (params.imageLabel !== undefined) {
            this.imageLabel = params.imageLabel;
        }
        if (params.windowHeight !== undefined) {
            this.windowHeight = params.windowHeight;
        }
        if (params.systemVolumeVisible !== undefined) {
            this.systemVolumeVisible = params.systemVolumeVisible;
        }
        if (params.sheetHeight !== undefined) {
            this.sheetHeight = params.sheetHeight;
        }
        if (params.isShow !== undefined) {
            this.isShow = params.isShow;
        }
        if (params.timer !== undefined) {
            this.timer = params.timer;
        }
        if (params.volumeUpCallBackFunc !== undefined) {
            this.volumeUpCallBackFunc = params.volumeUpCallBackFunc;
        }
        if (params.volumeDownCallBackFunc !== undefined) {
            this.volumeDownCallBackFunc = params.volumeDownCallBackFunc;
        }
        if (params.audioRendererController !== undefined) {
            this.audioRendererController = params.audioRendererController;
        }
        if (params.pageInfos !== undefined) {
            this.pageInfos = params.pageInfos;
        }
        if (params.windowClass !== undefined) {
            this.windowClass = params.windowClass;
        }
    }
    updateStateVars(params: Player_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__imageColor.purgeDependencyOnElmtId(rmElmtId);
        this.__imageLabel.purgeDependencyOnElmtId(rmElmtId);
        this.__windowHeight.purgeDependencyOnElmtId(rmElmtId);
        this.__volume.purgeDependencyOnElmtId(rmElmtId);
        this.__systemVolumeVisible.purgeDependencyOnElmtId(rmElmtId);
        this.__isDisabled.purgeDependencyOnElmtId(rmElmtId);
        this.__sheetHeight.purgeDependencyOnElmtId(rmElmtId);
        this.__isShow.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__imageColor.aboutToBeDeleted();
        this.__imageLabel.aboutToBeDeleted();
        this.__windowHeight.aboutToBeDeleted();
        this.__volume.aboutToBeDeleted();
        this.__systemVolumeVisible.aboutToBeDeleted();
        this.__isDisabled.aboutToBeDeleted();
        this.__sheetHeight.aboutToBeDeleted();
        this.__isShow.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __imageColor: ObservedPropertySimplePU<string>;
    get imageColor() {
        return this.__imageColor.get();
    }
    set imageColor(newValue: string) {
        this.__imageColor.set(newValue);
    }
    private __imageLabel: ObservedPropertyObjectPU<PixelMap | Resource>;
    get imageLabel() {
        return this.__imageLabel.get();
    }
    set imageLabel(newValue: PixelMap | Resource) {
        this.__imageLabel.set(newValue);
    }
    private __windowHeight: ObservedPropertySimplePU<number>;
    get windowHeight() {
        return this.__windowHeight.get();
    }
    set windowHeight(newValue: number) {
        this.__windowHeight.set(newValue);
    }
    private __volume: ObservedPropertyAbstractPU<number>;
    get volume() {
        return this.__volume.get();
    }
    set volume(newValue: number) {
        this.__volume.set(newValue);
    }
    private __systemVolumeVisible: ObservedPropertySimplePU<boolean>;
    get systemVolumeVisible() {
        return this.__systemVolumeVisible.get();
    }
    set systemVolumeVisible(newValue: boolean) {
        this.__systemVolumeVisible.set(newValue);
    }
    private __isDisabled: ObservedPropertyAbstractPU<boolean>;
    get isDisabled() {
        return this.__isDisabled.get();
    }
    set isDisabled(newValue: boolean) {
        this.__isDisabled.set(newValue);
    }
    private __sheetHeight: ObservedPropertySimplePU<number>;
    get sheetHeight() {
        return this.__sheetHeight.get();
    }
    set sheetHeight(newValue: number) {
        this.__sheetHeight.set(newValue);
    }
    private __isShow: ObservedPropertySimplePU<boolean>;
    get isShow() {
        return this.__isShow.get();
    }
    set isShow(newValue: boolean) {
        this.__isShow.set(newValue);
    }
    private timer: number | undefined;
    private volumeUpCallBackFunc: (event: KeyEvent) => void;
    private volumeDownCallBackFunc: (event: KeyEvent) => void;
    private audioRendererController: AudioRendererController | undefined;
    private pageInfos: NavPathStack;
    private windowClass: window.Window | undefined;
    aboutToAppear(): void {
        this.getImageColor();
        this.keyIntercept();
        this.audioRendererController = AppStorage.get('audioRendererController');
        let systemBarProperties: window.SystemBarProperties = {
            statusBarContentColor: '#ffffff',
            statusBarColor: this.imageColor
        };
        this.windowClass?.setWindowSystemBarProperties(systemBarProperties).catch(() => {
            Logger.error('setWindowSystemBarProperties fail ');
        }).then(() => {
            Logger.info('setWindowSystemBarProperties success ');
        });
    }
    aboutToDisappear(): void {
        AppStorage.setOrCreate('progress', undefined);
        AppStorage.setOrCreate('currentTime', undefined);
        this.audioRendererController?.release();
        let sysBarProps: window.SystemBarProperties = {
            statusBarContentColor: '#000000'
        };
        this.windowClass?.setWindowSystemBarProperties(sysBarProps).catch((error: BusinessError) => {
            Logger.error('ImageSwitch', `setWindowSystemBarProperties failed. code=${error.code}, message=${error.message}`);
        });
    }
    keyIntercept(): void {
        try {
            let options1: inputConsumer.KeyPressedConfig = {
                key: KeyCode.KEYCODE_VOLUME_UP,
                action: 1,
                isRepeat: false, // Prioritize the consumption of key events and do not report them.
            };
            let options2: inputConsumer.KeyPressedConfig = {
                key: KeyCode.KEYCODE_VOLUME_DOWN,
                action: 1,
                isRepeat: false, // Prioritize the consumption of key events and do not report them.
            };
            // Clicked the event callback on the volume button.
            this.volumeUpCallBackFunc = (event: KeyEvent) => {
                if (this.isDisabled) {
                    this.getUIContext().getPromptAction().showToast({ message: { "id": 16777239, "type": 10003, params: [], "bundleName": "com.example.audiostreamvolumemanagement", "moduleName": "entry" } });
                    return;
                }
                this.systemVolumeVisible = true;
                this.volume = this.volume + 1;
                clearTimeout(this.timer);
                this.timer = setTimeout(() => {
                    this.systemVolumeVisible = false;
                }, 3000);
            };
            // Clicked the volume button and triggered the event callback.
            this.volumeDownCallBackFunc = (event: KeyEvent) => {
                if (this.isDisabled) {
                    this.getUIContext().getPromptAction().showToast({ message: { "id": 16777238, "type": 10003, params: [], "bundleName": "com.example.audiostreamvolumemanagement", "moduleName": "entry" } });
                    return;
                }
                this.systemVolumeVisible = true;
                this.volume = this.volume - 1;
                clearTimeout(this.timer);
                this.timer = setTimeout(() => {
                    this.systemVolumeVisible = false;
                }, 3000);
            };
            inputConsumer.off('keyPressed');
            // Register for event listening.
            inputConsumer.on('keyPressed', options1, this.volumeUpCallBackFunc);
            inputConsumer.on('keyPressed', options2, this.volumeDownCallBackFunc);
        }
        catch (error) {
            Logger.error(`Subscribe execute failed, error: ${JSON.stringify(error, [`code`, `message`])}`);
        }
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            NavDestination.create(() => {
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Stack.create();
                    Stack.height('100%');
                    Stack.width('100%');
                }, Stack);
                {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        if (isInitialRender) {
                            let componentCall = new 
                            // Do not display the system volume bar.
                            SetVolume(this, { volume: this.volume }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/Player.ets", line: 192, col: 9 });
                            ViewPU.create(componentCall);
                            let paramsLambda = () => {
                                return {
                                    volume: this.volume
                                };
                            };
                            componentCall.paramsGenerator_ = paramsLambda;
                        }
                        else {
                            this.updateStateVarsOfChildByElmtId(elmtId, {
                                volume: this.volume
                            });
                        }
                    }, { name: "SetVolume" });
                }
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Column.create();
                    Column.padding({ right: 16 });
                    Column.alignItems(HorizontalAlign.End);
                    Gesture.create(GesturePriority.Low);
                    PanGesture.create({ direction: PanDirection.Vertical });
                    PanGesture.onActionUpdate((event: GestureEvent) => {
                        this.systemVolumeVisible = true;
                        let curVolume = this.volume - this.getUIContext().vp2px(event.offsetY) / this.windowHeight;
                        curVolume = curVolume >= 15.0 ? 15.0 : curVolume;
                        curVolume = curVolume <= 0.0 ? 0.0 : curVolume;
                        this.volume = curVolume;
                        clearTimeout(this.timer);
                        this.timer = setTimeout(() => {
                            this.systemVolumeVisible = false;
                        }, 3000);
                    });
                    PanGesture.pop();
                    Gesture.pop();
                    Column.zIndex(5);
                    Column.height(280);
                    Column.width('100%');
                    Column.margin({ bottom: 200 });
                }, Column);
                {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        if (isInitialRender) {
                            let componentCall = new 
                            // Use the custom volume bar.
                            SystemVolumePanel(this, {
                                volume: this.__volume,
                                volumeVisible: this.__systemVolumeVisible
                            }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/Player.ets", line: 195, col: 11 });
                            ViewPU.create(componentCall);
                            let paramsLambda = () => {
                                return {
                                    volume: this.volume,
                                    volumeVisible: this.systemVolumeVisible
                                };
                            };
                            componentCall.paramsGenerator_ = paramsLambda;
                        }
                        else {
                            this.updateStateVarsOfChildByElmtId(elmtId, {});
                        }
                    }, { name: "SystemVolumePanel" });
                }
                Column.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Image.create(this.imageLabel);
                    Image.size({ height: '120%' });
                    Image.aspectRatio(1);
                    Image.objectFit(ImageFit.Cover);
                    Image.opacity(0.5);
                }, Image);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Column.create();
                    Column.height('100%');
                    Column.width('100%');
                    Column.padding({ top: 12, bottom: 36 });
                }, Column);
                this.NavDestinationTitle.bind(this)();
                this.CoverInfo.bind(this)();
                this.MusicInfo.bind(this)();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Blank.create();
                }, Blank);
                Blank.pop();
                {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        if (isInitialRender) {
                            let componentCall = new ControlAreaComponent(this, { songData: songDataList[0], imageColor: this.imageColor }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/Player.ets", line: 232, col: 11 });
                            ViewPU.create(componentCall);
                            let paramsLambda = () => {
                                return {
                                    songData: songDataList[0],
                                    imageColor: this.imageColor
                                };
                            };
                            componentCall.paramsGenerator_ = paramsLambda;
                        }
                        else {
                            this.updateStateVarsOfChildByElmtId(elmtId, {
                                songData: songDataList[0], imageColor: this.imageColor
                            });
                        }
                    }, { name: "ControlAreaComponent" });
                }
                Column.pop();
                Stack.pop();
            }, { moduleName: "entry", pagePath: "entry/src/main/ets/pages/Player" });
            NavDestination.hideTitleBar(true);
            NavDestination.backgroundColor(this.imageColor);
            NavDestination.hideBackButton(true);
            NavDestination.height('100%');
            NavDestination.width('100%');
            NavDestination.onReady((context: NavDestinationContext) => {
                this.pageInfos = context.pathStack;
            });
        }, NavDestination);
        NavDestination.pop();
    }
    NavDestinationTitle(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.alignItems(HorizontalAlign.End);
            Column.padding({
                top: 36,
                right: 16,
                left: 16
            });
            Column.width('100%');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.justifyContent(FlexAlign.SpaceBetween);
            Row.width('100%');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width(42);
            Row.height(42);
            Row.borderRadius(42);
            Row.backgroundColor('#19FFFFFF');
            Row.justifyContent(FlexAlign.Center);
            Row.onClick(() => {
                this.pageInfos.pop();
            });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 16777244, "type": 20000, params: [], "bundleName": "com.example.audiostreamvolumemanagement", "moduleName": "entry" });
            Image.width(20);
            Image.height(20);
        }, Image);
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width(42);
            Row.height(42);
            Row.borderRadius(42);
            Row.backgroundColor('#19FFFFFF');
            Row.justifyContent(FlexAlign.Center);
            Row.bindSheet({ value: this.isShow, changeEvent: newValue => { this.isShow = newValue; } }, { builder: () => {
                    VolumeSetting.call(this);
                } }, {
                height: this.sheetHeight,
                backgroundColor: '#FFFFFF',
                title: { title: { "id": 16777236, "type": 10003, params: [], "bundleName": "com.example.audiostreamvolumemanagement", "moduleName": "entry" } }
            });
            Row.onClick(() => {
                this.isShow = true;
            });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 16777256, "type": 20000, params: [], "bundleName": "com.example.audiostreamvolumemanagement", "moduleName": "entry" });
            Image.width(24);
            Image.height(24);
        }, Image);
        Row.pop();
        Row.pop();
        Column.pop();
    }
    CoverInfo(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.height('40%');
            Row.padding({ top: 24 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create(songDataList[0].label);
            Image.height('100%');
            Image.aspectRatio(1);
            Image.borderRadius(8);
            Image.shadow({
                radius: 12,
                color: '#66000000',
                offsetX: 0,
                offsetY: 8
            });
            Image.margin(3);
        }, Image);
        Row.pop();
    }
    MusicInfo(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.padding({
                right: 24,
                left: 24
            });
            Column.margin({ top: 24 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Flex.create({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center });
        }, Flex);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(songDataList[0].title);
            Text.fontSize(20);
            Text.fontColor(Color.White);
            Text.opacity(0.86);
            Text.fontWeight(FontWeight.Bold);
            Text.fontFamily('HarmonyHeiTi-Bold');
        }, Text);
        Text.pop();
        Flex.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(songDataList[0].singer);
            Text.textAlign(TextAlign.Start);
            Text.fontSize(14);
            Text.fontColor('#99FFFFFF');
            Text.fontFamily('HarmonyHeiTi');
            Text.width('100%');
            Text.fontWeight(FontWeight.Regular);
        }, Text);
        Text.pop();
        Column.pop();
    }
    getImageColor() {
        this.getUIContext().getHostContext()!.resourceManager.getMediaContent(songDataList[0].label.id)
            .then((value: Uint8Array) => {
            let buffer = value.buffer as ArrayBuffer;
            let imageSource: image.ImageSource = image.createImageSource(buffer);
            let currentPixelMap: image.PixelMap;
            imageSource.createPixelMap().then((pixelMap) => {
                effectKit.createColorPicker(pixelMap, (error, colorPicker) => {
                    if (error) {
                        Logger.error(`Failed to create color picker. Error: ${error.code}, message: ${error.message}`);
                    }
                    else {
                        currentPixelMap = pixelMap;
                        let color: effectKit.Color = colorPicker.getLargestProportionColor();
                        let colorArr: number[] = ColorTools.dealColor(color.red, color.green, color.blue);
                        this.imageColor = `rgba(${colorArr[0]}, ${colorArr[1]}, ${colorArr[2]}, 1)`;
                    }
                });
                let headFilter = effectKit.createEffect(pixelMap);
                if (headFilter !== null) {
                    headFilter.blur(15);
                    headFilter.getEffectPixelMap().then((value) => {
                        this.imageLabel = value;
                    });
                }
            })
                .finally(() => {
                imageSource?.release();
                currentPixelMap?.release();
            })
                .catch((error: BusinessError) => {
                Logger.error(`createPixelMap error: ${error.code}, message: ${error.message}`);
            });
        })
            .catch((error: BusinessError) => {
            Logger.error(`getMediaContent error: ${error.code}, message: ${error.message}`);
        });
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "Player";
    }
}
registerNamedRoute(() => new Player(undefined, {}), "", { bundleName: "com.example.audiostreamvolumemanagement", moduleName: "entry", pagePath: "pages/Player", pageFullPath: "entry/src/main/ets/pages/Player", integratedHsp: "false", moduleType: "followWithHap" });
(function () {
    if (typeof NavigationBuilderRegister === "function") {
        NavigationBuilderRegister("player", wrapBuilder(PlayerBuilder));
    }
})();
