import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CenterFaIcon extends StatelessWidget {
  const CenterFaIcon(
    this.icone, {
    super.key,
    this.size = 20,
    this.boxSize,
    this.fill,
    this.weight,
    this.grade,
    this.opticalSize,
    this.color,
    this.shadows,
    this.semanticLabel,
    this.textDirection,
    this.applyTextScaling,
    this.blendMode,
    this.fontWeight,
  });

  final FaIconData icone;
  final double size;
  final double? boxSize;
  final double? fill;
  final double? weight;
  final double? grade;
  final double? opticalSize;
  final Color? color;
  final List<Shadow>? shadows;
  final String? semanticLabel;
  final TextDirection? textDirection;
  final bool? applyTextScaling;
  final BlendMode? blendMode;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: boxSize,
      child: Center(
        child: Transform.translate(
          offset: const Offset(0, 2),
          child: FaIcon(
            icone,
            size: size,
            fill: fill,
            weight: weight,
            grade: grade,
            opticalSize: opticalSize,
            color: color,
            shadows: shadows,
            semanticLabel: semanticLabel,
            textDirection: textDirection,
            applyTextScaling: applyTextScaling,
            blendMode: blendMode,
            fontWeight: fontWeight,
          ),
        ),
      ),
    );
  }
}
