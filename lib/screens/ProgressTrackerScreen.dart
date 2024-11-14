import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:math';
import '../styles/app_colors.dart';
import '../styles/app_styles.dart';

class ProgressTrackerScreen extends StatefulWidget {
  const ProgressTrackerScreen({Key? key}) : super(key: key);

  @override
  _ProgressTrackerScreenState createState() => _ProgressTrackerScreenState();
}

class _ProgressTrackerScreenState extends State<ProgressTrackerScreen> {
  late Database database;
  int consecutiveDays = 0, totalEntries = 0;
  List<String> unlockedAchievements = [];
  List<Map<String, dynamic>> entries = [];

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    database = await openDatabase(
      join(await getDatabasesPath(), 'progress_tracker.db'),
      onCreate: (db, version) async {
        await db.execute("CREATE TABLE entries(id INTEGER PRIMARY KEY, rating INTEGER, date TEXT)");
        await db.execute("CREATE TABLE stats(id INTEGER PRIMARY KEY, consecutiveDays INTEGER, totalEntries INTEGER)");
        await db.execute("CREATE TABLE IF NOT EXISTS achievements(id INTEGER PRIMARY KEY, name TEXT UNIQUE)");
      },
      version: 1,
    );

    await _loadEntries();
    await _loadStats();
    await _loadAchievements();
    _checkAchievements();
  }

  Future<void> _loadEntries() async {
    entries = await database.query('entries');
    setState(() {});
  }

  Future<void> _loadStats() async {
    final List<Map<String, dynamic>> stats = await database.query('stats');
    if (stats.isNotEmpty) {
      setState(() {
        consecutiveDays = (stats.first['consecutiveDays'] as int?) ?? 0;
        totalEntries = (stats.first['totalEntries'] as int?) ?? 0;
      });
    } else {
      await _updateStats();
    }
  }

  Future<void> _updateStats() async {
    await database.insert('stats', {'consecutiveDays': consecutiveDays, 'totalEntries': totalEntries}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _loadAchievements() async {
    final achievements = await database.query('achievements');
    setState(() {
      unlockedAchievements = achievements.map((a) => a['name'] as String).toList();
    });
  }

  Future<void> _unlockAchievement(String achievement) async {
    if (!unlockedAchievements.contains(achievement)) {
      await database.insert('achievements', {'name': achievement});
      setState(() => unlockedAchievements.add(achievement));
    }
  }

  void _checkAchievements() {
    if (consecutiveDays >= 7) _unlockAchievement("Primeira Semana Completa");
    if (consecutiveDays >= 30) _unlockAchievement("Registro Diário por 30 Dias");
    if (consecutiveDays >= 90) _unlockAchievement("3 Meses de Uso Contínuo");
  }

  double _calculateWeeklyProgress() => min(entries.length / 7, 1.0);
  double _calculateOverallProgress() => min(entries.length / 30, 1.0);

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      color: const Color(0xFFf4e988),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          Icon(icon, color: const Color(0xFF042434), size: 30),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF042434))),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(fontSize: 16, color: Color(0xFF042434))),
        ]),
      ),
    );
  }

  Widget _buildProgressSummary() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _buildStatCard("Dias Consecutivos", "$consecutiveDays", Icons.calendar_today),
      _buildStatCard("Total de Entradas", "$totalEntries", Icons.book),
    ]);
  }

  Widget _buildAchievementSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Conquistas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF042434))),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        children: unlockedAchievements.map((achievement) => Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: const Color(0xFFe1766b),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star, color: Colors.yellow),
              const SizedBox(width: 8),
              Text(achievement, style: const TextStyle(fontSize: 16, color: Colors.white)),
            ]),
          ),
        )).toList(),
      ),
    ]);
  }

  Widget _buildProgressCharts() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFFe1766b).withOpacity(0.1),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          const Text('Progresso Semanal e Mensal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            Column(children: [
              CircularProgressIndicator(value: _calculateWeeklyProgress(), color: const Color(0xFF1d7c8d), strokeWidth: 8),
              const SizedBox(height: 5),
              const Text("Meta Semanal")
            ]),
            Column(children: [
              CircularProgressIndicator(value: _calculateOverallProgress(), color: const Color(0xFF1d7c8d), strokeWidth: 8),
              const SizedBox(height: 5),
              const Text("Meta Mensal")
            ]),
          ]),
        ]),
      ),
    );
  }

  Widget _buildBarChart() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BarChart(BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 10,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) => Text(value.toInt().toString()))),
          ),
          gridData: const FlGridData(show: true),
          barGroups: entries.asMap().entries.map((entry) => BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value['rating'].toDouble(),
                color: const Color(0xFF35a5ab),
                width: 15,
              ),
            ],
          )).toList(),
        )),
      ),
    );
  }

  Widget _buildLineChart() {
    final dataPoints = List.generate(entries.length, (index) => FlSpot(index.toDouble(), entries[index]['rating'].toDouble()));
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LineChart(LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) => Text(value.toInt().toString()))),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: dataPoints,
              isCurved: true,
              color: const Color(0xFFe1766b),
              barWidth: 3,
              belowBarData: BarAreaData(show: true, color: const Color(0xFFe1766b).withOpacity(0.3)),
            ),
          ],
        )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Acompanhamento de Progresso e Recompensas',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1d7c8d),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              _buildProgressSummary(),
              const SizedBox(height: 20),
              _buildAchievementSection(),
              const SizedBox(height: 20),
              _buildProgressCharts(),
              const SizedBox(height: 20),
              const Text("Gráfico Semanal", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(height: 200, child: _buildBarChart()),
              const SizedBox(height: 20),
              const Text("Linha de Progresso", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(height: 200, child: _buildLineChart()),
            ],
          ),
        ),
      ),
    );
  }
}
