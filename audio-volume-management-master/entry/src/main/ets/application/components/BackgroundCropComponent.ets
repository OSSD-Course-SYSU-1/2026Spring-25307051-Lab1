import { Logger } from '../../framework/utils/Logger';

const TAG = 'BackgroundCropComponent';

/**
 * 图片裁剪组件
 */
@CustomDialog
export struct BackgroundCropComponent {
  @State imageUri: string = '';
  @State cropX: number = 0;
  @State cropY: number = 0;
  @State cropWidth: number = 0;
  @State cropHeight: number = 0;
  @State imageWidth: number = 0;
  @State imageHeight: number = 0;
  @State displayScale: number = 1;
  @State displayWidth: number = 360; // 图片实际显示宽度
  @State displayHeight: number = 400; // 图片实际显示高度
  @State containerWidth: number = 360; // 容器宽度
  @State containerHeight: number = 400; // 容器高度
  @State imageOffsetX: number = 0; // 图片在容器中的X偏移
  @State imageOffsetY: number = 0; // 图片在容器中的Y偏移
  @State lastX: number = 0; // 上次位置
  @State lastY: number = 0;
  @State isImageLoaded: boolean = false; // 图片是否加载完成
  
  // 屏幕宽高比（9:16或3:4等）
  @Prop screenRatio: number = 9 / 16;
  
  controller: CustomDialogController;
  onCropComplete?: (cropX: number, cropY: number, cropWidth: number, cropHeight: number) => void;

  aboutToAppear() {
    Logger.info(TAG, 'BackgroundCropComponent aboutToAppear');
  }

  build() {
    Column() {
      // 标题
      Row() {
        Text('裁剪背景图片')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)

        Text('取消')
          .fontSize(16)
          .fontColor('#007DFF')
          .onClick(() => {
            this.controller.close();
          })
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 图片预览区域
      Stack() {
        // 原图
        Image(this.imageUri)
          .width('100%')
          .height(400)
          .objectFit(ImageFit.Contain)
          .onComplete((event) => {
            if (event) {
              this.imageWidth = event.width;
              this.imageHeight = event.height;
              // 计算图片在Contain模式下的实际显示尺寸
              this.calculateDisplaySize();
              this.isImageLoaded = true;
              this.initCropArea();
            }
          })

        // 裁剪框
        Column() {
          // 四个角标记
          Row() {
            this.CornerMark()
            Blank().layoutWeight(1)
            this.CornerMark()
          }
          .width('100%')

          Blank().layoutWeight(1)

          Row() {
            this.CornerMark()
            Blank().layoutWeight(1)
            this.CornerMark()
          }
          .width('100%')
        }
        .width(this.cropWidth * this.displayScale)
        .height(this.cropHeight * this.displayScale)
        .borderWidth(2)
        .borderColor('#FFFFFF')
        .backgroundColor('transparent')
        .position({
          x: this.imageOffsetX + this.cropX * this.displayScale,
          y: this.imageOffsetY + this.cropY * this.displayScale
        })
        .gesture(
          PanGesture({ direction: PanDirection.All })
            .onActionStart((event: GestureEvent) => {
              // 记录起始位置
              this.lastX = event.offsetX;
              this.lastY = event.offsetY;
              Logger.info(TAG, `Pan start: offsetX=${event.offsetX}, offsetY=${event.offsetY}, scale=${this.displayScale}`);
            })
            .onActionUpdate((event: GestureEvent) => {
              // 计算增量
              const deltaX = (event.offsetX - this.lastX) / this.displayScale;
              const deltaY = (event.offsetY - this.lastY) / this.displayScale;
              
              // 更新位置（添加边界检查）
              const newCropX = this.cropX + deltaX;
              const newCropY = this.cropY + deltaY;
              
              // 限制在图片范围内
              this.cropX = Math.max(0, Math.min(this.imageWidth - this.cropWidth, newCropX));
              this.cropY = Math.max(0, Math.min(this.imageHeight - this.cropHeight, newCropY));
              
              // 更新上次位置
              this.lastX = event.offsetX;
              this.lastY = event.offsetY;
              
              Logger.info(TAG, `Pan update: delta=${deltaX.toFixed(2)},${deltaY.toFixed(2)}, crop=${this.cropX.toFixed(2)},${this.cropY.toFixed(2)}`);
            })
            .onActionEnd((event: GestureEvent) => {
              Logger.info(TAG, `Pan end: cropX=${this.cropX.toFixed(2)}, cropY=${this.cropY.toFixed(2)}, bounds=[0-${(this.imageWidth - this.cropWidth).toFixed(2)}, 0-${(this.imageHeight - this.cropHeight).toFixed(2)}]`);
            })
        )
      }
      .width('100%')
      .height(400)
      .backgroundColor('#000000')

      // 提示文字
      Text('拖动裁剪框选择背景区域')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 12 })

