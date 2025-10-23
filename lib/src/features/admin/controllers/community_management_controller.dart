import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../utils/constants/admin_colors.dart';
import '../../../utils/constants/enums.dart'; // 导入枚举
import '../../authentication/models/user_model.dart';
import '../../community/models/post_model.dart';

class CommunityManagementController extends GetxController {
  static CommunityManagementController get instance => Get.find();

  // Observable variables
  final RxList<PostModel> allPosts = <PostModel>[].obs;
  final RxList<PostModel> filteredPosts = <PostModel>[].obs;
  final RxList<PostModel> selectedPosts = <PostModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool showingActivePosts = true.obs;
  final Rx<PostType?> selectedPostType = Rx<PostType?>(null); // 改为可空的 PostType

  // Search and sorting
  final TextEditingController searchController = TextEditingController();
  final RxInt sortColumnIndex = 0.obs;
  final RxBool sortAscending = true.obs;

  // Pagination
  final RxInt currentPage = 1.obs;
  final RxInt itemsPerPage = 10.obs;
  final RxInt totalPages = 1.obs;
  final RxList<int> itemsPerPageOptions = [10, 25, 50, 100].obs;

  // Post types for filtering
  final RxList<PostType> postTypes = PostType.values.obs; // 直接使用枚举值

