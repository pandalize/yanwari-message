import 'package:flutter/material.dart';
import '../../utils/design_system.dart';

class PageContainer extends StatelessWidget {
  final Widget child;
  final bool showGradient;
  
  const PageContainer({
    super.key,
    required this.child,
    this.showGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: showGradient
          ? BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  YanwariDesignSystem.primaryColorLight,
                  YanwariDesignSystem.backgroundPrimary,
                ],
                stops: const [0.0, 0.2],
              ),
            )
          : null,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
          child: Padding(
            padding: EdgeInsets.only(bottom: 100), // ナビゲーションバー分
            child: child,
          ),
        ),
      ),
    );
  }
}