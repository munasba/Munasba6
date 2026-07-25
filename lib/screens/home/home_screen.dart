import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/events_provider.dart';
import '../../providers/guests_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/event_card.dart';
import '../../widgets/stat_card.dart';
import '../events/create_event_screen.dart';
import '../events/event_detail_screen.dart';
import '../guests/guests_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeTab(query: _query, onQueryChanged: (v) => setState(() => _query = v), searchController: _searchController),
      const GuestsScreen(eventId: null), // كل المدعوين (دفتر عام)
      const _EventsListTab(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_tab]),
      floatingActionButton: _tab == 0 || _tab == 2
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateEventScreen()),
              ),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('مناسبة جديدة', style: TextStyle(color: Colors.white)),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'مدعوون'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'مناسبات'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'الإعدادات'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final String query;
  final ValueChanged<String> onQueryChanged;
  final TextEditingController searchController;
  const _HomeTab({required this.query, required this.onQueryChanged, required this.searchController});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().profile;
    final eventsProvider = context.watch<EventsProvider>();
    final guestsProvider = context.watch<GuestsProvider>();
    final results = eventsProvider.search(query);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.accentPink.withOpacity(0.6),
              backgroundImage: (user?.imagePath != null && File(user!.imagePath!).existsSync())
                  ? FileImage(File(user.imagePath!))
                  : null,
              child: (user?.imagePath == null)
                  ? Icon(
                      user?.gender.name == 'female' ? Icons.face_3_rounded : Icons.face_6_rounded,
                      color: AppColors.primary,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('مرحباً بك 👋', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  Text(user?.name ?? 'ضيف',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          controller: searchController,
          onChanged: onQueryChanged,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: 'ابحث عن مناسبة...',
            prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      searchController.clear();
                      onQueryChanged('');
                    },
                  )
                : null,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.people_alt_rounded,
                value: '${guestsProvider.totalGuests}',
                label: 'إجمالي المدعوين',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.event_available_rounded,
                value: '${eventsProvider.upcoming.length}',
                label: 'المناسبات القادمة',
                color: AppColors.gold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(query.isEmpty ? 'المناسبات القادمة' : 'نتائج البحث',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 10),
        if (results.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: const [
                Icon(Icons.event_busy, size: 48, color: AppColors.textMuted),
                SizedBox(height: 10),
                Text('لا توجد مناسبات بعد', style: TextStyle(color: AppColors.textMuted)),
              ],
            ),
          )
        else
          ...results.map((e) => EventCard(
                event: e,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: e.id)),
                ),
              )),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _EventsListTab extends StatelessWidget {
  const _EventsListTab();

  @override
  Widget build(BuildContext context) {
    final events = context.watch<EventsProvider>().events
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('كل المناسبات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        Expanded(
          child: events.isEmpty
              ? const Center(
                  child: Text('لا توجد مناسبات، اضغط + لإنشاء أول مناسبة', style: TextStyle(color: AppColors.textMuted)),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: events
                      .map((e) => EventCard(
                            event: e,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: e.id)),
                            ),
                          ))
                      .toList(),
                ),
        ),
        const SizedBox(height: 70),
      ],
    );
  }
}
