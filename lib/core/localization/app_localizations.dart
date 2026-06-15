import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  bool get isZh => locale.languageCode == 'zh';

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static final Map<String, Map<String, String>> _t = {
    'en': {
      'app_name': 'FinWise',
      'smart_finance': 'Smart finance, simplified',
      'welcome_back': 'Welcome back',
      'sign_in': 'Sign In',
      'sign_up': 'Sign Up',
      'create_account': 'Create Account',
      'join_finwise': 'Join FinWise',
      'create_your_account': 'Create your account',
      'email': 'Email',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'email_hint': 'you@example.com',
      'password_hint': '••••••••',
      'confirm_password_hint': 'Re-enter password',
      'dont_have_account': "Don't have an account? ",
      'already_have_account': 'Already have an account? ',
      'analytics': 'Analytics',
      'financial_insights': 'Your financial insights',
      'settings': 'Settings',
      'ai_assistant': 'AI Assistant',
      'ready_to_help': 'Ready to help',
      'smart_companion': 'Your smart financial companion',
      'ask_me_anything': 'Ask me anything...',
      'thinking': 'Thinking...',
      'overview': 'Overview',
      'monthly_spent': 'Monthly Spent',
      'budget_limit': 'Budget Limit',
      'today_spending': "Today's Spending",
      'vs_last_month': 'vs Last Month',
      'monthly_progress': 'Monthly Progress',
      'used': 'used',
      'remaining': 'remaining',
      'insights': 'Insights',
      'start_tracking': 'Start Tracking!',
      'start_tracking_desc': 'Record your first transaction to see personalized insights about your spending patterns.',
      'budget_vs_spent': 'Budget vs Spent',
      'category': 'Category',
      'transactions': 'Transactions',
      'last_7_days': 'Last 7 Days',
      'transaction': 'transaction',
      'no_recent_transactions': 'No recent transactions',
      'no_transactions_period': 'No transactions for this period',
      'this_week': 'This Week',
      'this_month': 'This Month',
      'this_year': 'This Year',
      'all_time': 'All Time',
      'custom': 'Custom',
      'profile': 'Profile',
      'language': 'Language',
      'transaction_history': 'Transaction History',
      'no_transactions_yet': 'No transactions yet',
      'start_recording': 'Start by recording your first expense',
      'delete_transaction': 'Delete Transaction?',
      'delete_confirm': 'Are you sure you want to delete this transaction?',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'transaction_deleted': 'Transaction deleted',
      'coming_soon': 'settings coming soon',
      'recording_expense': "I've recorded your expense!",
      'expense_recorded': 'Expense Recorded',
      'failed_expense': 'Failed to record expense.',
      'reminder_saved': 'Reminder saved!',
      'reminder_set': 'Reminder Set',
      'failed_reminder': 'Failed to save reminder.',
      'failed_budget': 'Failed to set budget.',
      'budget_set': 'Budget Set!',
      'ai_not_configured': 'AI assistant is not configured. Please add your GEMINI_API_KEY to the .env file.',
      'record_lunch': 'Record lunch \$15',
      'adjust_budget': 'Adjust my budget',
      'set_spending': 'Set spending limit',
      'set_reminder': 'Set reminder',
      'category_food': 'Food',
      'category_transport': 'Transport',
      'category_shopping': 'Shopping',
      'category_entertainment': 'Entertainment',
      'category_bills': 'Bills',
      'category_health': 'Health',
      'category_other': 'Other',
      'language_setting': 'Language',
      'language_subtitle': 'Choose your preferred language',
      'english': 'English',
      'traditional_chinese': 'Traditional Chinese',
      'language_changed': 'Language changed to English',
      'language_changed_zh': '語言已切換為繁體中文',
    },
    'zh': {
      'app_name': 'FinWise',
      'smart_finance': '智慧理財，簡單生活',
      'welcome_back': '歡迎回來',
      'sign_in': '登入',
      'sign_up': '註冊',
      'create_account': '建立帳戶',
      'join_finwise': '加入 FinWise',
      'create_your_account': '建立您的帳戶',
      'email': '電子郵件',
      'password': '密碼',
      'confirm_password': '確認密碼',
      'email_hint': 'you@example.com',
      'password_hint': '••••••••',
      'confirm_password_hint': '重新輸入密碼',
      'dont_have_account': '還沒有帳戶？ ',
      'already_have_account': '已有帳戶？ ',
      'analytics': '分析',
      'financial_insights': '您的財務洞察',
      'settings': '設定',
      'ai_assistant': 'AI 助理',
      'ready_to_help': '準備為您服務',
      'smart_companion': '您的智慧財務夥伴',
      'ask_me_anything': '問我任何事...',
      'thinking': '思考中...',
      'overview': '總覽',
      'monthly_spent': '本月支出',
      'budget_limit': '預算上限',
      'today_spending': '今日支出',
      'vs_last_month': '與上月比較',
      'monthly_progress': '每月進度',
      'used': '已使用',
      'remaining': '剩餘',
      'insights': '洞察',
      'start_tracking': '開始記錄！',
      'start_tracking_desc': '記錄您的第一筆交易，即可看到個人化的消費分析。',
      'budget_vs_spent': '預算 vs 支出',
      'category': '分類',
      'transactions': '交易紀錄',
      'last_7_days': '最近 7 天',
      'transaction': '筆交易',
      'no_recent_transactions': '最近沒有交易紀錄',
      'no_transactions_period': '此時間範圍內沒有交易紀錄',
      'this_week': '本週',
      'this_month': '本月',
      'this_year': '今年',
      'all_time': '全部',
      'custom': '自訂',
      'profile': '個人資料',
      'language': '語言',
      'transaction_history': '交易紀錄',
      'no_transactions_yet': '尚無交易紀錄',
      'start_recording': '開始記錄您的第一筆消費',
      'delete_transaction': '刪除交易？',
      'delete_confirm': '您確定要刪除這筆交易嗎？',
      'cancel': '取消',
      'delete': '刪除',
      'transaction_deleted': '交易已刪除',
      'coming_soon': '設定即將推出',
      'recording_expense': '已記錄您的消費！',
      'expense_recorded': '消費已記錄',
      'failed_expense': '記錄消費失敗。',
      'reminder_saved': '提醒已儲存！',
      'reminder_set': '提醒已設定',
      'failed_reminder': '儲存提醒失敗。',
      'failed_budget': '設定預算失敗。',
      'budget_set': '預算已設定！',
      'ai_not_configured': 'AI 助理未設定。請在 .env 檔案中加入 GEMINI_API_KEY。',
      'record_lunch': '記錄午餐 \$15',
      'adjust_budget': '調整預算',
      'set_spending': '設定支出限額',
      'set_reminder': '設定提醒',
      'category_food': '餐飲',
      'category_transport': '交通',
      'category_shopping': '購物',
      'category_entertainment': '娛樂',
      'category_bills': '帳單',
      'category_health': '醫療',
      'category_other': '其他',
      'language_setting': '語言',
      'language_subtitle': '選擇您的偏好語言',
      'english': 'English',
      'traditional_chinese': '繁體中文',
      'language_changed': 'Language changed to English',
      'language_changed_zh': '語言已切換為繁體中文',
    },
  };

  String tr(String key) => _t[locale.languageCode]?[key] ?? _t['en']?[key] ?? key;

  String get appName => tr('app_name');
  String get smartFinance => tr('smart_finance');
  String get welcomeBack => tr('welcome_back');
  String get signIn => tr('sign_in');
  String get signUp => tr('sign_up');
  String get createAccount => tr('create_account');
  String get joinFinwise => tr('join_finwise');
  String get createYourAccount => tr('create_your_account');
  String get email => tr('email');
  String get password => tr('password');
  String get confirmPassword => tr('confirm_password');
  String get emailHint => tr('email_hint');
  String get passwordHint => tr('password_hint');
  String get confirmPasswordHint => tr('confirm_password_hint');
  String get dontHaveAccount => tr('dont_have_account');
  String get alreadyHaveAccount => tr('already_have_account');
  String get analytics => tr('analytics');
  String get financialInsights => tr('financial_insights');
  String get settings => tr('settings');
  String get aiAssistant => tr('ai_assistant');
  String get readyToHelp => tr('ready_to_help');
  String get smartCompanion => tr('smart_companion');
  String get askMeAnything => tr('ask_me_anything');
  String get thinking => tr('thinking');
  String get overview => tr('overview');
  String get monthlySpent => tr('monthly_spent');
  String get budgetLimit => tr('budget_limit');
  String get todaySpending => tr('today_spending');
  String get vsLastMonth => tr('vs_last_month');
  String get monthlyProgress => tr('monthly_progress');
  String get used => tr('used');
  String get remaining => tr('remaining');
  String get insights => tr('insights');
  String get startTracking => tr('start_tracking');
  String get startTrackingDesc => tr('start_tracking_desc');
  String get budgetVsSpent => tr('budget_vs_spent');
  String get category => tr('category');
  String get transactions => tr('transactions');
  String get last7Days => tr('last_7_days');
  String get transaction => tr('transaction');
  String get noRecentTransactions => tr('no_recent_transactions');
  String get noTransactionsPeriod => tr('no_transactions_period');
  String get thisWeek => tr('this_week');
  String get thisMonth => tr('this_month');
  String get thisYear => tr('this_year');
  String get allTime => tr('all_time');
  String get custom => tr('custom');
  String get profile => tr('profile');
  String get language => tr('language');
  String get transactionHistory => tr('transaction_history');
  String get noTransactionsYet => tr('no_transactions_yet');
  String get startRecording => tr('start_recording');
  String get deleteTransaction => tr('delete_transaction');
  String get deleteConfirm => tr('delete_confirm');
  String get cancel => tr('cancel');
  String get delete => tr('delete');
  String get transactionDeleted => tr('transaction_deleted');
  String get comingSoon => tr('coming_soon');
  String get recordingExpense => tr('recording_expense');
  String get expenseRecorded => tr('expense_recorded');
  String get failedExpense => tr('failed_expense');
  String get reminderSaved => tr('reminder_saved');
  String get reminderSet => tr('reminder_set');
  String get failedReminder => tr('failed_reminder');
  String get failedBudget => tr('failed_budget');
  String get budgetSet => tr('budget_set');
  String get aiNotConfigured => tr('ai_not_configured');
  String get recordLunch => tr('record_lunch');
  String get adjustBudget => tr('adjust_budget');
  String get setSpending => tr('set_spending');
  String get setReminder => tr('set_reminder');
  String get categoryFood => tr('category_food');
  String get categoryTransport => tr('category_transport');
  String get categoryShopping => tr('category_shopping');
  String get categoryEntertainment => tr('category_entertainment');
  String get categoryBills => tr('category_bills');
  String get categoryHealth => tr('category_health');
  String get categoryOther => tr('category_other');
  String get languageSetting => tr('language_setting');
  String get languageSubtitle => tr('language_subtitle');
  String get english => tr('english');
  String get traditionalChinese => tr('traditional_chinese');
  String get languageChanged => tr('language_changed');
  String get languageChangedZh => tr('language_changed_zh');
}
