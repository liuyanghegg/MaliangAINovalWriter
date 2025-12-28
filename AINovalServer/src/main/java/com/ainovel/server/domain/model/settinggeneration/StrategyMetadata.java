package com.ainovel.server.domain.model.settinggeneration;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

/**
 * 策略元数据
 * 简化的策略元数据，专注于核心分类和标签信息
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StrategyMetadata {
    
    /**
     * 策略类别
     */
    @Builder.Default
    private List<String> categories = new ArrayList<>();
    
    /**
     * 策略标签
     */
    @Builder.Default
    private List<String> tags = new ArrayList<>();
    
    /**
     * 适用的小说类型
     */
    @Builder.Default
    private List<String> applicableGenres = new ArrayList<>();
    
    /**
     * 难度等级（1-5）
     */
    @Builder.Default
    private Integer difficultyLevel = 3;
    
    /**
     * 预估生成时间（分钟）
     */
    @Builder.Default
    private Integer estimatedGenerationTime = 10;
}