package com.ainovel.server.repository;

import com.ainovel.server.domain.model.UserEditorSettings;
import org.springframework.data.mongodb.repository.ReactiveMongoRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Mono;

/**
 * 用户编辑器设置仓库接口
 */
@Repository
public interface UserEditorSettingsRepository extends ReactiveMongoRepository<UserEditorSettings, String> {
    
    /**
     * 根据用户ID查找编辑器设置
     * @param userId 用户ID
     * @return 用户编辑器设置
     */
    Mono<UserEditorSettings> findByUserId(String userId);
    
    /**
     * 根据用户ID删除编辑器设置
     * @param userId 用户ID
     * @return 删除结果
     */
    Mono<Void> deleteByUserId(String userId);
} 