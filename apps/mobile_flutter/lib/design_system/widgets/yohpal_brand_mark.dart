import 'package:flutter/material.dart';

/// The YohPal Live logo mark, used anywhere a screen needs the brand mark
/// without a boxed container around it (auth screens, splash). The
/// wordmark is baked into the image itself.
class YohPalBrandMark extends StatelessWidget {
  final double width;

  const YohPalBrandMark({super.key, this.width = 200});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'lib/Assets/icon.png',
      width: width,
      fit: BoxFit.contain,
    );
  }
}
