import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ManasibaApp());
}

// ==================== APP THEME & COLORS ====================
class AppColors {
  static const Color primary = Color(0xFFA65D7A);
  static const Color primaryLight = Color(0xFFC98FA5);
  static const Color primaryDark = Color(0xFF7A3D56);
  static const Color background = Color(0xFFFFF8F8);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF5A3A4A);
  static const Color textSecondary = Color(0xFF8B6B7A);
  static const Color textMuted = Color(0xFFB8A0AA);
  static const Color divider = Color(0xFFF0E0E5);
  static const Color success = Color(0xFF6B9E75);
  static const Color warning = Color(0xFFE8B86D);
  static const Color cardBg = Color(0xFFFFFAFB);
  static const Color pinkLight = Color(0xFFFFE8EC);
  static const Color pinkMedium = Color(0xFFF5D5DD);
}

class AppStyles {
  static TextStyle get headlineLarge => const TextStyle(
        fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary, height: 1.2);
  static TextStyle get headlineMedium => const TextStyle(
        fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.3);
  static TextStyle get titleLarge => const TextStyle(
        fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static TextStyle get bodyLarge => const TextStyle(
        fontSize: 16, color: AppColors.textPrimary, height: 1.5);
  static TextStyle get bodyMedium => const TextStyle(
        fontSize: 14, color: AppColors.textSecondary, height: 1.4);
  static TextStyle get label => const TextStyle(
        fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500);
}

// ==================== MODELS ====================
class UserProfile {
  String name; String gender; String? imagePath;
  UserProfile({this.name = '', this.gender = 'male', this.imagePath});
  Map<String, dynamic> toJson() => {'name': name, 'gender': gender, 'imagePath': imagePath};
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] ?? '', gender: json['gender'] ?? 'male', imagePath: json['imagePath']);
}

class Guest {
  String id; String name; String phone; String category;
  bool isInvited; bool isContactImported; String? imagePath;
  Guest({required this.id, required this.name, required this.phone,
    this.category = 'الكل', this.isInvited = false, this.isContactImported = false, this.imagePath});
  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'phone': phone, 'category': category,
    'isInvited': isInvited, 'isContactImported': isContactImported, 'imagePath': imagePath};
  factory Guest.fromJson(Map<String, dynamic> json) => Guest(
    id: json['id'], name: json['name'], phone: json['phone'], category: json['category'] ?? 'الكل',
    isInvited: json['isInvited'] ?? false, isContactImported: json['isContactImported'] ?? false,
    imagePath: json['imagePath']);
}

class EventModel {
  String id; String name; String type; DateTime date; TimeOfDay time;
  String location; String? imagePath; String notes; List<Guest> guests;
  String invitationCardTemplate; String invitationText;
  Color invitationBgColor; String invitationFontFamily;

  EventModel({required this.id, required this.name, required this.type, required this.date,
    required this.time, required this.location, this.imagePath, this.notes = '', this.guests = const [],
    this.invitationCardTemplate = 'template1', this.invitationText = '',
    this.invitationBgColor = const Color(0xFFFFF8F8), this.invitationFontFamily = 'Cairo'});

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'type': type, 'date': date.toIso8601String(),
    'time': '${time.hour}:${time.minute}', 'location': location, 'imagePath': imagePath,
    'notes': notes, 'guests': guests.map((g) => g.toJson()).toList(),
    'invitationCardTemplate': invitationCardTemplate, 'invitationText': invitationText,
    'invitationBgColor': invitationBgColor.value, 'invitationFontFamily': invitationFontFamily};

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final tp = (json['time'] as String).split(':');
    return EventModel(
      id: json['id'], name: json['name'], type: json['type'],
      date: DateTime.parse(json['date']),
      time: TimeOfDay(hour: int.parse(tp[0]), minute: int.parse(tp[1])),
      location: json['location'], imagePath: json['imagePath'], notes: json['notes'] ?? '',
      guests: (json['guests'] as List?)?.map((g) => Guest.fromJson(g)).toList() ?? [],
      invitationCardTemplate: json['invitationCardTemplate'] ?? 'template1',
      invitationText: json['invitationText'] ?? '',
      invitationBgColor: Color(json['invitationBgColor'] ?? 0xFFFFF8F8),
      invitationFontFamily: json['invitationFontFamily'] ?? 'Cairo');
  }

  int get invitedCount => guests.where((g) => g.isInvited).length;
  int get notInvitedCount => guests.where((g) => !g.isInvited).length;
  int get totalGuests => guests.length;
  Duration get timeRemaining {
    final now = DateTime.now();
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    return dt.difference(now);
  }
}

// ==================== STORAGE SERVICE ====================
class StorageService {
  static SharedPreferences? _prefs;
  static Future<void> init() async { _prefs = await SharedPreferences.getInstance(); }
  static Future<void> saveUserProfile(UserProfile p) async =>
    await _prefs?.setString('user_profile', jsonEncode(p.toJson()));
  static UserProfile? getUserProfile() {
    final d = _prefs?.getString('user_profile');
    return d == null ? null : UserProfile.fromJson(jsonDecode(d));
  }
  static Future<void> setOnboardingComplete() async =>
    await _prefs?.setBool('onboarding_complete', true);
  static bool isOnboardingComplete() => _prefs?.getBool('onboarding_complete') ?? false;
  static Future<void> saveEvents(List<EventModel> events) async {
    await _prefs?.setStringList('events', events.map((e) => jsonEncode(e.toJson())).toList());
  }
  static List<EventModel> getEvents() {
    return (_prefs?.getStringList('events') ?? []).map((e) => EventModel.fromJson(jsonDecode(e))).toList();
  }
  static Future<void> saveDarkMode(bool v) async => await _prefs?.setBool('dark_mode', v);
  static bool isDarkMode() => _prefs?.getBool('dark_mode') ?? false;
}

// ==================== APP ====================
class ManasibaApp extends StatefulWidget {
  const ManasibaApp({super.key});
  @override State<ManasibaApp> createState() => _ManasibaAppState();
}

class _ManasibaAppState extends State<ManasibaApp> {
  bool _ready = false; bool _done = false;
  @override void initState() { super.initState(); _init(); }
  Future<void> _init() async {
    await StorageService.init();
    setState(() { _done = StorageService.isOnboardingComplete(); _ready = true; });
  }
  @override Widget build(BuildContext context) {
    if (!_ready) return MaterialApp(debugShowCheckedModeBanner: false,
      home: Scaffold(backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary))));
    return MaterialApp(debugShowCheckedModeBanner: false, title: 'مناسبة',
      theme: ThemeData(fontFamily: 'Cairo', useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, primary: AppColors.primary, background: AppColors.background),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(backgroundColor: AppColors.background, elevation: 0, centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
          titleTextStyle: TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary, unselectedItemColor: AppColors.textMuted, type: BottomNavigationBarType.fixed, elevation: 8),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
        inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
        cardTheme: CardTheme(color: AppColors.cardBg, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
      home: _done ? const MainScreen() : const OnboardingScreen());
  }
}

