import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

import 'DiaryScreen.dart';
import 'DiaryEntriesScreen.dart';
import 'RespirationScreen.dart';
import 'SosScreen.dart';
import 'AnxietyReportScreen.dart';
import 'GuidedMeditationScreen.dart';
import 'ProgressTrackerScreen.dart';
import '../resource_library/ResourceLibraryScreen.dart';
import 'CommunitySupportForumScreen.dart';
import 'ProfileScreen.dart';
import '../styles/app_colors.dart' as AppColors;
import '../styles/app_styles.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({Key? key}) : super(key: key);

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  int selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _userName = ''; // Variável para armazenar o nome do usuário

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Carrega o nome do usuário
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeInAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'Usuário(a)'; // Carrega o nome do usuário ou usa um padrão
      selectedIndex = prefs.getInt('selectedIndex') ?? 0;
    });
  }

  Future<void> _saveSelectedIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedIndex', index);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> menuCategories = [
    {
      'label': 'Ansiedade',
      'icon': Icons.book,
      'options': [
        MenuOption('Diário de Ansiedade', Icons.book, DiaryScreen()),
        MenuOption('Registros do Diário', Icons.note_alt, DiaryEntriesScreen()),
        MenuOption('Relatórios do Diário', Icons.analytics, RelatorioEmocoesScreen()),
      ],
    },
    {
      'label': 'Relaxamento',
      'icon': Icons.spa,
      'options': [
        MenuOption('Respiração', Icons.air, RespirationScreen()),
        MenuOption('Modo SOS', Icons.warning_amber_rounded, SosScreen()),
        MenuOption('Mindfulness', Icons.self_improvement, GuidedMeditationScreen()),
      ],
    },
    {
      'label': 'Suporte',
      'icon': Icons.group,
      'options': [
        MenuOption('Progresso', Icons.emoji_events, ProgressTrackerScreen()),
        MenuOption('Biblioteca', Icons.library_books, ResourceLibraryScreen()),
        MenuOption('Comunidade', Icons.forum, CommunitySupportForumScreen()),
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final selectedOptions = menuCategories[selectedIndex]['options'] as List<MenuOption>;
    final filteredOptions = _searchQuery.isEmpty
        ? selectedOptions
        : selectedOptions.where((option) => option.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: _buildCustomAppBar(),
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(child: _buildOptionsGrid(filteredOptions)),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildCustomAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(130),
      child: ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                "lib/assets/background.gif",
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: FadeTransition(
                opacity: _fadeInAnimation,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                        _loadUserData(); // Recarrega o nome do usuário ao retornar da ProfileScreen
                      },
                      child: const CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 18,
                        child: Icon(Icons.person, color: AppColors.AppColors.primaryColor),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Bem-vindo(a) $_userName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              centerTitle: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(10),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, color: AppColors.AppColors.primaryColor),
            hintText: 'O que você precisa agora?',
            hintStyle: TextStyle(color: AppColors.AppColors.primaryColor.withOpacity(0.5)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsGrid(List<MenuOption> options) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) => MenuOptionTile(option: options[index]),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: (index) {
        HapticFeedback.lightImpact();
        setState(() => selectedIndex = index);
        _saveSelectedIndex(index);
      },
      items: menuCategories.map((category) {
        final isSelected = selectedIndex == menuCategories.indexOf(category);
        return BottomNavigationBarItem(
          icon: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.identity()..scale(isSelected ? 1.2 : 1.0),
            child: Icon(category['icon']),
          ),
          label: category['label'],
        );
      }).toList(),
      selectedItemColor: AppColors.AppColors.primaryColor,
      unselectedItemColor: AppColors.AppColors.secondaryColor.withOpacity(0.6),
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      elevation: 10,
    );
  }
}

class MenuOptionTile extends StatelessWidget {
  final MenuOption option;
  const MenuOptionTile({Key? key, required this.option}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => option.screen,
            transitionsBuilder: (_, animation, __, child) {
              final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(CurveTween(curve: Curves.ease));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.AppColors.cardBackground, AppColors.AppColors.cardBackground.withOpacity(0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: AppColors.AppColors.shadowColor.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(tag: option.title, child: Icon(option.icon, size: 36, color: AppColors.AppColors.primaryColor)),
            const SizedBox(height: 10),
            Text(option.title, textAlign: TextAlign.center, style: AppStyles.titleStyle),
          ],
        ),
      ),
    );
  }
}

class MenuOption {
  final String title;
  final IconData icon;
  final Widget screen;
  MenuOption(this.title, this.icon, this.screen);
}
