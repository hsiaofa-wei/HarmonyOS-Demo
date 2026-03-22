/**
 * 消息角色枚举
 */
export enum MessageRole {
  USER = 'user',
  ASSISTANT = 'assistant',
  SYSTEM = 'system'
}

/**
 * 消息状态枚举
 */
export enum MessageStatus {
  SENDING = 'sending',
  SUCCESS = 'success',
  ERROR = 'error'
}

/**
 * 消息数据模型
 */
export interface Message {
  id: string;
  role: MessageRole;
  content: string;
  timestamp: number;
  status?: MessageStatus;
}

/**
 * 创建消息的工厂函数
 */
export function createMessage(
  role: MessageRole,
  content: string,
  status: MessageStatus = MessageStatus.SUCCESS
): Message {
  return {
    id: `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    role,
    content,
    timestamp: Date.now(),
    status
  };
}