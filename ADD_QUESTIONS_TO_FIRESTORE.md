# How to Add Questions to Firestore

## Method 1: Using Firebase Console (Manual)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Firestore Database**
4. Click **Start collection** (if collection doesn't exist)
5. Collection ID: `questions`
6. For each question:
   - Click **Add document**
   - Document ID: Auto-generate
   - Add fields:
     - `text` (string): The question text
     - `choices` (array): Array of strings with 4 choices
     - `correctIndex` (number): Index of correct answer (0-3)

## Method 2: Using Firebase Admin SDK (Recommended for Bulk Import)

### Step 1: Install Firebase Admin SDK

```bash
npm install -g firebase-tools
npm install firebase-admin
```

### Step 2: Create Import Script

Create a file `import-questions.js`:

```javascript
const admin = require('firebase-admin');
const questions = require('./lib/data/construction_questions.json');

// Initialize Firebase Admin
const serviceAccount = require('./path-to-your-service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function importQuestions() {
  const batch = db.batch();
  
  questions.forEach((question, index) => {
    const docRef = db.collection('questions').doc();
    batch.set(docRef, {
      text: question.text,
      choices: question.choices,
      correctIndex: question.correctIndex,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
  });
  
  await batch.commit();
  console.log(`Successfully imported ${questions.length} questions!`);
}

importQuestions().catch(console.error);
```

### Step 3: Run the Script

```bash
node import-questions.js
```

## Method 3: Using Flutter App (Quick Test)

You can also add questions directly through the app by creating a simple admin screen, but for production, use Method 1 or 2.

## Questions File Location

The questions JSON file is located at:
```
lib/data/construction_questions.json
```

This file contains **60 construction-related questions** ready to import.

## Verification

After importing, verify in Firestore Console:
- Collection: `questions`
- Document count: 60 documents
- Each document has: `text`, `choices`, `correctIndex`

## Notes

- Make sure Firestore security rules allow writes (for initial setup)
- Questions are numbered 1-60 covering various construction topics
- Each question has 4 multiple-choice options
- `correctIndex` is 0-based (0 = first choice, 3 = fourth choice)

