package com.ainovel.server.service.analytics;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.HashMap;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import com.ainovel.server.domain.model.analytics.WritingEvent;
import com.ainovel.server.repository.WritingEventRepository;

import lombok.RequiredArgsConstructor;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Service
@RequiredArgsConstructor
public class WritingAnalyticsService {

    private final WritingEventRepository repository;

    public Mono<Void> recordEvent(WritingEvent event) {
        return repository.save(event).then();
    }

    public Flux<WritingEvent> listUserEvents(String userId, int page, int size) {
        return repository.findByUserIdOrderByTimestampDesc(userId, PageRequest.of(page, size));
    }

    public Mono<Map<String, Object>> aggregateUserDaily(String userId, LocalDate start, LocalDate end,
                                                        String novelId, String chapterId, String sceneId) {
        LocalDateTime from = start != null ? start.atStartOfDay() : LocalDate.now().minusDays(30).atStartOfDay();
        LocalDateTime to = end != null ? end.atTime(LocalTime.MAX) : LocalDateTime.now();

        return repository.findByUserIdAndTimestampBetweenOrderByTimestampDesc(
                userId, from, to, PageRequest.of(0, Integer.MAX_VALUE))
            .filter(e -> novelId == null || novelId.isBlank() || novelId.equals(e.getNovelId()))
            .filter(e -> chapterId == null || chapterId.isBlank() || chapterId.equals(e.getChapterId()))
            .filter(e -> sceneId == null || sceneId.isBlank() || sceneId.equals(e.getSceneId()))
            .collectList()
            .map(list -> {
                Map<LocalDate, Integer> words = new HashMap<>();
                for (WritingEvent e : list) {
                    LocalDate d = e.getTimestamp().toLocalDate();
                    words.merge(d, e.getDeltaWords() != null ? e.getDeltaWords() : 0, Integer::sum);
                }
                Map<String, Integer> series = words.entrySet().stream()
                    .sorted(Map.Entry.comparingByKey())
                    .collect(Collectors.toMap(k -> k.getKey().toString(), Map.Entry::getValue, (a,b)->a, HashMap::new));
                Map<String, Object> res = new HashMap<>();
                res.put("dailyWords", series);
                res.put("totalWords", list.stream().mapToInt(e -> e.getDeltaWords() != null ? e.getDeltaWords() : 0).sum());
                return res;
            });
    }

    public Mono<Map<String, Object>> aggregateBySource(String userId, LocalDate start, LocalDate end,
                                                       String novelId, String chapterId, String sceneId) {
        LocalDateTime from = start != null ? start.atStartOfDay() : LocalDate.now().minusDays(30).atStartOfDay();
        LocalDateTime to = end != null ? end.atTime(LocalTime.MAX) : LocalDateTime.now();

        return repository.findByUserIdAndTimestampBetweenOrderByTimestampDesc(
                userId, from, to, PageRequest.of(0, Integer.MAX_VALUE))
            .filter(e -> novelId == null || novelId.isBlank() || novelId.equals(e.getNovelId()))
            .filter(e -> chapterId == null || chapterId.isBlank() || chapterId.equals(e.getChapterId()))
            .filter(e -> sceneId == null || sceneId.isBlank() || sceneId.equals(e.getSceneId()))
            .collectList()
            .map(list -> {
                Map<String, Integer> bySource = new HashMap<>();
                for (WritingEvent e : list) {
                    String src = e.getSource() != null ? e.getSource() : "MANUAL";
                    bySource.merge(src, e.getDeltaWords() != null ? e.getDeltaWords() : 0, Integer::sum);
                }
                Map<String, Object> res = new HashMap<>();
                res.put("wordsBySource", bySource);
                return res;
            });
    }

    /**
     * 统计用户的写作天数（去重后的日期数，跨全量数据）
     */
    public Mono<Long> countUniqueWritingDays(String userId) {
        return repository.findByUserIdOrderByTimestampDesc(userId, PageRequest.of(0, Integer.MAX_VALUE))
                .map(e -> e.getTimestamp().toLocalDate())
                .distinct()
                .count();
    }

    /**
     * 计算连续写作天数（基于写作事件日期，按天连续计数）
     */
    public Mono<Long> calculateConsecutiveWritingDays(String userId) {
        return repository.findByUserIdOrderByTimestampDesc(userId, PageRequest.of(0, Integer.MAX_VALUE))
                .map(e -> e.getTimestamp().toLocalDate())
                .distinct()
                .sort((d1, d2) -> d2.compareTo(d1))
                .collectList()
                .map(dates -> {
                    if (dates.isEmpty()) return 0L;
                    long consecutive = 1L;
                    LocalDate previous = dates.get(0);
                    for (int i = 1; i < dates.size(); i++) {
                        LocalDate current = dates.get(i);
                        if (previous.minusDays(1).equals(current)) {
                            consecutive++;
                            previous = current;
                        } else {
                            break;
                        }
                    }
                    return consecutive;
                });
    }
}


