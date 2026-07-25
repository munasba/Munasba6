import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/event_model.dart';
import '../../providers/events_provider.dart';
import '../../theme/app_theme.dart';

class CreateEventScreen extends StatefulWidget {
  final EventModel? existing;
  const CreateEventScreen({super.key, this.existing});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  EventType _type = EventType.wedding;
  DateTime? _date;
  TimeOfDay? _time;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameController.text = e.name;
      _locationController.text = e.location;
      _notesController.text = e.notes;
      _type = e.type;
      _date = e.date;
      _time = e.time;
      _imagePath = e.imagePath;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _imagePath = picked.path);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      locale: const Locale('ar'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty || _date == null || _time == null || _locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تعبئة الاسم والتاريخ والوقت والمكان')),
      );
      return;
    }
    final event = EventModel(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      type: _type,
      date: _date!,
      time: _time!,
      location: _locationController.text.trim(),
      notes: _notesController.text.trim(),
      imagePath: _imagePath,
      invitationTemplateId: widget.existing?.invitationTemplateId ?? 'template_1',
      invitationText: widget.existing?.invitationText,
      invitationFontFamily: widget.existing?.invitationFontFamily ?? 'Cairo',
      invitationBackgroundColorValue: widget.existing?.invitationBackgroundColorValue ?? 0xFFFDF3F1,
    );
    await context.read<EventsProvider>().addOrUpdate(event);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'إنشاء مناسبة جديدة' : 'تعديل المناسبة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppColors.accentPink.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(24),
                    image: (_imagePath != null && File(_imagePath!).existsSync())
                        ? DecorationImage(image: FileImage(File(_imagePath!)), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _imagePath == null
                      ? const Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 32)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(child: Text('إضافة صورة', style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
            const SizedBox(height: 20),
            const Text('اسم المناسبة', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(hintText: 'مثال: حفل زفاف أحمد وسارة'),
            ),
            const SizedBox(height: 16),
            const Text('نوع المناسبة', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<EventType>(
              value: _type,
              decoration: const InputDecoration(),
              items: EventType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _PickerTile(
                    icon: Icons.calendar_today_rounded,
                    label: _date == null ? 'التاريخ' : '${_date!.year}/${_date!.month}/${_date!.day}',
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerTile(
                    icon: Icons.access_time_rounded,
                    label: _time == null ? 'الوقت' : _time!.format(context),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('المكان', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(hintText: 'مثال: قاعة اللؤلؤة - المدينة'),
            ),
            const SizedBox(height: 16),
            const Text('ملاحظات (اختياري)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              textAlign: TextAlign.right,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'ملاحظات إضافية...'),
            ),
            const SizedBox(height: 28),
            ElevatedButton(onPressed: _save, child: const Text('حفظ المناسبة')),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PickerTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accentPink.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}
