import 'package:flutter_test/flutter_test.dart';
import 'package:fire_alarm_app/main.dart';

void main() {
  testWidgets('App should render without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const FireAlarmApp());
    // App shows loading screen initially while checking auth state
    expect(find.text('正在加载...'), findsOneWidget);
  });
}
