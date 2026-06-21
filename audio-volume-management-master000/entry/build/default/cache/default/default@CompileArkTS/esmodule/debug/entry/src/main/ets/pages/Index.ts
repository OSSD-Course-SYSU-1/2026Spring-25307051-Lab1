if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface Index_Params {
    pathStack?: NavPathStack;
    introductions?: string[];
}
class Index extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.pathStack = new NavPathStack();
        this.introductions = [
            'app.string.introduction',
            'app.string.introduction_1',
            'app.string.introduction_2',
            'app.string.introduction_3',
            'app.string.introduction_4',
            'app.string.introduction_5'
        ];
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: Index_Params) {
        if (params.pathStack !== undefined) {
            this.pathStack = params.pathStack;
        }
        if (params.introductions !== undefined) {
            this.introductions = params.introductions;
        }
    }
    updateStateVars(params: Index_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
    }
    aboutToBeDeleted() {
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private pathStack: NavPathStack;
    private introductions: string[];
    NavigationTitle(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.padding({
                left: 16,
                top: 36
            });
            Column.alignItems(HorizontalAlign.End);
            Column.margin({ top: 36 });
            Column.width('100%');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create({ "id": 16777224, "type": 10003, params: [], "bundleName": "com.example.audiostreamvolumemanagement", "moduleName": "entry" });
            Text.fontSize(30);
            Text.fontWeight(FontWeight.Bold);
            Text.width('100%');
            Text.height(56);
        }, Text);
        Text.pop();
        Column.pop();
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Navigation.create(this.pathStack, { moduleName: "entry", pagePath: "entry/src/main/ets/pages/Index", isUserCreateStack: true });
            Navigation.hideToolBar(true);
            Navigation.width('100%');
            Navigation.height('100%');
        }, Navigation);
        this.NavigationTitle.bind(this)();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.height('100%');
            Column.padding({
                left: 16,
                right: 16,
                top: 16,
                bottom: 164
            });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.height('auto');
            Column.alignItems(HorizontalAlign.Start);
            Column.padding({
                left: 12,
                right: 12,
                bottom: 12,
                top: 12
            });
            Column.backgroundColor('#F1F3F5');
            Column.borderRadius(16);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create({ "id": 16777226, "type": 10003, params: [], "bundleName": "com.example.audiostreamvolumemanagement", "moduleName": "entry" });
            Text.fontSize(15);
            Text.lineHeight(20);
            Text.fontWeight(FontWeight.Bold);
            Text.width('100%');
            Text.margin({ bottom: 8 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const item = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create({ "id": -1, "type": -1, params: [item], "bundleName": "com.example.audiostreamvolumemanagement", "moduleName": "entry" });
                    Text.fontSize(13);
                    Text.opacity(0.6);
                    Text.lineHeight(20);
                }, Text);
                Text.pop();
            };
            this.forEachUpdateFunction(elmtId, this.introductions, forEachItemGenFunction, (item: string) => JSON.stringify(item), false, false);
        }, ForEach);
        ForEach.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel({ "id": 16777235, "type": 10003, params: [], "bundleName": "com.example.audiostreamvolumemanagement", "moduleName": "entry" });
            Button.width('100%');
            Button.buttonStyle(ButtonStyleMode.NORMAL);
            Button.onClick(() => {
                this.pathStack.pushPathByName('player', null);
            });
        }, Button);
        Button.pop();
        Column.pop();
        Navigation.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "Index";
    }
}
registerNamedRoute(() => new Index(undefined, {}), "", { bundleName: "com.example.audiostreamvolumemanagement", moduleName: "entry", pagePath: "pages/Index", pageFullPath: "entry/src/main/ets/pages/Index", integratedHsp: "false", moduleType: "followWithHap" });
