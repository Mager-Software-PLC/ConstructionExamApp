import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Common
      'app_name': 'Construction Exam',
      'welcome': 'Welcome',
      'welcome_back': 'Welcome Back!',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'done': 'Done',
      'next': 'Next',
      'back': 'Back',
      'close': 'Close',
      
      // Language Selection
      'select_language': 'Select Language',
      
      // Authentication
      'sign_in': 'Sign In',
      'sign_up': 'Sign Up',
      'register': 'Register',
      'create_account': 'Create Account',
      'login': 'Login',
      'logout': 'Logout',
      'email': 'Email',
      'email_address': 'Email Address',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'full_name': 'Full Name',
      'phone': 'Phone',
      'address': 'Address',
      'remember_me': 'Remember me',
      'forgot_password': 'Forgot Password?',
      'enter_email_reset': 'Enter your email address and we\'ll send you a link to reset your password.',
      'send_reset_link': 'Send Reset Link',
      'check_email': 'Check Your Email',
      'reset_link_sent': 'We\'ve sent a password reset link to your email address.',
      'email_sent_success': 'Email Sent Successfully!',
      'check_inbox': 'Please check your inbox and follow the instructions to reset your password.',
      'back_to_login': 'Back to Login',
      'email_required': 'Email is required',
      'invalid_email': 'Please enter a valid email',
      'email_not_found': 'No account found with this email address.',
      'reset_failed': 'Failed to send reset email. Please try again.',
      'dont_have_account': 'Don\'t have an account? Register',
      'already_have_account': 'Already have an account? Sign In',
      'sign_in_to_continue': 'Sign in to continue your learning journey',
      'join_us_to_start': 'Join us to start your construction exam preparation',
      
      // Home
      'home': 'Home',
      'ready_to_practice': 'Ready to practice construction exam questions?',
      'total_questions': 'Total Questions',
      'start_continue_exam': 'Start / Continue Exam',
      'certificate_ready': 'Certificate Ready!',
      'pass': 'Pass',
      'pass_status': 'Passed',
      'correct': 'Correct',
      'wrong': 'Wrong',
      'attempted': 'Attempted',
      
      // Categories
      'categories': 'Categories',
      'practice': 'Practice',
      'easy': 'Easy',
      'medium': 'Medium',
      'hard': 'Hard',
      'loading_questions': 'Loading questions...',
      'error_loading_questions': 'Error loading questions',
      'no_categories_available': 'No categories available',
      'refresh': 'Refresh',
      'retry': 'Retry',
      
      // Questions
      'questions': 'Questions',
      'question': 'Question',
      'of': 'of',
      'next_question': 'Next Question',
      'finish_exam': 'Finish Exam',
      'correct_answer': 'Correct!',
      'well_done': 'Well done! You got it right.',
      'incorrect': 'Incorrect',
      'try_again': 'Try Again',
      'try_again_message': 'The correct answer is highlighted in green. Keep practicing!',
      'no_questions_available': 'No questions available',
      'load_questions': 'Load Questions',
      
      // Progress
      'progress': 'Progress',
      'my_progress': 'My Progress',
      'completion_progress': 'Completion Progress',
      'exam_completion': 'Exam Completion',
      'overall_progress': 'Overall Progress',
      'answer_statistics': 'Answer Statistics',
      'answer_distribution': 'Answer Distribution',
      'performance_summary': 'Performance Summary',
      'total_questions_attempted': 'Total Questions Attempted',
      'correct_answers': 'Correct Answers',
      'incorrect_answers': 'Incorrect Answers',
      'accuracy_rate': 'Accuracy Rate',
      'no_answers_yet': 'No answers yet',
      
      // Profile
      'profile': 'Profile',
      'view_certificate': 'View Certificate',
      'tap_to_view_download': 'Tap to view or download',
      'profile_updated': 'Profile updated successfully',
      
      // Materials
      'materials': 'Materials',
      'no_materials': 'No materials available',
      'open_pdf': 'Open PDF',
      
      // Messages
      'messages': 'Messages',
      'no_conversations': 'No conversations yet',
      'start_conversation': 'Tap the + button to start a conversation',
      'no_messages': 'No messages yet',
      'start_chat': 'Start the conversation below',
      'type_message': 'Type a message...',
      
      // Certificate
      'certificate': 'Certificate',
      'certificate_of_completion': 'CERTIFICATE OF COMPLETION',
      'this_is_to_certify': 'This is to certify that',
      'has_successfully_completed': 'has successfully completed the',
      'construction_exam': 'CONSTRUCTION EXAM',
      'with_completion_rate': 'with a completion rate of',
      'signature': 'Signature',
      'date': 'Date',
      'certificate_id': 'Certificate ID',
      'print': 'Print',
      'export_pdf': 'Export PDF',
      'exporting': 'Exporting...',
      'certificate_exported': 'Certificate exported successfully!',
      'you_can_print_share': 'You can print or share this certificate as a PDF file.',
      
      // Admin
      'import_questions': 'Import Questions',
      'current_questions': 'Current Questions',
      'questions_count': 'questions',
      'import': 'Import',
      'importing': 'Importing...',
      'clear_all_questions': 'Clear All Questions',
      'clearing': 'Clearing...',
      'warning': 'Warning',
      'this_will_delete': 'This will delete all questions from Firestore. Use with caution!',
      'instructions': 'Instructions',
    },
    'am': {
      // Common
      'app_name': 'የግንባታ ፈተና',
      'welcome': 'እንኳን ደህና መጡ',
      'welcome_back': 'እንኳን ተመለሱ!',
      'loading': 'በመጫን ላይ...',
      'error': 'ስህተት',
      'success': 'ተሳክቷል',
      'cancel': 'ተወው',
      'save': 'አስቀምጥ',
      'delete': 'ሰርዝ',
      'edit': 'አርም',
      'done': 'ተጠናቋል',
      'next': 'ቀጣይ',
      'back': 'ተመለስ',
      'close': 'ዝጋ',
      
      // Language Selection
      'select_language': 'ቋንቋ ይምረጡ',
      
      // Authentication
      'sign_in': 'ግባ',
      'sign_up': 'ተመዝግብ',
      'register': 'ተመዝግብ',
      'create_account': 'መለያ ፍጠር',
      'login': 'ግባ',
      'logout': 'ውጣ',
      'email': 'ኢሜይል',
      'email_address': 'ኢሜይል አድራሻ',
      'password': 'የይለፍ ቃል',
      'confirm_password': 'የይለፍ ቃል ያረጋግጡ',
      'full_name': 'ሙሉ ስም',
      'phone': 'ስልክ',
      'address': 'አድራሻ',
      'remember_me': 'አስታውሰኝ',
      'forgot_password': 'የይለፍ ቃል ረሳኽ?',
      'enter_email_reset': 'ኢሜይል አድራሻዎን ያስገቡ እና የይለፍ ቃልዎን ለመቀየር አገናኝ እንልክልዎታለን።',
      'send_reset_link': 'የመቀየሪያ አገናኝ ላክ',
      'check_email': 'ኢሜይልዎን ይመልከቱ',
      'reset_link_sent': 'የይለፍ ቃል መቀየሪያ አገናኝ ወደ ኢሜይል አድራሻዎ ላክን።',
      'email_sent_success': 'ኢሜይል በተሳካ ሁኔታ ተላከ!',
      'check_inbox': 'እባክዎ የገቢ ሳጥንዎን ይመልከቱ እና የይለፍ ቃልዎን ለመቀየር መመሪያዎችን ይከተሉ።',
      'back_to_login': 'ወደ መግቢያ ተመለስ',
      'email_required': 'ኢሜይል ያስፈልጋል',
      'invalid_email': 'እባክዎ ትክክለኛ ኢሜይል ያስገቡ',
      'email_not_found': 'በዚህ ኢሜይል አድራሻ ምንም መለያ አልተገኘም።',
      'reset_failed': 'የመቀየሪያ ኢሜይል ማስተላለፍ አልተሳካም። እባክዎ እንደገና ይሞክሩ።',
      'dont_have_account': 'መለያ የሎትም? ይመዝግቡ',
      'already_have_account': 'መለያ አለዎት? ግቡ',
      'sign_in_to_continue': 'የእርስዎን የትምህርት ጉዞ ለመቀጠል ይግቡ',
      'join_us_to_start': 'የግንባታ ፈተና ማዘጋጀትዎን ለመጀመር ይቀላቀሉን',
      
      // Home
      'home': 'መነሻ',
      'ready_to_practice': 'የግንባታ ፈተና ጥያቄዎችን ለመለማመድ ዝግጁ ነዎት?',
      'total_questions': 'ጠቅላላ ጥያቄዎች',
      'start_continue_exam': 'ፈተና ጀምር / ቀጥል',
      'certificate_ready': 'ማስረጃ ዝግጁ ነው!',
      'pass': 'ተሳክቷል',
      'pass_status': 'ተሳክቷል',
      'correct': 'ትክክል',
      'wrong': 'ስህተት',
      'attempted': 'ተሞክሯል',
      
      // Questions
      'questions': 'ጥያቄዎች',
      'question': 'ጥያቄ',
      'of': 'ከ',
      'next_question': 'ቀጣይ ጥያቄ',
      'finish_exam': 'ፈተና አጠናቅቅ',
      'correct_answer': 'ትክክል!',
      'well_done': 'በጣም ጥሩ! በትክክል አገኘክዋል።',
      'incorrect': 'ስህተት',
      'try_again': 'እንደገና ሞክር',
      'try_again_message': 'ትክክለኛው መልስ በአረንጓዴ ተደምጧል። መለማመድዎን ይቀጥሉ!',
      'no_questions_available': 'ጥያቄዎች የሉም',
      'load_questions': 'ጥያቄዎችን ጫን',
      
      // Progress
      'progress': 'ሂደት',
      'my_progress': 'የእኔ ሂደት',
      'completion_progress': 'የማጠናቀቂያ ሂደት',
      'exam_completion': 'የፈተና ማጠናቀቂያ',
      'overall_progress': 'አጠቃላይ ሂደት',
      'answer_statistics': 'የመልስ ስታትስቲክስ',
      'answer_distribution': 'የመልስ ስርጭት',
      'performance_summary': 'የአፈጻጸም ማጠቃለያ',
      'total_questions_attempted': 'ጠቅላላ የተሞከሩ ጥያቄዎች',
      'correct_answers': 'ትክክለኛ መልሶች',
      'incorrect_answers': 'ስህተት ያላቸው መልሶች',
      'accuracy_rate': 'የትክክለኛነት መጠን',
      'no_answers_yet': 'እስካሁን መልሶች የሉም',
      
      // Profile
      'profile': 'መገለጫ',
      'view_certificate': 'ማስረጃ ይመልከቱ',
      'tap_to_view_download': 'ለመመልከት ወይም ለመሸጥ ይንኩ',
      'profile_updated': 'መገለጫ በተሳካ ሁኔታ ተዘምኗል',
      
      // Materials
      'materials': 'ቁሳቁሶች',
      'no_materials': 'ቁሳቁሶች አልተገኙም',
      'open_pdf': 'PDF ክፈት',
      
      // Messages
      'messages': 'መልዕክቶች',
      'no_conversations': 'እስካሁን ምንም ውይይቶች የሉም',
      'start_conversation': 'ውይይት ለመጀመር + ቁልፉን ይንኩ',
      'no_messages': 'እስካሁን ምንም መልዕክቶች የሉም',
      'start_chat': 'ከታች ውይይቱን ይጀምሩ',
      'type_message': 'መልዕክት ይጻፉ...',
      
      // Certificate
      'certificate': 'ማስረጃ',
      'certificate_of_completion': 'የማጠናቀቂያ ማስረጃ',
      'this_is_to_certify': 'ይህ የሚያረጋግጠው',
      'has_successfully_completed': 'በተሳካ ሁኔታ አጠናቋል',
      'construction_exam': 'የግንባታ ፈተና',
      'with_completion_rate': 'ከ',
      'signature': 'ፊርማ',
      'date': 'ቀን',
      'certificate_id': 'የማስረጃ መለያ',
      'print': 'አትም',
      'export_pdf': 'PDF ላክ',
      'exporting': 'በመላክ ላይ...',
      'certificate_exported': 'ማስረጃ በተሳካ ሁኔታ ተላከ!',
      'you_can_print_share': 'ይህንን ማስረጃ እንደ PDF ማተም ወይም ማጋራት ይችላሉ።',
      
      // Admin
      'import_questions': 'ጥያቄዎችን ላክ',
      'current_questions': 'የአሁኑ ጥያቄዎች',
      'questions_count': 'ጥያቄዎች',
      'import': 'ላክ',
      'importing': 'በመላክ ላይ...',
      'clear_all_questions': 'ሁሉንም ጥያቄዎች አጥፋ',
      'clearing': 'በመሰረዝ ላይ...',
      'warning': 'ማስጠንቀቂያ',
      'this_will_delete': 'ይህ ሁሉንም ጥያቄዎችን ከ Firestore ያስወግዳል። በጥንቃቄ ይጠቀሙ!',
      'instructions': 'መመሪያዎች',
    },
    'om': {
      // Common
      'app_name': 'Qormaata Hojii',
      'welcome': 'Baga nagaan dhufte',
      'welcome_back': 'Baga nagaan deebite!',
      'loading': 'Hojjechaa jira...',
      'error': 'Dogoggora',
      'success': 'Milkaa\'ina',
      'cancel': 'Dhiisi',
      'save': 'Qabsiisi',
      'delete': 'Haquu',
      'edit': 'Gulaaluu',
      'done': 'Xumurame',
      'next': 'Ittaan',
      'back': 'Duubatti',
      'close': 'Cufsi',
      
      // Language Selection
      'select_language': 'Afaan filadhu',
      
      // Authentication
      'sign_in': 'Seenuu',
      'sign_up': 'Galmaa\'i',
      'register': 'Galmaa\'i',
      'create_account': 'Akkaawuntii uumu',
      'login': 'Seenuu',
      'logout': 'Ba\'i',
      'email': 'Imeelii',
      'email_address': 'Teessoo Imeelii',
      'password': 'Jecha Ikkannoo',
      'confirm_password': 'Jecha Ikkannoo Mirkaneessi',
      'full_name': 'Maqaa Guutuu',
      'phone': 'Bilbila',
      'address': 'Teessoo',
      'remember_me': 'Na yaadadhu',
      'forgot_password': 'Jecha Ikkannoo Dagachaa?',
      'enter_email_reset': 'Teessoo Imeelii kee galchi, ergasii linkii jecha ikkannoo haquuuf si ergina.',
      'send_reset_link': 'Linkii Haquu Ergi',
      'check_email': 'Imeelii kee Mirkaneessi',
      'reset_link_sent': 'Linkii jecha ikkannoo haquuuf teessoo imeelii kee irratti ergineerra.',
      'email_sent_success': 'Imeelii Milkaa\'inaan Ergame!',
      'check_inbox': 'Mee sanduuqii kee mirkaneessi, ergasii jecha ikkannoo haquuuf qajeelfamoota hordofi.',
      'back_to_login': 'Duubatti Seenuu',
      'email_required': 'Imeelii barbaachisa',
      'invalid_email': 'Mee imeelii sirrii galchi',
      'email_not_found': 'Akkaawuntii teessoo imeelii kana waliin hin argamne.',
      'reset_failed': 'Imeelii haquu erguu hin danda\'amne. Mee irra deebi\'i.',
      'dont_have_account': 'Akkaawuntii hin qabduu? Galmaa\'i',
      'already_have_account': 'Akkaawuntii qabduu? Seenuu',
      'sign_in_to_continue': 'Seenuu barumsa kee itti fufuuf',
      'join_us_to_start': 'Nuun walitti makaa qormaata hojii itti qophaa\'uuf eegumsa eegaluu',
      
      // Home
      'home': 'Mana',
      'ready_to_practice': 'Qormaata hojii gaaffilee hojjechuuf qophaa\'eeraa?',
      'total_questions': 'Gaaffilee Waliigalaa',
      'start_continue_exam': 'Eegumsa Jalqabi / Itti Fufi',
      'certificate_ready': 'Ragaa Qophaa\'e!',
      'pass': 'Darba',
      'pass_status': 'Darbame',
      'correct': 'Sirrii',
      'wrong': 'Dogoggora',
      'attempted': 'Iyyatame',
      
      // Questions
      'questions': 'Gaaffilee',
      'question': 'Gaaffii',
      'of': 'irraa',
      'next_question': 'Gaaffii Ittaanu',
      'finish_exam': 'Eegumsa Xumuri',
      'correct_answer': 'Sirrii!',
      'well_done': 'Tole! Sirrii argite.',
      'incorrect': 'Dogoggora',
      'try_again': 'Irra Deebi\'i',
      'try_again_message': 'Deebii sirrii mara keessa adii ta\'e. Hojjechuu itti fufi!',
      'no_questions_available': 'Gaaffilee hin jiran',
      'load_questions': 'Gaaffilee Buufadhu',
      
      // Progress
      'progress': 'Odeeffannoo',
      'my_progress': 'Odeeffannoo Koo',
      'completion_progress': 'Odeeffannoo Xumuraa',
      'exam_completion': 'Xumura Eegumsaa',
      'overall_progress': 'Odeeffannoo Waliigalaa',
      'answer_statistics': 'Statistiksii Deebii',
      'answer_distribution': 'Qoqqoodiinsa Deebii',
      'performance_summary': 'Xumura Hojii',
      'total_questions_attempted': 'Gaaffilee Waliigalaa Iyyatame',
      'correct_answers': 'Deebiiwwan Sirrii',
      'incorrect_answers': 'Deebiiwwan Dogoggora',
      'accuracy_rate': 'Saffisa Sirrii',
      'no_answers_yet': 'Deebiiwwan hin jiran',
      
      // Profile
      'profile': 'Profaayilii',
      'view_certificate': 'Ragaa Muluudhu',
      'tap_to_view_download': 'Muluufi ykn buufachuuf tap godhi',
      'profile_updated': 'Profaayilii milkaa\'inaan oggaamame',
      
      // Materials
      'materials': 'Qabeenya',
      'no_materials': 'Qabeenya hin jiru',
      'open_pdf': 'PDF Bani',
      
      // Messages
      'messages': 'Ergamtoonni',
      'no_conversations': 'Haa\'iwwan hin jiran',
      'start_conversation': 'Haa\'ii jalqabuu + tap godhi',
      'no_messages': 'Ergamtoonni hin jiran',
      'start_chat': 'Haa\'ii gadi jiru jalqabi',
      'type_message': 'Ergaa galchi...',
      
      // Certificate
      'certificate': 'Ragaa',
      'certificate_of_completion': 'RAGAA XUMURAA',
      'this_is_to_certify': 'Kun mirkaneessuuf',
      'has_successfully_completed': 'milkaa\'inaan xumure',
      'construction_exam': 'QORMAATA HOJII',
      'with_completion_rate': 'saffisa xumuraa waliin',
      'signature': 'Mallattoo',
      'date': 'Guyyaa',
      'certificate_id': 'ID Ragaa',
      'print': 'Maxxansiisi',
      'export_pdf': 'PDF Baasii',
      'exporting': 'Baasii jira...',
      'certificate_exported': 'Ragaa milkaa\'inaan baafame!',
      'you_can_print_share': 'Ragaa kana maxxansiisuu ykn PDF akka faayilii hirmaachuu dandeessa.',
      
      // Admin
      'import_questions': 'Gaaffilee Fudhachiisi',
      'current_questions': 'Gaaffilee Ammaa Jiran',
      'questions_count': 'gaaffilee',
      'import': 'Fudhachiisi',
      'importing': 'Fudhachii jira...',
      'clear_all_questions': 'Gaaffilee Hunda Haquu',
      'clearing': 'Haquu jira...',
      'warning': 'Akeekkachiisa',
      'this_will_delete': 'Kun gaaffilee hunda Firestore irraa ni haqata. Eegumsaan fayyadami!',
      'instructions': 'Qajeelfamoota',
    },
    'ti': {
      // Common
      'app_name': 'ፈተና ህንጻ',
      'welcome': 'እንቋዕ ብደሓን መጻእኩም',
      'welcome_back': 'እንቋዕ ተመሊስኩም!',
      'loading': 'እናጽናን ኣሎና...',
      'error': 'ጌጋ',
      'success': 'ዓወት',
      'cancel': 'ኣብርህ',
      'save': 'ዓቅብ',
      'delete': 'ሰርዝ',
      'edit': 'ኣርም',
      'done': 'ወዲእኩም',
      'next': 'ቀጺሉ',
      'back': 'ንድሕሪት',
      'close': 'ዕጸዋ',
      
      // Language Selection
      'select_language': 'ቋንቋ ምረጽ',
      
      // Authentication
      'sign_in': 'እተው',
      'sign_up': 'ተመዝግብ',
      'register': 'ተመዝግብ',
      'create_account': 'ኣካውንት ፍጠር',
      'login': 'እተው',
      'logout': 'ውጻእ',
      'email': 'ኢመይል',
      'email_address': 'ኣድራሻ ኢመይል',
      'password': 'መሕለፊ ቃል',
      'confirm_password': 'መሕለፊ ቃል ኣረጋግጽ',
      'full_name': 'ምሉእ ስም',
      'phone': 'ተሌፎን',
      'address': 'ኣድራሻ',
      'remember_me': 'ዘክርኒ',
      'forgot_password': 'መሕለፊ ቃል ረሲንካ?',
      'enter_email_reset': 'ኣድራሻ ኢመይልካ ኣእቱ, ንመሕለፊ ቃልካ ንምምላስ ሊንክ ክንሰዲድካ ኢና።',
      'send_reset_link': 'ሊንክ ምምላስ ሰዲድ',
      'check_email': 'ኢመይልካ ርአ',
      'reset_link_sent': 'ንመሕለፊ ቃልካ ንምምላስ ሊንክ ናብ ኣድራሻ ኢመይልካ ሰዲድና ኣለና።',
      'email_sent_success': 'ኢመይል ብዓወት ተሰዲዱ!',
      'check_inbox': 'በጃኻ ኣብ ሳንዱቕ ኢመይልካ ርአ ከምኡውን ንመሕለፊ ቃልካ ንምምላስ መምርሒታት ተኸተል።',
      'back_to_login': 'ናብ እተው ተመለስ',
      'email_required': 'ኢመይል የድሊ',
      'invalid_email': 'ብጹሕ ኢመይል ኣእቱ',
      'email_not_found': 'ምስዚ ኣድራሻ ኢመይል ኣካውንት ኣይተረኽበን።',
      'reset_failed': 'ኢመይል ምምላስ ኣይተሰዲዱን። በጃኻ ከኣ እንደገና ፈትን።',
      'dont_have_account': 'ኣካውንት የብልካን? ተመዝግብ',
      'already_have_account': 'ኣካውንት ኣለካ? እተው',
      'sign_in_to_continue': 'ንትምህርትካ ንምቀጻል እተው',
      'join_us_to_start': 'ንፈተና ህንጻ ንምድላይ ንኽትጅምር ምሳና ተጸንበር',
      
      // Home
      'home': 'ቤት',
      'ready_to_practice': 'ንፈተና ህንጻ ሕቶታት ክትለማመድ እትደሊ ዲኻ?',
      'total_questions': 'ጠቅላላ ሕቶታት',
      'start_continue_exam': 'ፈተና ጀምር / ቀጻሊ',
      'certificate_ready': 'ሰራፍ ድሉው እዩ!',
      'pass': 'ሓለፈ',
      'pass_status': 'ሓሊፉ',
      'correct': 'ግቡእ',
      'wrong': 'ጌጋ',
      'attempted': 'ኣጽዲቑ',
      
      // Questions
      'questions': 'ሕቶታት',
      'question': 'ሕቶ',
      'of': 'ካብ',
      'next_question': 'ዝቕጽል ሕቶ',
      'finish_exam': 'ፈተና ዛዘም',
      'correct_answer': 'ግቡእ!',
      'well_done': 'ጽቡቕ! ብግቡእ ሰሊኻ።',
      'incorrect': 'ጌጋ',
      'try_again': 'እንደገና ፈትን',
      'try_again_message': 'እቲ ግቡእ መልሲ ብሓምለዋይ ተመልክቱ። ልምምድ ቀጻል!',
      'no_questions_available': 'ሕቶታት ኣይተረኽቡን',
      'load_questions': 'ሕቶታት ጽዓን',
      
      // Progress
      'progress': 'ዕቤት',
      'my_progress': 'ዕቤተይ',
      'completion_progress': 'ዕቤት ምዝዛን',
      'exam_completion': 'ዝዛን ፈተና',
      'overall_progress': 'ናይ ሓጹር ዕቤት',
      'answer_statistics': 'ስታትስቲክስ መልሲ',
      'answer_distribution': 'ኣከፋፈል መልሲ',
      'performance_summary': 'ገምጋም ውዳእ',
      'total_questions_attempted': 'ጠቅላላ ሕቶታት እተገብሩ',
      'correct_answers': 'ግቡእ መልስታት',
      'incorrect_answers': 'ጌጋ መልስታት',
      'accuracy_rate': 'ደረጃ ትክክለኛነት',
      'no_answers_yet': 'ክሳድ መልስታት የለን',
      
      // Profile
      'profile': 'መገለጺ',
      'view_certificate': 'ሰራፍ ርአ',
      'tap_to_view_download': 'ንምርኣይ ወይ ንምውራድ ኣድርድ',
      'profile_updated': 'መገለጺ ብዓወት ተዘምነ',
      
      // Materials
      'materials': 'ቁሳቁስ',
      'no_materials': 'ቁሳቁስ ኣይተረኽቡን',
      'open_pdf': 'PDF ክፈት',
      
      // Messages
      'messages': 'መልእኽቲ',
      'no_conversations': 'ክሳድ ዘበሳልዕ የለን',
      'start_conversation': 'ዘበሳልዕ ንምጅማር + ኣድርድ',
      'no_messages': 'ክሳድ መልእኽቲ የለን',
      'start_chat': 'እቲ ዘበሳልዕ ኣብ ታሕቲ ጀምር',
      'type_message': 'መልእኽቲ ጽሓፍ...',
      
      // Certificate
      'certificate': 'ሰራፍ',
      'certificate_of_completion': 'ሰራፍ ምዝዛን',
      'this_is_to_certify': 'እዚ ንምረጋግጽ',
      'has_successfully_completed': 'ብዓወት ዛዘመ',
      'construction_exam': 'ፈተና ህንጻ',
      'with_completion_rate': 'ደረጃ ምዝዛን ምስ',
      'signature': 'ፊርማ',
      'date': 'ዕለት',
      'certificate_id': 'ID ሰራፍ',
      'print': 'ኣተሓሕዝ',
      'export_pdf': 'PDF ላእል',
      'exporting': 'እናላእል ኣሎና...',
      'certificate_exported': 'ሰራፍ ብዓወት ተላኢሉ!',
      'you_can_print_share': 'እዚ ሰራፍ ክትተሓሕዞ ወይ ከም PDF ክትካፈሎ ትኽእል ኢኻ።',
      
      // Admin
      'import_questions': 'ሕቶታት ኣእትው',
      'current_questions': 'ናይ ሕጂ ሕቶታት',
      'questions_count': 'ሕቶታት',
      'import': 'ኣእትው',
      'importing': 'እናእትው ኣሎና...',
      'clear_all_questions': 'ኩሉ ሕቶታት ኣጽርዮ',
      'clearing': 'እናጽርይ ኣሎና...',
      'warning': 'መጠንቀቕታ',
      'this_will_delete': 'እዚ ኩሉ ሕቶታት ካብ Firestore ክሰርዝ እዩ። ብጥንቃቐ ተጠቐም!',
      'instructions': 'መምርሒታት',
    },
    'ar': {
      // Common
      'app_name': 'امتحان البناء',
      'welcome': 'مرحباً',
      'welcome_back': 'مرحباً بعودتك!',
      'loading': 'جاري التحميل...',
      'error': 'خطأ',
      'success': 'نجح',
      'cancel': 'إلغاء',
      'save': 'حفظ',
      'delete': 'حذف',
      'edit': 'تعديل',
      'done': 'تم',
      'next': 'التالي',
      'back': 'رجوع',
      'close': 'إغلاق',
      
      // Language Selection
      'select_language': 'اختر اللغة',
      
      // Authentication
      'sign_in': 'تسجيل الدخول',
      'sign_up': 'التسجيل',
      'register': 'التسجيل',
      'create_account': 'إنشاء حساب',
      'login': 'تسجيل الدخول',
      'logout': 'تسجيل الخروج',
      'email': 'البريد الإلكتروني',
      'email_address': 'عنوان البريد الإلكتروني',
      'password': 'كلمة المرور',
      'confirm_password': 'تأكيد كلمة المرور',
      'full_name': 'الاسم الكامل',
      'phone': 'الهاتف',
      'address': 'العنوان',
      'remember_me': 'تذكرني',
      'forgot_password': 'نسيت كلمة المرور؟',
      'enter_email_reset': 'أدخل عنوان بريدك الإلكتروني وسنرسل لك رابطًا لإعادة تعيين كلمة المرور.',
      'send_reset_link': 'إرسال رابط إعادة التعيين',
      'check_email': 'تحقق من بريدك الإلكتروني',
      'reset_link_sent': 'لقد أرسلنا رابط إعادة تعيين كلمة المرور إلى عنوان بريدك الإلكتروني.',
      'email_sent_success': 'تم إرسال البريد الإلكتروني بنجاح!',
      'check_inbox': 'يرجى التحقق من صندوق الوارد الخاص بك واتباع التعليمات لإعادة تعيين كلمة المرور.',
      'back_to_login': 'العودة إلى تسجيل الدخول',
      'email_required': 'البريد الإلكتروني مطلوب',
      'invalid_email': 'يرجى إدخال بريد إلكتروني صحيح',
      'email_not_found': 'لم يتم العثور على حساب بهذا العنوان الإلكتروني.',
      'reset_failed': 'فشل إرسال بريد إعادة التعيين. يرجى المحاولة مرة أخرى.',
      'dont_have_account': 'ليس لديك حساب؟ سجل',
      'already_have_account': 'لديك حساب بالفعل؟ سجل الدخول',
      'sign_in_to_continue': 'سجل الدخول لمتابعة رحلة التعلم الخاصة بك',
      'join_us_to_start': 'انضم إلينا لبدء التحضير لامتحان البناء',
      
      // Home
      'home': 'الرئيسية',
      'ready_to_practice': 'هل أنت مستعد لممارسة أسئلة امتحان البناء؟',
      'total_questions': 'إجمالي الأسئلة',
      'start_continue_exam': 'ابدأ / تابع الامتحان',
      'certificate_ready': 'الشهادة جاهزة!',
      'pass': 'نجح',
      'pass_status': 'نجح',
      'correct': 'صحيح',
      'wrong': 'خطأ',
      'attempted': 'محاول',
      
      // Questions
      'questions': 'الأسئلة',
      'question': 'سؤال',
      'of': 'من',
      'next_question': 'السؤال التالي',
      'finish_exam': 'إنهاء الامتحان',
      'correct_answer': 'صحيح!',
      'well_done': 'أحسنت! لقد أجبت بشكل صحيح.',
      'incorrect': 'خطأ',
      'try_again': 'حاول مرة أخرى',
      'try_again_message': 'الإجابة الصحيحة مميزة باللون الأخضر. استمر في الممارسة!',
      'no_questions_available': 'لا توجد أسئلة متاحة',
      'load_questions': 'تحميل الأسئلة',
      
      // Progress
      'progress': 'التقدم',
      'my_progress': 'تقدمي',
      'completion_progress': 'تقدم الإكمال',
      'exam_completion': 'إكمال الامتحان',
      'overall_progress': 'التقدم الإجمالي',
      'answer_statistics': 'إحصائيات الإجابات',
      'answer_distribution': 'توزيع الإجابات',
      'performance_summary': 'ملخص الأداء',
      'total_questions_attempted': 'إجمالي الأسئلة المحاولة',
      'correct_answers': 'إجابات صحيحة',
      'incorrect_answers': 'إجابات خاطئة',
      'accuracy_rate': 'معدل الدقة',
      'no_answers_yet': 'لا توجد إجابات بعد',
      
      // Profile
      'profile': 'الملف الشخصي',
      'view_certificate': 'عرض الشهادة',
      'tap_to_view_download': 'اضغط لعرض أو تنزيل',
      'profile_updated': 'تم تحديث الملف الشخصي بنجاح',
      
      // Materials
      'materials': 'المواد',
      'no_materials': 'لا توجد مواد متاحة',
      'open_pdf': 'فتح PDF',
      
      // Messages
      'messages': 'الرسائل',
      'no_conversations': 'لا توجد محادثات بعد',
      'start_conversation': 'اضغط على + لبدء محادثة',
      'no_messages': 'لا توجد رسائل بعد',
      'start_chat': 'ابدأ المحادثة أدناه',
      'type_message': 'اكتب رسالة...',
      
      // Certificate
      'certificate': 'الشهادة',
      'certificate_of_completion': 'شهادة الإكمال',
      'this_is_to_certify': 'هذا للتأكيد على أن',
      'has_successfully_completed': 'أكمل بنجاح',
      'construction_exam': 'امتحان البناء',
      'with_completion_rate': 'بمعدل إكمال',
      'signature': 'التوقيع',
      'date': 'التاريخ',
      'certificate_id': 'معرف الشهادة',
      'print': 'طباعة',
      'export_pdf': 'تصدير PDF',
      'exporting': 'جاري التصدير...',
      'certificate_exported': 'تم تصدير الشهادة بنجاح!',
      'you_can_print_share': 'يمكنك طباعة أو مشاركة هذه الشهادة كملف PDF.',
      
      // Admin
      'import_questions': 'استيراد الأسئلة',
      'current_questions': 'الأسئلة الحالية',
      'questions_count': 'أسئلة',
      'import': 'استيراد',
      'importing': 'جاري الاستيراد...',
      'clear_all_questions': 'مسح جميع الأسئلة',
      'clearing': 'جاري المسح...',
      'warning': 'تحذير',
      'this_will_delete': 'سيؤدي هذا إلى حذف جميع الأسئلة من Firestore. استخدم بحذر!',
      'instructions': 'التعليمات',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? 
           _localizedValues['en']?[key] ?? 
           key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'am', 'om', 'ti', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

