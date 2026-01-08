// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_export_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(reportExportService)
const reportExportServiceProvider = ReportExportServiceProvider._();

final class ReportExportServiceProvider
    extends
        $FunctionalProvider<
          ReportExportService,
          ReportExportService,
          ReportExportService
        >
    with $Provider<ReportExportService> {
  const ReportExportServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reportExportServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reportExportServiceHash();

  @$internal
  @override
  $ProviderElement<ReportExportService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReportExportService create(Ref ref) {
    return reportExportService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReportExportService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReportExportService>(value),
    );
  }
}

String _$reportExportServiceHash() =>
    r'801cf1ca9f982d27a64f639ac591c3db95198465';
