class TUserProfileValidator {
  TUserProfileValidator._();

  static String? validateEmptyText(String? fieldName, String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the $fieldName.';
    }

    return null;
  }

  /// Validate username
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a username.';
    }

    if (value.trim().length < 3) {
      return 'Username must be at least 3 characters long.';
    }

    if (value.trim().length > 30) {
      return 'Username must not exceed 30 characters.';
    }

    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the email address.';
    }

    // Regular expression for email validation
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!emailRegExp.hasMatch(value)) {
      return 'Invalid email address.';
    }

    return null;
  }

  /// Validate Malaysian phone number (must start with 0, no dashes)
  /// Stored format: 60XXXXXXXXX (without +)
  /// Input format: 0XXXXXXXXXX
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // 可选字段

    // 先统一清洗：去掉空格、- 等非数字
    var phone = value.replaceAll(RegExp(r'\D'), '');

    // 支持 601..., 01..., 1... 这几种输入，先 normalize 成 storage 格式方便判断
    final normalized = normalizeMalaysiaPhone(phone); // 一定是 60 开头

    // normalized 形如 6017xxxxxxx / 6011xxxxxxxx
    if (!normalized.startsWith('60')) {
      return 'Invalid phone number.';
    }

    final national = normalized.substring(2); // 去掉 60，剩下 1X...

    // 必须是以 1 开头的 mobile
    if (!national.startsWith('1')) {
      return 'Invalid Malaysian mobile number.';
    }

    // prefix：011, 012, 017...
    final prefix3 = '0' + national.substring(0, 2);
    // national: 17xxxxxxx / 11xxxxxxxx
    final local = '0$national'; // 转回本地 0 开头，方便用户理解长度规则

    if (prefix3 == '011' || prefix3 == '015') {
      if (local.length != 11) return '011/015 numbers must be 11 digits';
    } else {
      if (local.length != 10) return 'Mobile numbers must be 10 digits';
    }

    return null;
  }

  static String normalizeMalaysiaPhone(String input) {
    var phone = input.replaceAll(RegExp(r'\D'), ''); // 去掉空格、- 等

    // 已经是 60 开头（6017..., 6011...）
    if (phone.startsWith('60')) {
      return phone;
    }

    // 本地写法：01xxxx...
    if (phone.startsWith('0')) {
      // 去掉前面的 0，再加上 60
      phone = phone.substring(1); // 1 开头，例如 17xxxxxxx 或 11xxxxxxxx
      return '60$phone';
    }

    // 其它情况（容错处理）：如果不是 0/60 开头，就直接当作本地号加 60
    return '60$phone';
  }

  /// Convert Malaysian phone from 0XX to 60XX format for storage
  static String convertToStorageFormat(String phoneNumber) {
    return normalizeMalaysiaPhone(phoneNumber);
  }

  /// Convert from storage format (60XX) to display format (0XX)
  static String convertToDisplayFormat(String phone) {
    if (phone.startsWith('60')) {
      return '0${phone.substring(2)}';
    }
    return phone;
  }

  /// Validate gender
  static String? validateGender(String? value) {
    if (value == null || value.trim().isEmpty) {
      // return 'Please select a gender.';
      return null;
    }

    if (!['M', 'F'].contains(value)) {
      return 'Invalid gender selection.';
    }

    return null;
  }

  /// Validate date of birth
  static String? validateDateOfBirth(DateTime? value) {
    if (value == null) {
      // return 'Please select your date of birth.';
      return null;
    }

    final now = DateTime.now();
    final age = now.year - value.year;

    if (age < 13) {
      return 'You must be at least 13 years old.';
    }

    if (age > 120) {
      return 'Please enter a valid date of birth.';
    }

    return null;
  }

  /// Validate height (cm)
  static String? validateHeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your height.';
    }

    final height = double.tryParse(value);
    if (height == null) {
      return 'Please enter a valid number.';
    }

    if (height <= 0 || height > 273.9) {
      return 'Height must be between 0.1 and 273.9 cm.';
    }

    // Check decimal places
    if (value.contains('.') && value.split('.')[1].length > 1) {
      return 'Height can have at most 1 decimal place.';
    }

    return null;
  }

  /// Validate prescribed frequency
  static String? validatePrescribedFrequency(String? value) {
    if (value == null || value.trim().isEmpty) {
      // return 'Please enter the frequency.';
      return null;
    }

    final frequency = int.tryParse(value);
    if (frequency == null) {
      return 'Please enter a valid number.';
    }

    if (frequency < 0 || frequency > 10) {
      return 'Frequency must be between 0 and 10.';
    }

    return null;
  }

  /// Validate sleep duration (hours)
  static String? validateSleepDuration(String? value) {
    if (value == null || value.trim().isEmpty) {
      // return 'Please enter sleep duration.';
      return null;
    }

    final duration = double.tryParse(value);
    if (duration == null) {
      return 'Please enter a valid number.';
    }

    if (duration < 0 || duration > 24) {
      return 'Sleep duration must be between 0 and 24 hours.';
    }

    // Check decimal places
    if (value.contains('.') && value.split('.')[1].length > 1) {
      return 'Duration can have at most 1 decimal place.';
    }

    return null;
  }

  /// Validate stress level (1-10 scale)
  static String? validateStressLevel(int? value) {
    if (value == null) {
      return 'Please select your stress level.';
    }

    if (value < 1 || value > 10) {
      return 'Stress level must be between 1 and 10.';
    }

    return null;
  }

  /// Validate water intake (ml)
  static String? validateWaterIntake(String? value) {
    if (value == null || value.trim().isEmpty) {
      // return 'Please enter water intake.';
      return null;
    }

    final intake = int.tryParse(value);
    if (intake == null) {
      return 'Please enter a valid number.';
    }

    if (intake < 0 || intake > 10000) {
      return 'Water intake must be between 0 and 10000 ml.';
    }

    return null;
  }

  /// Validate daily steps goal
  static String? validateDailyStepsGoal(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter daily steps goal.';
      // return null;
    }

    final steps = int.tryParse(value);
    if (steps == null) {
      return 'Please enter a valid number.';
    }

    if (steps < 1000 || steps > 50000) {
      return 'Daily steps goal must be between 1,000 and 50,000 steps.';
    }

    return null;
  }

  /// Validate weekly exercise time (minutes)
  static String? validateWeeklyExerciseTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter weekly exercise time.';
      // return null;
    }

    final exerciseTime = int.tryParse(value);
    if (exerciseTime == null) {
      return 'Please enter a valid number.';
    }

    if (exerciseTime < 0 || exerciseTime > 1000) {
      return 'Weekly exercise time must be between 0 and 1000 minutes.';
    }

    return null;
  }

  /// Validate old password (for password change)
  static String? validateOldPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your current password.';
    }

    return null;
  }

  /// Validate new password
  static String? validateNewPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a new password.';
    }

    // Check for minimum password length
    if (value.length < 8) {
      return 'Password must be at least 8 characters long.';
    }

    // Check for uppercase letters
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter.';
    }

    // Check for lowercase letters
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter.';
    }

    // Check for numbers
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number.';
    }

    // Check for special characters
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character.';
    }

    return null;
  }

  /// Validate confirm password
  static String? validateConfirmNewPassword(String? value, String newPassword) {
    if (value == null || value.trim().isEmpty) {
      return 'Please confirm your new password.';
    }

    if (value != newPassword) {
      return 'Passwords do not match.';
    }

    return null;
  }
}