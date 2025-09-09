package com.ainovel.server.service.impl;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ainovel.server.controller.AdminUserController.UserStatistics;
import com.ainovel.server.controller.AdminUserController.UserUpdateRequest;
import com.ainovel.server.domain.model.User;
import com.ainovel.server.domain.model.User.AccountStatus;
import com.ainovel.server.repository.UserRepository;
import com.ainovel.server.service.AdminUserService;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 管理员用户管理服务实现
 */
@Service
public class AdminUserServiceImpl implements AdminUserService {
    
    private final UserRepository userRepository;
    
    @Autowired
    public AdminUserServiceImpl(UserRepository userRepository) {
        this.userRepository = userRepository;
    }
    
    @Override
    public Flux<User> findAllUsers(Pageable pageable) {
        return userRepository.findAll()
                .skip(pageable.getOffset())
                .take(pageable.getPageSize());
    }
    
    @Override
    public Flux<User> searchUsers(String search, Pageable pageable) {
        return userRepository.findByUsernameContainingIgnoreCaseOrEmailContainingIgnoreCase(search, search)
                .skip(pageable.getOffset())
                .take(pageable.getPageSize());
    }
    
    @Override
    public Mono<User> findUserById(String id) {
        return userRepository.findById(id);
    }
    
    @Override
    @Transactional
    public Mono<User> updateUser(String id, UserUpdateRequest request) {
        return userRepository.findById(id)
                .switchIfEmpty(Mono.error(new IllegalArgumentException("用户不存在: " + id)))
                .flatMap(user -> {
                    if (request.getEmail() != null) {
                        user.setEmail(request.getEmail());
                    }
                    if (request.getDisplayName() != null) {
                        user.setDisplayName(request.getDisplayName());
                    }
                    if (request.getAccountStatus() != null) {
                        user.setAccountStatus(request.getAccountStatus());
                    }
                    user.setUpdatedAt(LocalDateTime.now());
                    return userRepository.save(user);
                });
    }
    
    @Override
    @Transactional
    public Mono<User> updateUserStatus(String id, AccountStatus status) {
        return userRepository.findById(id)
                .switchIfEmpty(Mono.error(new IllegalArgumentException("用户不存在: " + id)))
                .flatMap(user -> {
                    user.setAccountStatus(status);
                    user.setUpdatedAt(LocalDateTime.now());
                    return userRepository.save(user);
                });
    }
    
    @Override
    @Transactional
    public Mono<User> assignRoleToUser(String userId, String roleId) {
        return userRepository.findById(userId)
                .switchIfEmpty(Mono.error(new IllegalArgumentException("用户不存在: " + userId)))
                .flatMap(user -> {
                    user.addRole(roleId);
                    user.setUpdatedAt(LocalDateTime.now());
                    return userRepository.save(user);
                });
    }
    
    @Override
    @Transactional
    public Mono<User> removeRoleFromUser(String userId, String roleId) {
        return userRepository.findById(userId)
                .switchIfEmpty(Mono.error(new IllegalArgumentException("用户不存在: " + userId)))
                .flatMap(user -> {
                    user.removeRole(roleId);
                    user.setUpdatedAt(LocalDateTime.now());
                    return userRepository.save(user);
                });
    }
    
    @Override
    public Mono<UserStatistics> getUserStatistics() {
        return Mono.zip(
                userRepository.count(),
                userRepository.countByAccountStatus(AccountStatus.ACTIVE),
                userRepository.countByAccountStatus(AccountStatus.SUSPENDED),
                userRepository.countByCreatedAtAfter(LocalDateTime.now().minusDays(1)),
                userRepository.countByCreatedAtAfter(LocalDateTime.now().minusWeeks(1)),
                userRepository.countByCreatedAtAfter(LocalDateTime.now().minusMonths(1))
        ).map(tuple -> {
            UserStatistics stats = new UserStatistics();
            stats.setTotalUsers(tuple.getT1());
            stats.setActiveUsers(tuple.getT2());
            stats.setSuspendedUsers(tuple.getT3());
            stats.setNewUsersToday(tuple.getT4());
            stats.setNewUsersThisWeek(tuple.getT5());
            stats.setNewUsersThisMonth(tuple.getT6());
            return stats;
        });
    }
    
    @Override
    @Transactional
    public Mono<Long> batchUpdateUserStatus(List<String> userIds, AccountStatus status) {
        return Flux.fromIterable(userIds)
                .flatMap(userId -> updateUserStatus(userId, status))
                .count();
    }
    
    @Override
    @Transactional
    public Mono<Void> deleteUser(String id) {
        return userRepository.findById(id)
                .switchIfEmpty(Mono.error(new IllegalArgumentException("用户不存在: " + id)))
                .flatMap(user -> {
                    // 软删除：设置为禁用状态
                    user.setAccountStatus(AccountStatus.DISABLED);
                    user.setUpdatedAt(LocalDateTime.now());
                    return userRepository.save(user);
                })
                .then();
    }
}