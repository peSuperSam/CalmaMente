import 'package:flutter/material.dart';
import '../styles/app_colors.dart';
import '../styles/app_styles.dart';
import 'feedback_dialog.dart';
import 'resource_detail_screen.dart';
import 'resource_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResourceLibraryScreen extends StatefulWidget {
  const ResourceLibraryScreen({Key? key}) : super(key: key);

  @override
  _ResourceLibraryScreenState createState() => _ResourceLibraryScreenState();
}

class _ResourceLibraryScreenState extends State<ResourceLibraryScreen> {
  final List<Map<String, dynamic>> resources = [
    {
      'icon': Icons.self_improvement,
      'title': 'Meditação para Iniciantes',
      'description': 'Introdução às práticas de meditação.',
      'color': AppColors.secondaryColor,
      'image': 'lib/assets/images/meditacao.png',
    },
    {
      'icon': Icons.mood,
      'title': 'Controle da Ansiedade',
      'description': 'Técnicas para reduzir a ansiedade.',
      'color': AppColors.accentColor,
      'image': 'lib/assets/images/ansiedade.png',
    },
    {
      'icon': Icons.nature_people,
      'title': 'Relaxamento com Sons da Natureza',
      'description': 'Sons naturais para ajudar no relaxamento.',
      'color': AppColors.primaryColorLight,
      'image': 'lib/assets/images/natureza.png',
    },
    {
      'icon': Icons.book,
      'title': 'Leitura sobre Mindfulness',
      'description': 'Artigos e e-books sobre mindfulness.',
      'color': AppColors.primaryColorDark,
      'image': 'lib/assets/images/mindfulness.png',
    },
  ];
  
  Set<int> favoriteIndices = {};
  bool showFavoritesOnly = false;
  String searchQuery = '';
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    prefs = await SharedPreferences.getInstance();
    setState(() => favoriteIndices = (prefs.getStringList('favorites') ?? []).map(int.parse).toSet());
  }

  void toggleFavorite(int index) {
    setState(() => favoriteIndices.contains(index) ? favoriteIndices.remove(index) : favoriteIndices.add(index));
    prefs.setStringList('favorites', favoriteIndices.map((i) => i.toString()).toList());
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(favoriteIndices.contains(index) ? 'Adicionado aos favoritos' : 'Removido dos favoritos'),
      action: SnackBarAction(
        label: 'Desfazer',
        onPressed: () => toggleFavorite(index),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final filteredResources = resources.asMap().entries.where((entry) {
      final matchesSearch = entry.value['title'].toLowerCase().contains(searchQuery.toLowerCase());
      final isFavorite = favoriteIndices.contains(entry.key);
      return matchesSearch && (!showFavoritesOnly || isFavorite);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Biblioteca de Recursos', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list, color: Colors.red),
            onSelected: (value) {
              setState(() => showFavoritesOnly = value == 'Favoritos');
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'Todos', child: Text('Todos os recursos')),
              PopupMenuItem(value: 'Favoritos', child: Text('Somente favoritos')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryColor,
        icon: const Icon(Icons.feedback),
        label: const Text("Feedback"),
        onPressed: () => showDialog(context: context, builder: (_) => FeedbackDialog()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                hintText: 'Pesquisar recursos...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (query) => setState(() => searchQuery = query),
            ),
          ),
          Expanded(
            child: filteredResources.isEmpty
                ? Center(child: Text('Nenhum recurso encontrado', style: AppStyles.subtitleTextStyle))
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: filteredResources.length,
                    itemBuilder: (context, index) {
                      final resourceIndex = filteredResources[index].key;
                      final resource = filteredResources[index].value;
                      return ResourceItem(
                        icon: resource['icon'],
                        title: resource['title'],
                        description: resource['description'],
                        color: resource['color'],
                        imagePath: resource['image'],
                        isFavorite: favoriteIndices.contains(resourceIndex),
                        onFavoriteToggle: () => toggleFavorite(resourceIndex),
                        onTap: () => Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => ResourceDetailScreen(
                              title: resource['title'] ?? 'Recurso',
                              description: resource['description'] ?? 'Descrição indisponível',
                              icon: resource['icon'] ?? Icons.info,
                              color: resource['color'] ?? AppColors.primaryColor,
                            ),
                            transitionsBuilder: (_, animation, __, child) => FadeTransition(
                              opacity: animation,
                              child: child,
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
}
