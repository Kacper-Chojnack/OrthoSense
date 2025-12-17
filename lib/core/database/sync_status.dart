/// Sync status for Outbox Pattern.
/// Records start as [pending], transition to [syncing] during upload,
/// and finally [synced] on success.
enum SyncStatus {
  pending,
  syncing,
  synced,
  failed;

  static SyncStatus fromString(String value) => switch (value) {
        'pending' => SyncStatus.pending,
        'syncing' => SyncStatus.syncing,
        'synced' => SyncStatus.synced,
        'failed' => SyncStatus.failed,
        _ => SyncStatus.pending,
      };
}
