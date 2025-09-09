package com.ainovel.server.service;

import com.ainovel.server.domain.model.UserEditorSettings;
import com.ainovel.server.repository.UserEditorSettingsRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;

/**
 * 用户编辑器设置服务
 */
@Service
public class UserEditorSettingsService {
    
    private static final Logger logger = LoggerFactory.getLogger(UserEditorSettingsService.class);
    
    @Autowired
    private UserEditorSettingsRepository userEditorSettingsRepository;
    
    /**
     * 获取用户编辑器设置，如果不存在则返回默认设置
     * @param userId 用户ID
     * @return 用户编辑器设置
     */
    public Mono<UserEditorSettings> getUserEditorSettings(String userId) {
        logger.debug("获取用户编辑器设置: {}", userId);
        
        return userEditorSettingsRepository.findByUserId(userId)
                .switchIfEmpty(createDefaultSettings(userId))
                .doOnNext(settings -> logger.debug("找到用户编辑器设置: {}", settings.getId()))
                .doOnError(error -> logger.error("获取用户编辑器设置失败: {}", error.getMessage()));
    }
    
    /**
     * 保存用户编辑器设置
     * @param settings 编辑器设置
     * @return 保存后的设置
     */
    public Mono<UserEditorSettings> saveUserEditorSettings(UserEditorSettings settings) {
        logger.debug("保存用户编辑器设置: {}", settings.getUserId());
        
        settings.setUpdatedAt(LocalDateTime.now());
        
        return userEditorSettingsRepository.save(settings)
                .doOnNext(saved -> logger.debug("保存用户编辑器设置成功: {}", saved.getId()))
                .doOnError(error -> logger.error("保存用户编辑器设置失败: {}", error.getMessage()));
    }
    
    /**
     * 更新用户编辑器设置
     * @param userId 用户ID
     * @param newSettings 新的设置数据
     * @return 更新后的设置
     */
    public Mono<UserEditorSettings> updateUserEditorSettings(String userId, UserEditorSettings newSettings) {
        logger.debug("更新用户编辑器设置: {}", userId);
        
        return userEditorSettingsRepository.findByUserId(userId)
                .switchIfEmpty(createDefaultSettings(userId))
                .map(existingSettings -> {
                    // 更新所有字段
                    updateSettingsFields(existingSettings, newSettings);
                    existingSettings.setUpdatedAt(LocalDateTime.now());
                    return existingSettings;
                })
                .flatMap(userEditorSettingsRepository::save)
                .doOnNext(saved -> logger.debug("更新用户编辑器设置成功: {}", saved.getId()))
                .doOnError(error -> logger.error("更新用户编辑器设置失败: {}", error.getMessage()));
    }
    
    /**
     * 删除用户编辑器设置
     * @param userId 用户ID
     * @return 删除结果
     */
    public Mono<Void> deleteUserEditorSettings(String userId) {
        logger.debug("删除用户编辑器设置: {}", userId);
        
        return userEditorSettingsRepository.deleteByUserId(userId)
                .doOnSuccess(result -> logger.debug("删除用户编辑器设置成功: {}", userId))
                .doOnError(error -> logger.error("删除用户编辑器设置失败: {}", error.getMessage()));
    }
    
    /**
     * 创建默认设置
     * @param userId 用户ID
     * @return 默认设置
     */
    private Mono<UserEditorSettings> createDefaultSettings(String userId) {
        logger.debug("为用户创建默认编辑器设置: {}", userId);
        
        UserEditorSettings defaultSettings = new UserEditorSettings(userId);
        return userEditorSettingsRepository.save(defaultSettings);
    }
    