  // Mock user data for poster info
  final RxMap<String, UserModel> posterData = <String, UserModel>{}.obs;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(filterPosts);
    loadMockData();
    filterPosts();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // Load mock data for demonstration
  void loadMockData() {
    // Mock posts data with mixed media types (text, image, video)
    allPosts.assignAll([
      PostModel(
        postId: 'post_001',
        posterId: 'user_001',
        postContent: 'Check out this amazing sunset! Nature is beautiful and it reminds us to appreciate the little things in life. Here are some photos I took during my evening walk.',
        postType: PostType.general, // 使用枚举
        mediaUrls: [
          'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400',
          'text:Evening walk thoughts: Taking time to appreciate nature helps reduce stress and improves mental wellbeing. The golden hour light creates the most beautiful shadows.',
          'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=400'
        ],
        likes: ['user_002', 'user_003', 'user_004', 'user_005'],
        comments: const [],
        commentCount: 0,
        isDisable: false,
        createdAt: DateTime.now().subtract(Duration(days: 2)),
        updatedAt: DateTime.now().subtract(Duration(days: 2)),
      ),
      PostModel(
        postId: 'post_002',
        posterId: 'user_002',
        postContent: 'Just finished my workout! Here are my top 5 tips for staying motivated with your fitness routine. Remember, consistency is key!',
        postType: PostType.tips, // 使用枚举
        mediaUrls: [
          'text:Top 5 Fitness Tips:\n\n1. Set realistic goals - Start small and build up\n2. Track your progress - Use apps or journals\n3. Find a workout buddy - Accountability matters\n4. Mix up your routine - Prevent boredom\n5. Celebrate small wins - Every step counts!',
          'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400'
        ],
        likes: ['user_001', 'user_004'],
        comments: const [],
        commentCount: 0,
        isDisable: false,
        createdAt: DateTime.now().subtract(Duration(days: 1)),
        updatedAt: DateTime.now().subtract(Duration(days: 1)),
      ),
      PostModel(
        postId: 'post_003',
        posterId: 'user_003',
        postContent: 'My favorite healthy pasta recipe! Perfect for meal prep and packed with nutrients. Here\'s a step-by-step video guide.',
        postType: PostType.recipe, // 使用枚举
        mediaUrls: [
          'text:Healthy Pasta Recipe:\n\nIngredients:\n- 300g whole wheat pasta\n- 200g cherry tomatoes\n- 150g fresh spinach\n- 3 cloves garlic, minced\n- 2 tbsp olive oil\n- Fresh basil leaves\n- 50g Parmesan cheese\n- Salt and pepper to taste\n\nInstructions:\n1. Cook pasta according to package directions\n2. Heat olive oil, sauté garlic\n3. Add tomatoes, cook until soft\n4. Add spinach, wilt down\n5. Toss with pasta and cheese',
          'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
          'https://images.unsplash.com/photo-1551782450-17144efb9c50?w=400'
        ],
        likes: ['user_001', 'user_002', 'user_004', 'user_005'],
        comments: const [],
        commentCount: 0,
        isDisable: false,
        createdAt: DateTime.now().subtract(Duration(days: 3)),
        updatedAt: DateTime.now().subtract(Duration(days: 3)),
      ),
      PostModel(
        postId: 'post_004',
        posterId: 'user_004',
        postContent: 'My journey to better mental health started with small daily habits. Here\'s what worked for me and how it transformed my life over the past year.',
        postType: PostType.story, // 使用枚举
        mediaUrls: [
          'text:My Mental Health Journey:\n\nA year ago, I was struggling with anxiety and stress. It started with just 5 minutes of daily meditation using a simple app. Then I added:\n\n- Morning journaling (3 minutes)\n- Regular walks in nature (20 minutes)\n- Reaching out to friends weekly\n- Setting boundaries at work\n- Practicing gratitude daily\n\nSmall changes led to big improvements in my overall wellbeing. The key was consistency, not perfection.',
          'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400'
        ],
        likes: ['user_001', 'user_002', 'user_003', 'user_005'],
        comments: const [],
        commentCount: 0,
        isDisable: false,
        createdAt: DateTime.now().subtract(Duration(days: 4)),
        updatedAt: DateTime.now().subtract(Duration(days: 4)),
      ),
      PostModel(
        postId: 'post_005',
        posterId: 'user_005',
        postContent: 'This post contains inappropriate content that was reported by users and has been disabled by moderators.',
        postType: PostType.general, // 使用枚举
        mediaUrls: [
          'text:This content has been removed by the moderation team for violating community guidelines.'
        ],
        likes: ['user_002'],
        comments: const [],
        commentCount: 0,
        isDisable: true,
        createdAt: DateTime.now().subtract(Duration(days: 5)),
        updatedAt: DateTime.now().subtract(Duration(hours: 12)),
      ),
      PostModel(
        postId: 'post_006',
        posterId: 'user_001',
        postContent: 'Quick morning yoga routine to start your day right! These simple poses can be done in just 10 minutes.',
        postType: PostType.tips, // 使用枚举
        mediaUrls: [
          'https://sample-videos.com/zip/10/mp4/SampleVideo_640x360_1mb.mp4',
          'text:Morning Yoga Routine (10 minutes):\n\n1. Cat-Cow Stretch - 1 minute\n2. Downward Facing Dog - 2 minutes\n3. Sun Salutation A - 3 minutes\n4. Warrior I (both sides) - 2 minutes\n5. Child\'s Pose - 2 minutes\n\nTip: Focus on your breath and don\'t worry about perfect form. The goal is to wake up your body gently.'
        ],
        likes: ['user_002', 'user_003', 'user_004'],
        comments: const [],
        commentCount: 0,
        isDisable: false,
        createdAt: DateTime.now().subtract(Duration(hours: 8)),
        updatedAt: DateTime.now().subtract(Duration(hours: 8)),
      ),
      PostModel(
        postId: 'post_007',
        posterId: 'user_003',
        postContent: 'Grandmother\'s secret chocolate chip cookie recipe that\'s been in our family for generations! Finally decided to share it.',
        postType: PostType.recipe, // 使用枚举
        mediaUrls: [
          'text:Grandma\'s Secret Chocolate Chip Cookies:\n\nIngredients:\n- 2 cups all-purpose flour\n- 1 tsp baking soda\n- 1 tsp salt\n- 1 cup butter (room temperature)\n- 3/4 cup packed brown sugar\n- 1/4 cup white sugar\n- 2 large eggs\n- 2 tsp pure vanilla extract\n- 2 cups chocolate chips\n\nSecret Tips:\n- Chill dough for 2 hours before baking\n- Use room temperature eggs\n- Don\'t overbake - they\'ll continue cooking on the pan\n\nBake at 375°F for 9-11 minutes. Makes about 36 cookies.',
          'https://images.unsplash.com/photo-1499636136210-6f4ee915583e?w=400'
        ],
        likes: ['user_001', 'user_002', 'user_005'],
        comments: const [],
        commentCount: 0,
        isDisable: false,
        createdAt: DateTime.now().subtract(Duration(hours: 18)),
        updatedAt: DateTime.now().subtract(Duration(hours: 18)),
      ),
    ]);

    // Mock user data
    posterData.assignAll({
      'user_001': UserModel(
        userId: 'user_001',
        username: 'alice_nature',
        userType: 'user',
        email: 'alice@example.com',
        phoneNumber: '+1234567890',
        profileImg: '',
        isVerify: true,
        accountAvailable: true,
        joinDate: DateTime.now().subtract(Duration(days: 365)),
        totalScore: 2450,
      ),
      'user_002': UserModel(
        userId: 'user_002',
        username: 'fitness_mike',
        userType: 'user',
        email: 'mike@example.com',
        phoneNumber: '+1234567891',
        profileImg: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
        isVerify: true,
        accountAvailable: true,
        joinDate: DateTime.now().subtract(Duration(days: 200)),
        totalScore: 1850,
      ),
      'user_003': UserModel(
        userId: 'user_003',
        username: 'chef_sarah',
        userType: 'user',
        email: 'sarah@example.com',
        phoneNumber: '+1234567892',
        profileImg: '',
        isVerify: true,
        accountAvailable: true,
        joinDate: DateTime.now().subtract(Duration(days: 180)),
        totalScore: 2100,
      ),
      'user_004': UserModel(
        userId: 'user_004',
        username: 'wellness_jane',
        userType: 'user',
        email: 'jane@example.com',
        phoneNumber: '+1234567893',
        profileImg: 'https://images.unsplash.com/photo-1494790108755-2616b612b5bc?w=100',
        isVerify: true,
        accountAvailable: true,
        joinDate: DateTime.now().subtract(Duration(days: 500)),
        totalScore: 3200,
      ),
      'user_005': UserModel(
        userId: 'user_005',
        username: 'banned_user',
        userType: 'user',
        email: 'banned@example.com',
        phoneNumber: '+1234567894',
        profileImg: '',
        isVerify: false,
        accountAvailable: false,
        joinDate: DateTime.now().subtract(Duration(days: 150)),
        totalScore: 120,
      ),
    });
  }

