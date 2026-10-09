import 'package:flutter/material.dart';

/// The devmau.site "M" mark (same artwork as the site favicon).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 48});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo.png',
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'Mau Portfolio',
    );
  }
}
