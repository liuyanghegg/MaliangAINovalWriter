package com.ainovel.server.common.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * 通用游标分页响应
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CursorPageResponse<T> {
    /** 当前返回的数据项 */
    private List<T> items;
    /** 下一页游标（可能为null表示没有更多） */
    private String nextCursor;
    /** 是否还有更多数据 */
    private boolean hasMore;
}



