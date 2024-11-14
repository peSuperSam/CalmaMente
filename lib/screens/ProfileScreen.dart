import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:calmamente/repositories/user_profile_repository.dart';
import '../config/SettingsScreen.dart';
import '../styles/app_colors.dart' as AppColors; // Importa com prefixo para evitar conflitos
import 'LoginScreen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userProfileRepository = UserProfileRepository();
  final _picker = ImagePicker();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String userName = "", userEmail = "", _profileImageUrl = "", _initialName = "", _initialEmail = "";
  bool _isSaving = false, _isLoadingImage = false, _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    setState(() => _isLoadingData = true);
    
    // Carrega as informações do usuário, incluindo o nome e email do registro
    final userInfo = await _userProfileRepository.loadUserInfo();
    
    setState(() {
      userName = userInfo['userName'] ?? '';  // Nome colocado no registro
      userEmail = userInfo['userEmail'] ?? ''; // Email colocado no registro
      _profileImageUrl = userInfo['profileImageUrl'] ?? '';

      // Verifica se a imagem de perfil existe no dispositivo
      if (_profileImageUrl.isNotEmpty && !File(_profileImageUrl).existsSync()) {
        _profileImageUrl = '';
      }

      // Define os valores iniciais
      _initialName = userName;
      _initialEmail = userEmail;
      _nameController.text = userName;
      _emailController.text = userEmail;
      _isLoadingData = false;
    });
  }

  Future<void> _updateUserProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    // Salva as informações atualizadas do usuário
    await _userProfileRepository.saveUserInfo(
      _nameController.text,
      _emailController.text,
      _profileImageUrl,
    );
    
    setState(() {
      userName = _nameController.text;
      userEmail = _emailController.text;
      _initialName = userName;
      _initialEmail = userEmail;
      _isSaving = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Perfil atualizado com sucesso'),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isLoadingImage = true);
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _profileImageUrl = image.path;
      });
      _updateUserProfile();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhuma imagem selecionada")),
      );
    }
    setState(() => _isLoadingImage = false);
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Remover Foto'),
              onTap: () {
                Navigator.of(context).pop();
                setState(() => _profileImageUrl = '');
              },
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider<Object> _getImageProvider() {
    return _profileImageUrl.isNotEmpty && File(_profileImageUrl).existsSync()
        ? FileImage(File(_profileImageUrl)) as ImageProvider<Object>
        : const AssetImage('lib/assets/default_avatar.png');
  }

  Widget _buildEditableField(String label, TextEditingController controller, IconData icon, String? Function(String?)? validator) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.AppColors.primaryColor),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
      validator: validator,
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Limpa as preferências de login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()), // Navega para a tela de login
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Perfil",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: _logout, // Chamando a função de logout
            tooltip: 'Sair',
          ),
        ],
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onTap: _showImageSourceOptions,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.AppColors.secondaryColor,
                              backgroundImage: _getImageProvider(),
                              child: _isLoadingImage ? const CircularProgressIndicator() : null,
                            ),
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.camera_alt, color: AppColors.AppColors.primaryColor, size: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildEditableField(
                      "Nome",
                      _nameController,
                      Icons.person,
                      (value) => value!.isEmpty ? 'Por favor, insira seu nome' : null,
                    ),
                    const SizedBox(height: 15),
                    _buildEditableField(
                      "Email",
                      _emailController,
                      Icons.email,
                      (value) {
                        if (value!.isEmpty) return 'Por favor, insira seu email';
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Por favor, insira um email válido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    const Divider(thickness: 1, color: Colors.grey),
                    Expanded(
                      child: ListView(
                        children: [
                          _buildProfileOption(Icons.lock, "Alterar Senha"),
                          _buildProfileOption(Icons.settings, "Configurações", onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SettingsScreen()),
                            );
                          }),
                          _buildProfileOption(Icons.help_outline, "Ajuda"),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: (_nameController.text != _initialName || _emailController.text != _initialEmail)
                                ? () {
                                    setState(() {
                                      _nameController.text = _initialName;
                                      _emailController.text = _initialEmail;
                                    });
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text("Desfazer Alterações", style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _updateUserProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isSaving ? Colors.grey : AppColors.AppColors.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            icon: _isSaving
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Icon(Icons.save, color: Colors.white),
                            label: Text(
                              _isSaving ? "Salvando..." : "Salvar Alterações",
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.AppColors.primaryColor),
      title: Text(title, style: const TextStyle(color: AppColors.AppColors.primaryColor, fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