// ==================== ONBOARDING ====================
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pc = PageController();
  int _current = 0;
  final List<_OnbData> _pages = [
    _OnbData(title: 'مناسبة', subtitle: 'كل مناسبة تستحق ان تُنظم\nباجمل طريقة', showLogo: true),
    _OnbData(title: 'انشئ مناسباتك بسهولة', subtitle: 'اضف تفاصيل مناسبتك من تاريخ ومكان\nووصف في خطوات بسيطة', showCalendar: true),
    _OnbData(title: 'شارك دعوتك مع من تحب', subtitle: 'ارسل بطاقات الدعوة لمدعويك وشاركها\nبضغطة واحدة', showInvitation: true),
  ];

  void _next() {
    if (_current < _pages.length - 1) {
      _pc.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserSetupScreen()));
    }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.background,
      body: Stack(children: [
        Positioned(top: -20, left: -30, child: _flower()),
        Positioned(top: 40, right: -20, child: _flower(rotated: true)),
        Positioned(bottom: 80, left: -20, child: _flower()),
        Positioned(bottom: 120, right: -40, child: _flower(rotated: true)),
        SafeArea(child: Column(children: [
          Expanded(child: PageView.builder(controller: _pc,
            onPageChanged: (i) => setState(() => _current = i), itemCount: _pages.length,
            itemBuilder: (c, i) => _buildPage(_pages[i]))),
          _buildBottom(), const SizedBox(height: 24)]))]));
  }

  Widget _flower({bool rotated = false}) => Transform.rotate(angle: rotated ? 0.5 : -0.3,
    child: Opacity(opacity: 0.15, child: Icon(Icons.local_florist, size: 120, color: AppColors.primaryLight)));

  Widget _buildPage(_OnbData p) => Padding(padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Spacer(flex: 2),
      if (p.showLogo) ...[_buildLogo(), const SizedBox(height: 32)]
      else if (p.showCalendar) ...[_calIllust(), const SizedBox(height: 40)]
      else if (p.showInvitation) ...[_invIllust(), const SizedBox(height: 40)],
      Text(p.title, style: AppStyles.headlineLarge, textAlign: TextAlign.center),
      const SizedBox(height: 16),
      Text(p.subtitle, style: AppStyles.bodyLarge.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
      const Spacer(flex: 3)]));

  Widget _buildLogo() => Container(width: 140, height: 140,
    decoration: BoxDecoration(shape: BoxShape.circle,
      border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2)),
    child: Center(child: Stack(alignment: Alignment.center, children: [
      Icon(Icons.favorite, size: 80, color: AppColors.primary.withOpacity(0.2)),
      const Icon(Icons.people, size: 50, color: AppColors.primary),
      Positioned(top: 20, child: Icon(Icons.favorite, size: 20, color: AppColors.primaryDark))])));

  Widget _calIllust() => Container(width: 200, height: 200,
    decoration: BoxDecoration(color: AppColors.pinkLight, borderRadius: BorderRadius.circular(100),
      border: Border.all(color: AppColors.pinkMedium, width: 2)),
    child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.calendar_month, size: 80, color: AppColors.primary.withOpacity(0.8)),
      const SizedBox(height: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.favorite, color: Colors.white, size: 20))])));

  Widget _invIllust() => Container(width: 200, height: 200,
    decoration: BoxDecoration(color: AppColors.pinkLight, borderRadius: BorderRadius.circular(100),
      border: Border.all(color: AppColors.pinkMedium, width: 2)),
    child: Center(child: Stack(alignment: Alignment.center, children: [
      Icon(Icons.mail_outline, size: 90, color: AppColors.primary.withOpacity(0.6)),
      Positioned(top: 30, right: 40,
        child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          child: const Icon(Icons.share, color: Colors.white, size: 20)))])));

  Widget _buildBottom() => Padding(padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      TextButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserSetupScreen())),
        child: Text('تخطي', style: AppStyles.bodyMedium.copyWith(color: AppColors.textMuted))),
      Row(children: List.generate(_pages.length, (i) => Container(margin: const EdgeInsets.symmetric(horizontal: 4),
        width: _current == i ? 24 : 8, height: 8,
        decoration: BoxDecoration(color: _current == i ? AppColors.primary : AppColors.divider, borderRadius: BorderRadius.circular(4))))),
      GestureDetector(onTap: _next,
        child: Container(width: 56, height: 56, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          child: const Icon(Icons.arrow_forward_ios, color: Colors.white)))]));
}

class _OnbData { final String title, subtitle; final bool showLogo, showCalendar, showInvitation;
  _OnbData({required this.title, required this.subtitle, this.showLogo = false, this.showCalendar = false, this.showInvitation = false});
}

// ==================== USER SETUP ====================
class UserSetupScreen extends StatefulWidget {
  const UserSetupScreen({super.key});
  @override State<UserSetupScreen> createState() => _UserSetupScreenState();
}

class _UserSetupScreenState extends State<UserSetupScreen> {
  final _nameCtrl = TextEditingController(); String _gender = 'male'; File? _img; final _picker = ImagePicker();
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _img = File(image.path));
  }
  void _save() {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء ادخال اسمك'))); return;
    }
    StorageService.saveUserProfile(UserProfile(name: _nameCtrl.text.trim(), gender: _gender, imagePath: _img?.path));
    StorageService.setOnboardingComplete();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
  }
  @override Widget build(BuildContext context) => Scaffold(backgroundColor: AppColors.background,
    body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(32),
      child: Column(children: [
        const SizedBox(height: 40), Text('مرحبا بك', style: AppStyles.headlineLarge),
        const SizedBox(height: 8), Text('اخبرنا قليلا عن نفسك', style: AppStyles.bodyMedium),
        const SizedBox(height: 40), _avatar(), const SizedBox(height: 32), _nameField(),
        const SizedBox(height: 24), _genderSel(), const SizedBox(height: 48),
        SizedBox(width: double.infinity, height: 56,
          child: ElevatedButton(onPressed: _save,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), elevation: 0),
            child: const Text('ابدأ الان', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))))]))));

  Widget _avatar() => GestureDetector(onTap: _pickImage,
    child: Stack(alignment: Alignment.bottomRight, children: [
      Container(width: 140, height: 140, decoration: BoxDecoration(shape: BoxShape.circle,
        color: AppColors.pinkLight,
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 3),
        image: _img != null ? DecorationImage(image: FileImage(_img!), fit: BoxFit.cover) : null),
        child: _img == null ? Center(child: Icon(_gender == 'male' ? Icons.person : Icons.person_2,
          size: 70, color: AppColors.primary.withOpacity(0.5))) : null),
      Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
        child: const Icon(Icons.camera_alt, color: Colors.white, size: 22))]));

  Widget _nameField() => TextField(controller: _nameCtrl, textAlign: TextAlign.center,
    decoration: InputDecoration(hintText: 'اسمك', hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.7)),
      prefixIcon: const Icon(Icons.person_outline, color: AppColors.textMuted)));

  Widget _genderSel() => Row(children: [
    Expanded(child: GestureDetector(onTap: () => setState(() => _gender = 'male'),
      child: Container(padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: _gender == 'male' ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _gender == 'male' ? AppColors.primary : AppColors.divider)),
        child: Column(children: [
          Icon(Icons.male, color: _gender == 'male' ? Colors.white : AppColors.textSecondary, size: 32),
          const SizedBox(height: 8),
          Text('ذكر', style: TextStyle(color: _gender == 'male' ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w600))])))),
    const SizedBox(width: 16),
    Expanded(child: GestureDetector(onTap: () => setState(() => _gender = 'female'),
      child: Container(padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: _gender == 'female' ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _gender == 'female' ? AppColors.primary : AppColors.divider)),
        child: Column(children: [
          Icon(Icons.female, color: _gender == 'female' ? Colors.white : AppColors.textSecondary, size: 32),
          const SizedBox(height: 8),
          Text('انثى', style: TextStyle(color: _gender == 'female' ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w600))]))))]);
}

