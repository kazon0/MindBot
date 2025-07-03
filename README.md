#  MindBot AI 校园心理医生  
<iOS 前端开发 & UI 部分>

<img src="https://github.com/user-attachments/assets/b617ddbf-196d-4f81-93ae-9de423756559" width="300" alt="WechatIMG179">

##  技术栈
**Swift 5** · **SwiftUI** · **Combine** · **MVVM 架构**  
**Speech Framework** · **WebSocket** · **RESTful API**  
**Charts** 图表库 · **Lottie** 动画引擎

---

##  项目简介

MindBot 是一款面向高校学生的心理健康服务 App，集 **AI 情绪对话**、**心理评估图表**、**咨询预约**、**匿名社区** 等功能于一体，致力于打造温暖、智能的心理关怀平台。

<img src="https://github.com/user-attachments/assets/2e4ab928-c00c-4263-82c8-0b5737d1daa8" width="300" alt="海报">

---


##  核心模块

<img src="https://github.com/user-attachments/assets/424d438c-f3c6-4eb1-b8a6-a7fc1cc91d45" width="300" alt="079a4a8a45d6fd3b16722964d841f4d2">


-  **AI 情绪对话**  
  支持语音识别与文字输入，结合 WebSocket 实现流式智能语义对话体验

-  **心理评估与情绪图表**  
  集成图表库 Charts，直观展示用户历史情绪波动趋势与测评报告，辅助自我分析

-  **心理咨询预约系统**  
  日历式预约界面，用户可选择咨询师与时间段，预约成功后自动推送提醒

-  **心理互助社区**  
  支持匿名发帖与留言，引用 WaterfallGrid 实现专业瀑布流排布的内容浏览体验

---

##  技术亮点

-  **模块解耦与状态管理**  
  使用 MVVM 架构，结合 `@StateObject` + `@Published` 实现视图与逻辑的解耦与状态响应

-  **WebSocket 实时通信**  
  基于 `URLSessionWebSocketTask` 实现双线程异步监听，结合 Combine 进行消息绑定与更新

-  **语音识别输入**  
  采用 Speech Framework 实现中英文混合语音实时转文字，支持自动与手动终止

-  **图表可视化与筛选**  
  使用 Charts 封装情绪记录图表，支持时间维度筛选、趋势对比和评估报告导出

-  **Lottie 与 SwiftUI 动效**  
  集成 Lottie 与 SwiftUI 动画特效，增强用户操作反馈与视觉体验

---

>  *MindBot 旨在通过科技手段，赋能心理关怀，构建更智慧的校园心理服务体系。*

