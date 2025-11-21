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
    return ['en', 'am', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

