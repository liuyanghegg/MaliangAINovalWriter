package com.ainovel.server.task.transport;

import reactor.core.publisher.Mono;

/**
 * 任务传输层抽象。
 * 负责将已创建的任务分发到具体的执行通道（RabbitMQ 或本地内存队列）。
 */
public interface TaskTransport {

    /**
     * 分发任务到传输通道。
     *
     * @param taskId    任务ID
     * @param userId    用户ID
     * @param taskType  任务类型
     * @param parameters 任务参数
     * @return Mono<Void>
     */
    Mono<Void> dispatchTask(String taskId, String userId, String taskType, Object parameters);

    /**
     * 分发带有重试计数的任务（用于重试路径）。
     */
    default Mono<Void> dispatchTask(String taskId, String userId, String taskType, Object parameters, int retryCount) {
        // 默认实现忽略 retryCount，具体实现可覆盖
        return dispatchTask(taskId, userId, taskType, parameters);
    }

    /**
     * 分发一个延迟重试任务。
     *
     * @param delayMillis 延迟毫秒
     */
    default Mono<Void> dispatchDelayedRetryTask(String taskId, String userId, String taskType, Object parameters,
                                                int retryCount, long delayMillis) {
        // 默认无操作，由实现覆盖
        return Mono.empty();
    }
}