    /**
     * 更新设置字段
     * @param existing 现有设置
     * @param newSettings 新设置
     */
    private void updateSettingsFields(UserEditorSettings existing, UserEditorSettings newSettings) {
        // 字体相关设置
        if (newSettings.getFontSize() != null) {
            existing.setFontSize(newSettings.getFontSize());
        }
        if (newSettings.getFontFamily() != null) {
            existing.setFontFamily(newSettings.getFontFamily());
        }
        if (newSettings.getFontWeight() != null) {
            existing.setFontWeight(newSettings.getFontWeight());
        }
        if (newSettings.getLineSpacing() != null) {
            existing.setLineSpacing(newSettings.getLineSpacing());
        }
        if (newSettings.getLetterSpacing() != null) {
            existing.setLetterSpacing(newSettings.getLetterSpacing());
        }
        
        // 间距和布局设置
        if (newSettings.getPaddingHorizontal() != null) {
            existing.setPaddingHorizontal(newSettings.getPaddingHorizontal());
        }
        if (newSettings.getPaddingVertical() != null) {
            existing.setPaddingVertical(newSettings.getPaddingVertical());
        }
        if (newSettings.getParagraphSpacing() != null) {
            existing.setParagraphSpacing(newSettings.getParagraphSpacing());
        }
        if (newSettings.getIndentSize() != null) {
            existing.setIndentSize(newSettings.getIndentSize());
        }
        if (newSettings.getMaxLineWidth() != null) {
            existing.setMaxLineWidth(newSettings.getMaxLineWidth());
        }
        if (newSettings.getMinEditorHeight() != null) {
            existing.setMinEditorHeight(newSettings.getMinEditorHeight());
        }
        
        // 编辑器行为设置
        if (newSettings.getAutoSaveEnabled() != null) {
            existing.setAutoSaveEnabled(newSettings.getAutoSaveEnabled());
        }
        if (newSettings.getAutoSaveIntervalMinutes() != null) {
            existing.setAutoSaveIntervalMinutes(newSettings.getAutoSaveIntervalMinutes());
        }
        if (newSettings.getSpellCheckEnabled() != null) {
            existing.setSpellCheckEnabled(newSettings.getSpellCheckEnabled());
        }
        if (newSettings.getShowWordCount() != null) {
            existing.setShowWordCount(newSettings.getShowWordCount());
        }
        if (newSettings.getShowLineNumbers() != null) {
            existing.setShowLineNumbers(newSettings.getShowLineNumbers());
        }
        if (newSettings.getHighlightActiveLine() != null) {
            existing.setHighlightActiveLine(newSettings.getHighlightActiveLine());
        }
        if (newSettings.getUseTypewriterMode() != null) {
            existing.setUseTypewriterMode(newSettings.getUseTypewriterMode());
        }
        
        // 主题和外观设置
        if (newSettings.getDarkModeEnabled() != null) {
            existing.setDarkModeEnabled(newSettings.getDarkModeEnabled());
        }
        if (newSettings.getShowMiniMap() != null) {
            existing.setShowMiniMap(newSettings.getShowMiniMap());
        }
        if (newSettings.getSmoothScrolling() != null) {
            existing.setSmoothScrolling(newSettings.getSmoothScrolling());
        }
        if (newSettings.getFadeInAnimation() != null) {
            existing.setFadeInAnimation(newSettings.getFadeInAnimation());
        }
        if (newSettings.getThemeVariant() != null) {
            existing.setThemeVariant(newSettings.getThemeVariant());
        }
        
        // 文本选择和光标设置
        if (newSettings.getCursorBlinkRate() != null) {
            existing.setCursorBlinkRate(newSettings.getCursorBlinkRate());
        }
        if (newSettings.getSelectionHighlightColor() != null) {
            existing.setSelectionHighlightColor(newSettings.getSelectionHighlightColor());
        }
        if (newSettings.getEnableVimMode() != null) {
            existing.setEnableVimMode(newSettings.getEnableVimMode());
        }
        
        // 导出和打印设置
        if (newSettings.getDefaultExportFormat() != null) {
            existing.setDefaultExportFormat(newSettings.getDefaultExportFormat());
        }
        if (newSettings.getIncludeMetadata() != null) {
            existing.setIncludeMetadata(newSettings.getIncludeMetadata());
        }
    }
} 