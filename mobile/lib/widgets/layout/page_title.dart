import 'package:flutter/material.dart';
import '../../utils/design_system.dart';

class PageTitle extends StatelessWidget {
  final String title;
  
  const PageTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: YanwariDesignSystem.spacingXl),
      child: Text(
        title,
        style: YanwariDesignSystem.headingLg.copyWith(
          color: YanwariDesignSystem.textPrimary,
        ),
      ),
    );
  }
}