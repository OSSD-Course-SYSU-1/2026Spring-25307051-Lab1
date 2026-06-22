/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

@Entry
@Component
struct Index {
  pathStack: NavPathStack = new NavPathStack();
  private introductions: string [] = [
    'app.string.introduction',
    'app.string.introduction_1',
    'app.string.introduction_2',
    'app.string.introduction_3',
    'app.string.introduction_4',
    'app.string.introduction_5'
  ];

  @Builder
  NavigationTitle() {
    Column() {
      Text($r('app.string.audio_volume_control'))
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .height(56)
    }
    .padding({
      left: 16,
      top: 36
    })
    .alignItems(HorizontalAlign.End)
    .margin({ top: 36 })
    .width('100%')
  }

  build() {
    Navigation(this.pathStack) {
      this.NavigationTitle()
      Column() {
        Column() {
          Text($r('app.string.explanation'))
            .fontSize(15)
            .lineHeight(20)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          ForEach(this.introductions, (item: string) => {
            Text($r(item))
              .fontSize(13)
              .opacity(0.6)
              .lineHeight(20)
          }, (item: string) => JSON.stringify(item))
        }
        .width('100%')
        .height('auto')
        .alignItems(HorizontalAlign.Start)
        .padding({
          left: 12,
          right: 12,
          bottom: 12,
          top: 12
        })
        .backgroundColor('#F1F3F5')
        .borderRadius(16)

        Blank()

        Button($r('app.string.playback_page'))
          .width('100%')
          .buttonStyle(ButtonStyleMode.NORMAL)
          .onClick(() => {
            this.pathStack.pushPathByName('player', null);
          })
      }
      .width('100%')
      .height('100%')
      .padding({
        left: 16,
        right: 16,
        top: 16,
        bottom: 164
      })
    }
    .hideToolBar(true)
    .width('100%')
    .height('100%')
  }
}