// ==================== MAIN SCREEN ====================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _idx = 0; UserProfile? _profile; List<EventModel> _events = []; Timer? _timer;
  @override void initState() { super.initState(); _load(); _timer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() {}); }); }
  @override void dispose() { _timer?.cancel(); super.dispose(); }
  void _load() { setState(() { _profile = StorageService.getUserProfile(); _events = StorageService.getEvents(); }); }
  void _save() { StorageService.saveEvents(_events); _load(); }
  @override Widget build(BuildContext context) {
    final screens = [
      HomeScreen(profile: _profile, events: _events, onEventsChanged: _save, onRefresh: _load),
      EventsScreen(events: _events, onEventsChanged: _save, onRefresh: _load),
      GuestsScreen(events: _events, onEventsChanged: _save),
      const InvitationCardsScreen(), const SettingsScreen()];
    return Scaffold(body: screens[_idx],
      bottomNavigationBar: BottomNavigationBar(currentIndex: _idx, onTap: (i) => setState(() => _idx = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'المناسبات'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'مدعوون'),
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'بطاقات الدعوة'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الاعدادات')]));
  }
}

// ==================== HOME SCREEN ====================
class HomeScreen extends StatefulWidget {
  final UserProfile? profile; final List<EventModel> events;
  final VoidCallback onEventsChanged; final VoidCallback onRefresh;
  const HomeScreen({super.key, required this.profile, required this.events, required this.onEventsChanged, required this.onRefresh});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _q = '';
  List<EventModel> get _f => _q.isEmpty ? widget.events : widget.events.where((e) => e.name.toLowerCase().contains(_q.toLowerCase())).toList();
  int get _tg => widget.events.fold(0, (s, e) => s + e.totalGuests);
  int get _ue => widget.events.where((e) => e.timeRemaining.inSeconds > 0).length;

  @override Widget build(BuildContext context) {
    final p = widget.profile;
    return Scaffold(backgroundColor: AppColors.background,
      drawer: AppDrawer(profile: p),
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0,
        leading: Builder(builder: (ctx) => IconButton(icon: const Icon(Icons.menu, color: AppColors.textPrimary), onPressed: () => Scaffold.of(ctx).openDrawer())),
        title: const Text('مناسبة'), actions: [IconButton(icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary), onPressed: () {})]),
      body: RefreshIndicator(color: AppColors.primary, onRefresh: () async => widget.onRefresh(),
        child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _welcome(p), const SizedBox(height: 20), _stats(), const SizedBox(height: 20), _search(),
            const SizedBox(height: 20), _secTitle('المناسبات القادمة'), const SizedBox(height: 12), _eventsList()]))),
      floatingActionButton: FloatingActionButton.extended(onPressed: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => CreateEventScreen(onSave: (ev) { widget.events.add(ev); widget.onEventsChanged(); })));
      }, icon: const Icon(Icons.add), label: const Text('انشاء مناسبة جديدة')));
  }

  Widget _welcome(UserProfile? p) => Container(padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topRight, end: Alignment.bottomLeft),
      borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))]),
    child: Row(children: [
      Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.2),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 2)),
        child: p?.imagePath != null ? ClipOval(child: Image.file(File(p!.imagePath!), fit: BoxFit.cover))
          : Center(child: Icon(p?.gender == 'female' ? Icons.person_2 : Icons.person, color: Colors.white, size: 32))),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('مرحبا بك', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
        const SizedBox(height: 4), Text(p?.name ?? 'زائرنا الكريم', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4), Text('كل مناسبة تستحق ان تنظم باجمل طريقة', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12))])),
      const Icon(Icons.favorite, color: Colors.white, size: 32)]));

  Widget _stats() => Row(children: [
    Expanded(child: _statCard(icon: Icons.people_outline, value: _tg.toString(), label: 'اجمالي المدعوين')),
    const SizedBox(width: 12), Expanded(child: _statCard(icon: Icons.calendar_today_outlined, value: _ue.toString(), label: 'المناسبات القادمة'))]);

  Widget _statCard({required IconData icon, required String value, required String label}) => Container(padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
    child: Column(children: [
      Icon(icon, color: AppColors.primary, size: 28), const SizedBox(height: 8),
      Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      const SizedBox(height: 4), Text(label, style: AppStyles.label, textAlign: TextAlign.center)]));

  Widget _search() => Container(decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
    child: TextField(textAlign: TextAlign.right, decoration: const InputDecoration(hintText: 'بحث عن مناسبة...',
      prefixIcon: Icon(Icons.search, color: AppColors.textMuted), border: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)), onChanged: (v) => setState(() => _q = v)));

  Widget _secTitle(String t) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    TextButton(onPressed: () {}, child: const Text('عرض الكل', style: TextStyle(color: AppColors.primary))), Text(t, style: AppStyles.titleLarge)]);

  Widget _eventsList() {
    if (_f.isEmpty) return Center(child: Column(children: [
      const SizedBox(height: 40), Icon(Icons.event_busy, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
      const SizedBox(height: 16), Text('لا توجد مناسبات بعد', style: AppStyles.bodyMedium)]));
    return Column(children: _f.map((e) => _eventCard(e)).toList());
  }

  Widget _eventCard(EventModel e) {
    final dl = e.timeRemaining.inDays; final past = e.timeRemaining.inSeconds <= 0;
    return GestureDetector(onTap: () async {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailsScreen(event: e, onUpdate: widget.onEventsChanged)));
      widget.onRefresh();
    }, child: Container(margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
      child: Row(children: [
        ClipRRect(borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
          child: Container(width: 80, height: 100, color: AppColors.pinkLight,
            child: e.imagePath != null ? Image.file(File(e.imagePath!), fit: BoxFit.cover)
              : const Icon(Icons.celebration, color: AppColors.primary, size: 40))),
        Expanded(child: Padding(padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(e.name, style: AppStyles.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4), Text(DateFormat('yyyy MMMM dd', 'ar').format(e.date), style: AppStyles.bodyMedium),
            const SizedBox(height: 4), Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Icon(Icons.location_on, size: 14, color: AppColors.textMuted), const SizedBox(width: 4), Text(e.location, style: AppStyles.label)])]))),
        Container(width: 60, height: 100, decoration: const BoxDecoration(color: AppColors.pinkLight, borderRadius: BorderRadius.horizontal(left: Radius.circular(16))),
          child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(past ? '0' : dl.toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
            Text(past ? 'انتهت' : 'يوم', style: AppStyles.label)])))])));
  }
}

