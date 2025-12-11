import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../common/widgets/dialogs/dialog.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../utils/validators/user_profile_validator.dart';
import 'user_controller.dart';

class UpdateSingleFieldController extends GetxController {
  static UpdateSingleFieldController get instance => Get.find();

  final userController = UserController.instance;
  final userRepository = UserRepository.instance;

  /// Form Key for validation
  final editFieldFormKey = GlobalKey<FormState>();

  /// Edit Field Screen 状态管理
  final editFieldController = TextEditingController();
  final editFieldFocusNode = FocusNode();
  final editFieldHasChanges = false.obs;
  final editFieldIsSaving = false.obs;
  final editFieldIsCheckingPop = false.obs;

  /// 当前编辑的字段信息
  final currentEditField = Rx<Map<String, dynamic>?>(null);

  /// 初始化编辑字段
  void initEditField(String title, String fieldName, String currentValue,
      {TextInputType keyboardType = TextInputType.text,
        String? prefix,
        String? suffix,
        List<TextInputFormatter>? inputFormatters,
        int? maxLength}) {
    currentEditField.value = {
      'title': title,
      'fieldName': fieldName,
      'currentValue': currentValue,
      'keyboardType': keyboardType,
      'prefix': prefix,
      'suffix': suffix,
      'inputFormatters': inputFormatters,
      'maxLength': maxLength,
    };

    editFieldController.text = currentValue;
    editFieldHasChanges.value = false;
    editFieldIsSaving.value = false;
    editFieldIsCheckingPop.value = false;

    // 添加监听器
    editFieldController.addListener(_onEditFieldTextChanged);

    // 延迟获取焦点
    Future.delayed(Duration(milliseconds: 300), () {
      editFieldFocusNode.requestFocus();
    });
  }

  /// 清理编辑字段状态
  void disposeEditField() {
    editFieldController.removeListener(_onEditFieldTextChanged);
    editFieldController.clear();
    editFieldFocusNode.unfocus();
    currentEditField.value = null;
    editFieldHasChanges.value = false;
    editFieldIsSaving.value = false;
    editFieldIsCheckingPop.value = false;
  }

  /// 文本变化监听
  void _onEditFieldTextChanged() {
    final currentField = currentEditField.value;
    if (currentField != null) {
      final hasChanges = editFieldController.text.trim() != currentField['currentValue'];
      if (hasChanges != editFieldHasChanges.value) {
        editFieldHasChanges.value = hasChanges;
      }
    }
  }

  /// 检查是否可以返回
  Future<bool> checkEditFieldPopConditions() async {
    if (editFieldIsSaving.value || editFieldIsCheckingPop.value) return false;
    if (!editFieldHasChanges.value) return true;

    editFieldIsCheckingPop.value = true;

    try {
      final shouldDiscard = await TDialog.keepWriting(
        title: 'Unsaved Changes',
        message: 'You have unsaved changes. Do you want to discard them?',
      );

      return shouldDiscard == true;
    } finally {
      editFieldIsCheckingPop.value = false;
    }
  }

  /// 保存编辑字段
  Future<void> saveEditField() async {
    if (editFieldIsSaving.value) return;

    final currentField = currentEditField.value;
    if (currentField == null) return;

    // 表单验证
    if (!editFieldFormKey.currentState!.validate()) return;

    editFieldIsSaving.value = true;

    try {
      final value = editFieldController.text.trim();
      final fieldName = currentField['fieldName'];

      // 转换基于字段类型
      dynamic result;
      if (_isNumericField(fieldName)) {
        result = double.tryParse(value);
        if (result == null) {
          throw Exception('Invalid number format');
        }
      } else {
        result = value;
      }

      // 特殊处理：对于 username 和 phoneNumber，直接检查重复并保存
      if (fieldName == 'username') {
        await _saveUsernameDirectly(result as String);
      } else if (fieldName == 'phoneNumber') {
        await _savePhoneNumberDirectly(result as String);
      } else {
        // 其他字段返回结果给 ProfileScreen 处理
        Get.back(result: result);
      }
    } catch (e) {
      editFieldIsSaving.value = false;
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to save changes: $e',
      );
    }
  }

  /// 检查是否为数字字段
  bool _isNumericField(String fieldName) {
    final currentField = currentEditField.value;
    if (currentField == null) return false;

    final keyboardType = currentField['keyboardType'];
    return keyboardType == TextInputType.number ||
        keyboardType == const TextInputType.numberWithOptions(decimal: true) ||
        keyboardType == const TextInputType.numberWithOptions(signed: true) ||
        fieldName == 'height' ||
        fieldName == 'weight';
  }

  /// 直接保存 username
  Future<void> _saveUsernameDirectly(String newUsername) async {
    try {
      // 检查网络连接
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        throw 'No internet connection';
      }

      // 检查用户名重复
      final isDuplicate = await userRepository.checkUsernameDuplicate(
        newUsername,
        userController.user.value.userId,
      );

      if (isDuplicate) {
        throw TTexts.usernameAlreadyBeenUsed;
      }

      // 直接更新到数据库
      await userRepository.updateSingleField({'username': newUsername});

      // 刷新用户数据
      await userController.fetchUserRecord();

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Username updated successfully',
      );

      if (Get.context != null) {
        Navigator.of(Get.context!, rootNavigator: true).pop(newUsername);
      }
    } catch (e) {
      editFieldIsSaving.value = false;
      rethrow;
    }
  }

  /// 直接保存 phoneNumber
  Future<void> _savePhoneNumberDirectly(String phoneNumber) async {
    try {
      // 检查网络连接
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        throw 'No internet connection';
      }

      // 转换格式
      final storageFormat = TUserProfileValidator.convertToStorageFormat(phoneNumber);

      // 检查电话号码重复
      final isDuplicate = await userRepository.checkPhoneNumberDuplicate(
        storageFormat,
        userController.user.value.userId,
      );

      if (isDuplicate) {
        throw TTexts.phoneNumberAlreadyBeenUsed;
      }

      // 直接更新到数据库
      await userRepository.updateSingleField({'phoneNumber': storageFormat});

      // 刷新用户数据
      await userController.fetchUserRecord();

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Phone number updated successfully',
      );

      if (Get.context != null) {
        Navigator.of(Get.context!, rootNavigator: true).pop(phoneNumber);
      }
    } catch (e) {
      editFieldIsSaving.value = false;
      rethrow;
    }
  }

  @override
  void onClose() {
    // 清理编辑字段相关资源
    editFieldController.dispose();
    editFieldFocusNode.dispose();
    super.onClose();
  }
}