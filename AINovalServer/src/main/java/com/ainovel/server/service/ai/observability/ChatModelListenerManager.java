package com.ainovel.server.service.ai.observability;

import dev.langchain4j.model.chat.listener.ChatModelListener;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

/**
 * ChatModel监听器管理器
 * 负责管理所有的ChatModelListener实例，支持动态扩展
 * 
 * 设计优势：
 * 1. 高扩展性：新增监听器只需创建Bean，无需修改现有代码
 * 2. 统一管理：所有监听器的注册和获取都在此处
 * 3. 易于测试：可以方便地mock或替换监听器
 * 4. 符合开闭原则：对扩展开放，对修改关闭
 */
@Slf4j
@Component
public class ChatModelListenerManager {

    private final List<ChatModelListener> listeners;

    /**
     * Spring会自动注入所有ChatModelListener类型的Bean
     * 这样当有新的监听器Bean被创建时，会自动被包含进来
     */
    @Autowired
    public ChatModelListenerManager(List<ChatModelListener> listeners) {
        this.listeners = new ArrayList<>(listeners); // 创建副本避免外部修改
        log.info("🚀 ChatModelListenerManager 初始化完成，共注册 {} 个监听器", listeners.size());
        
        // 打印所有注册的监听器
        for (int i = 0; i < listeners.size(); i++) {
            ChatModelListener listener = listeners.get(i);
            log.info("  [{}] 监听器: {}", i + 1, listener.getClass().getSimpleName());
        }
    }

    /**
     * 获取所有注册的监听器
     * @return 监听器列表的副本，确保线程安全
     */
    public List<ChatModelListener> getAllListeners() {
        return new ArrayList<>(listeners);
    }

    /**
     * 获取指定类型的监听器
     * @param listenerClass 监听器类型
     * @return 匹配的监听器列表
     */
    @SuppressWarnings("unchecked")
    public <T extends ChatModelListener> List<T> getListenersByType(Class<T> listenerClass) {
        return listeners.stream()
                .filter(listenerClass::isInstance)
                .map(listener -> (T) listener)
                .toList();
    }

    /**
     * 检查是否有指定类型的监听器
     * @param listenerClass 监听器类型
     * @return 是否存在该类型的监听器
     */
    public boolean hasListener(Class<? extends ChatModelListener> listenerClass) {
        return listeners.stream()
                .anyMatch(listenerClass::isInstance);
    }

    /**
     * 获取监听器数量
     * @return 监听器总数
     */
    public int getListenerCount() {
        return listeners.size();
    }

    /**
     * 获取监听器信息（用于调试和日志）
     * @return 监听器信息字符串
     */
    public String getListenerInfo() {
        if (listeners.isEmpty()) {
            return "无监听器注册";
        }
        
        StringBuilder info = new StringBuilder();
        info.append(String.format("共 %d 个监听器: ", listeners.size()));
        for (int i = 0; i < listeners.size(); i++) {
            if (i > 0) info.append(", ");
            info.append(listeners.get(i).getClass().getSimpleName());
        }
        return info.toString();
    }
}