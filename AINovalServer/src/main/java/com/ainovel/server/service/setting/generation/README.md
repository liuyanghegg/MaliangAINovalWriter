# AI驱动的结构化小说设定生成系统

## 概述

本系统实现了一个高度解耦、可扩展的AI驱动设定生成框架，支持使用LangChain4j的工具调用（Function Calling）策略，实现结构化数据的可靠生成。

## 核心特性

1. **工具调用策略**：使用LangChain4j的Function Calling功能，确保LLM输出结构化、可验证的数据
2. **流式响应**：通过SSE（Server-Sent Events）实时推送生成进度和结果
3. **会话管理**：基于Redis的会话状态管理，支持长时间的生成任务
4. **数据验证**：多层次的数据验证机制，包括JSON Schema验证和业务逻辑验证
5. **策略模式**：可扩展的生成策略设计，目前实现了"九线法"策略
6. **错误恢复**：智能错误处理和部分恢复机制

## 架构设计

### 核心组件

1. **SettingGenerationService**
   - 主服务入口，协调各组件工作
   - 管理生成流程和AI模型交互

2. **SettingGenerationToolCallHandler**
   - 实现工具调用的具体逻辑
   - 管理事件流推送
   - 维护线程本地会话上下文

3. **SettingGenerationSessionManager**
   - 管理会话生命周期
   - 基于Redis的分布式会话存储
   - 支持会话过期和续期

4. **SettingValidationService**
   - JSON Schema验证
   - 业务逻辑验证
   - 内容质量检查

5. **LangChain4jToolAdapter**
   - 工具规范生成
   - 工具调用执行和结果处理

6. **SettingGenerationStrategy（接口）**
   - 定义生成策略的标准接口
   - 支持不同的设定生成方法

### 数据模型

- **SettingGenerationSession**：会话状态和生成的节点数据
- **SettingNode**：单个设定节点
- **SettingGenerationEvent**：SSE事件的多态模型
- **SettingGenerationTool**：工具调用定义

## API使用说明

### 1. 获取可用策略

```http
GET /api/v1/setting-generation/strategies
```

响应示例：
```json
{
  "code": 200,
  "data": [
    {
      "name": "九线法",
      "description": "基于网文创作九线法理论，系统化地构建小说的核心设定",
      "expectedRootNodeCount": 9,
      "maxDepth": 4
    }
  ]
}
```

### 2. 启动设定生成（SSE流）

```http
POST /api/v1/setting-generation/start
Content-Type: application/json

{
  "initialPrompt": "一个在古代东方王朝背景下，蒸汽朋克技术与传统修仙门派共存的世界",
  "strategy": "nine-line-method",
  "aiProvider": "OPENAI",
  "aiModel": "gpt-4",
  "aiConfig": {
    "temperature": "0.8"
  }
}
```

SSE事件流示例：
```
event: SessionStartedEvent
data: {"sessionId":"xxx","initialPrompt":"...","strategy":"nine-line-method"}

event: NodeCreatedEvent
data: {"sessionId":"xxx","node":{"id":"n1","name":"人物线","type":"OTHER",...}}

event: GenerationProgressEvent
data: {"sessionId":"xxx","message":"生成进度","progress":0.5}

event: GenerationCompletedEvent
data: {"sessionId":"xxx","totalNodesGenerated":45,"status":"SUCCESS"}
```

### 3. 修改设定节点（SSE流）

```http
POST /api/v1/setting-generation/{sessionId}/update-node
Content-Type: application/json

{
  "nodeId": "node_123",
  "modificationPrompt": "将这个门派改为更加邪恶的机械改造派",
  "aiProvider": "OPENAI",
  "aiModel": "gpt-4",
  "aiConfig": {}
}
```

### 4. 保存生成的设定

```http
POST /api/v1/setting-generation/{sessionId}/save
```

## 扩展新策略

要添加新的生成策略，实现`SettingGenerationStrategy`接口：

```java
@Component("your-strategy-name")
public class YourStrategy implements SettingGenerationStrategy {
    
    @Override
    public String getStrategyName() {
        return "Your Strategy Name";
    }
    
    @Override
    public String buildSystemPrompt() {
        // 构建系统提示词
    }
    
    @Override
    public String buildUserPrompt(String initialPrompt, SettingGenerationSession session) {
        // 构建用户提示词
    }
    
    // 实现其他必需方法...
}
```

## 配置要求

### Redis配置
```yaml
spring:
  redis:
    host: localhost
    port: 6379
    timeout: 60s
```

### AI模型配置
确保配置了支持Function Calling的模型：
- OpenAI: GPT-3.5-turbo, GPT-4
- Anthropic: Claude-3系列
- 其他兼容的模型

## 性能优化建议

1. **批量创建**：使用`createSettingNodes`工具一次创建多个相关节点
2. **会话管理**：及时清理过期会话，避免Redis内存溢出
3. **流式处理**：利用响应式编程特性，避免阻塞操作
4. **缓存策略**：对常用的策略元数据进行缓存

## 错误处理

系统实现了多层错误处理：

1. **LLM输出错误**：自动重试和修正机制
2. **验证失败**：详细的错误信息反馈
3. **会话过期**：自动清理和友好提示
4. **网络异常**：断线重连和恢复机制

## 未来改进方向

1. **更多生成策略**：三幕剧结构、英雄之旅等
2. **智能推荐**：基于用户历史偏好推荐策略
3. **协作编辑**：支持多人同时编辑设定
4. **版本控制**：设定的版本管理和回滚
5. **导出功能**：支持多种格式的设定导出