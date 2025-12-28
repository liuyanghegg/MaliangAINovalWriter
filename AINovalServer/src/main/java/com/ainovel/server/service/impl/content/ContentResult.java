package com.ainovel.server.service.impl.content;

/**
 * 内容结果类
 * 封装内容提供器返回的结果
 */
public class ContentResult {
    private final String content;
    private final String type;
    private final String id;

    public ContentResult(String content, String type, String id) {
        this.content = content;
        this.type = type;
        this.id = id;
    }

    public String getContent() { 
        return content; 
    }
    
    public String getType() { 
        return type; 
    }
    
    public String getId() { 
        return id; 
    }
} 