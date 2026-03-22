import { Message, MessageStatus, MessageRole } from '../model/Message';
import { ChatService } from '../service/ChatService';
import router from '@ohos.router';

/**
 * 聊天主页面
 */
@Entry
@Component
struct ChatPage {
  @State messages: Message[] = [];
  @State inputText: string = '';
  @State isSending: boolean = false;
  @State showSessionList: boolean = false;
  @State debugInfo: string = '';  // 调试信息
  
  private chatService: ChatService = ChatService.getInstance();
  private scroller: Scroller = new Scroller();
  
  aboutToAppear() {
    // 初始化或获取当前会话
    if (!this.chatService.getCurrentSession()) {
      this.chatService.createNewSession();
    }
    this.loadMessages();
  }
  
  /**
   * 加载消息列表
   */
  loadMessages() {
    this.messages = this.chatService.getCurrentMessages();
    // 滚动到底部
    setTimeout(() => {
      this.scroller.scrollEdge(Edge.Bottom);
    }, 100);
  }
  
  /**
   * 发送消息
   */
  async sendMessage() {
    if (this.inputText.trim() === '' || this.isSending) {
      return;
    }
    
    const content = this.inputText.trim();
    this.inputText = '';
    this.isSending = true;
    this.debugInfo = '开始发送消息...';
    
    // 立即更新UI显示用户消息
    this.messages = [...this.chatService.getCurrentMessages()];
    
    try {
      this.debugInfo = '正在调用API...';
      await this.chatService.sendMessage(content, (message) => {
        this.debugInfo = `状态更新: ${message.status}`;
        console.info('消息状态更新:', message.status, message.content);
        // 强制更新消息列表
        this.messages = [...this.chatService.getCurrentMessages()];
        // 滚动到底部
        setTimeout(() => {
          this.scroller.scrollEdge(Edge.Bottom);
        }, 50);
      });
      this.debugInfo = '消息发送成功';
    } catch (error) {
      this.debugInfo = `发送失败: ${error}`;
      console.error('发送消息失败:', error);
      // 确保错误状态也能显示
      this.messages = [...this.chatService.getCurrentMessages()];
    } finally {
      this.isSending = false;
      // 最终再刷新一次
      this.messages = [...this.chatService.getCurrentMessages()];
    }
  }
  
  /**
   * 创建新会话
   */
  createNewSession() {
    this.chatService.createNewSession();
    this.messages = [];
    this.showSessionList = false;
  }
  
  build() {
    Column() {
      // 顶部标题栏
      this.TitleBar()
      
      // 调试信息
      if (this.debugInfo !== '') {
        Text(this.debugInfo)
          .fontSize(12)
          .fontColor('#FF0000')
          .backgroundColor('#FFFF00')
          .padding(4)
          .width('100%')
      }
      
      // 消息列表
      if (this.messages.length === 0) {
        this.EmptyView()
      } else {
        this.MessageList()
      }
      
      // 底部输入区域
      this.InputArea()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
  
  /**
   * 标题栏
   */
  @Builder
  TitleBar() {
    Row() {
      // 菜单按钮
      Button() {
        Image($r('app.media.startIcon'))
          .width(24)
          .height(24)
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.showSessionList = !this.showSessionList;
      })
      
      // 标题
      Text(this.chatService.getCurrentSession()?.title || '智能助手')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      
      // 新建会话按钮
      Button() {
        Text('+')
          .fontSize(24)
          .fontColor('#007DFF')
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.createNewSession();
      })
      
      // 设置按钮
      Button() {
        Text('⚙')
          .fontSize(20)
          .fontColor('#6B7280')
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        router.pushUrl({ url: 'pages/SettingsPage' });
      })
    }
    .width('100%')
    .height(56)
    .padding({ left: 8, right: 8 })
    .backgroundColor('#FFFFFF')
    .shadow({
      radius: 2,
      color: '#1F000000',
      offsetY: 2
    })
  }
  
  /**
   * 空状态视图
   */
  @Builder
  EmptyView() {
    Column() {
      Image($r('app.media.startIcon'))
        .width(80)
        .height(80)
        .margin({ bottom: 16 })
      
      Text('开始对话')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1F2937')
        .margin({ bottom: 8 })
      
      Text('发送消息开始与AI助手对话')
        .fontSize(14)
        .fontColor('#6B7280')
    }
    .layoutWeight(1)
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }
  
  /**
   * 消息列表
   */
  @Builder
  MessageList() {
    List({ scroller: this.scroller }) {
      ForEach(this.messages, (message: Message) => {
        ListItem() {
          // 直接渲染消息，不使用子组件
          Row() {
            if (message.role === MessageRole.USER) {
              // 用户消息 - 右侧显示
              Blank()
                .layoutWeight(1)
              
              // 用户消息气泡
              Column() {
                Text(message.content)
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
            } else {
              // AI消息 - 左侧显示
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
                
                // 消息内容 - 根据状态显示不同内容
                if (message.status === MessageStatus.SENDING) {
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
                } else if (message.status === MessageStatus.ERROR) {
                  Text(message.content)
                    .fontSize(16)
                    .fontColor('#EF4444')
                    .lineHeight(24)
                    .padding(12)
                } else {
                  Text(message.content)
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
              
              Blank()
                .layoutWeight(1)
            }
          }
          .width('100%')
          .margin({ top: 8, bottom: 8 })
          .padding({ left: 16, right: 16 })
        }
      }, (message: Message) => message.id + '_' + message.status)
    }
    .layoutWeight(1)
    .width('100%')
    .edgeEffect(EdgeEffect.Spring)
  }
  
  /**
   * 输入区域
   */
  @Builder
  InputArea() {
    Row() {
      // 输入框
      TextArea({ placeholder: '输入消息...', controller: new TextAreaController() })
        .width(0)
        .layoutWeight(1)
        .height(40)
        .backgroundColor('#F3F4F6')
        .borderRadius(20)
        .padding({ left: 16, right: 16 })
        .onChange((value) => {
          this.inputText = value;
        })
        .enabled(!this.isSending)
      
      // 发送按钮
      Button() {
        if (this.isSending) {
          LoadingProgress()
            .width(20)
            .height(20)
            .color(Color.White)
        } else {
          Text('发送')
            .fontSize(14)
            .fontColor(Color.White)
        }
      }
      .width(60)
      .height(40)
      .backgroundColor(this.isSending ? '#9CA3AF' : '#007DFF')
      .borderRadius(20)
      .margin({ left: 8 })
      .enabled(!this.isSending && this.inputText.trim() !== '')
      .onClick(() => {
        this.sendMessage();
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('#FFFFFF')
    .shadow({
      radius: 8,
      color: '#1F000000',
      offsetY: -2
    })
  }
}