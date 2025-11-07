import '../../../utils/constants/enums.dart';

class LeaderboardUserModel {
  final String userId;
  final String userName;
  final int totalScore;
  final String profileImg;

  LeaderboardUserModel({
    required this.userId,
    required this.userName,
    required this.totalScore,
    this.profileImg = '',
  });
}

class LeaderboardModel {
  final LeaderboardUserModel user;
  final int currentRank;
  final int? previousRank;
  final RankChange? rankChange;
  final bool isCurrentUser;

  LeaderboardModel({
    required this.user,
    required this.currentRank,
    this.previousRank,
    this.rankChange,
    this.isCurrentUser = false,
  });

  int get rankDifference {
    if (previousRank == null) return 0;
    return previousRank! - currentRank;
  }
}
