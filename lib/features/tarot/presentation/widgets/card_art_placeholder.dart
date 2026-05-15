import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../models/tarot_card.dart';

enum CardArtVariant { faceDown, faceUp }

class CardArtPlaceholder extends StatelessWidget {
  const CardArtPlaceholder({
    super.key,
    required this.variant,
    this.card,
    this.width = 140,
    this.aspectRatio = 1 / 1.6,
  }) : assert(
          variant == CardArtVariant.faceDown || card != null,
          'card is required when variant is faceUp',
        );

  const CardArtPlaceholder.mini({
    super.key,
    required this.card,
  })  : variant = CardArtVariant.faceUp,
        width = 44,
        aspectRatio = 1 / 1.45;

  final CardArtVariant variant;
  final TarotCard? card;
  final double width;
  final double aspectRatio;

  bool get _isFaceUp => variant == CardArtVariant.faceUp;

  @override
  Widget build(BuildContext context) {
    final height = width / aspectRatio;
    final isMini = width <= 60;

    if (_isFaceUp) {
      return _buildFaceUp(context, isMini, width, height);
    }

    return _buildCardShell(
      isMini: isMini,
      width: width,
      height: height,
      child: _buildFaceDownContent(isMini),
    );
  }

  Widget _buildFaceUp(
    BuildContext context,
    bool isMini,
    double width,
    double height,
  ) {
    final c = card!;
    final hasImage = !isMini &&
        c.imagePath != null &&
        c.imagePath!.isNotEmpty;

    if (hasImage) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isMini ? 8 : 14),
          border: Border.all(
            color: AppColors.softGold.withValues(alpha: 0.55),
            width: 1.4,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isMini ? 8 : 14),
          child: Image.asset(
            c.imagePath!,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return _buildCardShell(
      isMini: isMini,
      width: width,
      height: height,
      child: _buildFaceUpContent(isMini),
    );
  }

  Widget _buildCardShell({
    required bool isMini,
    required double width,
    required double height,
    required Widget child,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF24432F), AppColors.deepGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isMini ? 8 : 14),
          border: Border.all(
            color: AppColors.softGold.withValues(alpha: 0.55),
            width: 1.4,
          ),
        ),
        padding: EdgeInsets.all(isMini ? 4 : 8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isMini ? 5 : 9),
            border: Border.all(
              color: AppColors.softGold.withValues(alpha: 0.35),
              width: 0.8,
            ),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }

  Widget _buildFaceDownContent(bool isMini) {
    return Icon(
      Icons.auto_awesome,
      color: AppColors.softGold.withValues(alpha: 0.85),
      size: isMini ? 18 : 32,
    );
  }

  Widget _buildFaceUpContent(bool isMini) {
    final c = card!;
    final numeral = _romanNumeral(c.number);

    if (isMini) {
      return Text(
        numeral,
        style: TextStyle(
          color: AppColors.softGold,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 18,
            color: AppColors.softGold.withValues(alpha: 0.75),
          ),
          Expanded(
            child: Center(
              child: FittedBox(
                child: Text(
                  numeral,
                  style: const TextStyle(
                    color: AppColors.softGold,
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
          Text(
            c.name.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.softGold.withValues(alpha: 0.9),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  static String _romanNumeral(int n) {
    const numerals = <int, String>{
      1000: 'M',
      900: 'CM',
      500: 'D',
      400: 'CD',
      100: 'C',
      90: 'XC',
      50: 'L',
      40: 'XL',
      10: 'X',
      9: 'IX',
      5: 'V',
      4: 'IV',
      1: 'I',
    };
    if (n == 0) return '0';
    final buffer = StringBuffer();
    var remaining = n;
    for (final entry in numerals.entries) {
      while (remaining >= entry.key) {
        buffer.write(entry.value);
        remaining -= entry.key;
      }
    }
    return buffer.toString();
  }
}
