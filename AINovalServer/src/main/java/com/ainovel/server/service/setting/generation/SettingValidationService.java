package com.ainovel.server.service.setting.generation;

import com.ainovel.server.domain.model.SettingType;
import com.ainovel.server.domain.model.setting.generation.SettingGenerationSession;
import com.ainovel.server.domain.model.setting.generation.SettingNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.Set;
import java.util.HashSet;
import java.util.List;
import java.util.ArrayList;

/**
 * 设定验证服务
 * 负责验证LLM生成的设定数据的有效性
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class SettingValidationService {
    
    private final ObjectMapper objectMapper;
    
    /**
     * 验证单个节点
     */
    public ValidationResult validateNode(SettingNode node, SettingGenerationSession session) {
        List<String> errors = new ArrayList<>();
        
        // 1. 基本字段验证
        validateBasicFields(node, errors);
        
        // 2. 业务逻辑验证
        validateBusinessLogic(node, session, errors);
        
        // 3. 内容质量验证
        validateContentQuality(node, errors);
        
        if (errors.isEmpty()) {
            return ValidationResult.success();
        } else {
            return ValidationResult.failure(errors);
        }
    }
    
    /**
     * 批量验证节点
     */
    public BatchValidationResult validateNodes(List<SettingNode> nodes, SettingGenerationSession session) {
        Set<String> validNodeIds = new HashSet<>();
        List<NodeValidationError> errors = new ArrayList<>();
        
        for (SettingNode node : nodes) {
            ValidationResult result = validateNode(node, session);
            if (result.isValid()) {
                validNodeIds.add(node.getId());
            } else {
                errors.add(new NodeValidationError(node.getId(), node.getName(), result.getErrors()));
            }
        }
        
        return new BatchValidationResult(validNodeIds, errors);
    }
    
    /**
     * 验证基本字段
     */
    private void validateBasicFields(SettingNode node, List<String> errors) {
        if (node.getName() == null || node.getName().trim().isEmpty()) {
            errors.add("Name cannot be empty");
        }
        if (node.getType() == null) {
            errors.add("Type cannot be null");
        }
        if (node.getDescription() == null || node.getDescription().trim().isEmpty()) {
            errors.add("Description cannot be empty");
        }
    }
    
    /**
     * 验证业务逻辑
     */
    private void validateBusinessLogic(SettingNode node, SettingGenerationSession session, List<String> errors) {
        // 验证类型枚举值
        if (node.getType() != null) {
            try {
                SettingType.valueOf(node.getType().toString());
            } catch (IllegalArgumentException e) {
                errors.add("Invalid setting type: " + node.getType());
            }
        }
        
        // 验证父节点存在性
        if (node.getParentId() != null) {
            SettingNode parent = session.getGeneratedNodes().get(node.getParentId());
            if (parent == null) {
                errors.add("Parent node not found: " + node.getParentId());
            }
        }
        
        // 验证ID唯一性（允许在修改上下文中用相同ID更新当前节点）
        if (node.getId() != null && session.getGeneratedNodes().containsKey(node.getId())) {
            Object currentIdForModification = session.getMetadata().get("currentNodeIdForModification");
            boolean isInModificationContext = currentIdForModification instanceof String
                && node.getId().equals((String) currentIdForModification);
            if (!isInModificationContext) {
                errors.add("Duplicate node ID: " + node.getId());
            } else {
                // 处于修改上下文且是修改当前节点：校验父节点未被非法变更
                SettingNode existing = session.getGeneratedNodes().get(node.getId());
                String originalParentId = existing != null ? existing.getParentId() : null;
                boolean parentMismatch = (originalParentId == null && node.getParentId() != null)
                    || (originalParentId != null && !originalParentId.equals(node.getParentId()));
                if (parentMismatch) {
                    errors.add("Parent mismatch for update: " + node.getParentId());
                }
            }
        }

        // 验证“同父同名同类型”去重（避免重复设定）
        // 规则：在同一个父节点下，名称（忽略大小写与全角半角空白）和类型相同视为重复
        if (node.getName() != null && node.getType() != null) {
            String normalizedName = normalizeName(node.getName());
            for (SettingNode existing : session.getGeneratedNodes().values()) {
                if (existing == null || existing.getId() == null) continue;
                if (node.getId() != null && node.getId().equals(existing.getId())) continue; // 跳过自身
                boolean sameParent = (node.getParentId() == null && existing.getParentId() == null)
                        || (node.getParentId() != null && node.getParentId().equals(existing.getParentId()));
                if (!sameParent) continue;
                if (existing.getName() == null || existing.getType() == null) continue;
                if (!existing.getType().equals(node.getType())) continue;
                if (normalizeName(existing.getName()).equals(normalizedName)) {
                    errors.add("Duplicate node under same parent: name='" + node.getName() + "', type='" + node.getType() + "'");
                    break;
                }
            }
        }
        
        // 验证循环引用
        if (hasCircularReference(node, session)) {
            errors.add("Circular reference detected for node: " + node.getId());
        }
    }
    
    /**
     * 验证内容质量 - 放宽要求
     */
    private void validateContentQuality(SettingNode node, List<String> errors) {
        // 验证名称质量
        if (node.getName() != null && node.getName().length() > 100) {
            errors.add("Name too long: " + node.getName().length() + " characters");
        }
        
        // 验证描述质量 - 大幅放宽要求
        if (node.getDescription() != null) {
            if (node.getDescription().length() > 5000) {
                errors.add("Description too long: " + node.getDescription().length() + " characters");
            }
            
            // 对于九线法根节点，只要求非空即可
            if (node.getParentId() == null && isNineLineMethodNode(node)) {
                log.debug("Relaxed validation for nine-line method root node: {}", node.getName());
                // 九线法根节点的描述只需要非空即可
                if (node.getDescription().trim().isEmpty()) {
                    errors.add("Root node description cannot be empty");
                }
            } else if (node.getDescription().length() < 3) {
                // 非根节点要求至少3个字符
                errors.add("Description too short: " + node.getDescription().length() + " characters");
            }
            
            // 检查是否包含占位符文本 - 放宽检查
            if (containsPlaceholderText(node.getDescription())) {
                log.warn("Description contains placeholder text: {}", node.getDescription());
                // 不再作为错误，只记录警告
            }
        }
    }
    
    /**
     * 检查是否为九线法节点
     */
    private boolean isNineLineMethodNode(SettingNode node) {
        String[] nineLines = {"人物线", "情感线", "事件线", "悬念线", "金手指线", "世界观线", "成长线", "势力线", "主题线"};
        for (String line : nineLines) {
            if (line.equals(node.getName())) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * 检查循环引用
     */
    private boolean hasCircularReference(SettingNode node, SettingGenerationSession session) {
        if (node.getParentId() == null) {
            return false;
        }
        
        Set<String> visited = new HashSet<>();
        String current = node.getParentId();
        
        while (current != null) {
            if (visited.contains(current) || current.equals(node.getId())) {
                return true;
            }
            visited.add(current);
            
            SettingNode parent = session.getGeneratedNodes().get(current);
            current = parent != null ? parent.getParentId() : null;
        }
        
        return false;
    }
    
    /**
     * 检查是否包含占位符文本
     */
    private boolean containsPlaceholderText(String text) {
        if (text == null || text.trim().isEmpty()) {
            return false;
        }
        
        String[] placeholders = {
            "[描述]", "[待补充]", "[TODO]", "[PLACEHOLDER]",
            "Lorem ipsum", "placeholder", "example", "待填写", "待完善"
        };
        
        String lowerText = text.toLowerCase();
        for (String placeholder : placeholders) {
            if (lowerText.contains(placeholder.toLowerCase())) {
                return true;
            }
        }
        
        return false;
    }

    /**
     * 规范化名称：去除首尾空白，将连续空白折叠为单空格，转为小写。
     */
    private String normalizeName(String name) {
        if (name == null) return "";
        String s = name.replace('\u3000', ' ').trim();
        s = s.replaceAll("\\s+", " ");
        return s.toLowerCase();
    }
    
    /**
     * 验证结果
     */
    public record ValidationResult(boolean isValid, List<String> errors) {
        public static ValidationResult success() {
            return new ValidationResult(true, List.of());
        }
        
        public static ValidationResult failure(List<String> errors) {
            return new ValidationResult(false, errors);
        }
        
        public static ValidationResult failure(String error) {
            return new ValidationResult(false, List.of(error));
        }
        
        public List<String> getErrors() {
            return errors;
        }
    }
    
    /**
     * 批量验证结果
     */
    public record BatchValidationResult(
        Set<String> validNodeIds,
        List<NodeValidationError> errors
    ) {}
    
    /**
     * 节点验证错误
     */
    public record NodeValidationError(
        String nodeId,
        String nodeName,
        List<String> errors
    ) {}
}