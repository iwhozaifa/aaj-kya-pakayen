import 'package:aaj_kya_pakayen/core/widgets/app_logo.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('renders the brand svg at the requested size', (tester) async {
    await tester.pumpApp(const AppLogo(size: 120));

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(tester.getSize(find.byType(AppLogo)), const Size(120, 120));
    expect(AppLogo.asset, 'assets/brand/logo.svg');
  });
}
