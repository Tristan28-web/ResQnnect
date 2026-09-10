import 'dart:convert';
import 'package:flutter/material.dart';

class ProfileImage extends StatelessWidget {
  final String? source;
  final double radius;
  final IconData placeholderIcon;

  const ProfileImage({
    super.key,
    required this.source,
    this.radius = 24,
    this.placeholderIcon = Icons.person,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (source == null || source!.isEmpty || source == 'null') {
      return _buildPlaceholder(isDark);
    }

    final trimmedSource = source!.trim();

    // Check if it's a URL
    if (trimmedSource.startsWith('http') || trimmedSource.startsWith('https')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        backgroundImage: NetworkImage(trimmedSource),
        onBackgroundImageError: (_, __) => _buildPlaceholder(isDark),
      );
    }

    // Assume Base64
    try {
      // Clean up the base64 string
      String base64Str = trimmedSource;
      if (base64Str.contains(',')) {
        base64Str = base64Str.split(',').last;
      }
      base64Str = base64Str.replaceAll(RegExp(r'\s+'), '');

      return CircleAvatar(
        radius: radius,
        backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        backgroundImage: MemoryImage(base64Decode(base64Str)),
        onBackgroundImageError: (_, __) => _buildPlaceholder(isDark),
      );
    } catch (e) {
      debugPrint('Base64 decode error: $e');
      return _buildPlaceholder(isDark);
    }
  }

  Widget _buildPlaceholder(bool isDark) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
      child: Icon(
        placeholderIcon,
        color: isDark ? Colors.white38 : Colors.black38,
        size: radius * 1.2,
      ),
    );
  }
}
