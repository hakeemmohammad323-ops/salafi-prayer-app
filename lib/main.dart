import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math' as math;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const MuslimProSalafiApp());
}

class MuslimProSalafiApp extends StatelessWidget {
  const MuslimProSalafiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salafi Prayer & Deen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFA8F8F6),
        useMaterial3: true,
      ),
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    const PrayerTimesTab(),
    const QiblaCompassTab(),
    const AthkarTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: 'Prayers'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Qibla'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Athkar'),
        ],
      ),
    );
  }
}

class PrayerTimesTab extends StatefulWidget {
  const PrayerTimesTab({super.key});

  @override
  State<PrayerTimesTab> createState() => _PrayerTimesTabState();
}

class _PrayerTimesTabState extends State<PrayerTimesTab> {
  PrayerTimes? _prayerTimes;
  bool _loading = true;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _fetchLocationAndTimes();
  }

  Future<void> _fetchLocationAndTimes() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    final coordinates = Coordinates(position.latitude, position.longitude);
    final params = CalculationMethod.muslim_world_league.getParameters();
    params.madhab = Madhab.shafi;

    final prayerTimes = PrayerTimes.today(coordinates, params);

    setState(() {
      _prayerTimes = prayerTimes;
      _loading = false;
    });
  }

  void _playTestMeccaAdhan() async {
    await _audioPlayer.play(AssetSource('audio/makkah_adhan.mp3'));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final timesMap = {
      'Fajr': _prayerTimes!.fajr,
      'Dhuhr': _prayerTimes!.dhuhr,
      'Asr': _prayerTimes!.asr,
      'Maghrib': _prayerTimes!.maghrib,
      'Isha': _prayerTimes!.isha,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salafi Prayer Times'),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: _playTestMeccaAdhan,
            tooltip: 'Test Mecca Adhan',
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.teal.shade700,
            width: double.infinity,
            child: Column(
              children: [
                Text(
                  DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Standard Salafi Fiqh (MWL 18° / Standard Asr)',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: timesMap.entries.map((entry) {
                return ListTile(
                  leading: const Icon(Icons.access_time_filled, color: Colors.teal),
                  title: Text(entry.key, style: const TextStyle(fontSize: 18)),
                  trailing: Text(
                    DateFormat('hh:mm a').format(entry.value),
                    style: const TextStyle(fontSize: 18, color: Colors.teal),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class QiblaCompassTab extends StatefulWidget {
  const QiblaCompassTab({super.key});

  @override
  State<QiblaCompassTab> createState() => _QiblaCompassTabState();
}

class _QiblaCompassTabState extends State<QiblaCompassTab> {
  double? _heading = 0;

  @override
  void initState() {
    super.initState();
    FlutterCompass.head?.listen((CompassEvent event) {
      if (mounted) {
        setState(() => _heading = event.heading);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Qibla Direction')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${_heading?.toStringAsFixed(0) ?? 0}°',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Transform.rotate(
              angle: ((_heading ?? 0) * (math.pi / 180) * -1),
              child: const Icon(Icons.navigation, size: 150, color: Colors.teal),
            ),
          ],
        ),
      ),
    );
  }
}

class AthkarTab extends StatelessWidget {
  const AthkarTab({super.key});

  @override
  Widget build(BuildContext context) {
    final athkarList = [
      {'title': 'Morning Remembrance', 'arabic': 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ'},
      {'title': 'Evening Remembrance', 'arabic': 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ'},
      {'title': 'After Prayer Dhikr', 'arabic': 'أَسْتَغْفِرُ اللَّهَ (3x) ، اللَّهُمَّ أَنْتَ السَّلاَمُ...'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Athkar')),
      body: ListView.builder(
        itemCount: athkarList.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(athkarList[index]['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(athkarList[index]['arabic']!, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 20, color: Colors.teal)),
            ),
          );
        },
      ),
    );
  }
}
