package com.ainovel.server.common.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.Builder;

import java.util.List;

/**
 * 通用分页响应类
 * @param <T> 数据类型
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PagedResponse<T> {
    
    /**
     * 当前页数据内容
     */
    private List<T> content;
    
    /**
     * 当前页码（从0开始）
     */
    private int page;
    
    /**
     * 每页大小
     */
    private int size;
    
    /**
     * 总元素数量
     */
    private long totalElements;
    
    /**
     * 总页数
     */
    private int totalPages;
    
    /**
     * 是否有下一页
     */
    private boolean hasNext;
    
    /**
     * 是否有上一页
     */
    private boolean hasPrevious;
    
    /**
     * 是否是第一页
     */
    private boolean first;
    
    /**
     * 是否是最后一页
     */
    private boolean last;
    
    /**
     * 创建分页响应的静态工厂方法
     * @param content 当前页数据
     * @param page 当前页码（从0开始）
     * @param size 每页大小
     * @param totalElements 总元素数量
     * @return 分页响应对象
     */
    public static <T> PagedResponse<T> of(List<T> content, int page, int size, long totalElements) {
        int totalPages = (int) Math.ceil((double) totalElements / size);
        boolean hasNext = page < totalPages - 1;
        boolean hasPrevious = page > 0;
        boolean first = page == 0;
        boolean last = page == totalPages - 1 || totalPages == 0;
        
        return PagedResponse.<T>builder()
                .content(content)
                .page(page)
                .size(size)
                .totalElements(totalElements)
                .totalPages(totalPages)
                .hasNext(hasNext)
                .hasPrevious(hasPrevious)
                .first(first)
                .last(last)
                .build();
    }
    
    /**
     * 创建空的分页响应
     * @param page 当前页码
     * @param size 每页大小
     * @return 空的分页响应对象
     */
    public static <T> PagedResponse<T> empty(int page, int size) {
        return of(List.of(), page, size, 0);
    }
}