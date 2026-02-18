import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Exibe uma imagem a partir de base64 ou um placeholder gradiente para imagens demo
class AppImage extends StatelessWidget {
  final String imageData;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AppImage({
    super.key,
    required this.imageData,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget img;

    if (imageData.startsWith('demo:')) {
      final parts = imageData.split(':');
      final color1 = _hexToColor(parts[1]);
      final color2 = _hexToColor(parts[2]);
      final idx = int.tryParse(parts[3]) ?? 1;
      img = _DemoImagePlaceholder(
        color1: color1,
        color2: color2,
        index: idx,
        fit: fit,
      );
    } else {
      try {
        final bytes = base64Decode(imageData);
        img = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _errorWidget(),
        );
      } catch (_) {
        img = _errorWidget();
      }
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: SizedBox(width: width, height: height, child: img),
      );
    }
    return SizedBox(width: width, height: height, child: img);
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  Widget _errorWidget() => Container(
        width: width,
        height: height,
        color: AppTheme.bgCard,
        child: const Icon(Icons.image_not_supported, color: AppTheme.textMuted),
      );
}

class _DemoImagePlaceholder extends StatelessWidget {
  final Color color1;
  final Color color2;
  final int index;
  final BoxFit fit;

  const _DemoImagePlaceholder({
    required this.color1,
    required this.color2,
    required this.index,
    required this.fit,
  });

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.wb_sunny_rounded,
      Icons.restaurant_rounded,
      Icons.local_florist_rounded,
      Icons.location_city_rounded,
    ];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          icons[(index - 1) % icons.length],
          size: 60,
          color: Colors.white.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

/// Avatar circular com inicial quando sem imagem
class UserAvatar extends StatelessWidget {
  final String? avatarBase64;
  final String name;
  final double size;

  const UserAvatar({
    super.key,
    this.avatarBase64,
    required this.name,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarBase64 != null && avatarBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(avatarBase64!);
        return CircleAvatar(
          radius: size / 2,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (_) {}
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppTheme.purple,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Badge de nota da foto
class ScoreBadge extends StatelessWidget {
  final double score;
  final bool large;

  const ScoreBadge({super.key, required this.score, this.large = false});

  Color get _color {
    if (score >= 8.0) return AppTheme.success;
    if (score >= 5.0) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 8,
        vertical: large ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(large ? 12 : 8),
        border: Border.all(color: _color.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: large ? 20 : 14,
            color: _color,
          ),
          const SizedBox(width: 4),
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(
              color: _color,
              fontSize: large ? 18 : 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '/10',
            style: TextStyle(
              color: _color.withValues(alpha: 0.7),
              fontSize: large ? 13 : 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Botão gradiente roxo→rosa
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed != null
              ? AppTheme.gradientPurplePink
              : const LinearGradient(
                  colors: [AppTheme.textMuted, AppTheme.textMuted],
                ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(label),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Pin marker visual na imagem
class PinMarker extends StatelessWidget {
  final String label;
  final double score;
  final bool isSelected;
  final bool isOwn;
  final VoidCallback? onTap;

  const PinMarker({
    super.key,
    required this.label,
    required this.score,
    this.isSelected = false,
    this.isOwn = false,
    this.onTap,
  });

  Color get _scoreColor {
    if (score >= 8.0) return AppTheme.success;
    if (score >= 5.0) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isSelected ? 52 : 36,
        height: isSelected ? 52 : 36,
        decoration: BoxDecoration(
          color: isOwn
              ? AppTheme.pink.withValues(alpha: 0.9)
              : AppTheme.purple.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : _scoreColor,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            score.toStringAsFixed(score == score.roundToDouble() ? 0 : 1),
            style: TextStyle(
              color: Colors.white,
              fontSize: isSelected ? 13 : 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
