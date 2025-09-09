package com.ainovel.server.domain.model;

/**
 * AI功能类型枚举 用于定义不同AI功能的类型标识
 */
public enum AIFeatureType {
    /**
     * 场景生成摘要
     */
    SCENE_TO_SUMMARY,
    /**
     * 摘要生成场景
     */
    SUMMARY_TO_SCENE,
    
    /**
     * 文本扩写功能
     */
    TEXT_EXPANSION,
    
    /**
     * 文本重构功能
     */
    TEXT_REFACTOR,
    
    /**
     * 文本缩写功能
     */
    TEXT_SUMMARY,
    
    /**
     * AI聊天对话功能
     */
    AI_CHAT,
    
    /**
     * 小说内容生成功能
     */
    NOVEL_GENERATION,
    
    /**
     * 专业续写小说功能
     */
    PROFESSIONAL_FICTION_CONTINUATION,
    
    /**
     * 场景节拍生成功能
     */
    SCENE_BEAT_GENERATION,
    
    /**
     * AI设定树生成功能
     */
    SETTING_TREE_GENERATION

    ,
    /**
     * 小说编排（大纲/章节/组合）
     */
    NOVEL_COMPOSE

    // 未来可扩展其他功能点，如角色生成、大纲优化等
}