// ==================== EVENT DETAILS ====================
class EventDetailsScreen extends StatefulWidget {
  final EventModel event; final VoidCallback onUpdate;
  const EventDetailsScreen({super.key, required this.event, required this.onUpdate});
  @override State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  Timer? _timer;
  @override void initState() { super.initState(); _timer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() {}); }); }
  @override void dispose() { _timer?.cancel(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final e = widget.event; final dur = e.timeRemaining;
    return Scaffold(backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('تفاصيل المناسبة'), actions: [
        PopupMenuButton<String>(onSelected: (v) {
          if (v == 'edit') Navigator.push(context, MaterialPageRoute(builder: (_) => CreateEventScreen(event: e, onSave: (_) => widget.onUpdate())));
          else if (v == 'delete') _confirmDelete();
        }, itemBuilder: (_) => [const PopupMenuItem(value: 'edit', child: Text('تعديل')), const PopupMenuItem(value: 'delete', child: Text('حذف', style: TextStyle(color: Colors.red)))])]),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        _header(e), const SizedBox(height: 20), _countdown(dur), const SizedBox(height: 20), _info(e),
        const SizedBox(height: 20), _guestsSummary(e), const SizedBox(height: 20), _actions(e)])));
  }

  Widget _header(EventModel e) => Container(width: double.infinity, height: 200,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
      image: e.imagePath != null ? DecorationImage(image: FileImage(File(e.imagePath!)), fit: BoxFit.cover) : null,
      gradient: e.imagePath == null ? const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]) : null),
    child: e.imagePath == null ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.celebration, color: Colors.white, size: 50), const SizedBox(height: 12),
      Text(e.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))])) : null);

  Widget _countdown(Duration d) {
    final past = d.inSeconds <= 0; final days = d.inDays; final hrs = d.inHours % 24; final mins = d.inMinutes % 60; final secs = d.inSeconds % 60;
    return Container(width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: past ? [Colors.grey.shade400, Colors.grey.shade600] : [AppColors.primary, AppColors.primaryDark]),
        borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Text(past ? 'المناسبة انتهت' : 'الوقت المتبقي', style: const TextStyle(color: Colors.white, fontSize: 16)), const SizedBox(height: 16),
        if (!past) Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _tUnit(days, 'يوم'), _tUnit(hrs, 'ساعة'), _tUnit(mins, 'دقيقة'), _tUnit(secs, 'ثانية')])
        else const Icon(Icons.check_circle, color: Colors.white, size: 48)]));
  }

  Widget _tUnit(int v, String l) => Column(children: [
    Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
      child: Center(child: Text(v.toString().padLeft(2, '0'), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)))),
    const SizedBox(height: 8), Text(l, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12))]);

  Widget _info(EventModel e) => Container(padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
    child: Column(children: [
      _iRow(Icons.calendar_today, 'التاريخ', DateFormat('yyyy MMMM dd', 'ar').format(e.date)), const Divider(height: 24),
      _iRow(Icons.access_time, 'الوقت', e.time.format(context)), const Divider(height: 24),
      _iRow(Icons.location_on, 'المكان', e.location), const Divider(height: 24),
      _iRow(Icons.people, 'عدد المدعوين', '${e.totalGuests} مدعو'),
      if (e.notes.isNotEmpty) ...[const Divider(height: 24), _iRow(Icons.notes, 'ملاحظات', e.notes)]]));

  Widget _iRow(IconData i, String l, String v) => Row(children: [
    Expanded(child: Text(v, textAlign: TextAlign.right, style: AppStyles.bodyLarge)), const SizedBox(width: 12),
    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(l, style: AppStyles.label), const SizedBox(height: 4), Icon(i, color: AppColors.primary, size: 20)])]);

  Widget _guestsSummary(EventModel e) {
    final inv = e.invitedCount; final ninv = e.notInvitedCount; final tot = e.totalGuests;
    return Container(padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('احصائيات المدعوين', style: AppStyles.titleLarge), const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _gStat('لم يتم الدعوة', ninv, AppColors.textMuted)),
          Expanded(child: _gStat('تمت الدعوة', inv, AppColors.success)),
          Expanded(child: _gStat('الاجمالي', tot, AppColors.primary))]),
        if (tot > 0) ...[const SizedBox(height: 16),
          ClipRRect(borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: tot > 0 ? inv / tot : 0, backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation(AppColors.success), minHeight: 8))]]));
  }

  Widget _gStat(String l, int v, Color c) => Column(children: [
    Text(v.toString(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: c)), const SizedBox(height: 4), Text(l, style: AppStyles.label)]);

  Widget _actions(EventModel e) => Row(children: [
    Expanded(child: _actBtn(icon: Icons.delete_outline, label: 'حذف', color: Colors.red.shade400, onTap: _confirmDelete)),
    const SizedBox(width: 8), Expanded(child: _actBtn(icon: Icons.edit, label: 'تعديل', color: AppColors.primary, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateEventScreen(event: e, onSave: (_) => widget.onUpdate()))))),
    const SizedBox(width: 8), Expanded(child: _actBtn(icon: Icons.card_giftcard, label: 'بطاقة الدعوة', color: AppColors.primaryDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InvitationCardScreen(event: e))))),
    const SizedBox(width: 8), Expanded(child: _actBtn(icon: Icons.share, label: 'مشاركة', color: AppColors.success, onTap: () => _share(e)))]);

  Widget _actBtn({required IconData icon, required String label, required Color color, required VoidCallback onTap}) => GestureDetector(onTap: onTap,
    child: Container(padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(children: [Icon(icon, color: color, size: 24), const SizedBox(height: 4), Text(label, style: TextStyle(color: color, fontSize: 11))])));

  void _share(EventModel e) {
    final text = 'دعوة لحضور ' + e.name + '\nالتاريخ: ' + DateFormat('yyyy/MM/dd', 'ar').format(e.date) + '\nالوقت: ' + e.time.format(context) + '\nالمكان: ' + e.location + '\nنتشرف بحضوركم!';
    Share.share(text);
  }

  void _confirmDelete() => showDialog(context: context, builder: (_) => AlertDialog(
    title: const Text('حذف المناسبة'), content: const Text('هل انت متأكد من حذف هذه المناسبة؟'),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('الغاء')),
      TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); widget.onUpdate(); }, child: const Text('حذف', style: TextStyle(color: Colors.red)))],
  ));
}

