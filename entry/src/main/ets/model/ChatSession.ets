import { Message } from './Message';

/**
 * 聊天会话模型
 */
export interface ChatSession {
  id: string;
  title: string;
  messages: Message[];
  createdAt: number;
  updatedAt: number;
}

/**
 * 创建新会话的工厂函数
 */
export function createChatSession(title: string = '新对话'): ChatSession {
  const now = Date.now();
  return {
    id: `session_${now}_${Math.random().toString(36).substr(2, 9)}`,
    title,
    messages: [],
    createdAt: now,
    updatedAt: now
  };
}