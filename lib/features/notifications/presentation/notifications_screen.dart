import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/api_service.dart';
import '../models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  String _selectedFilter = 'ALL'; // ALL, UNREAD, LOW_STOCK_ALERT, PAYMENT_REMINDER, SYSTEM

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void dispose() {
    // Ensure all viewed notifications are permanently marked read on cloud
    ApiService.markAllNotificationsRead().catchError((_) => <String, dynamic>{});
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getNotifications(limit: 100);
      if (res['success'] == true) {
        final list = (res['notifications'] as List<dynamic>? ?? [])
            .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
            .toList();
        final hasUnread = list.any((n) => !n.isRead);

        if (mounted) {
          setState(() {
            _notifications = list;
            _unreadCount = res['unreadCount'] ?? list.where((n) => !n.isRead).length;
            _isLoading = false;
          });
        }

        // Auto-mark as read when user opens and views the notifications feed
        if (hasUnread) {
          ApiService.markAllNotificationsRead().catchError((_) => <String, dynamic>{});
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(NotificationModel notif) async {
    if (notif.isRead) return;
    try {
      await ApiService.markNotificationRead(notif.id);
      setState(() {
        final idx = _notifications.indexWhere((n) => n.id == notif.id);
        if (idx != -1) {
          _notifications[idx] = _notifications[idx].copyWith(isRead: true);
          if (_unreadCount > 0) _unreadCount--;
        }
      });
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    try {
      final res = await ApiService.markAllNotificationsRead();
      if (res['success'] == true) {
        setState(() {
          _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
          _unreadCount = 0;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All notifications marked as read'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _deleteNotification(NotificationModel notif) async {
    final idx = _notifications.indexOf(notif);
    setState(() {
      _notifications.removeAt(idx);
      if (!notif.isRead && _unreadCount > 0) _unreadCount--;
    });
    try {
      await ApiService.deleteNotification(notif.id);
    } catch (_) {}
  }

  Future<void> _triggerLowStockScan() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Scanning inventory stock levels...'),
          ],
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final res = await ApiService.checkLowStockAlerts();
    if (!mounted) return;

    if (res['success'] == true) {
      final created = res['createdAlerts'] ?? 0;
      final count = res['lowStockCount'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            created > 0
                ? 'Scan complete: $created new low stock alert(s) generated!'
                : 'Stock levels verified: $count item(s) below threshold.',
          ),
          backgroundColor: const Color(0xFF4338CA),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadNotifications();
    }
  }

  List<NotificationModel> get _filteredNotifications {
    if (_selectedFilter == 'UNREAD') {
      return _notifications.where((n) => !n.isRead).toList();
    } else if (_selectedFilter != 'ALL') {
      return _notifications.where((n) => n.type == _selectedFilter).toList();
    }
    return _notifications;
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'LOW_STOCK_ALERT':
        return const Color(0xFFEF4444); // Red
      case 'PAYMENT_REMINDER':
        return const Color(0xFF6366F1); // Indigo
      case 'SALE':
      case 'PAYMENT':
        return const Color(0xFF10B981); // Emerald
      case 'SYSTEM':
      default:
        return const Color(0xFF3B82F6); // Blue
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'LOW_STOCK_ALERT':
        return Icons.inventory_2_outlined;
      case 'PAYMENT_REMINDER':
        return Icons.currency_rupee_rounded;
      case 'SALE':
        return Icons.receipt_long_rounded;
      case 'PAYMENT':
        return Icons.account_balance_wallet_outlined;
      case 'SYSTEM':
      default:
        return Icons.notifications_active_outlined;
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM, hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredNotifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount new',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Scan Low Stock',
            icon: const Icon(Icons.radar_rounded, color: Color(0xFF4338CA)),
            onPressed: _triggerLowStockScan,
          ),
          if (_notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
              onSelected: (val) {
                if (val == 'mark_all_read') _markAllAsRead();
                if (val == 'refresh') _loadNotifications();
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.done_all_rounded, size: 18, color: Color(0xFF4338CA)),
                      SizedBox(width: 10),
                      Text('Mark all as read'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF64748B)),
                      SizedBox(width: 10),
                      Text('Refresh feed'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          _buildFilterBar(),

          // Notifications List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4338CA),
                      strokeWidth: 2.5,
                    ),
                  )
                : RefreshIndicator(
                    color: const Color(0xFF4338CA),
                    onRefresh: _loadNotifications,
                    child: filtered.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: filtered.length,
                            separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                            itemBuilder: (ctx, index) {
                              final notif = filtered[index];
                              return _buildNotificationCard(notif);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = [
      {'key': 'ALL', 'label': 'All'},
      {'key': 'UNREAD', 'label': 'Unread ($_unreadCount)'},
      {'key': 'LOW_STOCK_ALERT', 'label': 'Stock Alerts'},
      {'key': 'PAYMENT_REMINDER', 'label': 'Reminders'},
      {'key': 'SYSTEM', 'label': 'System'},
    ];

    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (ctx, i) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final f = filters[i];
          final isSelected = _selectedFilter == f['key'];
          return ChoiceChip(
            selected: isSelected,
            label: Text(
              f['label']!,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF475569),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
            selectedColor: const Color(0xFF4338CA),
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected ? const Color(0xFF4338CA) : const Color(0xFFE2E8F0),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onSelected: (val) {
              if (val) setState(() => _selectedFilter = f['key']!);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notif) {
    final color = _getTypeColor(notif.type);
    final icon = _getTypeIcon(notif.type);

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
      ),
      onDismissed: (_) => _deleteNotification(notif),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          _markAsRead(notif);
          _showDetailModal(notif);
        },
        child: Container(
          decoration: BoxDecoration(
            color: notif.isRead ? Colors.white : const Color(0xFFF1F5F9).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: notif.isRead ? const Color(0xFFE2E8F0) : color.withValues(alpha: 0.3),
              width: notif.isRead ? 1 : 1.5,
            ),
            boxShadow: notif.isRead
                ? []
                : [
                    BoxShadow(
                      color: color.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Badge
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),

              // Title, body and time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              color: const Color(0xFF0F172A),
                              fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (!notif.isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.body,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 13,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(notif.createdAt),
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailModal(NotificationModel notif) {
    final color = _getTypeColor(notif.type);
    final icon = _getTypeIcon(notif.type);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modal pill handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notif.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTime(notif.createdAt),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  notif.body,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.share_outlined, size: 18, color: Color(0xFF475569)),
                      label: const Text('Share Text', style: TextStyle(color: Color(0xFF475569))),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Share.share('${notif.title}\n\n${notif.body}');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4338CA),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 18, color: Colors.white),
                      label: const Text('Copy Text', style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: '${notif.title}\n\n${notif.body}'));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notification copied to clipboard'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 36,
              color: Color(0xFF4338CA),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'All Caught Up!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'No notifications in this filter category.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4338CA),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: const Icon(Icons.radar_rounded, size: 18, color: Colors.white),
            label: const Text('Scan Low Stock Alert', style: TextStyle(color: Colors.white, fontSize: 13)),
            onPressed: _triggerLowStockScan,
          ),
        ],
      ),
    );
  }
}

