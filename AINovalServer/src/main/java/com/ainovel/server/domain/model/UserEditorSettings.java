package com.ainovel.server.domain.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.index.Indexed;

import java.time.LocalDateTime;

/**
 * 用户编辑器设置实体
 * 存储用户的个性化编辑器配置
 */
@Document(collection = "user_editor_settings")
public class UserEditorSettings {
    
    @Id
    private String id;
    
    @Indexed
    private String userId;
    
    // 字体相关设置
    private Double fontSize = 16.0;
    private String fontFamily = "Roboto";
    private String fontWeight = "normal"; // normal, bold, w300, w400, w500, w600, w700
    private Double lineSpacing = 1.5;
    private Double letterSpacing = 0.0;
    
    // 间距和布局设置
    private Double paddingHorizontal = 16.0;
    private Double paddingVertical = 12.0;
    private Double paragraphSpacing = 8.0;
    private Double indentSize = 32.0;
    private Double maxLineWidth = 800.0;
    private Double minEditorHeight = 150.0;
    
    // 编辑器行为设置
    private Boolean autoSaveEnabled = true;
    private Integer autoSaveIntervalMinutes = 5;
    private Boolean spellCheckEnabled = true;
    private Boolean showWordCount = true;
    private Boolean showLineNumbers = false;
    private Boolean highlightActiveLine = true;
    private Boolean useTypewriterMode = false;
    
    // 主题和外观设置
    private Boolean darkModeEnabled = false;
    private Boolean showMiniMap = false;
    private Boolean smoothScrolling = true;
    private Boolean fadeInAnimation = true;
    // 主题变体（与前端 WebTheme 保持一致：monochrome | blueWhite | pinkWhite | paperWhite）
    private String themeVariant = "monochrome";
    
    // 文本选择和光标设置
    private Double cursorBlinkRate = 1.0;
    private String selectionHighlightColor = "#2196F3";
    private Boolean enableVimMode = false;
    
    // 导出和打印设置
    private String defaultExportFormat = "markdown";
    private Boolean includeMetadata = true;
    
    // 时间戳
    private LocalDateTime createdAt = LocalDateTime.now();
    private LocalDateTime updatedAt = LocalDateTime.now();
    
    // 构造函数
    public UserEditorSettings() {}
    
    public UserEditorSettings(String userId) {
        this.userId = userId;
    }
    
    // Getters and Setters
    public String getId() {
        return id;
    }
    
    public void setId(String id) {
        this.id = id;
    }
    
    public String getUserId() {
        return userId;
    }
    
    public void setUserId(String userId) {
        this.userId = userId;
    }
    
    public Double getFontSize() {
        return fontSize;
    }
    
    public void setFontSize(Double fontSize) {
        this.fontSize = fontSize;
    }
    
    public String getFontFamily() {
        return fontFamily;
    }
    
    public void setFontFamily(String fontFamily) {
        this.fontFamily = fontFamily;
    }
    
    public String getFontWeight() {
        return fontWeight;
    }
    
    public void setFontWeight(String fontWeight) {
        this.fontWeight = fontWeight;
    }
    
    public Double getLineSpacing() {
        return lineSpacing;
    }
    
    public void setLineSpacing(Double lineSpacing) {
        this.lineSpacing = lineSpacing;
    }
    
    public Double getLetterSpacing() {
        return letterSpacing;
    }
    
    public void setLetterSpacing(Double letterSpacing) {
        this.letterSpacing = letterSpacing;
    }
    
    public Double getPaddingHorizontal() {
        return paddingHorizontal;
    }
    
    public void setPaddingHorizontal(Double paddingHorizontal) {
        this.paddingHorizontal = paddingHorizontal;
    }
    
    public Double getPaddingVertical() {
        return paddingVertical;
    }
    
    public void setPaddingVertical(Double paddingVertical) {
        this.paddingVertical = paddingVertical;
    }
    
    public Double getParagraphSpacing() {
        return paragraphSpacing;
    }
    
    public void setParagraphSpacing(Double paragraphSpacing) {
        this.paragraphSpacing = paragraphSpacing;
    }
    
    public Double getIndentSize() {
        return indentSize;
    }
    
    public void setIndentSize(Double indentSize) {
        this.indentSize = indentSize;
    }
    
