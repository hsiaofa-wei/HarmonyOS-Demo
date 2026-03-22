import { http } from '@kit.NetworkKit';
import { MessageRole } from '../model/Message';

/**
 * API配置
 */
export class ApiConfig {
  // TODO: 在这里填入你的通义千问API Key
  static API_KEY: string = '';

  // 通义千问API地址
  static BASE_URL: string = 'https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation';
  
  // 使用的模型
  static MODEL: string = 'qwen3-max';
  
  // 最大tokens
  static MAX_TOKENS: number = 2000;
  
  // 温度参数 (0-1)
  static TEMPERATURE: number = 0.7;
}

/**
 * API请求消息格式
 */
export class ApiMessage {
  role: string = '';
  content: string = '';
  
  constructor(role: string, content: string) {
    this.role = role;
    this.content = content;
  }
}

/**
 * API请求输入
 */
export class ApiInput {
  messages: ApiMessage[] = [];
  
  constructor(messages: ApiMessage[]) {
    this.messages = messages;
  }
}

/**
 * API请求参数
 */
export class ApiParameters {
  max_tokens: number = 2000;
  temperature: number = 0.7;
  result_format: string = 'message';
  
  constructor(maxTokens: number, temperature: number) {
    this.max_tokens = maxTokens;
    this.temperature = temperature;
  }
}

/**
 * API请求体
 */
export class ApiRequestBody {
  model: string = '';
  input: ApiInput | null = null;
  parameters: ApiParameters | null = null;
  
  constructor(model: string, input: ApiInput, parameters: ApiParameters) {
    this.model = model;
    this.input = input;
    this.parameters = parameters;
  }
}

/**
 * 请求消息项
 */
export class RequestMessageItem {
  role: MessageRole = MessageRole.USER;
  content: string = '';
  
  constructor(role: MessageRole, content: string) {
    this.role = role;
    this.content = content;
  }
}

/**
 * API服务类 - 处理与通义千问API的通信
 */
export class ApiService {
  private static instance: ApiService;
  
  private constructor() {}
  
  /**
   * 获取单例实例
   */
  static getInstance(): ApiService {
    if (!ApiService.instance) {
      ApiService.instance = new ApiService();
    }
    return ApiService.instance;
  }
  
  /**
   * 发送聊天请求
   */
  async sendChatRequest(
    messages: RequestMessageItem[]
  ): Promise<string> {
    // 检查API Key
    if (ApiConfig.API_KEY === 'YOUR_API_KEY_HERE' || ApiConfig.API_KEY === '') {
      throw new Error('请先配置您的API Key');
    }
    
    // 构建请求消息
    const apiMessages: ApiMessage[] = messages.map(msg => 
      new ApiMessage(msg.role, msg.content)
    );
    
    // 构建请求体
    const input = new ApiInput(apiMessages);
    const parameters = new ApiParameters(ApiConfig.MAX_TOKENS, ApiConfig.TEMPERATURE);
    const requestBody = new ApiRequestBody(ApiConfig.MODEL, input, parameters);
    
    console.info('=== API请求开始 ===');
    console.info('URL:', ApiConfig.BASE_URL);
    console.info('Model:', ApiConfig.MODEL);
    console.info('Messages:', JSON.stringify(apiMessages));
    
    try {
      // 创建HTTP请求
      const httpRequest = http.createHttp();
      
      // 发送POST请求
      const response = await httpRequest.request(
        ApiConfig.BASE_URL,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${ApiConfig.API_KEY}`
          },
          extraData: JSON.stringify(requestBody),
          connectTimeout: 60000,
          readTimeout: 60000
        }
      );
      
      console.info('响应状态码:', response.responseCode);
      console.info('响应结果:', response.result);
      
      // 销毁HTTP请求对象
      httpRequest.destroy();
      
      // 检查响应
      if (response.responseCode !== 200) {
        const errorBody = response.result as string;
        console.error('API请求失败:', response.responseCode, errorBody);
        throw new Error(`API请求失败(${response.responseCode}): ${errorBody}`);
      }
      
      // 解析响应
      const result = response.result as string;
      const jsonResponse: Record<string, Object> = JSON.parse(result) as Record<string, Object>;
      
      console.info('解析后的响应:', JSON.stringify(jsonResponse));
      
      // 尝试从响应中提取文本
      let responseText = '';
      
      // 格式1: output.text (result_format: text)
      const output = jsonResponse['output'] as Record<string, Object>;
      if (output && output['text']) {
        responseText = output['text'] as string;
      }
      // 格式2: output.choices[0].message.content (result_format: message)
      else if (output && output['choices']) {
        const choices = output['choices'] as Array<Record<string, Object>>;
        if (choices.length > 0) {
          const choice = choices[0];
          const message = choice['message'] as Record<string, Object>;
          if (message && message['content']) {
            responseText = message['content'] as string;
          }
        }
      }
      
      // 检查是否有错误码
      if (jsonResponse['code']) {
        const errorCode = jsonResponse['code'] as string;
        const errorMsg = jsonResponse['message'] as string;
        throw new Error(`API错误: ${errorCode} - ${errorMsg || '未知错误'}`);
      }
      
      if (!responseText) {
        console.error('无法从响应中提取文本，响应结构:', JSON.stringify(jsonResponse));
        throw new Error('API响应格式异常，无法提取回复内容');
      }
      
      console.info('=== API请求成功 ===');
      console.info('回复内容:', responseText);
      
      return responseText;
      
    } catch (error) {
      console.error('=== API请求异常 ===');
      console.error('错误信息:', error);
      throw new Error(`请求失败: ${error}`);
    }
  }
  
  /**
   * 验证API Key是否有效
   */
  async validateApiKey(): Promise<boolean> {
    try {
      // 发送一个简单的测试请求
      const testMessage = new RequestMessageItem(MessageRole.USER, 'Hi');
      await this.sendChatRequest([testMessage]);
      return true;
    } catch (error) {
      console.error('API Key验证失败:', error);
      return false;
    }
  }
}