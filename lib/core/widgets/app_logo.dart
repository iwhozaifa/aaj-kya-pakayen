import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The karahi brand mark.
class AppLogo extends StatelessWidget {
  const new({this.size = 96, super.key});

  static const asset = 'assets/brand/logo.svg';

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: SvgPicture.asset(asset, excludeFromSemantics: true),
    );
  }
}
