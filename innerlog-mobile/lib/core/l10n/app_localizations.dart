import 'package:flutter/material.dart';

/// Manual AppLocalizations (replaces flutter gen-l10n output).
/// Supports Vietnamese (default) and English.
class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const supportedLocales = [Locale('vi'), Locale('en')];

  String get _lang => locale.languageCode;

  String _t(String vi, String en) => _lang == 'en' ? en : vi;

  // ── App ────────────────────────────────────────────────────────
  String get appName => 'InnerLog';

  // ── Auth ───────────────────────────────────────────────────────
  String get login => _t('Đăng nhập', 'Log in');
  String get register => _t('Đăng ký', 'Sign up');
  String get logout => _t('Đăng xuất', 'Log out');
  String get email => 'Email';
  String get password => _t('Mật khẩu', 'Password');
  String get displayName => _t('Tên hiển thị', 'Display name');
  String get noAccount => _t('Chưa có tài khoản? Đăng ký', "Don't have an account? Sign up");
  String get hasAccount => _t('Đã có tài khoản? Đăng nhập', 'Already have an account? Log in');
  String get loginFailed => _t('Email hoặc mật khẩu không đúng', 'Incorrect email or password');
  String get registerFailed => _t('Đăng ký thất bại. Email có thể đã được sử dụng.', 'Registration failed. Email may already be in use.');
  String get emailRequired => _t('Vui lòng nhập email', 'Please enter your email');
  String get emailInvalid => _t('Email không hợp lệ', 'Invalid email');
  String get passwordRequired => _t('Vui lòng nhập mật khẩu', 'Please enter your password');
  String get passwordMinLength => _t('Mật khẩu tối thiểu 6 ký tự', 'Password must be at least 6 characters');
  String get nameRequired => _t('Vui lòng nhập tên', 'Please enter your name');

  // ── Navigation ─────────────────────────────────────────────────
  String get home => 'Home';
  String get checkin => 'Check-in';
  String get insights => 'Insights';
  String get goals => _t('Mục tiêu', 'Goals');
  String get profile => _t('Hồ sơ', 'Profile');
  String get notifications => _t('Thông báo', 'Notifications');

  // ── Onboarding ─────────────────────────────────────────────────
  String get onboardingSubtitle => _t(
    'Theo dõi cảm xúc mỗi ngày.\nAI phân tích xu hướng & đưa ra insight thông minh.',
    'Track your emotions daily.\nAI analyzes trends & delivers smart insights.',
  );
  String get onboardingPrivacy => _t(
    'Riêng tư. Không social. Không bán dữ liệu.',
    'Private. No social. No data selling.',
  );
  String get onboardingReminder => _t('Nhắc nhở hàng ngày', 'Daily reminder');
  String get onboardingReminderSub => _t(
    'Chọn giờ bạn muốn check-in mỗi ngày',
    "Choose when you'd like to check in each day",
  );
  String get enableReminder => _t('Bật nhắc nhở', 'Enable reminder');
  String get onboardingMood => _t('Hôm nay bạn thế nào?', 'How are you today?');
  String get continueBtn => _t('Tiếp tục', 'Continue');
  String get skip => _t('Bỏ qua', 'Skip');
  String get startJourney => _t('Bắt đầu hành trình 🚀', 'Start your journey 🚀');

  // ── Check-in ───────────────────────────────────────────────────
  String get dailyCheckin => 'Daily Check-in';
  String get howAreYou => _t('Hôm nay bạn cảm thấy thế nào?', 'How are you feeling today?');
  String get energy => _t('Năng lượng', 'Energy');
  String get energyLow => _t('Thấp', 'Low');
  String get energyNormal => _t('Bình thường', 'Normal');
  String get energyHigh => _t('Cao', 'High');
  String get tags => 'Tags';
  String get noteOptional => _t('Ghi chú (tùy chọn)', 'Note (optional)');
  String get noteHint => _t('Hôm nay có gì đặc biệt?', 'Anything special today?');
  String get checkinSuccess => _t('Check-in thành công! ✨', 'Check-in successful! ✨');
  String get checkinError => _t('Lỗi khi check-in. Vui lòng thử lại.', 'Check-in failed. Please try again.');
  String get offlineCheckin => _t(
    'Đang offline — check-in đã lưu, sẽ đồng bộ khi có mạng 📡',
    "You're offline — check-in saved, will sync when back online 📡",
  );
  String get streak => 'Streak';
  String get record => _t('Kỷ lục', 'Record');
  String get currentStreak => _t('Streak hiện tại', 'Current streak');
  String get congratulations => _t('🎉 Chúc mừng!', '🎉 Congratulations!');
  String streakMilestone(int days) => _t(
    'Bạn đã check-in $days ngày liên tục! Tuyệt vời!',
    "You've checked in $days days in a row! Amazing!",
  );
  String get thanks => _t('Cảm ơn!', 'Thanks!');

  // ── Tag labels ─────────────────────────────────────────────────
  String get tagWork => _t('💼 Công việc', '💼 Work');
  String get tagStudy => _t('📚 Học tập', '📚 Study');
  String get tagHealth => _t('🏃 Sức khỏe', '🏃 Health');
  String get tagRelationship => _t('❤️ Quan hệ', '❤️ Relationship');
  String get tagFinance => _t('💰 Tài chính', '💰 Finance');
  String get tagMood => _t('🧠 Cảm xúc', '🧠 Mood');

  // ── Insight ────────────────────────────────────────────────────
  String get weeklyInsight => _t('📊 Insight tuần này', '📊 This week\'s insight');
  String get viewDetail => _t('Xem chi tiết →', 'View details →');
  String get noInsight => _t('Chưa có insight. Hãy check-in thêm nhé!', 'No insights yet. Keep checking in!');
  String get latest => _t('Mới nhất', 'Latest');
  String get history => _t('Lịch sử', 'History');
  String get generateInsight => _t('Tạo insight', 'Generate insight');
  String get generating => _t('Đang tạo...', 'Generating...');
  String get generateError => _t('Không thể tạo insight. Thử lại sau.', 'Could not generate insight. Try again later.');
  String get noInsightHistory => _t('Chưa có lịch sử insight', 'No insight history yet');
  String get moodLast30 => _t('Mood 30 ngày qua', 'Mood — last 30 days');
  String get selectPeriod => _t('Chọn khoảng thời gian', 'Select time period');
  String get days7 => _t('7 ngày', '7 days');
  String get days30 => _t('30 ngày', '30 days');
  String get days60 => _t('60 ngày', '60 days');
  String get days90 => _t('90 ngày', '90 days');

  // ── Goals ──────────────────────────────────────────────────────
  String get noGoals => _t('Chưa có mục tiêu nào', 'No goals yet');
  String get createFirstGoal => _t('Tạo mục tiêu đầu tiên nhé!', 'Create your first goal!');
  String get goalName => _t('Tên mục tiêu', 'Goal name');
  String get goalCategory => _t('Loại', 'Category');
  String get createGoal => _t('Tạo mục tiêu', 'Create goal');
  String get addTask => _t('Thêm task...', 'Add task...');
  String goalsCompleted(int completed, int total) => _t(
    'Mục tiêu: $completed/$total hoàn thành',
    'Goals: $completed/$total completed',
  );

  // ── Notifications ──────────────────────────────────────────────
  String get noNotifications => _t('Chưa có thông báo', 'No notifications');
  String get markAllRead => _t('Đọc tất cả', 'Mark all read');

  // ── Profile ────────────────────────────────────────────────────
  String get language => _t('Ngôn ngữ', 'Language');
  String get timezone => _t('Múi giờ', 'Timezone');
  String get reminder => _t('Nhắc nhở', 'Reminder');
  String reminderOn(String time) => _t('Bật — $time', 'On — $time');
  String get reminderOff => _t('Tắt', 'Off');
  String get exportData => _t('Xuất dữ liệu cá nhân', 'Export personal data');
  String get dataExported => _t('Dữ liệu đã được xuất', 'Data exported');
  String get changePassword => _t('Đổi mật khẩu', 'Change password');
  String get currentPassword => _t('Mật khẩu hiện tại', 'Current password');
  String get newPassword => _t('Mật khẩu mới (tối thiểu 6 ký tự)', 'New password (min 6 characters)');
  String get confirm => _t('Xác nhận', 'Confirm');
  String get passwordChanged => _t('Đổi mật khẩu thành công', 'Password changed successfully');
  String get passwordChangeFailed => _t('Đổi mật khẩu thất bại. Kiểm tra mật khẩu hiện tại.', 'Password change failed. Check your current password.');
  String get deleteAccount => _t('Xóa tài khoản', 'Delete account');
  String get deleteAccountConfirm => _t('Xóa tài khoản?', 'Delete account?');
  String get deleteAccountWarning => _t(
    'Toàn bộ dữ liệu sẽ bị xóa vĩnh viễn. Không thể khôi phục.',
    'All data will be permanently deleted. This cannot be undone.',
  );
  String get cancel => _t('Hủy', 'Cancel');
  String get delete => _t('Xóa', 'Delete');
  String get plan => 'Plan';
  String get free => 'Free';
  String get premium => 'Premium';
  String get silentCoach => '🤖 Silent Coach';
  String get createAccount => _t('Tạo tài khoản', 'Create account');
  String get trackYourLife => _t('Theo dõi cuộc sống của bạn', 'Track your life');

  // ── Rating ─────────────────────────────────────────────────────
  String get ratingTitle => _t('Bạn thấy InnerLog hữu ích? 🌟', 'Enjoying InnerLog? 🌟');
  String get ratingMessage => _t(
    'Đánh giá 5 sao giúp InnerLog phát triển và phục vụ bạn tốt hơn!',
    'A 5-star rating helps InnerLog grow and serve you better!',
  );
  String get rateNow => _t('Đánh giá ngay ⭐', 'Rate now ⭐');
  String get rateLater => _t('Để sau', 'Later');
  String get rateNever => _t('Không hiển thị nữa', "Don't show again");

  // ── Errors ─────────────────────────────────────────────────────
  String get errorOccurred => _t('Có lỗi xảy ra', 'Something went wrong');
  String get tryAgain => _t('Vui lòng thử lại', 'Please try again');
  String syncedOffline(int count) => _t(
    'Đã đồng bộ $count check-in offline ✅',
    'Synced $count offline check-ins ✅',
  );

  // ── Mood labels (accessibility) ────────────────────────────────
  List<String> get moodLabels => _lang == 'en'
      ? ['', 'Very sad', 'Sad', 'Neutral', 'Happy', 'Very happy']
      : ['', 'Rất buồn', 'Buồn', 'Bình thường', 'Vui', 'Rất vui'];

  String moodSemantic(int score) {
    final labels = moodLabels;
    return _t(
      '${labels[score]}, điểm $score trên 5',
      '${labels[score]}, score $score out of 5',
    );
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['vi', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}
