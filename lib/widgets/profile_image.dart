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
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262C38) : const Color(0xFFFCEFEA),
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? const Color(0xFF3E4556) : const Color(0xFF23272F),
          width: 1.4,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF23272F),
          size: radius * 1.15,
        ),
      ),
    );
  }
}
