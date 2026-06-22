import { TaskGroup } from '../model/TaskGroup';

/**
 * 多选操作栏组件
 */
@Component
export struct MultiSelectBar {
  @Prop selectedCount: number;
  @Prop existingGroups: TaskGroup[];
  @State showGroupList: boolean = false;

  // 回调函数
  onCreateGroup?: () => void;
  onAddToGroup?: (groupId: string) => void;
  onCancel?: () => void;

  build() {
    Column() {
      // 操作按钮区域
      Row() {
        // 取消按钮
        Button('取消')
          .fontSize(16)
          .fontColor('#666666')
          .backgroundColor('#F0F0F0')
          .borderRadius(20)
          .onClick(() => {
            if (this.onCancel) {
              this.onCancel();
            }
          })

        // 选中计数
        Text(`已选 ${this.selectedCount} 项`)
          .fontSize(16)
          .fontColor('#333333')
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 创建/合并按钮
        Button() {
          Row() {
            Text('+')
              .fontSize(20)
              .fontColor(Color.White)
            Text('创建')
              .fontSize(16)
              .fontColor(Color.White)
              .margin({ left: 4 })
          }
        }
        .backgroundColor('#0A59F7')
        .borderRadius(20)
        .onClick(() => {
          this.showGroupList = !this.showGroupList;
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      // 组合体列表（展开状态）
      if (this.showGroupList) {
        Column() {
          // 创建新组合体选项
          Button('创建新组合体')
            .width('100%')
            .fontSize(16)
            .fontColor('#0A59F7')
            .backgroundColor('#E8F4FF')
            .borderRadius(8)
            .onClick(() => {
              this.showGroupList = false;
              if (this.onCreateGroup) {
                this.onCreateGroup();
              }
            })

          // 现有组合体列表
          if (this.existingGroups.length > 0) {
            Text('移入现有组合体')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ top: 12, bottom: 8 })

            ForEach(this.existingGroups, (group: TaskGroup) => {
              Button(group.name)
                .width('100%')
                .fontSize(16)
                .fontColor('#333333')
                .backgroundColor('#F5F5F5')
                .borderRadius(8)
                .margin({ top: 4 })
                .onClick(() => {
                  this.showGroupList = false;
                  if (this.onAddToGroup) {
                    this.onAddToGroup(group.id);
                  }
                })
            })
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 16 })
        .backgroundColor('#FFFFFF')
      }
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 16, topRight: 16 })
    .shadow({
      radius: 8,
      color: '#1F000000',
      offsetX: 0,
      offsetY: -4
    })
  }
}
