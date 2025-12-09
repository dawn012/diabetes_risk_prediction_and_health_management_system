import 'package:flutter/material.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';

/// Banner widget to show when a post is disabled
class DisabledPostBanner extends StatelessWidget {
  final String? reason;
  final VoidCallback? onContactAdmin;
  final bool isCompact; // 新增参数：控制是否显示紧凑版本

  const DisabledPostBanner({
    super.key,
    this.reason,
    this.onContactAdmin,
    this.isCompact = false, // 默认显示完整版本
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactVersion();
    } else {
      return _buildFullVersion();
    }
  }

  Widget _buildCompactVersion() {
    return Container(
      margin: EdgeInsets.all(TSizes.xs),
      padding: EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: TSizes.xs),
      decoration: BoxDecoration(
        color: TColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
        border: Border.all(
          color: TColors.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.block,
            color: TColors.error,
            size: 14,
          ),
          SizedBox(width: TSizes.xs),
          Text(
            'Post Disabled',
            style: TextStyle(
              color: TColors.error,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullVersion() {
    return Container(
      margin: EdgeInsets.all(TSizes.sm),
      padding: EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: TColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
        border: Border.all(
          color: TColors.error.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TColors.error.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.block,
                  color: TColors.error,
                  size: 20,
                ),
              ),
              SizedBox(width: TSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Post Disabled',
                      style: TextStyle(
                        color: TColors.error,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (reason != null && reason!.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        reason!,
                        style: TextStyle(
                          color: TColors.error.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: TSizes.sm),
          Text(
            'This post has been disabled by an administrator and is not visible to other users.',
            style: TextStyle(
              color: TColors.error.withOpacity(0.8),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          // if (onContactAdmin != null) ...[
          //   SizedBox(height: TSizes.sm),
          //   TextButton.icon(
          //     onPressed: onContactAdmin,
          //     icon: Icon(Icons.support_agent, size: 16),
          //     label: Text('Contact Support'),
          //     style: TextButton.styleFrom(
          //       foregroundColor: TColors.error,
          //       padding: EdgeInsets.symmetric(
          //         horizontal: TSizes.sm,
          //         vertical: TSizes.xs,
          //       ),
          //     ),
          //   ),
          // ],
        ],
      ),
    );
  }
}