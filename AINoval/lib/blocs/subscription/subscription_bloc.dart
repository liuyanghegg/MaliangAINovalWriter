import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../services/api_service/repositories/impl/subscription_repository_impl.dart';
import '../../models/admin/subscription_models.dart';

part 'subscription_event.dart';
part 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionRepositoryImpl subscriptionRepository;

  SubscriptionBloc(this.subscriptionRepository) : super(SubscriptionInitial()) {
    on<LoadSubscriptionPlans>(_onLoadSubscriptionPlans);
    on<LoadSubscriptionStatistics>(_onLoadSubscriptionStatistics);
    on<CreateSubscriptionPlan>(_onCreateSubscriptionPlan);
    on<UpdateSubscriptionPlan>(_onUpdateSubscriptionPlan);
    on<DeleteSubscriptionPlan>(_onDeleteSubscriptionPlan);
    on<ToggleSubscriptionPlanStatus>(_onToggleSubscriptionPlanStatus);
  }

  Future<void> _onLoadSubscriptionPlans(
    LoadSubscriptionPlans event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    try {
      final plans = await subscriptionRepository.getAllPlans();
      emit(SubscriptionPlansLoaded(plans));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }

  Future<void> _onLoadSubscriptionStatistics(
    LoadSubscriptionStatistics event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    try {
      final statistics = await subscriptionRepository.getSubscriptionStatistics();
      emit(SubscriptionStatisticsLoaded(statistics));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }

  Future<void> _onCreateSubscriptionPlan(
    CreateSubscriptionPlan event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      await subscriptionRepository.createPlan(event.plan);
      // 重新加载订阅计划列表
      add(LoadSubscriptionPlans());
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }

  Future<void> _onUpdateSubscriptionPlan(
    UpdateSubscriptionPlan event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      await subscriptionRepository.updatePlan(event.planId, event.plan);
      // 重新加载订阅计划列表
      add(LoadSubscriptionPlans());
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }

  Future<void> _onDeleteSubscriptionPlan(
    DeleteSubscriptionPlan event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      await subscriptionRepository.deletePlan(event.planId);
      // 重新加载订阅计划列表
      add(LoadSubscriptionPlans());
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }

  Future<void> _onToggleSubscriptionPlanStatus(
    ToggleSubscriptionPlanStatus event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      await subscriptionRepository.togglePlanStatus(event.planId, event.active);
      // 重新加载订阅计划列表
      add(LoadSubscriptionPlans());
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }
} 