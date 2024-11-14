import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../styles/app_colors.dart';
import '../styles/app_styles.dart';

class DiaryEntriesScreen extends StatefulWidget {
  const DiaryEntriesScreen({Key? key}) : super(key: key);

  @override
  _DiaryEntriesScreenState createState() => _DiaryEntriesScreenState();
}

class _DiaryEntriesScreenState extends State<DiaryEntriesScreen> {
  List<Map<String, dynamic>> entries = [];
  List<Map<String, dynamic>> filteredEntries = [];
  TextEditingController searchController = TextEditingController();
  String filterPeriod = 'Última Semana';
  int expandedIndex = -1;
  final List<String> motivationalQuotes = [
    "Um passo de cada vez.",
    "Lembre-se: você é mais forte do que pensa.",
    "Cada dia é uma nova oportunidade.",
    "Você é capaz de superar qualquer desafio.",
    "A paz começa de dentro para fora."
  ];

  @override
  void initState() {
    super.initState();
    _loadEntries();
    searchController.addListener(_filterEntries);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final dbEntries = await DatabaseService().getDiaryEntries();
    setState(() {
      entries = List<Map<String, dynamic>>.from(dbEntries);
      _applyPeriodFilter();
    });
  }

  void _filterEntries() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredEntries = entries.where((entry) {
        final details = entry['details'].toLowerCase();
        final date = DateFormat('dd/MM/yyyy').format(DateTime.parse(entry['date'])).toLowerCase();
        return details.contains(query) || date.contains(query);
      }).toList();
    });
  }

  void _applyPeriodFilter() {
    DateTime now = DateTime.now();
    setState(() {
      filteredEntries = entries.where((entry) {
        DateTime entryDate = DateTime.parse(entry['date']);
        if (filterPeriod == 'Última Semana') {
          return now.difference(entryDate).inDays <= 7;
        } else if (filterPeriod == 'Último Mês') {
          return now.difference(entryDate).inDays <= 30;
        } else if (filterPeriod == 'Últimos 3 Meses') {
          return now.difference(entryDate).inDays <= 90;
        }
        return true;
      }).toList();
    });
  }

  double _calculateAverageRating() {
    if (filteredEntries.isEmpty) return 0;
    double sum = filteredEntries.fold(0.0, (sum, entry) => sum + (entry['rating'] as int).toDouble());
    return sum / filteredEntries.length;
  }

  String _getRandomQuote() {
    return motivationalQuotes[DateTime.now().millisecondsSinceEpoch % motivationalQuotes.length];
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_alt_outlined, color: Colors.grey[400], size: 80),
          const SizedBox(height: 20),
          const Text(
            'Nenhum registro encontrado',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          const Text(
            'Comece a adicionar suas entradas diárias para acompanhar seu progresso.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Registros do Diário",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          _buildSummaryHeader(),
          _buildSearchAndFilter(),
          Expanded(
            child: filteredEntries.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: filteredEntries.length,
                    itemBuilder: (context, index) {
                      final entry = filteredEntries[index];
                      final date = DateFormat('dd/MM/yyyy').format(DateTime.parse(entry['date']));
                      final emoji = getEmojiForRating(entry['rating']);
                      final isExpanded = expandedIndex == index;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            expandedIndex = expandedIndex == index ? -1 : index;
                          });
                        },
                        child: Dismissible(
                          key: Key(entry['id'].toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.redAccent,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) {
                            _deleteEntry(entry['id']);
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            elevation: 3,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(emoji, style: AppStyles.emojiStyle),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Avaliação: ${entry['rating']} - $date',
                                          style: AppStyles.titleStyle,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                                        onPressed: () => _confirmDeleteEntry(entry['id']),
                                      ),
                                    ],
                                  ),
                                  if (isExpanded)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10.0),
                                      child: Text(
                                        entry['details'],
                                        style: AppStyles.subtitleStyle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text(
            'Resumo de ${filteredEntries.length} Registros',
            style: AppStyles.titleStyle,
          ),
          const SizedBox(height: 5),
          Text(
            'Avaliação Média: ${_calculateAverageRating().toStringAsFixed(1)}',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Text(
            _getRandomQuote(),
            textAlign: TextAlign.center,
            style: AppStyles.subtitleStyle.copyWith(fontStyle: FontStyle.italic, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        _filterEntries();
                      },
                    )
                  : null,
              hintText: 'Buscar por data ou detalhes...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButton<String>(
            value: filterPeriod,
            onChanged: (String? newValue) {
              setState(() {
                filterPeriod = newValue!;
                _applyPeriodFilter();
              });
            },
            items: <String>['Última Semana', 'Último Mês', 'Últimos 3 Meses', 'Todos']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteEntry(int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Excluir Entrada"),
          content: const Text("Tem certeza de que deseja excluir esta entrada?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteEntry(id);
              },
              child: const Text("Excluir", style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }

  void _deleteEntry(int id) async {
    await DatabaseService().deleteDiaryEntry(id);
    setState(() {
      entries = List<Map<String, dynamic>>.from(entries.where((entry) => entry['id'] != id));
      _applyPeriodFilter();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Entrada removida com sucesso.')),
    );
  }
}

String getEmojiForRating(int rating) {
  const emojis = ['😭', '😩', '😔', '😕', '😐', '🙂', '😊', '😁', '😃', '😍', '😎'];
  return emojis[rating.clamp(0, emojis.length - 1)];
}
