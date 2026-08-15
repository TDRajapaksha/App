class UserSession {
  static String? userId; // UUID as String
  static String? userName;
  static String? userEmail;
  static String? userPhone;
  static bool? isAdmin;

  static void clear() {
    userId = null;
    userName = null;
    userEmail = null;
    userPhone = null;
    isAdmin = null;
  }
}