// ==================== CREATE EVENT SCREEN ====================
class CreateEventScreen extends StatefulWidget {
  final EventModel? event; final Function(EventModel) onSave;
  const CreateEventScreen({super.key, this.event, required this.onSave});
  @override State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _nameCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _type = 'حفل زفاف';
  DateTime _date = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _time = const TimeOfDay(hour: 18, minute: 0);
  File? _img; final _picker = ImagePicker();
  final List<String> _types = ['حفل زفاف', 'خطوبة', 'عيد ميلاد', 'حفل تخرج', 'مناسبة اخرى'];

  @override void initState() {
    super.initState();
    if (widget.event != null) {
      final e = widget.event!;
      _nameCtrl.text = e.name; _locCtrl.text = e.location; _notesCtrl.text = e.notes;
      _type = e.type; _date = e.date; _time = e.time;
      if (e.imagePath != null) _img = File(e.imagePath!);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _img = File(image.path));
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty || _locCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة'))); return;
    }
    final ev = EventModel(
      id: widget.event?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(), type: _type, date: _date, time: _time,
      location: _locCtrl.text.trim(), imagePath: _img?.path, notes: _notesCtrl.text.trim(),
      guests: widget.event?.guests ?? [],
      invitationCardTemplate: widget.event?.invitationCardTemplate ?? 'template1',
      invitationText: widget.event?.invitationText ?? '',
      invitationBgColor: widget.event?.invitationBgColor ?? const Color(0xFFFFF8F8),
      invitationFontFamily: widget.event?.invitationFontFamily ?? 'Cairo');
    widget.onSave(ev); Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now(), lastDate: DateTime(2030));
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  @override Widget build(BuildContext context) => Scaffold(backgroundColor: AppColors.background,
    appBar: AppBar(title: Text(widget.event == null ? 'انشاء مناسبة جديدة' : 'تعديل المناسبة')),
    body: SingleChildScrollView(padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Center(child: GestureDetector(onTap: _pickImage,
          child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.pinkLight,
            border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
            image: _img != null ? DecorationImage(image: FileImage(_img!), fit: BoxFit.cover) : null),
            child: _img == null ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.camera_alt, color: AppColors.primary, size: 32), SizedBox(height: 4),
              Text('اضافة صورة', style: TextStyle(color: AppColors.primary, fontSize: 12))])) : null))),
        const SizedBox(height: 24),
        _field('اسم المناسبة', _nameCtrl, Icons.celebration, 'مثال: حفل زفاف احمد وسارة'),
        const SizedBox(height: 16), _dropdown(),
        const SizedBox(height: 16), _field('المكان', _locCtrl, Icons.location_on, 'قاعة الولاء - المدينة'),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: GestureDetector(onTap: _pickDate,
            child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text(DateFormat('yyyy/MM/dd', 'ar').format(_date), style: AppStyles.bodyLarge), const SizedBox(width: 12),
                const Icon(Icons.calendar_today, color: AppColors.primary)]))))),
          const SizedBox(width: 12),
          Expanded(child: GestureDetector(onTap: _pickTime,
            child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text(_time.format(context), style: AppStyles.bodyLarge), const SizedBox(width: 12),
                const Icon(Icons.access_time, color: AppColors.primary)])))))]),
        const SizedBox(height: 16),
        _field('ملاحظات (اختياري)', _notesCtrl, Icons.notes, 'ملاحظات اضافية...', maxLines: 3),
        const SizedBox(height: 32),
        SizedBox(width: double.infinity, height: 56,
          child: ElevatedButton(onPressed: _save,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), elevation: 0),
            child: Text(widget.event == null ? 'حفظ المناسبة' : 'تحديث المناسبة', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)))),
      ])));

  Widget _field(String label, TextEditingController ctrl, IconData icon, String hint, {int maxLines = 1}) => Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
    Text(label, style: AppStyles.bodyMedium), const SizedBox(height: 8),
    TextField(controller: ctrl, textAlign: TextAlign.right, maxLines: maxLines,
      decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: AppColors.textMuted)))]);

  Widget _dropdown() => Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
    Text('نوع المناسبة', style: AppStyles.bodyMedium), const SizedBox(height: 8),
    Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        isExpanded: true, alignment: Alignment.centerRight, value: _type,
        icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
        items: _types.map((t) => DropdownMenuItem(value: t, child: Align(alignment: Alignment.centerRight, child: Text(t)))).toList(),
        onChanged: (v) => setState(() => _type = v!))))]);
}

// ==================== EVENTS SCREEN ====================
class EventsScreen extends StatefulWidget {
  final List<EventModel> events; final VoidCallback onEventsChanged; final VoidCallback onRefresh;
  const EventsScreen({super.key, required this.events, required this.onEventsChanged, required this.onRefresh});
  @override State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _filter = 'الكل';
  final List<String> _filters = ['الكل', 'قادمة', 'سابقة'];

  List<EventModel> get _filtered {
    if (_filter == 'الكل') return widget.events;
    if (_filter == 'قادمة') return widget.events.where((e) => e.timeRemaining.inSeconds > 0).toList();
    return widget.events.where((e) => e.timeRemaining.inSeconds <= 0).toList();
  }

  @override Widget build(BuildContext context) => Scaffold(backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('المناسبات')),
    body: Column(children: [
      Container(padding: const EdgeInsets.symmetric(vertical: 12),
        child: SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: _filters.map((f) => Padding(padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(label: Text(f), selected: _filter == f,
              selectedColor: AppColors.primary, backgroundColor: AppColors.surface,
              labelStyle: TextStyle(color: _filter == f ? Colors.white : AppColors.textPrimary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: _filter == f ? AppColors.primary : AppColors.divider)),
              onSelected: (_) => setState(() => _filter = f)))).toList()))),
      Expanded(child: _filtered.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.event_busy, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
        const SizedBox(height: 16), Text('لا توجد مناسبات', style: AppStyles.bodyMedium)]))
        : ListView.builder(padding: const EdgeInsets.all(16), itemCount: _filtered.length,
          itemBuilder: (_, i) => _eventCard(_filtered[i])))]));

  Widget _eventCard(EventModel e) {
    final past = e.timeRemaining.inSeconds <= 0;
    return Container(margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
      child: ListTile(contentPadding: const EdgeInsets.all(16),
        leading: Container(width: 60, height: 60, decoration: BoxDecoration(color: AppColors.pinkLight, borderRadius: BorderRadius.circular(12)),
          child: e.imagePath != null ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(e.imagePath!), fit: BoxFit.cover))
            : const Icon(Icons.celebration, color: AppColors.primary)),
        title: Text(e.name, style: AppStyles.titleLarge), subtitle: Text('${DateFormat('yyyy/MM/dd', 'ar').format(e.date)} - ${e.location}', style: AppStyles.bodyMedium),
        trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: past ? Colors.grey.shade200 : AppColors.pinkLight, borderRadius: BorderRadius.circular(20)),
          child: Text(past ? 'انتهت' : '${e.timeRemaining.inDays} يوم', style: TextStyle(color: past ? Colors.grey : AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600))),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailsScreen(event: e, onUpdate: widget.onEventsChanged)));
          widget.onRefresh();
        }));
  }
}

