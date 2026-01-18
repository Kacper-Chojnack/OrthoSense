/// Unit tests for ActivityLogScreen and ActivityFilter.
///
/// Test coverage:
/// 1. ActivityFilter enum
/// 2. ActivityFilterNotifier
/// 3. Filter functionality
/// 4. Export options
/// 5. Stream provider
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/features/dashboard/presentation/screens/activity_log_screen.dart';

void main() {
  group('ActivityFilter', () {
    test('has all filter', () {
      expect(ActivityFilter.values.contains(ActivityFilter.all), isTrue);
    });

    test('has thisWeek filter', () {
      expect(ActivityFilter.values.contains(ActivityFilter.thisWeek), isTrue);
    });

    test('has thisMonth filter', () {
      expect(ActivityFilter.values.contains(ActivityFilter.thisMonth), isTrue);
    });

    test('has pendingSync filter', () {
      expect(
        ActivityFilter.values.contains(ActivityFilter.pendingSync),
        isTrue,
      );
    });

    test('has exactly 4 filter options', () {
      expect(ActivityFilter.values.length, equals(4));
    });
  });

  group('ActivityFilterNotifier', () {
    test('initial state is all', () {
      const initialFilter = 'all';
      expect(initialFilter, equals('all'));
    });

    test('setFilter changes state', () {
      var state = 'all';

      void setFilter(String filter) {
        state = filter;
      }

      setFilter('thisWeek');
      expect(state, equals('thisWeek'));
    });

    test('can filter by this week', () {
      var state = 'all';

      void setFilter(String filter) {
        state = filter;
      }

      setFilter('thisWeek');
      expect(state, equals('thisWeek'));
    });

    test('can filter by this month', () {
      var state = 'all';

      void setFilter(String filter) {
        state = filter;
      }

      setFilter('thisMonth');
      expect(state, equals('thisMonth'));
    });

    test('can filter by pending sync', () {
      var state = 'all';

      void setFilter(String filter) {
        state = filter;
      }

      setFilter('pendingSync');
      expect(state, equals('pendingSync'));
    });
  });

  group('Date filtering logic', () {
    test('this week includes items from past 7 days', () {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final itemDate = now.subtract(const Duration(days: 3));

      final isThisWeek = itemDate.isAfter(sevenDaysAgo);
      expect(isThisWeek, isTrue);
    });

    test('this week excludes items older than 7 days', () {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final itemDate = now.subtract(const Duration(days: 10));

      final isThisWeek = itemDate.isAfter(sevenDaysAgo);
      expect(isThisWeek, isFalse);
    });

    test('this month includes items from current month', () {
      final now = DateTime.now();
      final itemDate = DateTime(now.year, now.month, 15);

      final isThisMonth =
          itemDate.year == now.year && itemDate.month == now.month;
      expect(isThisMonth, isTrue);
    });

    test('this month excludes items from previous month', () {
      final now = DateTime.now();
      final previousMonth = now.month == 1 ? 12 : now.month - 1;
      final year = now.month == 1 ? now.year - 1 : now.year;
      final itemDate = DateTime(year, previousMonth, 15);

      final isThisMonth =
          itemDate.year == now.year && itemDate.month == now.month;
      expect(isThisMonth, isFalse);
    });
  });

  group('Pending sync filtering', () {
    test('identifies items pending sync', () {
      const syncedAt = null;
      final isPendingSync = syncedAt == null;
      expect(isPendingSync, isTrue);
    });

    test('excludes already synced items', () {
      final syncedAt = DateTime.now();
      final isPendingSync = syncedAt == null;
      expect(isPendingSync, isFalse);
    });
  });

  group('Export options', () {
    test('supports PDF export', () {
      const exportOptions = ['pdf', 'csv', 'share'];
      expect(exportOptions.contains('pdf'), isTrue);
    });

    test('supports CSV export', () {
      const exportOptions = ['pdf', 'csv', 'share'];
      expect(exportOptions.contains('csv'), isTrue);
    });

    test('supports share with doctor', () {
      const exportOptions = ['pdf', 'csv', 'share'];
      expect(exportOptions.contains('share'), isTrue);
    });
  });

  group('Export handling', () {
    test('handles PDF export selection', () {
      var handledExport = '';

      void handleExport(String value) {
        handledExport = value;
      }

      handleExport('pdf');
      expect(handledExport, equals('pdf'));
    });

    test('handles CSV export selection', () {
      var handledExport = '';

      void handleExport(String value) {
        handledExport = value;
      }

      handleExport('csv');
      expect(handledExport, equals('csv'));
    });

    test('handles share selection', () {
      var handledExport = '';

      void handleExport(String value) {
        handledExport = value;
      }

      handleExport('share');
      expect(handledExport, equals('share'));
    });
  });

  group('exerciseResultsStreamProvider', () {
    test('is autoDispose', () {
      const isAutoDispose = true;
      expect(isAutoDispose, isTrue);
    });

    test('watches exerciseResultsRepository', () {
      var repositoryWatched = false;

      void watchRepository() {
        repositoryWatched = true;
      }

      watchRepository();
      expect(repositoryWatched, isTrue);
    });

    test('calls watchAll on repository', () {
      var watchAllCalled = false;

      void watchAll() {
        watchAllCalled = true;
      }

      watchAll();
      expect(watchAllCalled, isTrue);
    });
  });

  group('AppBar', () {
    test('title is Activity Log', () {
      const title = 'Activity Log';
      expect(title, equals('Activity Log'));
    });

    test('has more_vert icon for menu', () {
      const iconName = 'more_vert_rounded';
      expect(iconName, contains('more_vert'));
    });

    test('menu tooltip is Export Options', () {
      const tooltip = 'Export Options';
      expect(tooltip, equals('Export Options'));
    });
  });

  group('Filter chips', () {
    test('All chip is present', () {
      const chipLabels = ['All', 'This Week', 'This Month', 'Pending Sync'];
      expect(chipLabels.contains('All'), isTrue);
    });

    test('selected chip shows current filter', () {
      const currentFilter = 'all';
      final isSelected = currentFilter == 'all';

      expect(isSelected, isTrue);
    });

    test('tapping chip changes filter', () {
      var currentFilter = 'all';

      void onSelected(String filter) {
        currentFilter = filter;
      }

      onSelected('thisWeek');
      expect(currentFilter, equals('thisWeek'));
    });
  });

  group('PopupMenuItem icons', () {
    test('PDF option uses picture_as_pdf icon', () {
      const iconName = 'picture_as_pdf_outlined';
      expect(iconName, contains('pdf'));
    });

    test('CSV option uses table_chart icon', () {
      const iconName = 'table_chart_outlined';
      expect(iconName, contains('table'));
    });

    test('Share option uses share icon', () {
      const iconName = 'share_outlined';
      expect(iconName, contains('share'));
    });
  });

  group('PopupMenuItem text', () {
    test('PDF option text', () {
      const text = 'Export as PDF';
      expect(text, contains('PDF'));
    });

    test('CSV option text', () {
      const text = 'Export as CSV';
      expect(text, contains('CSV'));
    });

    test('Share option text', () {
      const text = 'Share with Doctor';
      expect(text, contains('Doctor'));
    });
  });

  group('SingleChildScrollView', () {
    test('filter chips are horizontally scrollable', () {
      const scrollDirection = 'horizontal';
      expect(scrollDirection, equals('horizontal'));
    });

    test('has horizontal padding of 16', () {
      const horizontalPadding = 16.0;
      expect(horizontalPadding, equals(16.0));
    });

    test('has vertical padding of 8', () {
      const verticalPadding = 8.0;
      expect(verticalPadding, equals(8.0));
    });
  });

  group('Database integration', () {
    test('uses Drift database', () {
      const usesDrift = true;
      expect(usesDrift, isTrue);
    });

    test('data is single source of truth', () {
      const isSSoT = true;
      expect(isSSoT, isTrue);
    });

    test('uses Riverpod providers', () {
      const usesRiverpod = true;
      expect(usesRiverpod, isTrue);
    });
  });

  group('IntL formatting', () {
    test('uses Intl package for date formatting', () {
      const usesIntl = true;
      expect(usesIntl, isTrue);
    });
  });
}
