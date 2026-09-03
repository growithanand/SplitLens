import 'package:flutter_test/flutter_test.dart';
import 'package:splitlens/main.dart';

void main() {
  testWidgets('displays the SplitLens placeholder', (tester) async {
    await tester.pumpWidget(const SplitLensApp());

    expect(find.text('SplitLens'), findsOneWidget);
  });
}
