import 'package:fe_sakukampus_pbm/main.dart';
import 'package:fe_sakukampus_pbm/screens/splash_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('KosKuy splash renders', (WidgetTester tester) async {
    await tester.pumpWidget(const KosKuyApp());

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('V 1.0.0'), findsOneWidget);
  });
}
