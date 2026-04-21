import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/user_session.dart';
import '../database/database_helper.dart';
import 'login_page.dart';
import '../posture_control.dart';

class ConfiguracioPage extends StatefulWidget {
  const ConfiguracioPage({super.key});

  @override
  State<ConfiguracioPage> createState() => _ConfiguracioPageState();
}

class _ConfiguracioPageState extends State<ConfiguracioPage> {
  UserSession get _session => UserSession();
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (_session.username != null) {
        await DatabaseHelper().actualitzarAvatar(_session.username!, image.path);
        _session.avatarPath = image.path;
        setState(() {}); // Refrescar la UI
      }
    }
  }

  Future<void> _canviarContrasenyaDialog() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    String? errorMsg;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Canviar contrasenya'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errorMsg != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(errorMsg!,
                          style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  TextField(
                    controller: currentController,
                    obscureText: true,
                    decoration: InputDecoration(
                        labelText: 'Contrasenya actual',
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newController,
                    obscureText: true,
                    decoration: InputDecoration(
                        labelText: 'Nova contrasenya',
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: InputDecoration(
                        labelText: 'Repeteix nova contrasenya',
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none)),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel·lar')),
              ElevatedButton(
                onPressed: () async {
                  if (newController.text != confirmController.text) {
                    setStateDialog(() => errorMsg = 'Les noves contrasenyes no coincideixen');
                    return;
                  }
                  if (newController.text.length < 6) {
                    setStateDialog(() => errorMsg = 'La nova contrasenya és massa curta');
                    return;
                  }
                  if (_session.username == null) return;
                  
                  final db = DatabaseHelper();
                  final user = await db.loginUsuari(
                      username: _session.username!, password: currentController.text);
                  
                  if (user == null) {
                    setStateDialog(() => errorMsg = 'La contrasenya actual és incorrecta');
                  } else {
                    await db.actualitzarContrasenya(_session.username!, newController.text);
                    if (context.mounted) Navigator.pop(context);
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('Contrasenya actualitzada correctament!'), backgroundColor: Colors.green)
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB5A1E5), foregroundColor: Colors.white),
                child: const Text('Guarda'),
              )
            ],
          );
        });
      },
    );
  }

  void _mostrarDialegObjectius() {
    final contController = TextEditingController(text: '45');
    final diaController = TextEditingController(text: '8');
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Objectius Personals', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ajusta el límit de temps per a les alertes de postura.', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: contController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Màxim seguit sense aixecar-se (minuts)',
                  labelStyle: TextStyle(fontSize: 13),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFB5A1E5))),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: diaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Temps màxim assegut al dia (hores)',
                  labelStyle: TextStyle(fontSize: 13),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFB5A1E5))),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel·la', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Objectius personals desats!'), backgroundColor: Color(0xFFA8D5BA))
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB5A1E5), foregroundColor: Colors.white),
              child: const Text('Desa'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1EDE6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Targeta de perfil ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(color: Color(0x06000000), blurRadius: 20, offset: Offset(0, 8))
                    ]),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: _session.avatarPath == null ? const LinearGradient(
                                colors: [Color(0xFFB5A1E5), Color(0xFF8C82D6)]) : null,
                            borderRadius: BorderRadius.circular(16),
                            image: _session.avatarPath != null
                                ? DecorationImage(
                                    image: FileImage(File(_session.avatarPath!)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _session.avatarPath == null
                              ? Center(
                                  child: Text(
                                    _session.initials,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20),
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                                color: Color(0xFFB5A1E5),
                                shape: BoxShape.circle),
                            child: const Icon(Icons.edit,
                                color: Colors.white, size: 12),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _session.displayName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            _session.username != null
                                ? '@${_session.username}'
                                : '',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13),
                          ),
                          Text(
                            _session.email ?? '',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Secció COMPTE ───────────────────────────────────────────────
              const Text('COMPTE',
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
              const SizedBox(height: 8),
              _settingsCard([
                _settingsRow(
                    Icons.lock_outline,
                    const Color(0xFFFFE0E0),
                    Colors.red,
                    'Canviar contrasenya',
                    'Actualitza la teva contrasenya',
                    onTap: _canviarContrasenyaDialog),
              ]),

              const SizedBox(height: 24),

              // ── Secció PREFERÈNCIES ─────────────────────────────────────────
              const Text('PREFERÈNCIES',
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
              const SizedBox(height: 8),
              _settingsCard([
                _settingsRow(
                    Icons.notifications_outlined,
                    const Color(0xFFFFF9E0),
                    Colors.orange,
                    'Notificacions',
                    'Gestiona les alertes que vols rebre'),
                const Divider(height: 1),
                _settingsRow(
                    Icons.track_changes,
                    const Color(0xFFE0FFE8),
                    Colors.green,
                    'Objectius personals',
                    'Defineix les teves metes diàries',
                    onTap: _mostrarDialegObjectius),
              ]),

              const SizedBox(height: 24),

              const Center(
                child: Text('SensorFlow v1.0.0',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),

              const SizedBox(height: 16),

              // ── Botó de logout ──────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFEEEE),
                    borderRadius: BorderRadius.circular(16)),
                child: GestureDetector(
                  onTap: () {
                    _session.clear();
                    PostureController.instance.stop();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (_) => false,
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Tanca la sessió',
                          style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Color(0x04000000), blurRadius: 16, offset: Offset(0, 6))
          ]),
      child: Column(children: children),
    );
  }

  Widget _settingsRow(IconData icon, Color bgColor, Color iconColor,
      String title, String subtitle, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration:
                  BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  Text(subtitle,
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
