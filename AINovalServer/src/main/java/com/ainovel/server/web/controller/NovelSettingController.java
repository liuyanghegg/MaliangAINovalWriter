package com.ainovel.server.web.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import com.ainovel.server.domain.model.NovelSettingItem;
import com.ainovel.server.domain.model.NovelSettingItem.SettingRelationship;
import com.ainovel.server.domain.model.SettingGroup;
import com.ainovel.server.service.NovelSettingService;
import com.ainovel.server.web.dto.SettingSearchRequest;
import com.ainovel.server.web.dto.novelsetting.*;
import com.ainovel.server.web.dto.novelsetting.ParentChildRelationshipRequest;
import com.ainovel.server.web.dto.novelsetting.TrackingConfigRequest;
import com.ainovel.server.security.CurrentUser;

import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 小说设定控制器
 * 处理小说设定相关的API请求
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/novels/{novelId}/settings")
public class NovelSettingController {

    private final NovelSettingService novelSettingService;

    @Autowired
    public NovelSettingController(NovelSettingService novelSettingService) {
        this.novelSettingService = novelSettingService;
    }

    // ==================== 设定条目管理 ====================

    /**
     * 创建小说设定条目
     */
    @PostMapping("/items/create")
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<NovelSettingItem> createSettingItem(
            @PathVariable String novelId,
            @RequestBody NovelSettingItem settingItem,
            @AuthenticationPrincipal CurrentUser currentUser) {

        // 设置关联的小说ID和用户ID
        settingItem.setNovelId(novelId);
        settingItem.setUserId(currentUser.getId());

        return novelSettingService.createSettingItem(settingItem)
                .doOnSuccess(item -> log.info("用户 {} 为小说 {} 创建了设定项: {}", 
                        currentUser.getUsername(), novelId, item.getName()));
    }

    /**
     * 获取小说设定条目列表
     */
    @PostMapping("/items/list")
    public Flux<NovelSettingItem> getNovelSettingItems(
            @PathVariable String novelId,
            @RequestBody SettingItemListRequest request,
            @AuthenticationPrincipal CurrentUser currentUser) {

        Sort.Direction direction = "asc".equalsIgnoreCase(request.getSortDirection()) ? 
                Sort.Direction.ASC : Sort.Direction.DESC;
        Pageable pageable = PageRequest.of(
                request.getPage(), 
                request.getSize(), 
                Sort.by(direction, request.getSortBy()));

        return novelSettingService.getNovelSettingItems(
                novelId, 
                request.getType(), 
                request.getName(), 
                request.getPriority(), 
                request.getGeneratedBy(), 
                request.getStatus(), 
                pageable);
    }

