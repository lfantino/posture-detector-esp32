import 'package:flutter/material.dart';
import '../services/user_session.dart';
import 'login_page.dart';

class ConfiguracioPage extends StatelessWidget {
  const ConfiguracioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Stack(children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF4B5EFC), Color(0xFF7B8FFF)]), borderRadius: BorderRadius.circular(16)),
                        child: Center(child: Text(UserSession().initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))),
                      ),
                      Positioned(bottom: 0, right: 0,
                        child: Container(width: 22, height: 22, decoration: const BoxDecoration(color: Color(0xFF4B5EFC), shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.white, size: 12)),
                      ),
                    ]),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(UserSession().displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('@${UserSession().username ?? ''}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      Text(UserSession().email ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ])),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('COMPTE', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 8),
              _settingsCard([
                _settingsRow(Icons.lock_outline, const Color(0xFFFFE0E0), Colors.red, 'Canviar contrasenya', 'Actualitza la teva contrasenya'),
                const Divider(height: 1),
                _settingsRow(Icons.language, const Color(0xFFE0F0FF), Colors.blue, 'Idioma', 'Català'),
              ]),
              const SizedBox(height: 24),
              const Text('PREFERÈNCIES', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 8),
              _settingsCard([
                _settingsRow(Icons.notifications_outlined, const Color(0xFFFFF9E0), Colors.orange, 'Notificacions', 'Gestiona les alertes que vols rebre'),
                const Divider(height: 1),
                _settingsRow(Icons.track_changes, const Color(0xFFE0FFE8), Colors.green, 'Objectius personals', 'Defineix les teves metes diàries'),
              ]),
              const SizedBox(height: 24),
              const Center(child: Text('SensorFlow v1.0.0', style: TextStyle(color: Colors.grey, fontSize: 13))),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFFFEEEE), borderRadius: BorderRadius.circular(16)),
                child: GestureDetector(
                  onTap: () {
                    UserSession().clear();
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Tanca la sessió', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }

  Widget _settingsRow(IconData icon, Color bgColor, Color iconColor, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ])),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
