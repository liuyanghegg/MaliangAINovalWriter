package com.ainovel.server.dto.response;

import com.ainovel.server.domain.model.AIPromptPreset;
import lombok.Data;
import lombok.Builder;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * 功能预设列表响应
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PresetListResponse {
    
    /**
     * 收藏的预设列表（最多5个）
     */
    private List<PresetItemWithTag> favorites;
    
    /**
     * 最近使用的预设列表（最多5个）
     */
    private List<PresetItemWithTag> recentUsed;
    
    /**
     * 推荐的预设列表（补充用，最近创建的）
     */
    private List<PresetItemWithTag> recommended;
    
    /**
     * 带标签的预设项
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PresetItemWithTag {
        /**
         * 预设信息
         */
        private AIPromptPreset preset;
        
        /**
         * 是否收藏
         */
        private boolean isFavorite;
        
        /**
         * 是否最近使用
         */
        private boolean isRecentUsed;
        
        /**
         * 是否推荐项
         */
        private boolean isRecommended;
    }
}