    public Double getMaxLineWidth() {
        return maxLineWidth;
    }
    
    public void setMaxLineWidth(Double maxLineWidth) {
        this.maxLineWidth = maxLineWidth;
    }
    
    public Double getMinEditorHeight() {
        return minEditorHeight;
    }
    
    public void setMinEditorHeight(Double minEditorHeight) {
        this.minEditorHeight = minEditorHeight;
    }
    
    public Boolean getAutoSaveEnabled() {
        return autoSaveEnabled;
    }
    
    public void setAutoSaveEnabled(Boolean autoSaveEnabled) {
        this.autoSaveEnabled = autoSaveEnabled;
    }
    
    public Integer getAutoSaveIntervalMinutes() {
        return autoSaveIntervalMinutes;
    }
    
    public void setAutoSaveIntervalMinutes(Integer autoSaveIntervalMinutes) {
        this.autoSaveIntervalMinutes = autoSaveIntervalMinutes;
    }
    
    public Boolean getSpellCheckEnabled() {
        return spellCheckEnabled;
    }
    
    public void setSpellCheckEnabled(Boolean spellCheckEnabled) {
        this.spellCheckEnabled = spellCheckEnabled;
    }
    
    public Boolean getShowWordCount() {
        return showWordCount;
    }
    
    public void setShowWordCount(Boolean showWordCount) {
        this.showWordCount = showWordCount;
    }
    
    public Boolean getShowLineNumbers() {
        return showLineNumbers;
    }
    
    public void setShowLineNumbers(Boolean showLineNumbers) {
        this.showLineNumbers = showLineNumbers;
    }
    
    public Boolean getHighlightActiveLine() {
        return highlightActiveLine;
    }
    
    public void setHighlightActiveLine(Boolean highlightActiveLine) {
        this.highlightActiveLine = highlightActiveLine;
    }
    
    public Boolean getUseTypewriterMode() {
        return useTypewriterMode;
    }
    
    public void setUseTypewriterMode(Boolean useTypewriterMode) {
        this.useTypewriterMode = useTypewriterMode;
    }
    
    public Boolean getDarkModeEnabled() {
        return darkModeEnabled;
    }
    
    public void setDarkModeEnabled(Boolean darkModeEnabled) {
        this.darkModeEnabled = darkModeEnabled;
    }
    
    public Boolean getShowMiniMap() {
        return showMiniMap;
    }
    
    public void setShowMiniMap(Boolean showMiniMap) {
        this.showMiniMap = showMiniMap;
    }
    
    public Boolean getSmoothScrolling() {
        return smoothScrolling;
    }
    
    public void setSmoothScrolling(Boolean smoothScrolling) {
        this.smoothScrolling = smoothScrolling;
    }
    
    public Boolean getFadeInAnimation() {
        return fadeInAnimation;
    }
    
    public void setFadeInAnimation(Boolean fadeInAnimation) {
        this.fadeInAnimation = fadeInAnimation;
    }
    
    public String getThemeVariant() {
        return themeVariant;
    }
    
    public void setThemeVariant(String themeVariant) {
        this.themeVariant = themeVariant;
    }
    
    public Double getCursorBlinkRate() {
        return cursorBlinkRate;
    }
    
    public void setCursorBlinkRate(Double cursorBlinkRate) {
        this.cursorBlinkRate = cursorBlinkRate;
    }
    
    public String getSelectionHighlightColor() {
        return selectionHighlightColor;
    }
    
    public void setSelectionHighlightColor(String selectionHighlightColor) {
        this.selectionHighlightColor = selectionHighlightColor;
    }
    
    public Boolean getEnableVimMode() {
        return enableVimMode;
    }
    
    public void setEnableVimMode(Boolean enableVimMode) {
        this.enableVimMode = enableVimMode;
    }
    
    public String getDefaultExportFormat() {
        return defaultExportFormat;
    }
    
    public void setDefaultExportFormat(String defaultExportFormat) {
        this.defaultExportFormat = defaultExportFormat;
    }
    
    public Boolean getIncludeMetadata() {
        return includeMetadata;
    }
    
    public void setIncludeMetadata(Boolean includeMetadata) {
        this.includeMetadata = includeMetadata;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    
    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }
    
    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
} 