// ==================== GUESTS SCREEN ====================
class GuestsScreen extends StatefulWidget {
  final List<EventModel> events; final VoidCallback onEventsChanged;
  const GuestsScreen({super.key, required this.events, required this.onEventsChanged});
  @override State<GuestsScreen> createState() => _GuestsScreenState();
}

class _GuestsScreenState extends State<GuestsScreen> {
  EventModel? _selectedEvent;
  String _q = '';
  String _cat = 'الكل';
  final List<String> _cats = ['الكل', 'الزملاء', 'الاصدقاء', 'الصدقاء', 'العائلة'];

  List<EventModel> get _eventsWithGuests => widget.events.where((e) => e.guests.isNotEmpty).toList();

  List<Guest> get _guests {
    final ev = _selectedEvent ?? (_eventsWithGuests.isNotEmpty ? _eventsWithGuests.first : null);
    if (ev == null) return [];
    var g = ev.guests;
    if (_q.isNotEmpty) g = g.where((x) => x.name.toLowerCase().contains(_q.toLowerCase())).toList();
    if (_cat != 'الكل') g = g.where((x) => x.category == _cat).toList();
    return g;
  }

  void _toggleInvite(Guest g) {
    setState(() { g.isInvited = !g.isInvited; });
    widget.onEventsChanged();
  }

