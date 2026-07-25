import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/events_provider.dart';
import '../../providers/guests_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/countdown_timer.dart';
import '../../models/event_model.dart';
import '../guests/guests_screen.dart';
import '../invitation/invitation_card_screen.dart';
import 'create_event_screen.dart';

class EventDetailScreen extends StatelessWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final eventsProvider = context.watch<EventsProvider>();
    final event = eventsProvider.byId(eventId);
    if (event == null) {
      return const Scaffold(body: Center(child: Text('المناسبة غير موجودة')));
    }
    final guestsProvider = context.watch<GuestsProvider>();
    final stats = guestsProvider.statsForEvent(event.id);
    final df = DateFormat('EEEE d MMMM yyyy', 'ar');

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المناسبة'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'edit') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CreateEventScreen(existing: event)),
                );
              } else if (v == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('حذف المناسبة'),
                    content: const Text('هل أنت متأكد من حذف هذه المناسبة وكل بيانات المدعوين المرتبطة بها؟'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: AppColors.danger))),
                    ],
                  ),
                );
                if (confirm == true) {
                  await context.read<GuestsProvider>().deleteForEvent(event.id);
                  await context.read<EventsProvider>().delete(event.id);
                  if (context.mounted) Navigator.of(context).pop();
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('تعديل')),
              PopupMenuItem(value: 'delete', child: Text('حذف')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: (event.imagePath != null && File(event.imagePath!).existsSync())
                ? Image.file(File(event.imagePath!), height: 180, width: double.infinity, fit: BoxFit.cover)
                : Container(
                    height: 180,
                    width: double.infinity,
                    color: AppColors.accentPink.withOpacity(0.4),
                    child: Icon(event.type.icon, size: 56, color: AppColors.primary),
                  ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Text(event.type.label, style: const TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Text(event.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(child: CountdownTimer(targetDate: event.dateTime)),
          const SizedBox(height: 24),
          _InfoRow(icon: Icons.calendar_today_rounded, label: 'التاريخ', value: df.format(event.date)),
          _InfoRow(icon: Icons.access_time_rounded, label: 'الوقت', value: event.time.format(context)),
          _InfoRow(icon: Icons.location_on_rounded, label: 'المكان', value: event.location),
          _InfoRow(icon: Icons.people_alt_rounded, label: 'عدد المدعوين', value: '${stats['total']} مدعو'),
          if (event.notes.isNotEmpty)
            _InfoRow(icon: Icons.notes_rounded, label: 'ملاحظات', value: event.notes),
          const SizedBox(height: 20),
          _StatsCard(stats: stats),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => GuestsScreen(eventId: event.id)),
                  ),
                  icon: const Icon(Icons.people_outline),
                  label: const Text('المدعوون'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => InvitationCardScreen(eventId: event.id)),
                  ),
                  icon: const Icon(Icons.card_giftcard_rounded),
                  label: const Text('بطاقة الدعوة'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const Spacer(),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final Map<String, int> stats;
  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerRight,
            child: Text('إحصائية الدعوات', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatItem(label: 'تمت دعوتهم', value: stats['invited'] ?? 0, color: AppColors.success),
              _StatItem(label: 'تم الاتصال بهم', value: stats['called'] ?? 0, color: AppColors.gold),
              _StatItem(label: 'لم تتم دعوتهم', value: stats['notInvited'] ?? 0, color: AppColors.danger),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$value', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}
