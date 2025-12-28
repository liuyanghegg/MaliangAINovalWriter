package com.ainovel.server.service.setting;

import com.ainovel.server.domain.model.NovelSettingGenerationHistory;
import com.ainovel.server.domain.model.NovelSettingItem;
import com.ainovel.server.domain.model.NovelSettingItemHistory;
import com.ainovel.server.domain.model.setting.generation.SettingGenerationSession;
import com.ainovel.server.domain.model.setting.generation.SettingNode;
import org.springframework.data.domain.Pageable;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.List;

/**
 * 设定历史记录服务接口
 */
public interface NovelSettingHistoryService {

    // ==================== 历史记录管理 ====================

    /**
     * 从完成的会话创建历史记录
     * 
     * @param session 完成的设定生成会话
     * @param settingItemIds 生成的设定条目ID列表
     * @return 创建的历史记录
     */
    Mono<NovelSettingGenerationHistory> createHistoryFromSession(SettingGenerationSession session, 
                                                                List<String> settingItemIds);

    /**
     * 更新现有历史记录
     * 使用当前会话的数据更新指定的历史记录，不创建新的历史记录
     * 
     * @param session 当前的设定生成会话
     * @param settingItemIds 生成的设定条目ID列表
     * @param targetHistoryId 要更新的历史记录ID
     * @return 更新后的历史记录
     */
    Mono<NovelSettingGenerationHistory> updateHistoryFromSession(SettingGenerationSession session, 
                                                                List<String> settingItemIds,
                                                                String targetHistoryId);

    /**
     * 从会话ID创建历史记录
     * 
     * @param sessionId 会话ID
     * @param userId 用户ID
     * @param reason 创建原因
     * @return 创建的历史记录
     */
    Mono<NovelSettingGenerationHistory> createHistoryFromSession(String sessionId, String userId, String reason);

    /**
     * 获取小说的历史记录列表
     * 
     * @param novelId 小说ID
     * @param userId 用户ID
     * @param pageable 分页参数
     * @return 历史记录列表
     */
    Flux<NovelSettingGenerationHistory> getNovelHistories(String novelId, String userId, Pageable pageable);

    /**
     * 获取用户的历史记录列表
     * 
     * @param userId 用户ID
     * @param novelId 小说ID过滤（可选）
     * @param pageable 分页参数
     * @return 历史记录列表
     */
    Flux<NovelSettingGenerationHistory> getUserHistories(String userId, String novelId, Pageable pageable);

    /**
     * 根据ID获取历史记录详情
     * 
     * @param historyId 历史记录ID
     * @return 历史记录详情
     */
    Mono<NovelSettingGenerationHistory> getHistoryById(String historyId);
    
    /**
     * 获取历史记录中的完整设定数据
     * 
     * @param historyId 历史记录ID
     * @return 历史记录和对应的设定条目列表
     */
    Mono<HistoryWithSettings> getHistoryWithSettings(String historyId);

    /**
     * 删除历史记录
     * 
     * @param historyId 历史记录ID
     * @param userId 用户ID（权限验证）
     * @return 删除结果
     */
    Mono<Void> deleteHistory(String historyId, String userId);

    /**
     * 批量删除历史记录
     * 
     * @param historyIds 历史记录ID列表
     * @param userId 用户ID（权限验证）
     * @return 删除的数量
     */
    Mono<Integer> batchDeleteHistories(List<String> historyIds, String userId);

    // ==================== 历史记录操作 ====================

    /**
     * 从历史记录创建新的编辑会话
     * 
     * @param historyId 历史记录ID
     * @param newPrompt 新的提示词（可选，用于说明本次编辑目的）
     * @return 新创建的会话
     */
    Mono<SettingGenerationSession> createSessionFromHistory(String historyId, String newPrompt);

    /**
     * 复制历史记录（创建基于现有历史记录的新历史记录）
     * 
     * @param sourceHistoryId 源历史记录ID
     * @param copyReason 复制原因说明
     * @param userId 用户ID
     * @return 新的历史记录
     */
    Mono<NovelSettingGenerationHistory> copyHistory(String sourceHistoryId, String copyReason, String userId);

    /**
     * 将历史记录恢复到小说的设定中
     * 
     * @param historyId 历史记录ID
     * @param userId 用户ID（权限验证）
     * @return 恢复的设定条目ID列表
     */
    Mono<List<String>> restoreHistoryToNovel(String historyId, String userId);

    /**
     * 将历史记录恢复到指定小说的设定中
     * 
     * @param historyId 历史记录ID
     * @param novelId 目标小说ID
     * @param userId 用户ID（权限验证）
     * @return 恢复的设定条目ID列表
     */
    Mono<List<String>> restoreHistoryToNovel(String historyId, String novelId, String userId);

    /**
     * 直接复制历史记录中的设定条目到目标小说（不经 SettingNode 转换）。
     * - 使用历史记录中的 generatedSettingIds、rootSettingIds 与 parentChildMap
     * - 为每个设定条目创建全新副本（新ID、时间戳、novelId=userId），保留名称/描述/属性等
     * - 根据 parentChildMap 重新建立父子关系
     * - 忽略历史记录中的 novelId，历史仅提供设定树信息
     *
     * @param historyId 历史记录ID
     * @param novelId 目标小说ID
     * @param userId 操作用户ID（权限验证）
     * @return 新创建的设定条目ID列表
     */
    Mono<List<String>> copyHistoryItemsToNovel(String historyId, String novelId, String userId);

    // ==================== 节点历史记录 ====================

    /**
     * 记录节点变更历史
     * 
     * @param settingItemId 设定条目ID
     * @param historyId 所属历史记录ID
     * @param operationType 操作类型
     * @param beforeContent 变更前内容
     * @param afterContent 变更后内容
     * @param changeDescription 变更描述
     * @param userId 用户ID
     * @return 节点历史记录
     */
    Mono<NovelSettingItemHistory> recordNodeChange(String settingItemId, String historyId, 
                                                  String operationType, NovelSettingItem beforeContent, 
                                                  NovelSettingItem afterContent, String changeDescription,
                                                  String userId);

    /**
     * 获取节点的历史记录
     * 
     * @param settingItemId 设定条目ID
     * @param pageable 分页参数
     * @return 节点历史记录列表
     */
    Flux<NovelSettingItemHistory> getNodeHistories(String settingItemId, Pageable pageable);

    /**
     * 获取历史记录中所有节点的变更历史
     * 
     * @param historyId 历史记录ID
     * @return 节点历史记录列表
     */
    Flux<NovelSettingItemHistory> getHistoryNodeChanges(String historyId);

    // ==================== 统计和搜索 ====================

    /**
     * 统计用户的历史记录数量
     * 
     * @param userId 用户ID
     * @param novelId 小说ID过滤（可选）
     * @return 历史记录数量
     */
    Mono<Long> countUserHistories(String userId, String novelId);

    /**
     * 生成历史记录标题
     * 
     * @param initialPrompt 初始提示词
     * @param strategy 生成策略
     * @param settingsCount 设定数量
     * @return 生成的标题
     */
    String generateHistoryTitle(String initialPrompt, String strategy, Integer settingsCount);
     
    /**
     * 历史记录与设定数据的组合类
     */
    record HistoryWithSettings(
        NovelSettingGenerationHistory history,
        List<SettingNode> rootNodes
    ) {}
} 