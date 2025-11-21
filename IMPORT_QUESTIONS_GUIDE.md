# How to Import Questions to Firebase

## Quick Method (Using the App)

1. **Run the app:**
   ```bash
   flutter run
   ```

2. **Login to your account**

3. **Go to Profile screen** (bottom navigation)

4. **Click the cloud upload icon** (☁️) in the top right corner

5. **Click "Import Questions"** button

6. **Wait for import to complete** - You'll see a success message

7. **Done!** All 60 questions are now in Firestore

## What Gets Imported

- **60 construction-related questions**
- Each question includes:
  - Question text
  - 4 multiple-choice options
  - Correct answer index (0-3)
  - Creation timestamp
  - Order number

## Collection Structure

Questions are stored in Firestore under:
- **Collection:** `questions`
- **Fields:**
  - `text` (string): The question
  - `choices` (array): Array of 4 answer choices
  - `correctIndex` (number): Index of correct answer (0-3)
  - `createdAt` (timestamp): When imported
  - `order` (number): Question order (1-60)

## Verification

After importing, you can verify in Firebase Console:
1. Go to Firestore Database
2. Open `questions` collection
3. You should see 60 documents

## Troubleshooting

### "Error loading JSON file"
- Make sure `lib/data/construction_questions.json` exists
- Check `pubspec.yaml` has the asset listed

### "Permission denied"
- Make sure Firestore security rules allow writes
- Check that you're authenticated

### "Questions already exist"
- The import will still work, but may create duplicates
- Use "Clear All Questions" first if you want a fresh start

## Alternative: Direct Firebase Console Import

If you prefer, you can manually add questions through Firebase Console:
1. Go to Firestore Database
2. Create collection `questions`
3. Add documents one by one using the JSON structure

## Notes

- Import can be run multiple times (may create duplicates)
- Use "Clear All Questions" to start fresh
- Questions are imported in batches of 10 for efficiency
- Import progress is shown in real-time

