# Admin Account Migration Guide

This document explains how the admin account migration works and how to use it.

## Overview

The admin account migration ensures that:
1. An admin account exists in Firebase Authentication
2. An admin user document exists in Firestore with `isAdmin: true`
3. Both are properly linked and configured

## Admin Credentials

- **Email**: `admin@gmail.com`
- **Password**: `@WSXcde3`

## Automatic Migration

The admin account is automatically migrated when the app starts. The migration runs in `main.dart` via `AdminService().initializeAdmin()`.

## Manual Migration

If you need to run the migration manually, you can use the migration utility:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'lib/utils/admin_migration.dart';

// Ensure Firebase is initialized
await Firebase.initializeApp();

// Run migration
final migration = AdminMigration();
await migration.migrateAdmin();

// Verify migration
final verified = await migration.verifyAdmin();
if (verified) {
  print('Admin migration successful!');
}
```

## Migration Process

1. **Check Firestore**: Looks for existing admin user document
2. **Update Flag**: Ensures `isAdmin: true` is set
3. **Verify Firebase Auth**: Checks if Firebase Auth account exists
4. **Create if Missing**: Creates Firebase Auth account if it doesn't exist
5. **Link Accounts**: Ensures Firestore and Firebase Auth accounts are linked
6. **Sign Out**: Signs out admin after migration to prevent auto-login

## Verification

After migration, you can verify the admin account:

```dart
final migration = AdminMigration();
final verified = await migration.verifyAdmin();
```

This checks:
- Admin exists in Firestore
- `isAdmin` flag is `true`
- Firebase Auth account exists and credentials work

## Troubleshooting

### Admin account not created
- Check Firebase Console > Authentication > Users
- Check Firebase Console > Firestore > users collection
- Ensure Firebase is properly initialized
- Check console logs for error messages

### Admin can't login
- Verify email and password are correct
- Check if account exists in Firebase Authentication
- Ensure `isAdmin: true` is set in Firestore

### Migration fails silently
- Check Firebase configuration
- Verify internet connection
- Check Firebase Console for errors
- Review console logs for detailed error messages

## Security Notes

⚠️ **Important**: The admin password is hardcoded in the migration utility. For production:
1. Consider using environment variables
2. Use Firebase Admin SDK for server-side operations
3. Implement proper access controls
4. Regularly rotate admin credentials

## Files

- `lib/utils/admin_migration.dart` - Migration utility
- `lib/services/admin_service.dart` - Admin service wrapper
- `lib/utils/run_admin_migration.dart` - Standalone migration script

