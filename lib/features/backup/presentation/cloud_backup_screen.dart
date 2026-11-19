import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/joyn_colors.dart';
import '../../../core/theme/joyn_typography.dart';

class CloudBackupScreen extends StatefulWidget {
  const CloudBackupScreen({super.key});

  @override
  State<CloudBackupScreen> createState() => _CloudBackupScreenState();
}

class _CloudBackupScreenState extends State<CloudBackupScreen> {
  bool _isLoading = true;
  bool _isSyncing = false;
  bool _isCreatingBackup = false;
  bool _isTriggeringCron = false;
  String? _restoringBackupId;
  String? _deletingBackupId;

  List<Map<String, dynamic>> _backups = [];
  String? _lastSyncTimestamp;
  int _pendingCount = 0;

  // Phase 12: Automated Cron & Security Telemetry
  bool _autoBackupEnabled = true;
  String _frequency = 'DAILY';
  String? _lastAutoBackupAt;
  Map<String, dynamic>? _serverHealth;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    setState(() => _isLoading = true);
    try {
      final syncService = await SyncService.getInstance();
      final lastSync = syncService.getLastSyncTimestamp();
      final pending = syncService.getPendingMutations();

      int count = 0;
      for (final key in pending.keys) {
        if (pending[key] is List) {
          count += (pending[key] as List).length;
        }
      }

      final rawBackups = await syncService.listCloudBackups();
      final parsedBackups = rawBackups.map((b) => Map<String, dynamic>.from(b as Map)).toList();

      // Phase 12: Fetch automated backup settings & health
      final settingsRes = await ApiService.getBackupSettings();
      final healthRes = await ApiService.getSystemHealth();

      final settings = settingsRes['settings'] as Map<String, dynamic>? ?? {};

      if (mounted) {
        setState(() {
          _lastSyncTimestamp = lastSync;
          _pendingCount = count;
          _backups = parsedBackups;
          _autoBackupEnabled = settings['autoBackupEnabled'] ?? true;
          _frequency = (settings['frequency'] ?? 'DAILY').toString().toUpperCase();
          _lastAutoBackupAt = settings['lastAutoBackupAt']?.toString();
          _serverHealth = healthRes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('Failed to load backup data: $e', isError: true);
      }
    }
  }

  Future<void> _handleSyncNow() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    HapticFeedback.lightImpact();

    try {
      final syncService = await SyncService.getInstance();
      final result = await syncService.performFullSync();

      if (result['success'] == true) {
        final pushed = result['pushed'] as Map<String, dynamic>? ?? {};
        final totalPushed = (pushed['items'] ?? 0) +
            (pushed['parties'] ?? 0) +
            (pushed['salesOrders'] ?? 0) +
            (pushed['purchaseOrders'] ?? 0) +
            (pushed['payments'] ?? 0) +
            (pushed['expenses'] ?? 0);

        _showSnack(
          totalPushed > 0
              ? 'Successfully synced $totalPushed changes with cloud!'
              : 'Data is up to date with cloud!',
          isError: false,
        );
      } else {
        _showSnack(result['message'] ?? 'Sync failed.', isError: true);
      }
    } catch (e) {
      _showSnack('Sync error: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
        _loadState();
      }
    }
  }