    /**
     * 获取小说设定条目详情
     */
    @PostMapping("/items/detail")
    public Mono<NovelSettingItem> getSettingItemDetail(
            @PathVariable String novelId,
            @RequestBody SettingItemDetailRequest request,
            @AuthenticationPrincipal CurrentUser currentUser) {

        return novelSettingService.getSettingItemById(request.getItemId())
                .filter(item -> item.getNovelId().equals(novelId))
                .switchIfEmpty(Mono.error(new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "设定条目不存在或不属于该小说")));
    }

    /**
     * 更新小说设定条目
     */
    @PostMapping("/items/update")
    public Mono<NovelSettingItem> updateSettingItem(
            @PathVariable String novelId,
            @RequestBody SettingItemUpdateRequest request,
            @AuthenticationPrincipal CurrentUser currentUser) {

        NovelSettingItem settingItem = request.getSettingItem();
        
        if (!novelId.equals(settingItem.getNovelId())) {
            return Mono.error(new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "设定条目的novelId与路径参数不匹配"));
        }

        settingItem.setId(request.getItemId());
        settingItem.setUserId(currentUser.getId());
        return novelSettingService.updateSettingItem(request.getItemId(), settingItem)
                .doOnSuccess(item -> log.info("用户 {} 更新了小说 {} 的设定项: {}", 
                        currentUser.getUsername(), novelId, item.getName()));
    }

    /**
     * 删除小说设定条目
     */
    @PostMapping("/items/delete")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> deleteSettingItem(
            @PathVariable String novelId,
            @RequestBody SettingItemDeleteRequest request,
            @AuthenticationPrincipal CurrentUser currentUser) {

        return novelSettingService.getSettingItemById(request.getItemId())
                .filter(item -> item.getNovelId().equals(novelId))
                .switchIfEmpty(Mono.error(new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "设定条目不存在或不属于该小说")))
                .flatMap(item -> novelSettingService.deleteSettingItem(request.getItemId()))
                .doOnSuccess(v -> log.info("用户 {} 删除了小说 {} 的设定项 {}", 
                        currentUser.getUsername(), novelId, request.getItemId()));
    }

    /**
     * 添加设定条目之间的关系
     */
    @PostMapping("/items/add-relationship")
    public Mono<NovelSettingItem> addSettingRelationship(
            @PathVariable String novelId,
            @RequestBody SettingRelationshipRequest request,
            @AuthenticationPrincipal CurrentUser currentUser) {

        // 创建关系对象
        SettingRelationship relationship = SettingRelationship.builder()
                .targetItemId(request.getTargetItemId())
                .type(request.getRelationshipType())
                .description(request.getDescription())
                .build();

        return novelSettingService.addSettingRelationship(request.getItemId(), relationship)
                .doOnSuccess(item -> log.info("用户 {} 为小说 {} 的设定项 {} 添加了关系: {} -> {}", 
                        currentUser.getUsername(), novelId, item.getName(), request.getRelationshipType(), request.getTargetItemId()));
    }

    /**
     * 删除设定条目之间的关系
     */
    @PostMapping("/items/remove-relationship")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> removeSettingRelationship(
            @PathVariable String novelId,
            @RequestBody SettingRelationshipDeleteRequest request,
            @AuthenticationPrincipal CurrentUser currentUser) {

        return novelSettingService.removeSettingRelationship(
                request.getItemId(), 
                request.getTargetItemId(), 
                request.getRelationshipType())
                .doOnSuccess(v -> log.info("用户 {} 删除了小说 {} 的设定项关系: {} -> {}", 
                        currentUser.getUsername(), novelId, request.getItemId(), request.getTargetItemId()));
    }

    // ==================== 设定组管理 ====================

    /**
     * 创建设定组
     */
    @PostMapping("/groups/create")
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<SettingGroup> createSettingGroup(
            @PathVariable String novelId,
            @RequestBody SettingGroup settingGroup,
            @AuthenticationPrincipal CurrentUser currentUser) {

        settingGroup.setNovelId(novelId);
        settingGroup.setUserId(currentUser.getId());

        return novelSettingService.createSettingGroup(settingGroup)
                .doOnSuccess(group -> log.info("用户 {} 为小说 {} 创建了设定组: {}", 
                        currentUser.getUsername(), novelId, group.getName()));
    }

    /**
     * 获取小说的设定组列表
     */
    @PostMapping("/groups/list")
    public Flux<SettingGroup> getNovelSettingGroups(
            @PathVariable String novelId,
            @RequestBody SettingGroupListRequest request,
            @AuthenticationPrincipal CurrentUser currentUser) {

        return novelSettingService.getNovelSettingGroups(
                novelId, 
                request.getName(), 
                request.getIsActiveContext());
    }

    /**
     * 获取设定组详情
     */
    @PostMapping("/groups/detail")
    public Mono<SettingGroup> getSettingGroupDetail(
            @PathVariable String novelId,
            @RequestBody SettingGroupDetailRequest request,
            @AuthenticationPrincipal CurrentUser currentUser) {

        return novelSettingService.getSettingGroupById(request.getGroupId())
                .filter(group -> group.getNovelId().equals(novelId))
                .switchIfEmpty(Mono.error(new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "设定组不存在或不属于该小说")));
    }

    /**
     * 更新设定组
     */
    @PostMapping("/groups/update")
    public Mono<SettingGroup> updateSettingGroup(
            @PathVariable String novelId,
            @RequestBody SettingGroupUpdateRequest request,
            @AuthenticationPrincipal CurrentUser currentUser) {

        SettingGroup settingGroup = request.getSettingGroup();
        
        if (!novelId.equals(settingGroup.getNovelId())) {
            return Mono.error(new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "设定组的novelId与路径参数不匹配"));
        }

        settingGroup.setId(request.getGroupId());
        settingGroup.setUserId(currentUser.getId());
        return novelSettingService.updateSettingGroup(request.getGroupId(), settingGroup)
                .doOnSuccess(group -> log.info("用户 {} 更新了小说 {} 的设定组: {}", 
                        currentUser.getUsername(), novelId, group.getName()));
    }

    /**
     * 删除设定组
     */
    @PostMapping("/groups/delete")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> deleteSettingGroup(
            @PathVariable String novelId,
            @RequestBody SettingGroupDeleteRequest request,
            @AuthenticationPrincipal CurrentUser currentUser) {

        return novelSettingService.getSettingGroupById(request.getGroupId())
                .filter(group -> group.getNovelId().equals(novelId))
                .switchIfEmpty(Mono.error(new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "设定组不存在或不属于该小说")))
                .flatMap(group -> novelSettingService.deleteSettingGroup(request.getGroupId()))
                .doOnSuccess(v -> log.info("用户 {} 删除了小说 {} 的设定组 {}", 
                        currentUser.getUsername(), novelId, request.getGroupId()));
    }

    /**
     * 添加设定条目到设定组
     */
    @PostMapping("/groups/add-item")
    public Mono<SettingGroup> addItemToGroup(
            @PathVariable String novelId,
            @RequestBody GroupItemRequest request,
            @AuthenticationPrincipal CurrentUser currentUser) {

        log.info("接收到添加设定条目到设定组请求: novelId={}, groupId={}, itemId={}, user={}", 
                novelId, request.getGroupId(), request.getItemId(), currentUser.getUsername());
                
        return novelSettingService.addItemToGroup(request.getGroupId(), request.getItemId())
                .doOnSuccess(group -> {
                    log.info("成功将设定项 {} 添加到设定组 {}，组现有条目: {}", 
                            request.getItemId(), request.getGroupId(), group.getItemIds());
                })
                .doOnError(error -> {
                    log.error("添加设定条目到设定组失败: novelId={}, groupId={}, itemId={}, error={}", 
                            novelId, request.getGroupId(), request.getItemId(), error.getMessage());
                });
    }

    /**
     * 从设定组中移除设定条目
     */
    @PostMapping("/groups/remove-item")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> removeItemFromGroup(
            @PathVariable String novelId,
            @RequestBody GroupItemRequest request,
            @AuthenticationPrincipal CurrentUser currentUser) {

        return novelSettingService.removeItemFromGroup(request.getGroupId(), request.getItemId())
                .doOnSuccess(v -> log.info("用户 {} 从设定组 {} 移除了设定项 {}", 
                        currentUser.getUsername(), request.getGroupId(), request.getItemId()));
    }

    /**
     * 激活/停用设定组作为上下文
     */
    @PostMapping("/groups/set-active")
    public Mono<SettingGroup> setActiveContext(
            @PathVariable String novelId,
            @RequestBody SetGroupActiveRequest request,
            @AuthenticationPrincipal CurrentUser currentUser) {

        return novelSettingService.setGroupActiveContext(request.getGroupId(), request.isActive())
                .doOnSuccess(group -> log.info("用户 {} 将设定组 {} 的激活状态设置为: {}", 
                        currentUser.getUsername(), request.getGroupId(), request.isActive()));
    }

    // ==================== 父子关系管理 ====================

    /**
     * 设置父子关系
     */
    @PostMapping("/items/set-parent")
    public Mono<NovelSettingItem> setParentRelationship(
            @PathVariable String novelId,
            @RequestBody ParentChildRelationshipRequest request,
            @AuthenticationPrincipal CurrentUser currentUser) {

        return novelSettingService.setParentChildRelationship(
                request.getChildId(), 
                request.getParentId())
                .doOnSuccess(item -> log.info("用户 {} 为小说 {} 设置了父子关系: {} -> {}", 
                        currentUser.getUsername(), novelId, request.getParentId(), request.getChildId()));
    }

    /**
     * 移除父子关系
     */
    @PostMapping("/items/remove-parent")
    public Mono<NovelSettingItem> removeParentRelationship(
            @PathVariable String novelId,
            @RequestBody ParentChildRelationshipRequest request,
            @AuthenticationPrincipal CurrentUser currentUser) {

        return novelSettingService.removeParentChildRelationship(request.getChildId())
                .doOnSuccess(item -> log.info("用户 {} 移除了小说 {} 的父子关系: {}", 
                        currentUser.getUsername(), novelId, request.getChildId()));
    }

    /**
     * 获取设定的子设定列表
     */
    @PostMapping("/items/children")
    public Flux<NovelSettingItem> getChildrenSettings(
            @PathVariable String novelId,
            @RequestBody SettingItemDetailRequest request,
            @AuthenticationPrincipal CurrentUser currentUser) {

        return novelSettingService.getChildrenSettings(request.getItemId())
                .doOnComplete(() -> log.info("用户 {} 查询了小说 {} 设定项 {} 的子设定", 
                        currentUser.getUsername(), novelId, request.getItemId()));
    }

    /**
     * 获取设定的父设定
     */
    @PostMapping("/items/parent")
    public Mono<NovelSettingItem> getParentSetting(
            @PathVariable String novelId,
            @RequestBody SettingItemDetailRequest request,
            @AuthenticationPrincipal CurrentUser currentUser) {

        return novelSettingService.getParentSetting(request.getItemId())
                .doOnSuccess(parent -> log.info("用户 {} 查询了小说 {} 设定项 {} 的父设定: {}", 
                        currentUser.getUsername(), novelId, request.getItemId(), 
                        parent != null ? parent.getName() : "无"));
    }

    // ==================== 追踪配置管理 ====================

    /**
     * 更新追踪配置
     */
    @PostMapping("/items/tracking-config")
    public Mono<NovelSettingItem> updateTrackingConfig(
            @PathVariable String novelId,
            @RequestBody TrackingConfigRequest request,
            @AuthenticationPrincipal CurrentUser currentUser) {

        return novelSettingService.updateTrackingConfig(
                request.getItemId(),
                request.getNameAliasTracking(),
                request.getAiContextTracking(),
                request.getReferenceUpdatePolicy())
                .doOnSuccess(item -> log.info("用户 {} 更新了小说 {} 设定项 {} 的追踪配置", 
                        currentUser.getUsername(), novelId, request.getItemId()));
    }

    // ==================== 高级功能 ====================

    /**
     * 从文本中自动提取设定条目
     */
    @PostMapping("/extract")
    public Flux<NovelSettingItem> extractSettingsFromText(
            @PathVariable String novelId,
            @RequestBody ExtractSettingsRequest request,
            @AuthenticationPrincipal CurrentUser currentUser) {

        return novelSettingService.extractSettingsFromText(
                novelId, 
                request.getText(), 
                request.getType(), 
                currentUser.getId())
                .doOnComplete(() -> log.info("用户 {} 从文本中为小说 {} 提取了设定条目", 
                        currentUser.getUsername(), novelId));
    }

    /**
     * 根据关键词搜索设定条目
     */
    @PostMapping("/search")
    public Flux<NovelSettingItem> searchSettingItems(
            @PathVariable String novelId,
            @RequestBody SettingSearchRequest searchRequest,
            @AuthenticationPrincipal CurrentUser currentUser) {

        return novelSettingService.searchSettingItems(
                novelId, 
                searchRequest.getQuery(),
                searchRequest.getTypes(), 
                searchRequest.getGroupIds(),
                searchRequest.getMinScore(),
                searchRequest.getMaxResults())
                .doOnComplete(() -> log.info("用户 {} 搜索小说 {} 的设定条目，关键词: {}", 
                        currentUser.getUsername(), novelId, searchRequest.getQuery()));
    }
} 