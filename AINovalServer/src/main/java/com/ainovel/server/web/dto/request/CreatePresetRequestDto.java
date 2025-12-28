package com.ainovel.server.web.dto.request;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.List;

/**
 * 创建预设请求DTO
 */
@Data
public class CreatePresetRequestDto {

    /**
     * 预设名称
     */
    @NotBlank(message = "预设名称不能为空")
    @JsonProperty("presetName")
    private String presetName;

    /**
     * 预设描述
     */
    @JsonProperty("presetDescription")
    private String presetDescription;

    /**
     * 预设标签
     */
    @JsonProperty("presetTags")
    private List<String> presetTags;

    /**
     * AI请求配置
     */
    @NotNull(message = "请求配置不能为空")
    @Valid
    @JsonProperty("request")
    private UniversalAIRequestDto request;
} 