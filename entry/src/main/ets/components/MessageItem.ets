import { Message, MessageRole, MessageStatus } from '../model/Message';

/**
 * 消息项组件 - 显示单条消息
 */
@Component
export struct MessageItem {
  @Prop message: Message = {
    id: '',
    role: MessageRole.USER,
    content: '',
    timestamp: Date.now(),
    status: MessageStatus.SUCCESS
  };
  
  build() {
    Row() {
      if (this.message.role === MessageRole.USER) {
        // 用户消息 - 右侧显示
        Blank()
          .layoutWeight(1)
        
        this.UserMessageBubble()
      } else {
        // AI消息 - 左侧显示
        this.AIMessageBubble()
        
        Blank()
          .layoutWeight(1)
      }
    }
    .width('100%')
    .margin({ top: 8, bottom: 8 })
    .padding({ left: 16, right: 16 })
  }
  
  /**
   * 用户消息气泡
   */
  @Builder
  UserMessageBubble() {
    Column() {
      Text(this.message.content)
        .fontSize(16)
        .fontColor(Color.White)
        .lineHeight(24)
        .padding(12)
    }
    .backgroundColor('#007DFF')
    .borderRadius({
      topLeft: 16,
      topRight: 4,
      bottomLeft: 16,
      bottomRight: 16
    })
    .constraintSize({ maxWidth: '75%' })
    .alignItems(HorizontalAlign.End)
  }
  
  /**
   * AI消息气泡
   */
  @Builder
  AIMessageBubble() {
    Column() {
      // AI头像
      Row() {
        Text('AI')
          .fontSize(12)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
      }
      .width(32)
      .height(32)
      .borderRadius(16)
      .backgroundColor('#6B7280')
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 8 })
      
      // 消息内容
      if (this.message.status === MessageStatus.SENDING) {
        Row() {
          LoadingProgress()
            .width(20)
            .height(20)
            .color('#6B7280')
          
          Text('思考中...')
            .fontSize(14)
            .fontColor('#6B7280')
            .margin({ left: 8 })
        }
        .padding(12)
      } else if (this.message.status === MessageStatus.ERROR) {
        Text(this.message.content)
          .fontSize(16)
          .fontColor('#EF4444')
          .lineHeight(24)
          .padding(12)
      } else {
        Text(this.message.content)
          .fontSize(16)
          .fontColor('#1F2937')
          .lineHeight(24)
          .padding(12)
      }
    }
    .backgroundColor('#F3F4F6')
    .borderRadius({
      topLeft: 4,
      topRight: 16,
      bottomLeft: 16,
      bottomRight: 16
    })
    .constraintSize({ maxWidth: '75%' })
    .alignItems(HorizontalAlign.Start)
  }
}