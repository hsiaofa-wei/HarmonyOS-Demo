import { Message, MessageRole, MessageStatus, createMessage } from '../model/Message';
import { ChatSession, createChatSession } from '../model/ChatSession';
import { ApiService, RequestMessageItem } from './ApiService';

/**
 * 聊天服务 - 管理聊天会话和消息
 */
export class ChatService {
  private static instance: ChatService;
  private apiService: ApiService;
  private currentSession: ChatSession | null = null;
  private sessions: ChatSession[] = [];
  
  // 系统提示词 - 定义AI角色为老师
  private static readonly SYSTEM_PROMPT: string =
    '你是一位鸿蒙应用开发专家，擅长ArkTS和ArkUI。用户会问你关于鸿蒙开发的问题，比如组件使用、生命周期、权限配置等。请用简洁专业的语言回答。'
  
  private constructor() {
    this.apiService = ApiService.getInstance();
  }
  
  /**
   * 获取单例实例
   */
  static getInstance(): ChatService {
    if (!ChatService.instance) {
      ChatService.instance = new ChatService();
    }
    return ChatService.instance;
  }
  
  /**
   * 创建新会话
   */
  createNewSession(title: string = '新对话'): ChatSession {
    const session = createChatSession(title);
    this.sessions.unshift(session);
    this.currentSession = session;
    return session;
  }
  
  /**
   * 获取当前会话
   */
  getCurrentSession(): ChatSession | null {
    if (!this.currentSession && this.sessions.length > 0) {
      this.currentSession = this.sessions[0];
    }
    return this.currentSession;
  }
  
  /**
   * 获取所有会话
   */
  getAllSessions(): ChatSession[] {
    return this.sessions;
  }
  
  /**
   * 切换会话
   */
  switchSession(sessionId: string): ChatSession | null {
    const session = this.sessions.find(s => s.id === sessionId);
    if (session) {
      this.currentSession = session;
    }
    return this.currentSession;
  }
  
  /**
   * 删除会话
   */
  deleteSession(sessionId: string): void {
    const index = this.sessions.findIndex(s => s.id === sessionId);
    if (index !== -1) {
      this.sessions.splice(index, 1);
      if (this.currentSession?.id === sessionId) {
        this.currentSession = this.sessions.length > 0 ? this.sessions[0] : null;
      }
    }
  }
  
  /**
   * 发送消息并获取AI回复
   */
  async sendMessage(
    content: string,
    onProgress?: (message: Message) => void
  ): Promise<Message> {
    console.info('=== ChatService.sendMessage 开始 ===');
    
    // 确保有当前会话
    if (!this.currentSession) {
      this.createNewSession();
    }
    
    // 创建用户消息
    const userMessage = createMessage(MessageRole.USER, content);
    this.currentSession!.messages.push(userMessage);
    this.currentSession!.updatedAt = Date.now();
    console.info('用户消息已创建:', userMessage.id);
    
    // 更新会话标题（使用第一条用户消息）
    if (this.currentSession!.messages.filter(m => m.role === MessageRole.USER).length === 1) {
      this.currentSession!.title = content.substring(0, 30) + (content.length > 30 ? '...' : '');
    }
    
    // 创建AI回复消息（发送中状态）
    const aiMessage = createMessage(MessageRole.ASSISTANT, '', MessageStatus.SENDING);
    this.currentSession!.messages.push(aiMessage);
    console.info('AI消息已创建(发送中):', aiMessage.id);
    
    // 通知进度
    if (onProgress) {
      console.info('调用onProgress回调');
      onProgress(aiMessage);
    }
    
    try {
      // 准备发送给API的消息历史
      const apiMessages: RequestMessageItem[] = [];
      
      // 添加系统提示词（老师角色设定）
      apiMessages.push(new RequestMessageItem(MessageRole.SYSTEM, ChatService.SYSTEM_PROMPT));
      
      // 添加历史消息
      this.currentSession!.messages
        .filter(m => m.status !== MessageStatus.SENDING)
        .forEach(m => {
          apiMessages.push(new RequestMessageItem(m.role, m.content));
        });
      
      console.info('准备调用API，消息数量:', apiMessages.length);
      
      // 调用API
      const response = await this.apiService.sendChatRequest(apiMessages);
      console.info('API返回成功，响应长度:', response.length);
      
      // 更新AI消息
      aiMessage.content = response;
      aiMessage.status = MessageStatus.SUCCESS;
      this.currentSession!.updatedAt = Date.now();
      console.info('AI消息已更新为成功状态');
      
      // 通知进度
      if (onProgress) {
        console.info('再次调用onProgress回调');
        onProgress(aiMessage);
      }
      
      return aiMessage;
      
    } catch (error) {
      console.error('API调用失败:', error);
      // 更新错误状态
      aiMessage.content = `抱歉，发生了错误: ${error}`;
      aiMessage.status = MessageStatus.ERROR;
      
      // 通知进度
      if (onProgress) {
        onProgress(aiMessage);
      }
      
      throw new Error(`发送失败: ${error}`);
    }
  }
  
  /**
   * 清空当前会话的消息
   */
  clearCurrentSession(): void {
    if (this.currentSession) {
      this.currentSession.messages = [];
      this.currentSession.updatedAt = Date.now();
    }
  }
  
  /**
   * 获取当前会话的消息列表（返回新数组以触发UI更新）
   */
  getCurrentMessages(): Message[] {
    // 返回新数组副本，确保UI能检测到变化
    return [...(this.currentSession?.messages || [])];
  }
}