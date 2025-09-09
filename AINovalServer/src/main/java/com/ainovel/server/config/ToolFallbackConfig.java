package com.ainovel.server.config;

import com.ainovel.server.service.ai.tools.fallback.ToolFallbackParser;
import com.ainovel.server.service.ai.tools.fallback.ToolFallbackRegistry;
import com.ainovel.server.service.ai.tools.fallback.impl.DefaultToolFallbackRegistry;
import com.ainovel.server.service.ai.tools.fallback.impl.CreateComposeOutlinesJsonFallbackParser;
import com.ainovel.server.service.ai.tools.fallback.impl.TextToSettingsJsonFallbackParser;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Configuration
public class ToolFallbackConfig {

    @Bean
    public ToolFallbackParser textToSettingsJsonFallbackParser() {
        return new TextToSettingsJsonFallbackParser();
    }
    
    @Bean
    public ToolFallbackParser createComposeOutlinesJsonFallbackParser() {
        return new CreateComposeOutlinesJsonFallbackParser();
    }

    @Bean
    public ToolFallbackRegistry toolFallbackRegistry(List<ToolFallbackParser> parsers) {
        return new DefaultToolFallbackRegistry(parsers);
    }
}


