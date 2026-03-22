import { ApiConfig, ApiService } from '../service/ApiService';
import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';

/**
 * 设置页面 - 配置API Key等参数
 */
@Entry
@Component
struct SettingsPage {
  @State apiKey: string = ApiConfig.API_KEY;
  @State model: string = ApiConfig.MODEL;
  @State temperature: number = ApiConfig.TEMPERATURE;
  @State maxTokens: number = ApiConfig.MAX_TOKENS;
  @State isValidating: boolean = false;
  
  build() {
    Column() {
      // 标题栏
      Row() {
        Button() {
          Text('返回')
            .fontSize(16)
            .fontColor('#007DFF')
        }
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          router.back();
        })
        
        Text('设置')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        
        Blank()
          .width(60)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')
      
      // 设置内容
      Scroll() {
        Column() {
          // API配置区域
          this.SectionHeader('API 配置')
          
          this.SettingItem(
            'API Key',
            '请输入通义千问 API Key',
            this.apiKey,
            (value) => {
              this.apiKey = value;
            },
            true
          )
          
          // 模型配置区域
          this.SectionHeader('模型配置')
          
          this.SettingItem(
            '模型',
            'qwen-turbo / qwen-plus / qwen-max',
            this.model,
            (value) => {
              this.model = value;
            }
          )
          
          this.SettingItem(
            '温度 (0-1)',
            '控制回复的随机性，值越大越随机',
            this.temperature.toString(),
            (value) => {
              const num = parseFloat(value);
              if (!isNaN(num) && num >= 0 && num <= 1) {
                this.temperature = num;
              }
            }
          )
          
          this.SettingItem(
            '最大Tokens',
            '控制回复的最大长度',
            this.maxTokens.toString(),
            (value) => {
              const num = parseInt(value);
              if (!isNaN(num) && num > 0) {
                this.maxTokens = num;
              }
            }
          )
          
          // 操作按钮
          Column() {
            // 验证按钮
            Button('验证 API Key')
              .width('100%')
              .height(48)
              .backgroundColor('#10B981')
              .borderRadius(12)
              .margin({ bottom: 12 })
              .enabled(!this.isValidating && this.apiKey !== '')
              .onClick(async () => {
                this.isValidating = true;
                // 临时保存配置
                this.saveConfig();
                
                try {
                  const isValid = await ApiService.getInstance().validateApiKey();
                  if (isValid) {
                    promptAction.showToast({
                      message: 'API Key 验证成功！',
                      duration: 2000
                    });
                  } else {
                    promptAction.showToast({
                      message: 'API Key 验证失败，请检查',
                      duration: 2000
                    });
                  }
                } catch (error) {
                  promptAction.showToast({
                    message: '验证失败: ' + error,
                    duration: 2000
                  });
                } finally {
                  this.isValidating = false;
                }
              })
            
            // 保存按钮
            Button('保存配置')
              .width('100%')
              .height(48)
              .backgroundColor('#007DFF')
              .borderRadius(12)
              .onClick(() => {
                this.saveConfig();
                promptAction.showToast({
                  message: '配置已保存',
                  duration: 2000
                });
                router.back();
              })
          }
          .width('100%')
          .padding({ top: 24, bottom: 24 })
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
      .backgroundColor('#F9FAFB')
    }
    .width('100%')
    .height('100%')
  }
  
  /**
   * 保存配置
   */
  saveConfig() {
    ApiConfig.API_KEY = this.apiKey;
    ApiConfig.MODEL = this.model;
    ApiConfig.TEMPERATURE = this.temperature;
    ApiConfig.MAX_TOKENS = this.maxTokens;
  }
  
  /**
   * 区域标题
   */
  @Builder
  SectionHeader(title: string) {
    Text(title)
      .fontSize(14)
      .fontColor('#6B7280')
      .fontWeight(FontWeight.Medium)
      .width('100%')
      .margin({ top: 16, bottom: 8 })
  }
  
  /**
   * 设置项
   */
  @Builder
  SettingItem(
    label: string,
    hint: string,
    value: string,
    onChange: (value: string) => void,
    isPassword: boolean = false
  ) {
    Column() {
      Text(label)
        .fontSize(16)
        .fontColor('#1F2937')
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ bottom: 8 })
      
      if (isPassword) {
        TextInput({ placeholder: hint, text: value })
          .width('100%')
          .height(48)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .padding({ left: 12, right: 12 })
          .type(InputType.Password)
          .onChange((value) => {
            onChange(value);
          })
      } else {
        TextInput({ placeholder: hint, text: value })
          .width('100%')
          .height(48)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .padding({ left: 12, right: 12 })
          .onChange((value) => {
            onChange(value);
          })
      }
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .padding(12)
    .margin({ bottom: 12 })
  }
}