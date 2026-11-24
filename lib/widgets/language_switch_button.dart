// FILE: lib/widgets/language_switch_button.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../core/constants.dart';

class LanguageSwitchButton extends StatelessWidget {
  final bool isDarkBackground;
  final bool compact;

  const LanguageSwitchButton({
    Key? key,
    this.isDarkBackground = false,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        final isKhmer = settings.isKhmer;
        
        // Colors based on background
        final activeBgColor = isDarkBackground
            ? AppConstants.primaryYellow
            : AppConstants.primaryDarkBlue;
        final activeTextColor = isDarkBackground
            ? AppConstants.primaryDarkBlue
            : Colors.white;
        final inactiveTextColor = isDarkBackground
            ? Colors.white.withOpacity(0.7)
            : AppConstants.textDarkGray.withOpacity(0.6);
        final borderColor = isDarkBackground
            ? Colors.white.withOpacity(0.25)
            : Colors.grey.withOpacity(0.3);
        final containerBg = isDarkBackground
            ? Colors.black.withOpacity(0.2)
            : Colors.grey.withOpacity(0.12);

        return Container(
          height: compact ? 32 : 36,
          decoration: BoxDecoration(
            color: containerBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // EN Button
              GestureDetector(
                onTap: () {
                  if (isKhmer) {
                    settings.setLanguage('en');
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 10 : 12,
                    vertical: compact ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: !isKhmer ? activeBgColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'EN',
                    style: TextStyle(
                      fontSize: compact ? 12 : 13,
                      fontWeight: !isKhmer ? FontWeight.bold : FontWeight.w500,
                      color: !isKhmer ? activeTextColor : inactiveTextColor,
                    ),
                  ),
                ),
              ),

              // Divider
              Text(
                '/',
                style: TextStyle(
                  color: inactiveTextColor,
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w300,
                ),
              ),

              // KH Button
              GestureDetector(
                onTap: () {
                  if (!isKhmer) {
                    settings.setLanguage('km');
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 10 : 12,
                    vertical: compact ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: isKhmer ? activeBgColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'KH',
                    style: TextStyle(
                      fontSize: compact ? 12 : 13,
                      fontWeight: isKhmer ? FontWeight.bold : FontWeight.w500,
                      color: isKhmer ? activeTextColor : inactiveTextColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
