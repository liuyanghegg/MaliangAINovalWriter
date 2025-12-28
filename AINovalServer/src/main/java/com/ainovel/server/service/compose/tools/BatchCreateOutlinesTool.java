package com.ainovel.server.service.compose.tools;

import com.ainovel.server.service.ai.tools.ToolDefinition;
import dev.langchain4j.agent.tool.ToolSpecification;
import dev.langchain4j.model.chat.request.json.JsonArraySchema;
import dev.langchain4j.model.chat.request.json.JsonIntegerSchema;
import dev.langchain4j.model.chat.request.json.JsonObjectSchema;
import dev.langchain4j.model.chat.request.json.JsonStringSchema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 批量创建“黄金三章”章节大纲工具
 * 允许一次性创建多个大纲条目，包含标题与简要摘要，避免服务端对自然语言进行解析。
 */
@Slf4j
public class BatchCreateOutlinesTool implements ToolDefinition {


    public interface OutlineHandler {
        boolean handleOutlines(List<OutlineItem> outlines);
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class OutlineItem {
        private Integer index;
        private String title;
        private String summary;
    }

    private final OutlineHandler handler;
    private final com.fasterxml.jackson.databind.ObjectMapper objectMapper;

    public BatchCreateOutlinesTool(com.fasterxml.jackson.databind.ObjectMapper objectMapper, OutlineHandler handler) {
        this.handler = handler;
        this.objectMapper = objectMapper != null ? objectMapper : new com.fasterxml.jackson.databind.ObjectMapper();
    }

    @Override
    public String getName() {
        return "create_compose_outlines";
    }

    @Override
    public String getDescription() {
        return "批量创建章节大纲条目。每个条目包含 index、title、summary。用于黄金三章等大纲阶段，避免输出自由文本。";
    }

    @Override
    public ToolSpecification getSpecification() {
        JsonObjectSchema outlineSchema = JsonObjectSchema.builder()
            .addProperty("index", JsonIntegerSchema.builder().description("章节序号，从1开始。若缺省，服务端将按顺序补齐").build())
            .addProperty("title", JsonStringSchema.builder().description("章节标题").build())
            .addProperty("summary", JsonStringSchema.builder().description("章节概要/小结，建议100-200字").build())
            .required("title", "summary")
            .build();

        JsonObjectSchema parameters = JsonObjectSchema.builder()
            .addProperty("outlines", JsonArraySchema.builder()
                .items(outlineSchema)
                .description("要创建的大纲列表，建议按chapterCount一次性返回全部大纲")
                .build())
            .required("outlines")
            .build();

        return ToolSpecification.builder()
            .name(getName())
            .description(getDescription())
            .parameters(parameters)
            .build();
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Input {
        private List<OutlineItem> outlines;
    }

    @Override
    @SuppressWarnings("unchecked")
    public Object execute(Map<String, Object> parameters) {
        Input input;
        try {
            input = objectMapper.convertValue(parameters, Input.class);
        } catch (IllegalArgumentException e) {
            log.warn("Failed to bind parameters to Input class, fallback to map parsing. Error: {}", e.getMessage());
            input = new Input();
            Object outlinesObj = parameters.get("outlines");
            if (outlinesObj instanceof List<?> list) {
                List<OutlineItem> tmp = new ArrayList<>();
                int autoIndex = 1;
                for (Object o : list) {
                    if (o instanceof Map<?, ?> m) {
                        try {
                            Integer idx = null;
                            Object idxObj = m.get("index");
                            if (idxObj instanceof Number) idx = ((Number) idxObj).intValue();
                            else if (idxObj instanceof String s) { try { idx = Integer.parseInt(s.trim()); } catch (Exception ignore) {} }
                            if (idx == null) idx = autoIndex;
                            String title = (String) m.get("title");
                            String summary = (String) m.get("summary");
                            if (title == null) title = "第" + idx + "章";
                            if (summary == null) summary = "";
                            tmp.add(OutlineItem.builder().index(idx).title(title).summary(summary).build());
                            autoIndex = Math.max(autoIndex, idx + 1);
                        } catch (Exception ex) {
                            log.warn("Failed to parse outline map: {}", ex.getMessage());
                        }
                    }
                }
                input.setOutlines(tmp);
            }
        }

        List<OutlineItem> items = input != null ? input.getOutlines() : null;
        if (items == null || items.isEmpty()) {
            Map<String, Object> res = new HashMap<>();
            res.put("success", false);
            res.put("message", "No outlines provided");
            return res;
        }

        boolean ok = false;
        try {
            ok = handler != null && handler.handleOutlines(items);
        } catch (Exception e) {
            log.error("Outline handler failed: {}", e.getMessage(), e);
        }

        Map<String, Object> res = new HashMap<>();
        res.put("success", ok);
        res.put("count", items.size());
        res.put("indexes", items.stream().map(OutlineItem::getIndex).toList());
        return res;
    }
}


