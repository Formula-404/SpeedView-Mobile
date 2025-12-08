import 'package:flutter/material.dart';

import 'package:speedview/common/theme/typography.dart';

class SpeedViewAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SpeedViewAppBar({
    super.key,
    required this.title,
    this.actions,
  });

  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.appBarTheme.titleTextStyle ??
        speedViewHeadingStyle(
          context,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        );
    return AppBar(
      title: Text(
        title,
        style: titleStyle,
      ),
      leading: Builder(
        builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        },
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
