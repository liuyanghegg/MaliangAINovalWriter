package com.ainovel.server.web.dto.request;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

import jakarta.validation.constraints.NotBlank;
import java.util.List;

/**
 * 更新预设信息请求DTO
 */
@Data
public class UpdatePresetInfoRequest {

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
} 