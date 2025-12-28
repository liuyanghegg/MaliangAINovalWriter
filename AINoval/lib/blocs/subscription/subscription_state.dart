part of 'subscription_bloc.dart';

abstract class SubscriptionState extends Equatable {
  const SubscriptionState();

  @override
  List<Object?> get props => [];
}

class SubscriptionInitial extends SubscriptionState {}

class SubscriptionLoading extends SubscriptionState {}

class SubscriptionError extends SubscriptionState {
  final String message;

  const SubscriptionError(this.message);

  @override
  List<Object> get props => [message];
}

class SubscriptionPlansLoaded extends SubscriptionState {
  final List<SubscriptionPlan> plans;

  const SubscriptionPlansLoaded(this.plans);

  @override
  List<Object> get props => [plans];
}

class SubscriptionStatisticsLoaded extends SubscriptionState {
  final SubscriptionStatistics statistics;

  const SubscriptionStatisticsLoaded(this.statistics);

  @override
  List<Object> get props => [statistics];
} 