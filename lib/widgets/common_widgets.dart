import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Helper: detecta se string é uma URL HTTP(S)
bool _isHttpUrl(String? s) => s != null && (s.startsWith('http://') || s.startsWith('https://'));

/// Exibe uma imagem a partir de URL (Firebase Storage), base64 ou placeholder demo.
/// Prioridade: imageUrl > imageData (base64/demo).
class AppImage extends StatelessWidget {
  final String imageData;  // base64 ou 'demo:...' – usado como fallback
  final String? imageUrl;  // URL Firebase Storage – prioritário quando não vazio
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AppImage({
    super.key,
    this.imageData = '',
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget img;

    // Se imageData contém uma URL (Firebase Storage), usa ela como imageUrl
    final effectiveUrl = _isHttpUrl(imageUrl)
        ? imageUrl
        : _isHttpUrl(imageData)
            ? imageData
            : null;

    // Prioridade 1: URL Firebase Storage (de imageUrl ou imageData)
    if (effectiveUrl != null) {
      img = Image.network(
        effectiveUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                color: AppTheme.bgCard,
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.purple,
                  ),
                ),
              ),
        errorBuilder: (_, __, ___) => _errorWidget(),
      );
    } else if (imageData.startsWith('demo:')) {
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
    } else if (imageData.isNotEmpty) {
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
    } else {
      img = _errorWidget();
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
  final String? avatarBase64;  // base64 ou null
  final String? avatarUrl;     // URL Firebase Storage (prioritário)
  final String name;
  final double size;

  const UserAvatar({
    super.key,
    this.avatarBase64,
    this.avatarUrl,
    required this.name,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    // Prioridade 1: avatarUrl (Firebase Storage)
    if (_isHttpUrl(avatarUrl)) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(avatarUrl!),
        backgroundColor: AppTheme.purple,
        child: null,
      );
    }
    // Prioridade 2: avatarBase64 pode conter URL
    if (_isHttpUrl(avatarBase64)) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(avatarBase64!),
        backgroundColor: AppTheme.purple,
        child: null,
      );
    }
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
/// Círculo/pílula branco transparente — apenas borda branca + nota em branco.
/// A foto abaixo fica visível sem interferência de cor.
class ScoreBadge extends StatelessWidget {
  final double score;
  final bool large;

  const ScoreBadge({super.key, required this.score, this.large = false});

  @override
  Widget build(BuildContext context) {
    final double fontSize   = large ? 16 : 12;
    final double subSize    = large ? 11 : 9;
    final double padH       = large ? 12 : 7;
    final double padV       = large ? 7  : 4;
    final double radius     = large ? 20 : 14;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        // Fundo completamente transparente
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white, width: large ? 1.8 : 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
          ),
          Text(
            '/10',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: subSize,
              fontWeight: FontWeight.w600,
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 3),
              ],
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
/// - Borda sempre branca
/// - Fundo transparente (vidro fosco leve)
/// - Texto da nota em branco
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

  @override
  Widget build(BuildContext context) {
    final size = isSelected ? 52.0 : 36.0;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          // Interior completamente transparente
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
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
              fontWeight: FontWeight.w900,
              shadows: const [
                Shadow(
                  color: Colors.black,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