  void _addGuest() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String cat = 'الكل';
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('اضافة مدعو'), content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, textAlign: TextAlign.right, decoration: const InputDecoration(hintText: 'اسم المدعو')),
        const SizedBox(height: 12), TextField(controller: phoneCtrl, textAlign: TextAlign.right, decoration: const InputDecoration(hintText: 'رقم الهاتف')),
        const SizedBox(height: 12), DropdownButtonFormField<String>(value: cat, alignment: Alignment.centerRight,
          items: _cats.map((c) => DropdownMenuItem(value: c, child: Align(alignment: Alignment.centerRight, child: Text(c)))).toList(),
          onChanged: (v) => cat = v!, decoration: const InputDecoration(labelText: 'الفئة'))]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('الغاء')),
        TextButton(onPressed: () {
          if (nameCtrl.text.trim().isNotEmpty && _selectedEvent != null) {
            setState(() {
              _selectedEvent!.guests.add(Guest(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameCtrl.text.trim(), phone: phoneCtrl.text.trim(), category: cat));
            });
            widget.onEventsChanged();
          }
          Navigator.pop(context);
        }, child: const Text('اضافة'))],
    ));
  }

  void _importContacts() {
    if (_selectedEvent == null) return;
    final mockContacts = [
      Guest(id: 'c1', name: 'محمد علي', phone: '0770 123 4567', category: 'العائلة', isContactImported: true),
      Guest(id: 'c2', name: 'سارة حسن', phone: '0750 987 6543', category: 'الاصدقاء', isContactImported: true),
      Guest(id: 'c3', name: 'علي خالد', phone: '0780 111 2233', category: 'الزملاء', isContactImported: true),
      Guest(id: 'c4', name: 'ريم محمد', phone: '0771 222 3344', category: 'العائلة', isContactImported: true),
      Guest(id: 'c5', name: 'احمد عبدالله', phone: '0751 555 6677', category: 'الصدقاء', isContactImported: true),
    ];
    setState(() {
      for (var c in mockContacts) {
        if (!_selectedEvent!.guests.any((g) => g.phone == c.phone)) {
          _selectedEvent!.guests.add(c);
        }
      }
    });
    widget.onEventsChanged();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم استيراد جهات الاتصال بنجاح')));
  }

  @override Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('المدعوون'), actions: [
        if (_selectedEvent != null) IconButton(icon: const Icon(Icons.contacts), onPressed: _importContacts),
        if (_selectedEvent != null) IconButton(icon: const Icon(Icons.add), onPressed: _addGuest)]),
      body: _eventsWithGuests.isEmpty && widget.events.isEmpty
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.people_outline, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
            const SizedBox(height: 16), Text('لا توجد مناسبات لاضافة مدعوين', style: AppStyles.bodyMedium)]))
        : Column(children: [
            if (widget.events.length > 1)
              Container(padding: const EdgeInsets.all(16), child: DropdownButtonHideUnderline(
                child: DropdownButton<EventModel>(isExpanded: true, alignment: Alignment.centerRight,
                  value: _selectedEvent ?? (_eventsWithGuests.isNotEmpty ? _eventsWithGuests.first : widget.events.first),
                  hint: const Text('اختر المناسبة'), icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                  items: widget.events.map((e) => DropdownMenuItem(value: e, child: Align(alignment: Alignment.centerRight, child: Text(e.name)))).toList(),
                  onChanged: (v) => setState(() => _selectedEvent = v)))),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Container(decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
              child: TextField(textAlign: TextAlign.right, decoration: const InputDecoration(hintText: 'بحث عن مدعو...', prefixIcon: Icon(Icons.search, color: AppColors.textMuted), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)), onChanged: (v) => setState(() => _q = v)))),
            Container(padding: const EdgeInsets.symmetric(vertical: 8), child: SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: _cats.map((c) => Padding(padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(label: Text(c), selected: _cat == c, selectedColor: AppColors.primary, backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(color: _cat == c ? Colors.white : AppColors.textPrimary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: _cat == c ? AppColors.primary : AppColors.divider)),
                  onSelected: (_) => setState(() => _cat = c)))).toList()))),
            Expanded(child: _guests.isEmpty ? Center(child: Text('لا يوجد مدعوون', style: AppStyles.bodyMedium))
              : ListView.builder(padding: const EdgeInsets.all(16), itemCount: _guests.length,
                itemBuilder: (_, i) => _guestItem(_guests[i])))])),
      floatingActionButton: _selectedEvent != null ? FloatingActionButton.extended(onPressed: _addGuest, icon: const Icon(Icons.add), label: const Text('اضافة مدعو')) : null);
  }

  Widget _guestItem(Guest g) => Container(margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
    child: ListTile(leading: CircleAvatar(backgroundColor: AppColors.pinkLight,
      child: g.imagePath != null ? ClipOval(child: Image.file(File(g.imagePath!), fit: BoxFit.cover))
        : Text(g.name.isNotEmpty ? g.name[0] : '?', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
      title: Text(g.name, style: AppStyles.titleLarge), subtitle: Text(g.phone, style: AppStyles.bodyMedium),
      trailing: Checkbox(value: g.isInvited, activeColor: AppColors.success, onChanged: (_) => _toggleInvite(g)),
      onTap: () => _toggleInvite(g)));
}

// ==================== INVITATION CARD SCREEN ====================
class InvitationCardScreen extends StatefulWidget {
  final EventModel event;
  const InvitationCardScreen({super.key, required this.event});
  @override State<InvitationCardScreen> createState() => _InvitationCardScreenState();
}

class _InvitationCardScreenState extends State<InvitationCardScreen> {
  final GlobalKey _cardKey = GlobalKey();
  late String _template;
  late String _text;
  late Color _bgColor;
  late String _font;
  final List<Map<String, dynamic>> _templates = [
    {'id': 'template1', 'name': 'وردي انيق', 'bg': const Color(0xFFFFF8F8), 'border': AppColors.primary},
    {'id': 'template2', 'name': 'ذهبي فاخر', 'bg': const Color(0xFFFFFBF0), 'border': const Color(0xFFD4AF37)},
    {'id': 'template3', 'name': 'ازرق هادئ', 'bg': const Color(0xFFF0F8FF), 'border': const Color(0xFF5B8DB8)},
    {'id': 'template4', 'name': 'اخضر طبيعي', 'bg': const Color(0xFFF0FFF4), 'border': const Color(0xFF6B9E75)},
    {'id': 'template5', 'name': 'رمادي انيق', 'bg': const Color(0xFFF5F5F5), 'border': const Color(0xFF7A7A7A)},
  ];
  final List<Color> _colors = [
    const Color(0xFFFFF8F8), const Color(0xFFFFFBF0), const Color(0xFFF0F8FF),
    const Color(0xFFF0FFF4), const Color(0xFFFFF0F5), const Color(0xFFF5F5F5),
    const Color(0xFFFFF5EE), const Color(0xFFF8F8FF)];
  final List<String> _fonts = ['Cairo', 'Amiri', 'Tajawal', 'Almarai'];

  @override void initState() {
    super.initState();
    _template = widget.event.invitationCardTemplate;
    _text = widget.event.invitationText.isNotEmpty ? widget.event.invitationText
      : 'نتشرف بدعوتكم لحضور ' + widget.event.name + '\n\n' + DateFormat('EEEE، dd MMMM yyyy', 'ar').format(widget.event.date) + '\n' + widget.event.time.format(context) + '\n' + widget.event.location + '\n\nحضوركم يشرفنا ويجمل فرحتنا';
    _bgColor = widget.event.invitationBgColor;
    _font = widget.event.invitationFontFamily;
  }

  Future<void> _saveImage() async {
    try {
      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/invitation_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ البطاقة في ${file.path}')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  void _shareCard() {
    final text = 'دعوة لحضور ' + widget.event.name + '\n' + DateFormat('yyyy/MM/dd', 'ar').format(widget.event.date) + ' - ' + widget.event.time.format(context) + '\n' + widget.event.location;
    Share.share(text);
  }

  Color _getBorderColor() {
    final t = _templates.firstWhere((x) => x['id'] == _template, orElse: () => _templates[0]);
    return t['border'] as Color;
  }

  @override Widget build(BuildContext context) => Scaffold(backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('بطاقة الدعوة'), actions: [
      TextButton(onPressed: _saveImage, child: const Text('حفظ', style: TextStyle(color: AppColors.primary))),
    ]),
    body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      RepaintBoundary(key: _cardKey, child: Container(width: double.infinity, padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: _bgColor, borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _getBorderColor(), width: 3),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))]),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.local_florist, color: _getBorderColor(), size: 24),
            const SizedBox(width: 12), Icon(Icons.favorite, color: _getBorderColor(), size: 32), const SizedBox(width: 12),
            Icon(Icons.local_florist, color: _getBorderColor(), size: 24)])),
          const SizedBox(height: 24),
          Text('نتشرف بدعوتكم لحضور', style: TextStyle(fontFamily: _font, fontSize: 16, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Text(widget.event.type, style: TextStyle(fontFamily: _font, fontSize: 18, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(widget.event.name, textAlign: TextAlign.center, style: TextStyle(fontFamily: _font, fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 24),
          Container(width: 60, height: 2, color: _getBorderColor()),
          const SizedBox(height: 8), Icon(Icons.favorite, color: _getBorderColor(), size: 20), const SizedBox(height: 8), Container(width: 60, height: 2, color: _getBorderColor()),
          const SizedBox(height: 24),
          _infoLine(Icons.calendar_today, DateFormat('EEEE، dd MMMM yyyy', 'ar').format(widget.event.date)),
          const SizedBox(height: 12), _infoLine(Icons.access_time, widget.event.time.format(context)),
          const SizedBox(height: 12), _infoLine(Icons.location_on, widget.event.location),
          const SizedBox(height: 24),
          Text(_text, textAlign: TextAlign.center, style: TextStyle(fontFamily: _font, fontSize: 14, color: AppColors.textSecondary, height: 1.8)),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.local_florist, color: _getBorderColor().withOpacity(0.5), size: 20), const SizedBox(width: 8),
            Icon(Icons.local_florist, color: _getBorderColor().withOpacity(0.5), size: 16), const SizedBox(width: 8),
            Icon(Icons.local_florist, color: _getBorderColor().withOpacity(0.5), size: 20)])]))),
      const SizedBox(height: 24),
      _buildEditor(),
      const SizedBox(height: 24),
      Row(children: [
        Expanded(child: ElevatedButton.icon(onPressed: _shareCard, icon: const Icon(Icons.share), label: const Text('مشاركة الدعوة'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)))),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton.icon(onPressed: _saveImage, icon: const Icon(Icons.download), label: const Text('حفظ كصورة'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)))),
      ]),
    ])));

  Widget _infoLine(IconData i, String t) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
    Text(t, style: TextStyle(fontFamily: _font, fontSize: 15, color: AppColors.textPrimary)), const SizedBox(width: 8), Icon(i, size: 18, color: _getBorderColor())]);

  Widget _buildEditor() => Container(padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text('اختر التصميم', style: AppStyles.titleLarge), const SizedBox(height: 12),
      SizedBox(height: 80, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _templates.length,
        itemBuilder: (_, i) => GestureDetector(onTap: () => setState(() => _template = _templates[i]['id']),
          child: Container(width: 80, height: 80, margin: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(color: _templates[i]['bg'] as Color, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _template == _templates[i]['id'] ? _templates[i]['border'] as Color : AppColors.divider, width: _template == _templates[i]['id'] ? 3 : 1)),
            child: Center(child: Text(_templates[i]['name'] as String, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: _templates[i]['border'] as Color)))))),
      const SizedBox(height: 20),
      Text('النص المخصص', style: AppStyles.titleLarge), const SizedBox(height: 8),
      TextField(textAlign: TextAlign.right, maxLines: 3, controller: TextEditingController(text: _text),
        onChanged: (v) => _text = v, decoration: const InputDecoration(hintText: 'اكتب نص الدعوة هنا...')),
      const SizedBox(height: 20),
      Text('لون الخلفية', style: AppStyles.titleLarge), const SizedBox(height: 12),
      Wrap(spacing: 12, runSpacing: 12, children: _colors.map((c) => GestureDetector(onTap: () => setState(() => _bgColor = c),
        child: Container(width: 40, height: 40, decoration: BoxDecoration(color: c, shape: BoxShape.circle,
          border: Border.all(color: _bgColor == c ? AppColors.primary : AppColors.divider, width: _bgColor == c ? 3 : 1))))).toList()),
      const SizedBox(height: 20),
      Text('نوع الخط', style: AppStyles.titleLarge), const SizedBox(height: 12),
      Wrap(spacing: 12, children: _fonts.map((f) => ChoiceChip(label: Text(f), selected: _font == f,
        selectedColor: AppColors.primary, backgroundColor: AppColors.surface,
        labelStyle: TextStyle(color: _font == f ? Colors.white : AppColors.textPrimary, fontFamily: f),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: _font == f ? AppColors.primary : AppColors.divider)),
        onSelected: (_) => setState(() => _font = f))).toList()),
    ]));
}

