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
  String? nomComplet;
  String? avatarColor;
  String? avatarPath;
  String? createdAt;

  /// Emmagatzema les dades de l'usuari després del login.
  /// Els camps coincideixen exactament amb les columnes de la taula `usuaris`.
  void setUser(Map<String, dynamic> user) {
    userId      = user['id']          as String?;
    username    = user['username']    as String?;
    email       = user['email']       as String?;
    nomComplet  = user['nom_complet'] as String?;
    avatarColor = user['avatar_color'] as String?;
    avatarPath  = user['avatar_path'] as String?;
    createdAt   = user['created_at']  as String?;
  }

  /// Buida la sessió en fer logout.
  void clear() {
    userId      = null;
    username    = null;
    email       = null;
    nomComplet  = null;
    avatarColor = null;
    avatarPath  = null;
    createdAt   = null;
  }

  /// Nom visible: nom complet si existeix, sinó username, sinó 'Usuari'.
  String get displayName {
    if (nomComplet != null && nomComplet!.trim().isNotEmpty) {
      return nomComplet!.trim();
    }
    return username ?? 'Usuari';
  }

  /// Inicials per a l'avatar: fins a 2 primers caràcters del nom visible en majúscules.
  String get initials {
    final name = displayName;
    if (name == 'Usuari' || name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, min(2, name.length)).toUpperCase();
  }

  /// Indica si hi ha una sessió activa.
  bool get isLoggedIn => userId != null;
}
