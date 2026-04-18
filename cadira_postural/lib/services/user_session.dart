import 'dart:math';

/// Singleton que guarda les dades de l'usuari actiu durant la sessió.
/// Es reseteja en fer logout.
class UserSession {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  String? userId;
  String? username;
  String? email;
  String? createdAt;

  /// Emmagatzema les dades de l'usuari després del login.
  void setUser(Map<String, dynamic> user) {
    userId    = user['id']         as String?;
    username  = user['username']   as String?;
    email     = user['email']      as String?;
    createdAt = user['created_at'] as String?;
  }

  /// Buida la sessió en fer logout.
  void clear() {
    userId    = null;
    username  = null;
    email     = null;
    createdAt = null;
  }

  /// Nom visible: username tal com va ser registrat, o 'Usuari' si no hi ha sessió.
  String get displayName => username ?? 'Usuari';

  /// Inicials per a l'avatar: fins a 2 primers caràcters del username en majúscules.
  String get initials {
    final name = username ?? '';
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, min(2, name.length)).toUpperCase();
  }
}
