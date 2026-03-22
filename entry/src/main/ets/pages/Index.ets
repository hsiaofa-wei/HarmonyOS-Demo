import router from '@ohos.router';

/**
 * 启动页面 - 自动跳转到聊天页面
 */
@Entry
@Component
struct Index {
  aboutToAppear() {
    // 立即跳转到聊天页面
    this.navigateToChat();
  }
  
  async navigateToChat() {
    try {
      await router.replaceUrl({
        url: 'pages/ChatPage'
      });
    } catch (error) {
      console.error('路由跳转失败:', error);
    }
  }

  build() {
    Column() {
      Image($r('app.media.startIcon'))
        .width(100)
        .height(100)
        .margin({ bottom: 24 })
      
      Text('AI 智能助手')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1F2937')
        .margin({ bottom: 8 })
      
      Text('正在加载...')
        .fontSize(14)
        .fontColor('#6B7280')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
  }
}