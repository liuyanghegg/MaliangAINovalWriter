package com.ainovel.server.dto;

import com.ainovel.server.domain.model.AIPromptPreset;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * 预设包DTO - 用于聚合服务返回
 * 包含系统预设和用户预设的分类数据
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PresetPackage {

    /**
     * 系统预设列表
     */
    private List<AIPromptPreset> systemPresets;

    /**
     * 用户私有预设列表
     */
    private List<AIPromptPreset> userPresets;

    /**
     * 快捷访问预设列表（系统+用户）
     */
    private List<AIPromptPreset> quickAccessPresets;

    /**
     * 总预设数量
     */
    private int totalCount;

    /**
     * 功能类型
     */
    private String featureType;

    /**
     * 数据时间戳
     */
    private long timestamp;
}