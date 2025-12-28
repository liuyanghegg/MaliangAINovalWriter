package com.ainovel.server.web.dto;

import java.util.Map;

import lombok.Data;

@Data
public class SessionUpdateDto {

    private String userId;
    private String novelId;
    private String sessionId;
    private Map<String, Object> updates;
}
