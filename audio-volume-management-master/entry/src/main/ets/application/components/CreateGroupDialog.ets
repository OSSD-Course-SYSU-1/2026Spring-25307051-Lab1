/**
 * 创建组合体对话框组件
 */
@CustomDialog
@Component
export struct CreateGroupDialog {
  @State groupName: string = '';
  controller: CustomDialogController;
  onConfirm: (name: string) => void = (name: string) => {};

  build() {
    Column() {
      // 标题
      Text('创建组合体')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      // 输入框
      TextInput({ placeholder: '请输入组合体名称' })
        .width('100%')
        .height(48)
        .fontSize(16)
        .onChange((value: string) => {
          this.groupName = value;
        })
        .margin({ bottom: 20 })

      // 按钮区域
      Row() {
        Button('取消')
          .width('45%')
          .height(40)
          .fontSize(16)
          .fontColor('#666666')
          .backgroundColor('#F0F0F0')
          .borderRadius(20)
          .onClick(() => {
            this.controller.close();
          })

        Blank().width('10%')

        Button('确定')
          .width('45%')
          .height(40)
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor('#0A59F7')
          .borderRadius(20)
          .onClick(() => {
            if (this.onConfirm) {
              this.onConfirm(this.groupName || '新组合体');
            }
            this.controller.close();
          })
      }
      .width('100%')
    }
    .width('80%')
    .padding(24)
    .backgroundColor(Color.White)
    .borderRadius(16)
  }
}
