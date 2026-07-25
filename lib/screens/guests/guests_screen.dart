import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/guest_model.dart';
import '../../providers/guests_provider.dart';
import '../../services/contacts_service.dart';
import '../../theme/app_theme.dart';

/// إذا كان eventId = null فهذه شاشة "كل المدعوين" العامة (تظهر ضمن التنقل السفلي)
/// وإلا فهي مدعوو مناسبة محددة (تُفتح من تفاصيل المناسبة)
class GuestsScreen extends StatefulWidget {
  final String? eventId;
  const GuestsScreen({super.key, required this.eventId});

  @override
  State<GuestsScreen> createState() => _GuestsScreenState();
}

class _GuestsScreenState extends State<GuestsScreen> {
  String _query = '';
  GuestRelation? _filter;

  Future<void> _importFromContacts(String eventId) async {
    final contacts = await AppContactsService.fetchContacts();
    if (!mounted) return;
    if (contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر الوصول لجهات الاتصال أو لا توجد جهات اتصال')),
      );
      return;
    }
    final selected = await showModalBottomSheet<List<GuestModel>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ContactsPickerSheet(contacts: contacts, eventId: eventId),
    );
    if (selected != null && selected.isNotEmpty) {
      await context.read<GuestsProvider>().addMany(selected);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تمت إضافة ${selected.length} مدعو من جهات الاتصال')),
        );
      }
    }
  }

  Future<void> _addManual(String eventId) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    GuestRelation relation = GuestRelation.friend;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('إضافة مدعو'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, textAlign: TextAlign.right, decoration: const InputDecoration(hintText: 'الاسم')),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, textAlign: TextAlign.right, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'رقم الهاتف')),
              const SizedBox(height: 10),
              DropdownButtonFormField<GuestRelation>(
                value: relation,
                items: GuestRelation.values.map((r) => DropdownMenuItem(value: r, child: Text(r.label))).toList(),
                onChanged: (v) => setSt(() => relation = v ?? relation),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إضافة')),
          ],
        ),
      ),
    );
    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      await context.read<GuestsProvider>().add(GuestModel(
            id: const Uuid().v4(),
            eventId: eventId,
            name: nameCtrl.text.trim(),
            phone: phoneCtrl.text.trim(),
            relation: relation,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GuestsProvider>();
    final effectiveEventId = widget.eventId ?? '';
    final isGeneral = widget.eventId == null;

    List<GuestModel> list = isGeneral
        ? provider.all
        : provider.searchInEvent(effectiveEventId, _query);
    if (isGeneral && _query.isNotEmpty) {
      list = list.where((g) => g.name.contains(_query) || g.phone.contains(_query)).toList();
    }
    if (_filter != null) {
      list = list.where((g) => g.relation == _filter).toList();
    }

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (isGeneral)
                const Align(alignment: Alignment.centerRight, child: Text('المدعوون', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
              if (isGeneral) const SizedBox(height: 12),
              TextField(
                textAlign: TextAlign.right,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(hintText: 'ابحث عن مدعو...', prefixIcon: Icon(Icons.search)),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  children: [
                    _FilterChip(label: 'الكل', selected: _filter == null, onTap: () => setState(() => _filter = null)),
                    ...GuestRelation.values.map((r) => _FilterChip(
                          label: r.label,
                          selected: _filter == r,
                          onTap: () => setState(() => _filter = r),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('لا يوجد مدعوون بعد', style: TextStyle(color: AppColors.textMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) => _GuestTile(guest: list[i]),
                ),
        ),
        if (!isGeneral)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _importFromContacts(effectiveEventId),
                    icon: const Icon(Icons.contact_phone_outlined),
                    label: const Text('من جهات الاتصال'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _addManual(effectiveEventId),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('إضافة مدعو'),
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    if (isGeneral) return body;
    return Scaffold(appBar: AppBar(title: const Text('المدعوون')), body: body);
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textDark, fontSize: 12),
        backgroundColor: AppColors.chipPink.withOpacity(0.5),
      ),
    );
  }
}

class _GuestTile extends StatelessWidget {
  final GuestModel guest;
  const _GuestTile({required this.guest});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.accentPink.withOpacity(0.6),
            child: Text(guest.name.isNotEmpty ? guest.name[0] : '?', style: const TextStyle(color: AppColors.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(guest.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${guest.relation.label} · ${guest.phone}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'تم الاتصال',
            icon: Icon(Icons.call, color: guest.called ? AppColors.gold : AppColors.textMuted, size: 20),
            onPressed: () => context.read<GuestsProvider>().toggleCalled(guest.id),
          ),
          Checkbox(
            value: guest.invited,
            activeColor: AppColors.success,
            onChanged: (_) => context.read<GuestsProvider>().toggleInvited(guest.id),
          ),
        ],
      ),
    );
  }
}

class _ContactsPickerSheet extends StatefulWidget {
  final List<Contact> contacts;
  final String eventId;
  const _ContactsPickerSheet({required this.contacts, required this.eventId});

  @override
  State<_ContactsPickerSheet> createState() => _ContactsPickerSheetState();
}

class _ContactsPickerSheetState extends State<_ContactsPickerSheet> {
  final Set<int> _selected = {};

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.accentPink, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 12),
            const Text('اختر جهات الاتصال', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: widget.contacts.length,
                itemBuilder: (ctx, i) {
                  final c = widget.contacts[i];
                  final phone = (c.phones.isNotEmpty) ? c.phones.first.number : '';
                  final selected = _selected.contains(i);
                  return CheckboxListTile(
                    value: selected,
                    onChanged: (_) => setState(() => selected ? _selected.remove(i) : _selected.add(i)),
                    title: Text(c.displayName, textAlign: TextAlign.right),
                    subtitle: Text(phone, textAlign: TextAlign.right),
                    activeColor: AppColors.primary,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  final list = _selected.map((i) {
                    final c = widget.contacts[i];
                    final phone = (c.phones.isNotEmpty) ? c.phones.first.number : '';
                    return GuestModel(
                      id: const Uuid().v4(),
                      eventId: widget.eventId,
                      name: c.displayName,
                      phone: phone,
                    );
                  }).toList();
                  Navigator.of(context).pop(list);
                },
                child: Text('إضافة (${_selected.length})'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
