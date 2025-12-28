package com.ainovel.server.service.setting;

import com.ainovel.server.domain.model.NovelSettingItem;
import com.ainovel.server.domain.model.SettingType;
import com.ainovel.server.domain.model.setting.generation.SettingGenerationSession;
import com.ainovel.server.domain.model.setting.generation.SettingNode;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 设定转换服务
 * 负责 SettingNode 和 NovelSettingItem 之间的双向转换
 */
@Slf4j
@Service
public class SettingConversionService {

    /**
     * 将会话中的 SettingNode 转换为 NovelSettingItem 列表
     * 用于保存生成结果到数据库
     * 
     * @param session 设定生成会话
     * @param novelId 小说ID
     * @return 转换后的设定条目列表
     */
    public List<NovelSettingItem> convertSessionToSettingItems(SettingGenerationSession session, String novelId) {
        log.info("开始转换会话 {} 中的设定节点为设定条目，共 {} 个节点", 
                session.getSessionId(), session.getGeneratedNodes().size());

        List<NovelSettingItem> items = session.getGeneratedNodes().values().stream()
                .map(node -> convertNodeToSettingItem(node, novelId, session.getUserId()))
                .collect(Collectors.toList());

        // 更新子节点列表
        updateChildrenIds(items);

        log.info("成功转换 {} 个设定节点为设定条目", items.size());
        return items;
    }


    /**
     * 将单个 SettingNode 转换为 NovelSettingItem
     * 
     * @param node 设定节点
     * @param novelId 小说ID
     * @param userId 用户ID
     * @return 转换后的设定条目
     */
    public NovelSettingItem convertNodeToSettingItem(SettingNode node, String novelId, String userId) {
        return NovelSettingItem.builder()
                // 直接复用 SettingNode 的 UUID 作为持久化 ID
                .id(node.getId())
                .novelId(novelId)
                .userId(userId)
                .name(node.getName())
                .type(node.getType().getValue())
                .description(node.getDescription())
                // 直接复用父节点的 UUID
                .parentId(node.getParentId())
                
                // 转换属性映射
                .attributes(convertObjectMapToStringMap(node.getAttributes()))
                
                // 补全 NovelSettingItem 中独有的字段
                .priority(5) // 设置默认优先级
                .generatedBy("AI_SETTING_GENERATION")
                .status("active")
                .isAiSuggestion(false)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .tags(new ArrayList<>())
                .sceneIds(new ArrayList<>())
                .relationships(new ArrayList<>())
                .metadata(new HashMap<>())
                .nameAliasTracking("track")
                .aiContextTracking("detected")
                .referenceUpdatePolicy("ask")
                .childrenIds(new ArrayList<>())
                .build();
    }

    /**
     * 将 NovelSettingItem 列表转换为 SettingNode 列表
     * 用于从历史记录加载设定到新会话中进行编辑
     * 
     * @param items 设定条目列表
     * @return 转换后的设定节点列表
     */
    public List<SettingNode> convertSettingItemsToNodes(List<NovelSettingItem> items) {
        log.info("开始转换 {} 个设定条目为设定节点", items.size());

        List<SettingNode> nodes = items.stream()
                .map(this::convertSettingItemToNode)
                .collect(Collectors.toList());

        log.info("成功转换 {} 个设定条目为设定节点", nodes.size());
        return nodes;
    }

    /**
     * 将单个 NovelSettingItem 转换为 SettingNode
     * 
     * @param item 设定条目
     * @return 转换后的设定节点
     */
    public SettingNode convertSettingItemToNode(NovelSettingItem item) {
        return SettingNode.builder()
                // 直接使用 NovelSettingItem 的 ID
                .id(item.getId())
                .parentId(item.getParentId())
                .name(item.getName())
                .type(SettingType.fromValue(item.getType()))
                .description(item.getDescription())
                .attributes(convertStringMapToObjectMap(item.getAttributes()))
                .generationStatus(SettingNode.GenerationStatus.COMPLETED)
                .errorMessage(null)
                .generationPrompt(null)
                .strategyMetadata(new HashMap<>())
                .children(new ArrayList<>()) // 🔧 修复：确保 children 字段被初始化
                .build();
    }

    /**
     * 构建父子关系映射
     * 
     * @param items 设定条目列表
     * @return 父子关系映射（父ID -> 子ID列表）
     */
    public Map<String, List<String>> buildParentChildMap(List<NovelSettingItem> items) {
        Map<String, List<String>> parentChildMap = new HashMap<>();
        
        items.forEach(item -> {
            String parentId = item.getParentId();
            if (parentId != null) {
                parentChildMap.computeIfAbsent(parentId, k -> new ArrayList<>()).add(item.getId());
            }
        });
        
        return parentChildMap;
    }

    /**
     * 获取根节点ID列表
     * 
     * @param items 设定条目列表
     * @return 根节点ID列表
     */
    public List<String> getRootNodeIds(List<NovelSettingItem> items) {
        return items.stream()
                .filter(item -> item.getParentId() == null)
                .map(NovelSettingItem::getId)
                .collect(Collectors.toList());
    }

    /**
     * 将 Map<String, Object> 安全地转换为 Map<String, String>
     */
    private Map<String, String> convertObjectMapToStringMap(Map<String, Object> objectMap) {
        if (objectMap == null) {
            return new HashMap<>();
        }
        return objectMap.entrySet().stream()
                .collect(Collectors.toMap(
                        Map.Entry::getKey,
                        entry -> String.valueOf(entry.getValue())
                ));
    }

    /**
     * 将 Map<String, String> 转换为 Map<String, Object>
     */
    private Map<String, Object> convertStringMapToObjectMap(Map<String, String> stringMap) {
        if (stringMap == null) {
            return new HashMap<>();
        }
        return new HashMap<>(stringMap);
    }

    /**
     * 更新所有设定条目的子节点ID列表
     */
    private void updateChildrenIds(List<NovelSettingItem> items) {
        // 构建父子映射
        Map<String, List<String>> parentChildMap = new HashMap<>();
        items.forEach(item -> {
            String parentId = item.getParentId();
            if (parentId != null) {
                parentChildMap.computeIfAbsent(parentId, k -> new ArrayList<>()).add(item.getId());
            }
        });

        // 更新每个条目的子节点ID列表
        items.forEach(item -> {
            List<String> childrenIds = parentChildMap.getOrDefault(item.getId(), new ArrayList<>());
            item.setChildrenIds(childrenIds);
        });
    }
} 