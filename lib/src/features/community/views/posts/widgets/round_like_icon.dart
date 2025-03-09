import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../../utils/constants/colors.dart';

class RoundLikeIcon extends StatelessWidget {
  const RoundLikeIcon({super.key, this.radius = 12, this.iconSize = 15});

  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: TColors.primary,
      child: FaIcon(
        FontAwesomeIcons.solidThumbsUp,
        color: Colors.white,
        size: iconSize,
      ),
    );
  }
}