  // Filter posts based on search, type, and status
  void filterPosts() {
    List<PostModel> filtered = List.from(allPosts);

    // Filter by status (active/disabled)
    filtered = filtered.where((post) {
      return showingActivePosts.value ? !post.isDisable : post.isDisable;
    }).toList();

    // Filter by post type
    if (selectedPostType.value != null) {
      filtered = filtered.where((post) => post.postType == selectedPostType.value).toList();
    }

    // Filter by search query
    final query = searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((post) {
        final poster = posterData[post.posterId];
        return post.postId.toLowerCase().contains(query) ||
            post.postContent.toLowerCase().contains(query) ||
            (poster?.username.toLowerCase().contains(query) ?? false) ||
            (poster?.email.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Update pagination
    totalPages.value = (filtered.length / itemsPerPage.value).ceil();
    if (totalPages.value == 0) totalPages.value = 1;
    if (currentPage.value > totalPages.value) currentPage.value = 1;

    // Apply pagination
    final startIndex = (currentPage.value - 1) * itemsPerPage.value;
    final endIndex = (startIndex + itemsPerPage.value).clamp(0, filtered.length);
    filteredPosts.assignAll(filtered.sublist(startIndex, endIndex));
  }

  // Sort posts
  void sortPosts(int columnIndex, bool ascending) {
    sortColumnIndex.value = columnIndex;
    sortAscending.value = ascending;

    filteredPosts.sort((a, b) {
      dynamic valueA, valueB;

      switch (columnIndex) {
        case 0: // Post ID
          valueA = a.postId;
          valueB = b.postId;
          break;
        case 1: // Poster
          valueA = posterData[a.posterId]?.username ?? '';
          valueB = posterData[b.posterId]?.username ?? '';
          break;
        case 2: // Content (by length)
          valueA = a.postContent.length;
          valueB = b.postContent.length;
          break;
        case 3: // Type
          valueA = a.postType.displayName; // 使用显示名称进行比较
          valueB = b.postType.displayName;
          break;
        case 4: // Media Count
          valueA = a.mediaUrls.length;
          valueB = b.mediaUrls.length;
          break;
        case 5: // Likes Count
          valueA = a.likes.length;
          valueB = b.likes.length;
          break;
        case 6: // Created Date
          valueA = a.createdAt;
          valueB = b.createdAt;
          break;
        default:
          valueA = a.postId;
          valueB = b.postId;
      }

      int comparison = 0;
      if (valueA is String && valueB is String) {
        comparison = valueA.compareTo(valueB);
      } else if (valueA is int && valueB is int) {
        comparison = valueA.compareTo(valueB);
      } else if (valueA is DateTime && valueB is DateTime) {
        comparison = valueA.compareTo(valueB);
      }

      return ascending ? comparison : -comparison;
    });
  }

  // Toggle post selection
  void togglePostSelection(PostModel post, bool selected) {
    if (selected) {
      selectedPosts.add(post);
    } else {
      selectedPosts.remove(post);
    }
  }

  // Toggle select all
  void toggleSelectAll(bool selectAll) {
    if (selectAll) {
      selectedPosts.assignAll(filteredPosts);
    } else {
      selectedPosts.clear();
    }
  }

  // Show active posts
  void showActivePosts() {
    showingActivePosts.value = true;
    selectedPosts.clear();
    currentPage.value = 1;
    filterPosts();
  }

  // Show disabled posts
  void showDisabledPosts() {
    showingActivePosts.value = false;
    selectedPosts.clear();
    currentPage.value = 1;
    filterPosts();
  }

  // Change post type filter
  void changePostTypeFilter(PostType? type) {
    selectedPostType.value = type;
    currentPage.value = 1;
    filterPosts();
  }

  // 清除类型筛选
  void clearPostTypeFilter() {
    selectedPostType.value = null;
    currentPage.value = 1;
    filterPosts();
  }

  // Change page
  void changePage(int page) {
    if (page >= 1 && page <= totalPages.value) {
      currentPage.value = page;
      filterPosts();
    }
  }

  // Change items per page
  void changeItemsPerPage(int? items) {
    if (items != null) {
      itemsPerPage.value = items;
      currentPage.value = 1;
      filterPosts();
    }
  }

  // Disable a single post
  Future<void> disablePost(PostModel post) async {
    try {
      isLoading.value = true;

      // Simulate API call
      await Future.delayed(Duration(milliseconds: 500));

      // Update post status
      final index = allPosts.indexWhere((p) => p.postId == post.postId);
      if (index != -1) {
        final updatedPost = post.copyWith(
          isDisable: true,
          updatedAt: DateTime.now(),
        );
        allPosts[index] = updatedPost;
      }

      selectedPosts.clear();
      filterPosts();

      TLoaders.successSnackBar(
        title: 'Post Disabled',
        message: 'Post has been successfully disabled.',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to disable post. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Enable a single post
  Future<void> enablePost(PostModel post) async {
    try {
      isLoading.value = true;

      // Simulate API call
      await Future.delayed(Duration(milliseconds: 500));

      // Update post status
      final index = allPosts.indexWhere((p) => p.postId == post.postId);
      if (index != -1) {
        final updatedPost = post.copyWith(
          isDisable: false,
          updatedAt: DateTime.now(),
        );
        allPosts[index] = updatedPost;
      }

      selectedPosts.clear();
      filterPosts();

      TLoaders.successSnackBar(
        title: 'Post Enabled',
        message: 'Post has been successfully enabled.',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to enable post. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Batch disable posts
  Future<void> batchDisablePosts() async {
    if (selectedPosts.isEmpty) return;

    try {
      isLoading.value = true;

      // Simulate API call
      await Future.delayed(Duration(milliseconds: 1000));

      for (var post in selectedPosts) {
        final index = allPosts.indexWhere((p) => p.postId == post.postId);
        if (index != -1) {
          final updatedPost = post.copyWith(
            isDisable: true,
            updatedAt: DateTime.now(),
          );
          allPosts[index] = updatedPost;
        }
      }

      selectedPosts.clear();
      filterPosts();

      TLoaders.successSnackBar(
        title: 'Posts Disabled',
        message: '${selectedPosts.length} posts have been disabled successfully.',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to disable posts. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Batch enable posts
  Future<void> batchEnablePosts() async {
    if (selectedPosts.isEmpty) return;

    try {
      isLoading.value = true;

      // Simulate API call
      await Future.delayed(Duration(milliseconds: 1000));

      for (var post in selectedPosts) {
        final index = allPosts.indexWhere((p) => p.postId == post.postId);
        if (index != -1) {
          final updatedPost = post.copyWith(
            isDisable: false,
            updatedAt: DateTime.now(),
          );
          allPosts[index] = updatedPost;
        }
      }

      selectedPosts.clear();
      filterPosts();

      TLoaders.successSnackBar(
        title: 'Posts Enabled',
        message: '${selectedPosts.length} posts have been enabled successfully.',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to enable posts. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh posts
  Future<void> refreshPosts() async {
    isLoading.value = true;
    selectedPosts.clear();

    // Simulate API call
    await Future.delayed(Duration(seconds: 1));

    // In real implementation, fetch from API
    loadMockData();
    filterPosts();

    isLoading.value = false;

    TLoaders.successSnackBar(
      title: 'Refreshed',
      message: 'Posts data has been refreshed.',
    );
  }

  // Get highlighted text for search
  List<TextSpan> getHighlightedText(String text, String query, {Color? textColor}) {
    if (query.isEmpty) {
      return [TextSpan(text: text, style: TextStyle(color: textColor))];
    }

    final List<TextSpan> spans = [];
    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();
    int start = 0;

    while (true) {
      final int index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start), style: TextStyle(color: textColor)));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: TextStyle(color: textColor)));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          backgroundColor: TAdminColors.warning.withOpacity(0.3),
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ));

      start = index + query.length;
    }

    return spans;
  }
}