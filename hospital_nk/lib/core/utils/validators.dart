class AppValidators {
  AppValidators._();

  // ─── CHAMPS REQUIS ──────────────────────────────────────────────
  static String? required(String? value, {String fieldName = 'Ce champ'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName est requis';
    }
    return null;
  }

  // ─── EMAIL ──────────────────────────────────────────────────────
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'L\'email est requis';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Format email invalide';
    }
    return null;
  }

  // ─── MOT DE PASSE ───────────────────────────────────────────────
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    if (value.length < 8) {
      return 'Minimum 8 caractères';
    }
    return null;
  }

  static String? passwordStrong(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    if (value.length < 8) {
      return 'Minimum 8 caractères';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Au moins une majuscule requise';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Au moins un chiffre requis';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Au moins un caractère spécial requis';
    }
    return null;
  }

  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Confirmez le mot de passe';
    }
    if (value != password) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  // ─── NUMÉRIQUE ──────────────────────────────────────────────────
  static String? number(String? value, {String fieldName = 'Ce champ'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName est requis';
    }
    if (double.tryParse(value) == null) {
      return '$fieldName doit être un nombre';
    }
    return null;
  }

  static String? positiveNumber(String? value, {String fieldName = 'Ce champ'}) {
    final numCheck = number(value, fieldName: fieldName);
    if (numCheck != null) return numCheck;
    if (double.parse(value!) <= 0) {
      return '$fieldName doit être supérieur à 0';
    }
    return null;
  }

  static String? montant(String? value) {
    return positiveNumber(value, fieldName: 'Le montant');
  }

  static String? quantite(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La quantité est requise';
    }
    final qty = int.tryParse(value);
    if (qty == null) {
      return 'Quantité invalide';
    }
    if (qty <= 0) {
      return 'La quantité doit être supérieure à 0';
    }
    return null;
  }

  // ─── TELEPHONE ──────────────────────────────────────────────────
  static String? telephone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optionnel
    final phoneRegex = RegExp(r'^\+?[0-9]{9,15}$');
    if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
      return 'Numéro de téléphone invalide';
    }
    return null;
  }

  // ─── DATE ───────────────────────────────────────────────────────
  static String? date(String? value, {String fieldName = 'La date'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName est requise';
    }
    try {
      DateTime.parse(value);
      return null;
    } catch (_) {
      return 'Format de date invalide (AAAA-MM-JJ)';
    }
  }

  // ─── LONGUEUR ───────────────────────────────────────────────────
  static String? minLength(String? value, int min, {String fieldName = 'Ce champ'}) {
    if (value == null || value.length < min) {
      return '$fieldName doit contenir au moins $min caractères';
    }
    return null;
  }

  static String? maxLength(String? value, int max, {String fieldName = 'Ce champ'}) {
    if (value != null && value.length > max) {
      return '$fieldName ne doit pas dépasser $max caractères';
    }
    return null;
  }

  // ─── CODE / MATRICULE ───────────────────────────────────────────
  static String? code(String? value, {String fieldName = 'Le code'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName est requis';
    }
    if (!RegExp(r'^[A-Za-z0-9\-_]+$').hasMatch(value)) {
      return '$fieldName ne doit contenir que des lettres, chiffres, tirets';
    }
    return null;
  }
}
