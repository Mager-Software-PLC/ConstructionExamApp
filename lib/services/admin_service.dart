import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/admin_migration.dart';

class AdminService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String adminEmail = 'admin@gmail.com';
  static const String adminPassword = '@WSXcde3';

  // Initialize default admin account using migration utility
  Future<void> initializeAdmin() async {
    try {
      final migration = AdminMigration();
      await migration.migrateAdmin();
    } catch (e) {
      print('Error initializing admin: $e');
      // Don't throw - allow app to continue even if admin migration fails
    }
  }

  // Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['isAdmin'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

