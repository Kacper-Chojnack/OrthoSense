// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_schedule_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for managing notification schedule settings.

@ProviderFor(NotificationScheduleNotifier)
const notificationScheduleProvider = NotificationScheduleNotifierProvider._();

/// Provider for managing notification schedule settings.
final class NotificationScheduleNotifierProvider
    extends
        $AsyncNotifierProvider<
          NotificationScheduleNotifier,
          NotificationSchedule
        > {
  /// Provider for managing notification schedule settings.
  const NotificationScheduleNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationScheduleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationScheduleNotifierHash();

  @$internal
  @override
  NotificationScheduleNotifier create() => NotificationScheduleNotifier();
}

String _$notificationScheduleNotifierHash() =>
    r'd2321a95fac610b6fa1c6b05dd5c481ac079354c';

/// Provider for managing notification schedule settings.

abstract class _$NotificationScheduleNotifier
    extends $AsyncNotifier<NotificationSchedule> {
  FutureOr<NotificationSchedule> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<AsyncValue<NotificationSchedule>, NotificationSchedule>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<NotificationSchedule>,
                NotificationSchedule
              >,
              AsyncValue<NotificationSchedule>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
