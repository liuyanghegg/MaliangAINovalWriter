package com.ainovel.server.domain.model.analytics;

import java.time.LocalDateTime;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.index.CompoundIndexes;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 写作活动事件
 * 记录用户在场景内容上的编辑行为及字数变化，用于统计分析
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "writing_events")
@CompoundIndexes({
    @CompoundIndex(name = "user_time_idx", def = "{'userId': 1, 'timestamp': -1}"),
    @CompoundIndex(name = "novel_time_idx", def = "{'novelId': 1, 'timestamp': -1}"),
    @CompoundIndex(name = "scene_time_idx", def = "{'sceneId': 1, 'timestamp': -1}")
})
public class WritingEvent {

    @Id
    private String id;

    @Indexed
    private String userId;

    @Indexed
    private String novelId;

    @Indexed
    private String chapterId;

    @Indexed
    private String sceneId;

    /**
     * 编辑前字数
     */
    private Integer wordCountBefore;

    /**
     * 编辑后字数
     */
    private Integer wordCountAfter;

    /**
     * 本次变更字数（after - before）
     */
    private Integer deltaWords;

    /**
     * 编辑来源：MANUAL/AI
     */
    private String source;

    /**
     * 业务原因/备注
     */
    private String reason;

    /**
     * 事件时间
     */
    @Indexed
    private LocalDateTime timestamp;
}