      // 操作按钮
      Row() {
        Button('重置')
          .width('45%')
          .backgroundColor('#F0F0F0')
          .fontColor('#666666')
          .onClick(() => {
            this.initCropArea();
          })

        Button('确定')
          .width('45%')
          .backgroundColor('#007DFF')
          .onClick(() => {
            if (this.onCropComplete) {
              this.onCropComplete(this.cropX, this.cropY, this.cropWidth, this.cropHeight);
            }
            this.controller.close();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 16 })
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }

  /**
   * 角标记组件
   */
  @Builder
  CornerMark() {
    Column()
      .width(20)
      .height(20)
      .borderWidth(3)
      .borderColor('#FFFFFF')
  }

  /**
   * 计算图片在Contain模式下的实际显示尺寸
   */
  private calculateDisplaySize() {
    // 容器尺寸（Stack的尺寸）
    this.containerWidth = 360; // 默认值，实际应从组件获取
    this.containerHeight = 400;
    
    // 计算图片在Contain模式下的实际显示尺寸
    const imageRatio = this.imageWidth / this.imageHeight;
    const containerRatio = this.containerWidth / this.containerHeight;
    
    if (imageRatio > containerRatio) {
      // 图片更宽，以宽度为基准
      this.displayWidth = this.containerWidth;
      this.displayHeight = this.containerWidth / imageRatio;
    } else {
      // 图片更高，以高度为基准
      this.displayHeight = this.containerHeight;
      this.displayWidth = this.containerHeight * imageRatio;
    }
    
    // 计算图片在容器中的偏移量（居中显示）
    this.imageOffsetX = (this.containerWidth - this.displayWidth) / 2;
    this.imageOffsetY = (this.containerHeight - this.displayHeight) / 2;
    
    // 计算缩放比例：显示尺寸 / 原图尺寸
    this.displayScale = this.displayWidth / this.imageWidth;
    
    Logger.info(TAG, `Display size calculated: container=${this.containerWidth}x${this.containerHeight}, display=${this.displayWidth}x${this.displayHeight}, offset=${this.imageOffsetX},${this.imageOffsetY}, scale=${this.displayScale}`);
  }

  /**
   * 初始化裁剪区域
   */
  private initCropArea() {
    if (this.imageWidth > 0 && this.imageHeight > 0) {
      // 计算裁剪区域（按屏幕比例）
      const targetRatio = this.screenRatio;
      
      if (this.imageWidth / this.imageHeight > targetRatio) {
        // 图片更宽，以高度为基准
        this.cropHeight = this.imageHeight;
        this.cropWidth = this.imageHeight * targetRatio;
      } else {
        // 图片更高，以宽度为基准
        this.cropWidth = this.imageWidth;
        this.cropHeight = this.imageWidth / targetRatio;
      }

      // 居中裁剪区域
      this.cropX = (this.imageWidth - this.cropWidth) / 2;
      this.cropY = (this.imageHeight - this.cropHeight) / 2;

      Logger.info(TAG, `Crop area initialized: x=${this.cropX}, y=${this.cropY}, w=${this.cropWidth}, h=${this.cropHeight}, scale=${this.displayScale}`);
    }
  }

  /**
   * 设置图片URI
   */
  setImageUri(uri: string) {
    this.imageUri = uri;
  }
}