// ==================== INVITATION CARDS SCREEN ====================
class InvitationCardsScreen extends StatelessWidget {
  const InvitationCardsScreen({super.key});
  @override Widget build(BuildContext context) {
    final events = StorageService.getEvents().where((e) => e.guests.isNotEmpty).toList();
    return Scaffold(backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('بطاقات الدعوة')),
      body: events.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.card_giftcard, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
        const SizedBox(height: 16), Text('لا توجد بطاقات دعوة بعد', style: AppStyles.bodyMedium),
        const SizedBox(height: 8), Text('انشئ مناسبة واضف مدعوين لانشاء بطاقة دعوة', style: AppStyles.label)]))
        : ListView.builder(padding: const EdgeInsets.all(16), itemCount: events.length,
          itemBuilder: (_, i) => Container(margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
            child: ListTile(contentPadding: const EdgeInsets.all(16),
              leading: Container(width: 60, height: 60, decoration: BoxDecoration(color: AppColors.pinkLight, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.card_giftcard, color: AppColors.primary)),
              title: Text('بطاقة دعوة - ${events[i].name}', style: AppStyles.titleLarge),
              subtitle: Text('${events[i].invitedCount} / ${events[i].totalGuests} مدعو', style: AppStyles.bodyMedium),
              trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.primary, size: 18),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InvitationCardScreen(event: events[i])))))));
  }
}

// ==================== SETTINGS SCREEN ====================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _dark = false;
  @override void initState() { super.initState(); _dark = StorageService.isDarkMode(); }
  @override Widget build(BuildContext context) => Scaffold(backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('الاعدادات')),
    body: ListView(children: [
      _section('المظهر', [
        SwitchListTile(title: const Text('الوضع الداكن'), subtitle: const Text('تفعيل الوضع الليلي'),
          value: _dark, activeColor: AppColors.primary,
          onChanged: (v) { setState(() => _dark = v); StorageService.saveDarkMode(v); }),
      ]),
      _section('الحساب', [
        ListTile(leading: const Icon(Icons.person, color: AppColors.primary), title: const Text('تعديل الملف الشخصي'), trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserSetupScreen()))),
        ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
          onTap: () { StorageService.setOnboardingComplete(); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserSetupScreen())); }),
      ]),
      _section('عن التطبيق', [
        ListTile(leading: const Icon(Icons.info, color: AppColors.primary), title: const Text('عن التطبيق'), trailing: const Icon(Icons.arrow_forward_ios, size: 16)),
        ListTile(leading: const Icon(Icons.help, color: AppColors.primary), title: const Text('مساعدة'), trailing: const Icon(Icons.arrow_forward_ios, size: 16)),
        const ListTile(leading: Icon(Icons.code, color: AppColors.primary), title: Text('الاصدار'), trailing: Text('1.0.0')),
      ]),
    ]));

  Widget _section(String title, List<Widget> children) => Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
    Padding(padding: const EdgeInsets.fromLTRB(16, 24, 16, 8), child: Text(title, style: AppStyles.titleLarge)),
    Container(margin: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
      child: Column(children: children))]);
}

// ==================== APP DRAWER ====================
class AppDrawer extends StatelessWidget {
  final UserProfile? profile;
  const AppDrawer({super.key, required this.profile});
  @override Widget build(BuildContext context) => Drawer(child: Container(color: AppColors.background,
    child: Column(children: [
      Container(padding: const EdgeInsets.fromLTRB(16, 60, 16, 24), decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark])),
        child: Row(children: [
          Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.2), border: Border.all(color: Colors.white.withOpacity(0.4))),
            child: profile?.imagePath != null ? ClipOval(child: Image.file(File(profile!.imagePath!), fit: BoxFit.cover))
              : Center(child: Icon(profile?.gender == 'female' ? Icons.person_2 : Icons.person, color: Colors.white, size: 32))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('مرحبا بك', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
            Text(profile?.name ?? 'زائرنا الكريم', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))]))])),
      Expanded(child: ListView(children: [
        _drawerItem(Icons.home, 'الرئيسية', () => Navigator.pop(context)),
        _drawerItem(Icons.calendar_today, 'المناسبات', () => Navigator.pop(context)),
        _drawerItem(Icons.people, 'المدعوون', () => Navigator.pop(context)),
        _drawerItem(Icons.card_giftcard, 'بطاقات الدعوة', () => Navigator.pop(context)),
        const Divider(),
        _drawerItem(Icons.settings, 'الاعدادات', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        _drawerItem(Icons.help, 'مساعدة', () {}),
        _drawerItem(Icons.info, 'عن التطبيق', () {}),
        const Divider(),
        _drawerItem(Icons.logout, 'تسجيل الخروج', () {
          StorageService.setOnboardingComplete();
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserSetupScreen()));
        }, color: Colors.red),
      ])),
    ])));

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, {Color? color}) => ListTile(
    leading: Icon(icon, color: color ?? AppColors.primary), title: Text(title, style: TextStyle(color: color ?? AppColors.textPrimary)),
    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textMuted), onTap: onTap);
}
