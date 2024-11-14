import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../styles/app_colors.dart';
import '../styles/app_styles.dart';

class RelatorioEmocoesScreen extends StatefulWidget {
  const RelatorioEmocoesScreen({Key? key}) : super(key: key);

  @override
  _RelatorioEmocoesScreenState createState() => _RelatorioEmocoesScreenState();
}

class _RelatorioEmocoesScreenState extends State<RelatorioEmocoesScreen> {
  List<Map<String, dynamic>> entries = [];
  List<FlSpot> dataPoints = [];
  String selectedChartType = 'Gráfico de Linha';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _loadSelectedChartType();
  }

  Future<void> _loadEntries() async {
    final dbEntries = await DatabaseService().getDiaryEntries();
    setState(() {
      entries = dbEntries;
      dataPoints = List.generate(
        entries.length,
        (i) => FlSpot(i.toDouble(), entries[i]['rating'].toDouble()),
      );
      isLoading = false;
    });
  }

  Future<void> _loadSelectedChartType() async {
    final selectedType = await DatabaseService().getSelectedChartType();
    setState(() {
      selectedChartType = selectedType ?? 'Gráfico de Linha';
    });
  }

  Future<void> _saveSelectedChartType(String chartType) async {
    await DatabaseService().saveSelectedChartType(chartType);
    setState(() {
      selectedChartType = chartType;
    });
  }

  double get averageRating => dataPoints.isEmpty
      ? 0
      : dataPoints.map((e) => e.y).reduce((a, b) => a + b) / dataPoints.length;

  double get maxRating => dataPoints.isEmpty
      ? 0
      : dataPoints.map((e) => e.y).reduce((a, b) => a > b ? a : b);

  double get minRating => dataPoints.isEmpty
      ? 0
      : dataPoints.map((e) => e.y).reduce((a, b) => a < b ? a : b);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Relatório de Emoções',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSummaryStatistics(),
                  const SizedBox(height: 12),
                  _buildChartDropdown(),
                  const SizedBox(height: 8),
                  _buildSelectedChartContainer(),
                  const SizedBox(height: 12),
                  Expanded(child: _buildReportsList()),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryStatistics() {
    if (dataPoints.isEmpty) return Container();

    return Card(
      color: Colors.white, // Cor de fundo clara para o Card
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, AppColors.primaryColor.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatisticCard("Média", averageRating),
            _buildStatisticCard("Máximo", maxRating),
            _buildStatisticCard("Mínimo", minRating),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticCard(String title, double value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: AppStyles.subtitleStyle.copyWith(
            color: AppColors.primaryColorDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(1),
          style: AppStyles.statisticValueStyle.copyWith(
            fontSize: 18,
            color: AppColors.accentColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildChartDropdown() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: DropdownButton<String>(
        value: selectedChartType,
        isExpanded: true,
        onChanged: (String? newValue) {
          if (newValue != null) _saveSelectedChartType(newValue);
        },
        items: <String>['Gráfico de Linha', 'Gráfico de Pizza', 'Mapa de Calor']
            .map((value) => DropdownMenuItem(value: value, child: Text(value)))
            .toList(),
      ),
    );
  }

  Widget _buildSelectedChartContainer() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 250,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildSelectedChart(),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedChart() {
    switch (selectedChartType) {
      case 'Gráfico de Pizza':
        return _buildPieChart();
      case 'Mapa de Calor':
        return _buildHeatMapChart();
      default:
        return _buildLineChart();
    }
  }

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${DateFormat('dd/MM').format(DateTime.parse(entries[spot.x.toInt()]['date']))}: ${spot.y}',
                  AppStyles.tooltipTextStyle,
                );
              }).toList();
            },
          ),
        ),
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 2,
              getTitlesWidget: (value, _) => Text(
                value.toInt().toString(),
                style: AppStyles.axisTextStyle,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, _) => value.toInt() < entries.length
                  ? Text(
                      DateFormat('dd/MM').format(
                          DateTime.parse(entries[value.toInt()]['date'])),
                      style: AppStyles.axisTextStyle,
                    )
                  : const Text(''),
            ),
          ),
        ),
        minX: 0,
        maxX: dataPoints.length.toDouble() - 1,
        minY: 0,
        maxY: 10,
        lineBarsData: [
          LineChartBarData(
            spots: dataPoints,
            isCurved: true,
            color: AppColors.secondaryColor,
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.secondaryColor.withOpacity(0.3),
            ),
          ),
          LineChartBarData(
            spots: dataPoints.map((e) => FlSpot(e.x, averageRating)).toList(),
            isCurved: true,
            color: AppColors.cardBackground,
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    final moodFrequency = {for (var entry in entries) entry['rating']: 0};
    for (var entry in entries) {
      moodFrequency[entry['rating']] = (moodFrequency[entry['rating']] ?? 0) + 1;
    }

    return PieChart(
      PieChartData(
        sections: moodFrequency.entries.map((e) {
          return PieChartSectionData(
            value: e.value.toDouble(),
            title: '${(e.value / entries.length * 100).toStringAsFixed(1)}%',
            color: Colors.primaries[e.key % Colors.primaries.length],
            radius: 50,
            showTitle: true,
          );
        }).toList(),
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildHeatMapChart() {
    return GridView.builder(
      itemCount: 30,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
      ),
      itemBuilder: (context, index) {
        if (index < entries.length) {
          final entry = entries[index];
          final rating = entry['rating'];
          final color = Color.lerp(
              AppColors.primaryColor, AppColors.cardBackground, rating / 10)!;

          return Container(
            margin: const EdgeInsets.all(2),
            color: color,
            child: Center(
              child: Text(
                DateFormat('d').format(DateTime.parse(entry['date'])),
                style: AppStyles.heatMapTextStyle,
              ),
            ),
          );
        } else {
          return Container(
              margin: const EdgeInsets.all(2), color: Colors.grey.shade300);
        }
      },
    );
  }

  Widget _buildReportsList() {
    return entries.isEmpty
        ? const Center(child: Text('Nenhum registro foi adicionado ainda.'))
        : ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final formattedDate = DateFormat('dd/MM/yyyy')
                  .format(DateTime.parse(entry['date']));
              final emoji = getEmojiForRating(entry['rating']);

              return ListTile(
                leading: Text(emoji, style: AppStyles.emojiStyle),
                title: Text('Data: $formattedDate'),
                subtitle: Text('Avaliação: ${entry['rating']}'),
              );
            },
          );
  }

  String getEmojiForRating(int rating) {
    const emojis = ['😭', '😔', '😕', '😐', '🙂', '😊', '😁', '😃', '😆', '😍', '😎'];
    return emojis[rating.clamp(0, emojis.length - 1)];
  }
}
