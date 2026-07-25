import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/event_model.dart';
import '../../models/invitation_template.dart';
import '../../providers/events_provider.dart';
import '../../theme/app_theme.dart';

class InvitationCardScreen extends StatefulWidget {
  final String eventId;
  const InvitationCardScreen({super.key, required this.eventId});

  @override
  State<InvitationCardScreen> createState() => _InvitationCardScreenState();
}

class _InvitationCardScreenState extends State<InvitationCardScreen> {
  final _screenshotController = ScreenshotController();
  late TextEditingController _textController;
  String _templateId = 'template_1';
  String _fontFamily = 'Cairo';
  bool _saving = false;

  static const _fonts = ['Cairo', 'Amiri', 'Tajawal', 'Almarai'];

  @override
  void initState() {
    super.initState();
    final event = context.read<EventsProvider>().byId(widget.eventId);
    _templateId = event?.invitationTemplateId ?? 'template_1';
    _fontFamily = event?.invitationFontFamily ?? 'Cairo';
    _textController = TextEditingController(text: _defaultText(event));
  }

  String _defaultText(EventModel? event) {
    if (event == null) return '';
    if (event.invitationText.isNotEmpty) return event.invitationText;
    final df = DateFormat('EEEE d MMMM yyyy', 'ar');
    return 'يتشرف${event.type == EventType.wedding ? 'ون' : ''} بدعوتكم لحضور\n'
        '${event.name}\n\n'
        '📅 ${df.format(event.date)}\n'
        '🕐 الساعة ${event.time.format(context)}\n'
        '📍 ${event.location}\n\n'
        'حضوركم يشرفنا ويسعدنا';
  }

  Future<void> _persist() async {
    final event = context.read<EventsProvider>().byId(widget.eventId);
    if (event == null) return;
    event.invitationTemplateId = _templateId;
    event.invitationFontFamily = _fontFamily;
    event.invitationText = _textController.text;
    await context.read<EventsProvider>().addOrUpdate(event);
  }

  Future<void> _saveImage() async {
    setState(() => _saving = true);
    try {
      final bytes = await _screenshotController.capture(pixelRatio: 3);
      if (bytes == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/invitation_${widget.eventId}.png');
      await file.writeAsBytes(bytes);
      await _persist();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حفظ الصورة في: ${file.path}')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _shareImage() async {
    setState(() => _saving = true);
    try {
      final bytes = await _screenshotController.capture(pixelRatio: 3);
      if (bytes == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/invitation_share_${widget.eventId}.png');
      await file.writeAsBytes(bytes);
      await _persist();
      await Share.shareXFiles([XFile(file.path)], text: 'دعوة لحضور المناسبة');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final template = templateById(_templateId);
    return Scaffold(
      appBar: AppBar(
        title: const Text('بطاقة الدعوة'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: () async { await _persist(); if (mounted) Navigator.pop(context); }),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Screenshot(
                  controller: _screenshotController,
                  child: _InvitationCardPreview(
                    template: template,
                    text: _textController.text,
                    fontFamily: _fontFamily,
                  ),
                ),
              ),
            ),
          ),
          _TemplatePicker(
            selectedId: _templateId,
            onSelect: (id) => setState(() => _templateId = id),
          ),
          const Divider(height: 1),
          Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _ToolButton(
                    icon: Icons.text_fields,
                    label: 'النص',
                    onTap: () async {
                      final res = await showDialog<String>(
                        context: context,
                        builder: (ctx) => _TextEditDialog(initial: _textController.text),
                      );
                      if (res != null) setState(() => _textController.text = res);
                    },
                  ),
                ),
                Expanded(
                  child: _ToolButton(
                    icon: Icons.font_download_outlined,
                    label: 'الخط',
                    onTap: () async {
                      final res = await showModalBottomSheet<String>(
                        context: context,
                        builder: (ctx) => _FontPickerSheet(fonts: _fonts, current: _fontFamily),
                      );
                      if (res != null) setState(() => _fontFamily = res);
                    },
                  ),
                ),
                Expanded(
                  child: _ToolButton(
                    icon: Icons.palette_outlined,
                    label: 'الألوان',
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (ctx) => _TemplatePicker(selectedId: _templateId, onSelect: (id) { setState(() => _templateId = id); Navigator.pop(ctx); }, big: true),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: _ToolButton(
                    icon: Icons.download_rounded,
                    label: 'حفظ الصورة',
                    onTap: _saving ? null : _saveImage,
                  ),
                ),
                Expanded(
                  child: _ToolButton(
                    icon: Icons.share_rounded,
                    label: 'مشاركة',
                    onTap: _saving ? null : _shareImage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvitationCardPreview extends StatelessWidget {
  final InvitationTemplate template;
  final String text;
  final String fontFamily;

  const _InvitationCardPreview({required this.template, required this.text, required this.fontFamily});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: template.backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: template.borderColor, width: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(template.decorIcon, color: template.borderColor, size: 36),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.getFont(
              fontFamily,
              color: template.textColor,
              fontSize: 16,
              height: 1.7,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Icon(template.decorIcon, color: template.borderColor, size: 24),
        ],
      ),
    );
  }
}

class _TemplatePicker extends StatelessWidget {
  final String selectedId;
  final ValueChanged<String> onSelect;
  final bool big;
  const _TemplatePicker({required this.selectedId, required this.onSelect, this.big = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(vertical: 10),
      height: big ? 130 : 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: kInvitationTemplates.map((t) {
          final selected = t.id == selectedId;
          return GestureDetector(
            onTap: () => onSelect(t.id),
            child: Container(
              width: big ? 90 : 60,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: t.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? AppColors.primary : t.borderColor, width: selected ? 2.5 : 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(t.decorIcon, color: t.borderColor, size: big ? 26 : 18),
                  if (big) ...[
                    const SizedBox(height: 6),
                    Text(t.name, style: TextStyle(fontSize: 10, color: t.textColor)),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _ToolButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _TextEditDialog extends StatefulWidget {
  final String initial;
  const _TextEditDialog({required this.initial});

  @override
  State<_TextEditDialog> createState() => _TextEditDialogState();
}

class _TextEditDialogState extends State<_TextEditDialog> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تعديل نص الدعوة'),
      content: TextField(
        controller: _ctrl,
        maxLines: 8,
        textAlign: TextAlign.right,
        decoration: const InputDecoration(hintText: 'اكتب نص بطاقة الدعوة هنا'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () => Navigator.pop(context, _ctrl.text), child: const Text('حفظ')),
      ],
    );
  }
}

class _FontPickerSheet extends StatelessWidget {
  final List<String> fonts;
  final String current;
  const _FontPickerSheet({required this.fonts, required this.current});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: fonts
            .map((f) => ListTile(
                  title: Text(f, textAlign: TextAlign.right, style: GoogleFonts.getFont(f)),
                  trailing: f == current ? const Icon(Icons.check, color: AppColors.primary) : null,
                  onTap: () => Navigator.pop(context, f),
                ))
            .toList(),
      ),
    );
  }
}