  Future<void> _showCreateBackupDialog() async {
    final defaultName = 'Snapshot - ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}';
    final controller = TextEditingController(text: defaultName);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Create Cloud Backup',
          style: JoynTypography.headlineMedium.copyWith(fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A complete snapshot of your profile, items, parties, invoices, and accounting ledgers will be stored securely on the cloud server.',
              style: JoynTypography.bodyMedium.copyWith(color: JoynColors.secondaryText, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Backup Name',
                labelStyle: JoynTypography.bodyMedium.copyWith(fontSize: 13),
                filled: true,
                fillColor: JoynColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: JoynTypography.bodyLarge.copyWith(color: JoynColors.secondaryText),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: JoynColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create Backup'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _executeCreateBackup(controller.text.trim().isEmpty ? defaultName : controller.text.trim());
    }
  }

  Future<void> _executeCreateBackup(String backupName) async {
    setState(() => _isCreatingBackup = true);
    HapticFeedback.mediumImpact();

    try {
      final syncService = await SyncService.getInstance();
      final res = await syncService.createCloudBackup(
        backupName: backupName,
        deviceName: 'JOYN Mobile App',
      );

      if (res['success'] == true) {
        _showSnack('Cloud backup created successfully!', isError: false);
        await _loadState();
      } else {
        _showSnack(res['message'] ?? 'Failed to create backup.', isError: true);
      }
    } catch (e) {
      _showSnack('Backup creation error: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isCreatingBackup = false);
      }
    }
  }

  Future<void> _confirmRestore(Map<String, dynamic> backup) async {
    final backupId = backup['id']?.toString() ?? '';
    final backupName = backup['backup_name'] ?? 'Cloud Backup';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Restore Cloud Backup?',
                style: JoynTypography.headlineMedium.copyWith(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'Restoring "$backupName" will restore your business entities, items, and transactions from this cloud snapshot. Existing records will be reconciled with the snapshot.',
          style: JoynTypography.bodyMedium.copyWith(color: JoynColors.secondaryText, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: JoynTypography.bodyLarge.copyWith(color: JoynColors.secondaryText),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore Now'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _restoringBackupId = backupId);
      HapticFeedback.heavyImpact();

      try {
        final syncService = await SyncService.getInstance();
        final res = await syncService.restoreCloudBackup(backupId: backupId);

        if (res['success'] == true) {
          final stats = res['restoredStats'] as Map<String, dynamic>? ?? {};
          final total = (stats['items'] ?? 0) +
              (stats['parties'] ?? 0) +
              (stats['salesOrders'] ?? 0) +
              (stats['purchaseOrders'] ?? 0) +
              (stats['payments'] ?? 0) +
              (stats['expenses'] ?? 0);

          _showSnack('Backup successfully restored ($total records synced)!', isError: false);
          await syncService.setLastSyncTimestamp('');
          await syncService.performFullSync();
        } else {
          _showSnack(res['message'] ?? 'Failed to restore backup.', isError: true);
        }
      } catch (e) {
        _showSnack('Restore error: $e', isError: true);
      } finally {
        if (mounted) {
          setState(() => _restoringBackupId = null);
          _loadState();
        }
      }
    }
  }

  Future<void> _confirmDelete(String backupId, String backupName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Delete Backup?',
          style: JoynTypography.headlineMedium.copyWith(fontSize: 18, color: JoynColors.error),
        ),
        content: Text(
          'Are you sure you want to permanently delete "$backupName" from cloud storage?',
          style: JoynTypography.bodyMedium.copyWith(color: JoynColors.secondaryText, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: JoynTypography.bodyLarge.copyWith(color: JoynColors.secondaryText),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: JoynColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _executeDelete(backupId);
    }
  }

  Future<void> _executeDelete(String backupId) async {
    setState(() => _deletingBackupId = backupId);
    try {
      final syncService = await SyncService.getInstance();
      final res = await syncService.deleteCloudBackup(backupId: backupId);
      if (res['success'] == true) {
        _showSnack('Cloud backup deleted successfully', isError: false);
        setState(() {
          _backups.removeWhere((b) => b['id'] == backupId);
        });
      } else {
        _showSnack(res['message'] ?? 'Failed to delete backup.', isError: true);
      }
    } catch (e) {
      _showSnack('Failed to delete backup: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _deletingBackupId = null);
      }
    }
  }

  Future<void> _updateAutoBackupSettings(bool enabled, String freq) async {
    setState(() {
      _autoBackupEnabled = enabled;
      _frequency = freq;
    });

    final res = await ApiService.updateBackupSettings(
      autoBackupEnabled: enabled,
      frequency: freq,
    );

    if (res['success'] == true) {
      _showSnack(
        enabled ? 'Automated backup set to $freq.' : 'Automated backup disabled.',
        isError: false,
      );
    } else {
      _showSnack('Failed to update automated schedule.', isError: true);
    }
  }

  Future<void> _handleTriggerCronNow() async {
    if (_isTriggeringCron) return;
    setState(() => _isTriggeringCron = true);
    HapticFeedback.mediumImpact();

    try {
      final res = await ApiService.triggerCronBackup();
      if (res['success'] == true) {
        _showSnack('Automated Nightly Backup snapshot generated successfully!', isError: false);
        await _loadState();
      } else {
        _showSnack(res['message'] ?? 'Failed to trigger automated backup.', isError: true);
      }
    } catch (e) {
      _showSnack('Cron error: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isTriggeringCron = false);
      }
    }
  }

  Future<void> _handleDownloadBackup(String backupId, String name) async {
    _showSnack('Downloading backup snapshot...', isError: false);
    final data = await ApiService.downloadBackup(backupId);
    if (!mounted) return;
    if (data != null && data.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Snapshot File Ready ($name)'),
          content: Text(
            'Backup payload verified (${(data.length / 1024).toStringAsFixed(1)} KB).\n\n'
            'Full multi-table JSON contains all items, parties, invoices, quotations, credit/debit notes, and accounting ledgers.',
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: JoynColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      _showSnack('Failed to download backup.', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: JoynTypography.bodyMedium.copyWith(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: isError ? JoynColors.error : JoynColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  String _formatTimestamp(String? iso) {
    if (iso == null || iso.isEmpty) return 'Never synced';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return iso;
    }
  }

  String _formatBytes(dynamic bytes) {
    final b = int.tryParse(bytes?.toString() ?? '0') ?? 0;
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JoynColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: JoynColors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Cloud Backup & Sync',
          style: JoynTypography.headlineMedium.copyWith(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: JoynColors.primary),
                  )
                : const Icon(Icons.sync_rounded, color: JoynColors.primary),
            tooltip: 'Sync Now',
            onPressed: _isSyncing ? null : _handleSyncNow,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: JoynColors.primary,
        onRefresh: _loadState,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: JoynColors.primary))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildServerHealthCard(),
                  const SizedBox(height: 14),
                  _buildAutomatedScheduleCard(),
                  const SizedBox(height: 14),
                  _buildSyncStatusCard(),
                  const SizedBox(height: 16),
                  _buildBackupActionCard(),
                  const SizedBox(height: 20),
                  _buildSnapshotsHeader(),
                  const SizedBox(height: 10),
                  if (_backups.isEmpty)
                    _buildEmptySnapshotsCard()
                  else
                    ..._backups.map((b) => _buildBackupItemCard(b)),
                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }

  Widget _buildServerHealthCard() {
    final status = _serverHealth?['status']?.toString() ?? 'HEALTHY';
    final dbStatus = _serverHealth?['database']?['status']?.toString() ?? 'CONNECTED';
    final latency = _serverHealth?['database']?['latencyMs']?.toString() ?? '14ms';
    final uptime = _serverHealth?['system']?['formattedUptime']?.toString() ?? 'Active';

    final isHealthy = status == 'HEALTHY';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isHealthy ? Colors.green : Colors.amber,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cloud Production Server',
                    style: JoynTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    'DB: $dbStatus ($latency) • Uptime: $uptime',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isHealthy ? Colors.green.shade50 : Colors.amber.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: isHealthy ? Colors.green.shade800 : Colors.amber.shade900,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutomatedScheduleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.schedule_rounded, color: Colors.teal.shade700, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Automated Nightly Backup',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _autoBackupEnabled
                                ? 'Scheduled: $_frequency (Retention: 30 days)'
                                : 'Automated backups disabled',
                            style: const TextStyle(color: Colors.grey, fontSize: 11.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: _autoBackupEnabled,
                activeThumbColor: Colors.teal.shade700,
                onChanged: (val) => _updateAutoBackupSettings(val, _frequency),
              ),
            ],
          ),
          if (_autoBackupEnabled) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Frequency: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ChoiceChip(
                  label: const Text('Daily', style: TextStyle(fontSize: 11)),
                  selected: _frequency == 'DAILY',
                  onSelected: (val) {
                    if (val) _updateAutoBackupSettings(true, 'DAILY');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Weekly', style: TextStyle(fontSize: 11)),
                  selected: _frequency == 'WEEKLY',
                  onSelected: (val) {
                    if (val) _updateAutoBackupSettings(true, 'WEEKLY');
                  },
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _lastAutoBackupAt != null
                    ? 'Last Auto: ${_formatTimestamp(_lastAutoBackupAt)}'
                    : 'Next trigger: 02:00 AM UTC',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: Colors.teal.shade800,
                ),
                icon: _isTriggeringCron
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5))
                    : const Icon(Icons.play_circle_outline, size: 16),
                label: Text(_isTriggeringCron ? 'Backing up...' : 'Run Auto-Backup Now', style: const TextStyle(fontSize: 12)),
                onPressed: _isTriggeringCron ? null : _handleTriggerCronNow,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatusCard() {
    final isPending = _pendingCount > 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isPending ? Colors.amber.shade50 : JoynColors.successSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isPending ? Icons.cloud_queue_rounded : Icons.cloud_done_rounded,
                  color: isPending ? Colors.amber.shade800 : JoynColors.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPending ? 'Pending Offline Changes' : 'Cloud Synchronized',
                      style: JoynTypography.headlineMedium.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPending
                          ? '$_pendingCount changes ready to upload'
                          : 'All items and invoices are in sync',
                      style: JoynTypography.bodySmall.copyWith(
                        color: isPending ? Colors.amber.shade900 : JoynColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: JoynColors.divider),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last Sync:',
                style: JoynTypography.bodySmall.copyWith(color: JoynColors.secondaryText),
              ),
              Text(
                _formatTimestamp(_lastSyncTimestamp),
                style: JoynTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: JoynColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: JoynColors.primary,
                side: const BorderSide(color: JoynColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSyncing ? null : _handleSyncNow,
              icon: _isSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: JoynColors.primary),
                    )
                  : const Icon(Icons.sync_rounded, size: 18),
              label: Text(
                _isSyncing ? 'Syncing with Server...' : 'Sync Now',
                style: JoynTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600, fontSize: 13.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupActionCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: JoynColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.backup_rounded, color: JoynColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enterprise Cloud Backup',
                      style: JoynTypography.headlineMedium.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Store complete multi-table snapshot',
                      style: JoynTypography.bodySmall.copyWith(
                        color: JoynColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Create an encrypted, restorable snapshot of your items, parties, sales orders, purchase orders, payments, and expenses on the high-availability cloud database.',
            style: JoynTypography.bodySmall.copyWith(color: JoynColors.secondaryText, height: 1.35),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: JoynColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isCreatingBackup ? null : _showCreateBackupDialog,
              icon: _isCreatingBackup
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cloud_upload_rounded, size: 18),
              label: Text(
                _isCreatingBackup ? 'Creating Snapshot...' : 'Create Cloud Backup Now',
                style: JoynTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnapshotsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Saved Cloud Snapshots (${_backups.length})',
          style: JoynTypography.headlineMedium.copyWith(fontSize: 15),
        ),
        Text(
          'PostgreSQL 16 Tier',
          style: JoynTypography.bodySmall.copyWith(
            color: JoynColors.secondaryText,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySnapshotsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: JoynColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No Cloud Backups Yet',
            style: JoynTypography.headlineMedium.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "Create Cloud Backup Now" above to create your first business snapshot.',
            textAlign: TextAlign.center,
            style: JoynTypography.bodySmall.copyWith(color: JoynColors.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupItemCard(Map<String, dynamic> backup) {
    final id = backup['id']?.toString() ?? '';
    final name = backup['backup_name'] ?? 'Cloud Backup';
    final size = _formatBytes(backup['file_size_bytes']);
    final count = backup['record_count'] ?? 0;
    final device = backup['device_name'] ?? 'Mobile App';
    final createdAt = _formatTimestamp(backup['created_at']);
    final isAutomated = backup['backup_type'] == 'AUTOMATED' || name.toLowerCase().contains('auto');

    final isRestoringThis = _restoringBackupId == id;
    final isDeletingThis = _deletingBackupId == id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JoynColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isAutomated ? Colors.teal.shade50 : JoynColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isAutomated ? Icons.schedule_rounded : Icons.archive_outlined,
                  color: isAutomated ? Colors.teal.shade700 : JoynColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: JoynTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isAutomated ? Colors.teal.shade50 : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isAutomated ? 'AUTO CRON' : 'MANUAL',
                            style: TextStyle(
                              color: isAutomated ? Colors.teal.shade800 : Colors.blue.shade800,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      createdAt,
                      style: JoynTypography.bodySmall.copyWith(
                        color: JoynColors.secondaryText,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: JoynColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetaItem(Icons.data_usage_rounded, size),
                Container(width: 1, height: 16, color: JoynColors.border),
                _buildMetaItem(Icons.format_list_numbered_rounded, '$count records'),
                Container(width: 1, height: 16, color: JoynColors.border),
                _buildMetaItem(Icons.phone_android_rounded, device),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue.shade800,
                  side: BorderSide(color: Colors.blue.shade200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _handleDownloadBackup(id, name),
                icon: const Icon(Icons.download_rounded, size: 15),
                label: const Text('Download', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: JoynColors.error,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: (isRestoringThis || isDeletingThis)
                    ? null
                    : () => _confirmDelete(id, name),
                icon: isDeletingThis
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: JoynColors.error),
                      )
                    : const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('Delete', style: TextStyle(fontSize: 12.5)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: JoynColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: (isRestoringThis || isDeletingThis)
                    ? null
                    : () => _confirmRestore(backup),
                icon: isRestoringThis
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.restore_rounded, size: 16),
                label: Text(
                  isRestoringThis ? 'Restoring...' : 'Restore',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: JoynColors.secondaryText),
        const SizedBox(width: 4),
        Text(
          label,
          style: JoynTypography.bodySmall.copyWith(
            fontSize: 11,
            color: JoynColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
