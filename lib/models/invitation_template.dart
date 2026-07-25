import 'package:flutter/material.dart';

/// قالب بطاقة دعوة جاهز (تصميم حدود/زخرفة + ألوان)
class InvitationTemplate {
  final String id;
  final String name;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final IconData decorIcon;
  final Gradient? gradient;

  const InvitationTemplate({
    required this.id,
    required this.name,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.decorIcon,
    this.gradient,
  });
}

const List<InvitationTemplate> kInvitationTemplates = [
  InvitationTemplate(
    id: 'template_1',
    name: 'ورد كلاسيكي',
    backgroundColor: Color(0xFFFDF3F1),
    borderColor: Color(0xFFC98A94),
    textColor: Color(0xFF6E4350),
    decorIcon: Icons.local_florist,
  ),
  InvitationTemplate(
    id: 'template_2',
    name: 'ذهبي فاخر',
    backgroundColor: Color(0xFFFBF6EA),
    borderColor: Color(0xFFC9A15A),
    textColor: Color(0xFF5A4526),
    decorIcon: Icons.auto_awesome,
  ),
  InvitationTemplate(
    id: 'template_3',
    name: 'موف ملكي',
    backgroundColor: Color(0xFFF4EEF4),
    borderColor: Color(0xFF8E5A67),
    textColor: Color(0xFF4A2E36),
    decorIcon: Icons.diamond_outlined,
  ),
  InvitationTemplate(
    id: 'template_4',
    name: 'أزرق هادئ',
    backgroundColor: Color(0xFFEEF4F6),
    borderColor: Color(0xFF5A7E9C),
    textColor: Color(0xFF2C3E4A),
    decorIcon: Icons.nights_stay_outlined,
  ),
  InvitationTemplate(
    id: 'template_5',
    name: 'احتفالي',
    backgroundColor: Color(0xFFFDF0F5),
    borderColor: Color(0xFFD9668A),
    textColor: Color(0xFF5E2A3C),
    decorIcon: Icons.celebration,
  ),
];

InvitationTemplate templateById(String id) =>
    kInvitationTemplates.firstWhere((t) => t.id == id, orElse: () => kInvitationTemplates.first);
