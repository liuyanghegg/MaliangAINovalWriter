part of 'subscription_bloc.dart';

abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object?> get props => [];
}

class LoadSubscriptionPlans extends SubscriptionEvent {}

class LoadSubscriptionStatistics extends SubscriptionEvent {}

class CreateSubscriptionPlan extends SubscriptionEvent {
  final SubscriptionPlan plan;

  const CreateSubscriptionPlan(this.plan);

  @override
  List<Object> get props => [plan];
}

class UpdateSubscriptionPlan extends SubscriptionEvent {
  final String planId;
  final SubscriptionPlan plan;

  const UpdateSubscriptionPlan({
    required this.planId,
    required this.plan,
  });

  @override
  List<Object> get props => [planId, plan];
}

class DeleteSubscriptionPlan extends SubscriptionEvent {
  final String planId;

  const DeleteSubscriptionPlan(this.planId);

  @override
  List<Object> get props => [planId];
}

class ToggleSubscriptionPlanStatus extends SubscriptionEvent {
  final String planId;
  final bool active;

  const ToggleSubscriptionPlanStatus({
    required this.planId,
    required this.active,
  });

  @override
  List<Object> get props => [planId, active];
} 