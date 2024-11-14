import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../styles/app_colors.dart';

class CommunitySupportForumScreen extends StatefulWidget {
  const CommunitySupportForumScreen({Key? key}) : super(key: key);

  @override
  _CommunitySupportForumScreenState createState() => _CommunitySupportForumScreenState();
}

class _CommunitySupportForumScreenState extends State<CommunitySupportForumScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _posts = [];
  List<dynamic> _filteredPosts = [];
  List<int> _supportedPostIds = []; // Armazena os IDs das postagens que foram apoiadas pelo usuário
  bool _isLoading = false, _isSending = false;
  DateTime? _lastPostTime;
  static const int _postMaxLength = 200;

  @override
  void initState() {
    super.initState();
    _initializeCache();
    _showConductRulesDialog();
    _fetchPosts();
    _fetchSupportedPosts(); // Carregar apoios do usuário
    _subscribeToPosts();
  }

  Future<void> _initializeCache() async {
    setState(() => _isLoading = true);
    await Hive.initFlutter();
    final box = await Hive.openBox('postsCache');
    _posts = box.get('posts', defaultValue: []);
    _filteredPosts = _posts;
    setState(() => _isLoading = false);
  }

  Future<void> _fetchSupportedPosts() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final response = await supabase
        .from('supports')
        .select('post_id')
        .eq('user_id', userId);

    setState(() {
      _supportedPostIds = response.map<int>((support) => support['post_id'] as int).toList();
    });
  }

  void _showConductRulesDialog() => WidgetsBinding.instance.addPostFrameCallback((_) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(Icons.rule, color: AppColors.primaryColor, size: 30),
            const SizedBox(height: 8),
            Text(
              'Regras de Boa Convivência',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
        content: Text(
          'Bem-vindo à comunidade! Siga estas diretrizes para uma interação saudável:\n\n'
          '1. Respeite a todos com empatia.\n'
          '2. Não divulgue informações pessoais.\n'
          '3. Mantenha o ambiente leve e sem conteúdos ofensivos.\n'
          '4. Este espaço é para apoio e motivação.\n\n'
          'Agradecemos por tornar esta comunidade acolhedora!',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.justify,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Entendido',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  });

  void _subscribeToPosts() {
    supabase.from('posts').stream(primaryKey: ['id']).order('created_at').listen((data) {
      setState(() {
        _posts = data;
        _filteredPosts = data;
      });
      _cachePosts();
    });
  }

  Future<void> _cachePosts() async {
    final box = await Hive.openBox('postsCache');
    await box.put('posts', _posts);
  }

  Future<void> _fetchPosts() async {
    setState(() => _isLoading = true);
    final response = await supabase.from('posts').select().order('created_at', ascending: false);
    setState(() {
      _posts = response ?? [];
      _filteredPosts = _posts;
      _isLoading = false;
    });
    _cachePosts();
    _fetchSupportedPosts(); // Atualizar a lista de apoios após carregar as postagens
  }

  Future<void> _addPost() async {
    if (_postController.text.trim().isEmpty) {
      _showSnackBar('Digite uma mensagem antes de enviar.');
      return;
    }

    final now = DateTime.now();
    if (_lastPostTime != null && now.difference(_lastPostTime!) < Duration(seconds: 15)) {
      _showSnackBar('Aguarde alguns segundos antes de enviar outro post.');
      return;
    }
    _lastPostTime = now;

    setState(() => _isSending = true);

    final response = await supabase.from('posts').insert({
      'content': _postController.text,
      'created_at': DateTime.now().toIso8601String(),
      'support_count': 0, // Inicializando contador de apoio
    }).select();

    if (response != null && response.isNotEmpty) {
      _postController.clear();
      _showSnackBar('Postagem enviada com sucesso');
    } else {
      _showSnackBar('Erro ao enviar postagem. Verifique sua conexão.');
    }

    setState(() => _isSending = false);
  }

  Future<void> _incrementSupport(dynamic post) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null || _supportedPostIds.contains(post['id'])) {
      _showSnackBar('Você já apoiou este desabafo.');
      return;
    }

    // Tentativa de atualizar o contador de apoio
    try {
      final updatedCount = (post['support_count'] ?? 0) + 1;
      final response = await supabase
          .from('posts')
          .update({'support_count': updatedCount})
          .eq('id', post['id'])
          .select();

      if (response != null && response.isNotEmpty) {
        await supabase.from('supports').insert({
          'user_id': userId,
          'post_id': post['id'],
        });

        setState(() {
          post['support_count'] = updatedCount;
          _supportedPostIds.add(post['id']);
        });
      } else {
        _showSnackBar('Erro ao atualizar o contador de apoios.');
      }
    } catch (e) {
      _showSnackBar('Erro de conexão ao tentar apoiar.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays > 1) {
      return DateFormat('dd/MM/yyyy').format(date);
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m atrás';
    } else {
      return 'Agora';
    }
  }

  void _filterPosts(String query) {
    setState(() {
      _filteredPosts = _posts.where((post) => post['content'].toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  Widget _buildShimmerLoader() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Container(height: 80, width: double.infinity),
          ),
        ),
      ),
    );
  }

  Widget _buildPostList() {
    if (_isLoading) return _buildShimmerLoader();
    if (_filteredPosts.isEmpty) {
      return Center(child: Text('Nenhuma postagem encontrada', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      itemCount: _filteredPosts.length,
      itemBuilder: (context, index) {
        final post = _filteredPosts[index];
        final bool showDateSeparator = index == 0 ||
            _formatDate(post['created_at']) != _formatDate(_filteredPosts[index - 1]['created_at']);
        final bool hasSupported = _supportedPostIds.contains(post['id']);

        return AnimatedOpacity(
          opacity: 1.0,
          duration: Duration(milliseconds: 500),
          child: Column(
            children: [
              if (showDateSeparator)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _formatDate(post['created_at']),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                child: Card(
                  color: Colors.grey.shade100,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primaryColor,
                          child: Text(_generateAvatarLetter(post['content'])),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post['content'],
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatDate(post['created_at']),
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                hasSupported ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                                color: hasSupported ? Colors.grey : Colors.blueAccent,
                              ),
                              onPressed: hasSupported ? null : () => _incrementSupport(post),
                              tooltip: 'Enviar Apoio',
                            ),
                            Text(
                              '${post['support_count'] ?? 0}',
                              style: TextStyle(color: Colors.blueAccent),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _generateAvatarLetter(String content) {
    return content.isNotEmpty ? content[0].toUpperCase() : 'A';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Comunidade e Suporte Profissional',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPosts,
            tooltip: 'Atualizar',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar postagens...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
              ),
              onChanged: _filterPosts,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildPostList()),
          _buildPostInput(),
        ],
      ),
    );
  }

  Widget _buildPostInput() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _postController,
              maxLength: _postMaxLength,
              decoration: InputDecoration(
                hintText: 'Escreva algo... ex: Compartilhe um desafio ou uma reflexão calma.',
                counterText: '${_postController.text.length}/$_postMaxLength',
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                counterStyle: TextStyle(
                  color: _postController.text.length >= _postMaxLength * 0.9
                      ? Colors.red
                      : AppColors.primaryColor,
                ),
              ),
              onChanged: (text) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: _isSending
                ? CircularProgressIndicator(color: AppColors.primaryColor)
                : Icon(Icons.send, color: AppColors.primaryColor),
            onPressed: _postController.text.length > _postMaxLength ? null : _addPost,
            tooltip: 'Enviar Postagem',
          ),
        ],
      ),
    );
  }
}
