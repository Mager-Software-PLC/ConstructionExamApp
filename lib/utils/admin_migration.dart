import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Migration utility to ensure admin account exists
class AdminMigration {
  static const String adminEmail = 'admin@gmail.com';
  static const String adminPassword = '@WSXcde3';
  static const String adminName = 'Admin';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Migrate admin account - ensures admin exists and has correct permissions
  Future<void> migrateAdmin() async {
    try {
      print('🔄 Starting admin account migration...');

      // Step 1: Ensure Firebase Auth account exists
      User? firebaseUser;
      try {
        // Try to sign in first
        try {
          final credential = await _auth.signInWithEmailAndPassword(
            email: adminEmail,
            password: adminPassword,
          );
          firebaseUser = credential.user;
          print('✅ Admin Firebase Auth account exists');
        } catch (e) {
          // Account doesn't exist, create it
          print('📝 Creating Firebase Auth account...');
          final credential = await _auth.createUserWithEmailAndPassword(
            email: adminEmail,
            password: adminPassword,
          );
          firebaseUser = credential.user;
          print('✅ Created Firebase Auth account');
        }
      } catch (e) {
        print('⚠️  Firebase Auth error: $e');
        // Continue anyway - might already exist
      }

      // Step 2: Ensure Firestore document exists with isAdmin: true
      if (firebaseUser != null) {
        final adminUser = UserModel(
          uid: firebaseUser.uid,
          fullName: adminName,
          email: adminEmail,
          phone: '',
          progress: ProgressModel(),
          isAdmin: true,
        );

        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(adminUser.toMap(), SetOptions(merge: true));
        print('✅ Admin Firestore document created/updated');
      } else {
        // If Firebase Auth failed, check Firestore for existing admin
        final adminQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: adminEmail)
            .limit(1)
            .get();

        if (adminQuery.docs.isNotEmpty) {
          final adminDoc = adminQuery.docs.first;
          await adminDoc.reference.update({'isAdmin': true});
          print('✅ Updated existing admin document');
        } else {
          print('⚠️  Could not create admin account automatically');
          print('Please create admin account manually in Firebase Console');
        }
      }

      // Step 3: Sign out admin if signed in
      if (_auth.currentUser != null && _auth.currentUser!.email == adminEmail) {
        await _auth.signOut();
        print('✅ Signed out admin after migration');
      }

      print('✅ Admin migration completed');
    } catch (e) {
      print('❌ Error during admin migration: $e');
      // Don't rethrow - allow app to continue
    }
  }


  /// Verify admin account exists and has correct permissions
  Future<bool> verifyAdmin() async {
    try {
      final adminQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: adminEmail)
          .limit(1)
          .get();

      if (adminQuery.docs.isEmpty) {
        print('❌ Admin account not found in Firestore');
        return false;
      }

      final adminData = adminQuery.docs.first.data();
      final isAdmin = adminData['isAdmin'] ?? false;

      if (!isAdmin) {
        print('⚠️  Admin account exists but isAdmin flag is false');
        return false;
      }

      // Try to verify Firebase Auth account
      try {
        await _auth.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
        await _auth.signOut();
        print('✅ Admin account verified successfully');
        return true;
      } catch (e) {
        print('⚠️  Admin Firebase Auth account verification failed: $e');
        return false;
      }
    } catch (e) {
      print('❌ Error verifying admin: $e');
      return false;
    }
  }
}

