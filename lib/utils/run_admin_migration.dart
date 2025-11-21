import 'package:firebase_core/firebase_core.dart';
import 'admin_migration.dart';

/// Standalone script to run admin migration
/// Usage: Call this from main.dart or run separately
Future<void> runAdminMigration() async {
  try {
    print('🚀 Starting admin account migration...');
    
    // Ensure Firebase is initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    final migration = AdminMigration();
    
    // Run migration
    await migration.migrateAdmin();
    
    // Verify migration
    final verified = await migration.verifyAdmin();
    
    if (verified) {
      print('✅ Admin migration completed and verified successfully!');
      print('📧 Admin Email: admin@gmail.com');
      print('🔑 Admin Password: @WSXcde3');
    } else {
      print('⚠️  Admin migration completed but verification failed');
      print('Please check Firebase Console manually');
    }
  } catch (e) {
    print('❌ Admin migration failed: $e');
    print('Please ensure Firebase is properly configured');
  }
}

