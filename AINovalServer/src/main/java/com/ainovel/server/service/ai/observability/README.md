# 大模型可观测性系统 (LLM Observability System)

## 概述

本系统为AI小说助手提供了完整的大模型调用监控和追踪功能，支持接入Langfuse等LLMOps工具，用于后台管理监控、调试和运维。

## 系统架构

### 混合方案设计
- **AOP切面**: 通用的`AIModelProviderTraceAspect`，拦截所有`AIModelProvider`的`generateContent`和`generateContentStream`方法
- **增强监听器**: 对于LangChain4j提供商，额外使用`RichTraceChatModelListener`获取详细信息
- **事件驱动**: 使用Spring事件机制异步处理追踪数据
- **响应式设计**: 充分利用WebFlux和虚拟线程，确保高性能

### 核心组件

#### 1. 数据模型 (`LLMTrace`)
- **完整的请求信息**: 消息、参数、工具调用、提供商特定参数
- **详细的响应信息**: 助手消息、Token使用情况、元数据、工具调用结果
- **性能指标**: 请求延迟、首Token延迟、总耗时
- **错误信息**: 完整的错误堆栈和分类

#### 2. AOP切面 (`AIModelProviderTraceAspect`)
- 拦截所有AI模型提供商的调用
- 自动创建追踪对象并注入Reactor Context
- 处理Mono（非流式）和Flux（流式）两种响应类型
- 记录性能指标和错误信息

#### 3. 增强监听器 (`RichTraceChatModelListener`)
- 仅用于LangChain4j提供商
- 从LangChain4j的详细上下文中提取更多信息
- 增强请求参数（topP、topK、工具规范等）
- 增强响应元数据（系统指纹、推理Token等）

#### 4. 事件处理 (`LLMTraceEventListener`)
- 异步监听追踪事件
- 使用虚拟线程处理IO操作
- 防止监控逻辑影响主业务流程

#### 5. 数据持久化 (`LLMTraceService` & `LLMTraceRepository`)
- 使用ReactiveMongoRepository进行非阻塞数据库操作
- 支持复杂查询和性能统计
- MongoDB索引优化

## 集成状态

### ✅ 已完成集成的提供商
- **AnthropicLangChain4jModelProvider** - Claude系列模型
- **GeminiLangChain4jModelProvider** - Google Gemini系列模型  
- **OpenAILangChain4jModelProvider** - OpenAI GPT系列模型
- **OpenRouterLangChain4jModelProvider** - OpenRouter聚合模型
- **SiliconFlowLangChain4jModelProvider** - 硅基流动模型
- **TogetherAILangChain4jModelProvider** - TogetherAI模型

### 🔄 自动兼容的提供商
- **GrokModelProvider** - 通过AOP自动监控，基础信息追踪
- **任何未来的AIModelProvider实现** - AOP自动提供基础监控

## 数据采集能力

### 🎯 完整覆盖的信息
- **请求信息**: 消息历史、温度、最大Token数、工具规范、提供商特定参数
- **响应信息**: 助手消息、工具调用结果、Token使用量、完成原因、提供商特定元数据
- **性能指标**: 请求延迟、首Token延迟（流式）、总耗时
- **错误信息**: 异常类型、错误消息、完整堆栈跟踪
- **业务上下文**: 用户ID、会话ID、小说ID、场景ID、关联ID

### 📊 OpenTelemetry兼容
系统设计遵循OpenTelemetry生成式AI语义约定，便于集成标准可观测性工具。

## 技术特性

### 🚀 高性能设计
- **非阻塞IO**: 使用WebFlux响应式编程
- **虚拟线程**: Java 21虚拟线程处理并发
- **异步事件**: 监控逻辑与业务逻辑完全解耦
- **内存安全**: 避免ThreadLocal，使用Reactor Context

### 🛡️ 可靠性保障
- **错误隔离**: 监控系统故障不影响业务
- **异常处理**: 完善的错误处理和降级机制
- **性能监控**: 监控系统本身的性能追踪

### 🔧 可扩展性
- **插件化设计**: 新增提供商自动获得基础监控
- **配置化**: 通过Spring配置控制监听器启用/禁用
- **模块化**: 各组件职责清晰，易于维护

## 配置说明

### 启用异步处理
```java
@EnableAsync
@EnableAspectJAutoProxy
public class Application {
    // ...
}
```

### 线程池配置
系统使用专用的虚拟线程池`llmTraceExecutor`处理追踪事件。

### MongoDB索引
系统会自动创建以下复合索引：
- `user_provider_model_idx`: 用户、提供商、模型查询
- `session_timestamp_idx`: 会话和时间范围查询  
- `provider_model_performance_idx`: 性能分析查询

## 数据查询示例

### 基础查询
```java
// 查询用户的调用记录
Flux<LLMTrace> traces = traceService.findByUserId("user123", 0, 20);

// 查询会话的所有调用
Flux<LLMTrace> sessionTraces = traceService.findBySessionId("session456");

// 性能统计
Mono<PerformanceStats> stats = traceService.getPerformanceStats("openai", "gpt-4", startTime, endTime);
```

### MongoDB原生查询
```javascript
// 查询高耗时调用
db.llm_traces.find({"performance.totalDurationMs": {$gt: 5000}})

// 查询工具调用记录
db.llm_traces.find({"response.message.toolCalls": {$exists: true, $ne: []}})

// 错误统计
db.llm_traces.aggregate([
  {$match: {"error": {$ne: null}}},
  {$group: {_id: "$error.type", count: {$sum: 1}}}
])
```

## 接入Langfuse

系统设计充分考虑了Langfuse等LLMOps工具的接入需求：

1. **数据格式兼容**: 追踪数据结构遵循行业标准
2. **事件流**: 可通过监听`LLMTraceEvent`将数据推送到Langfuse
3. **链路追踪**: 支持`traceId`和`correlationId`进行调用链关联

## 注意事项

### 内存管理
- 系统完全避免使用ThreadLocal，防止内存泄漏
- 使用Reactor Context传递追踪数据，范围受限且自动清理

### 性能影响
- 监控逻辑异步执行，不影响业务响应时间
- MongoDB写操作批量化，减少数据库压力
- 合理的索引设计，确保查询性能

### 数据保留
建议根据业务需求配置数据保留策略，定期清理历史数据以控制存储成本。

## 未来扩展

### 可能的增强功能
- **实时仪表板**: 基于追踪数据的实时监控面板
- **智能告警**: 基于性能和错误率的自动告警
- **成本优化**: 基于Token使用情况的成本分析和优化建议
- **A/B测试**: 支持模型和参数的对比测试

### 集成计划
- **Prometheus指标**: 导出关键指标到Prometheus
- **Grafana仪表板**: 预配置的监控仪表板
- **ELK Stack**: 日志聚合和分析
- **OpenTelemetry**: 完整的分布式追踪集成