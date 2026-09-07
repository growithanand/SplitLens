import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitlens/features/expense_split/presentation/expense_split_screen.dart';

void main() {
  testWidgets('validates blank and duplicate participant names', (
    tester,
  ) async {
    await _pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('add-participant-button')));
    await tester.pump();
    expect(find.text('Name cannot be blank.'), findsOneWidget);

    await _addParticipant(tester, 'Alice');
    await _addParticipant(tester, ' alice ');

    expect(find.text('Participant names must be unique.'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
  });

  testWidgets('shows exact allocations and the remainder recipient', (
    tester,
  ) async {
    await _pumpScreen(tester);

    await tester.enterText(find.byKey(const ValueKey('total-field')), '10.00');
    await _addParticipant(tester, 'Alice');
    await _addParticipant(tester, 'Bob');
    await _addParticipant(tester, 'Charlie');

    expect(find.text('€3.34'), findsOneWidget);
    expect(find.text('€3.33'), findsNWidgets(2));
    expect(
      find.text('Rounding: Alice receives one extra cent.'),
      findsOneWidget,
    );
  });

  testWidgets('updates the allocation after removing a participant', (
    tester,
  ) async {
    await _pumpScreen(tester);

    await tester.enterText(find.byKey(const ValueKey('total-field')), '10.00');
    await _addParticipant(tester, 'Alice');
    await _addParticipant(tester, 'Bob');

    await tester.tap(find.byTooltip('Remove Alice'));
    await tester.pump();

    expect(find.text('Alice'), findsNothing);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('€10.00'), findsOneWidget);
    expect(find.text('No rounding adjustment is needed.'), findsOneWidget);
  });

  testWidgets('shows total validation errors', (tester) async {
    await _pumpScreen(tester);

    await tester.enterText(find.byKey(const ValueKey('total-field')), '-1.00');
    await tester.pump();
    expect(find.text('Total cannot be negative.'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('total-field')), '1,234');
    await tester.pump();
    expect(
      find.text('Use two decimal digits to make the amount clear.'),
      findsOneWidget,
    );
  });

  testWidgets('stacks participant entry on a narrow large-text screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpScreen(tester, textScaler: const TextScaler.linear(2));

    final field = find.byKey(const ValueKey('participant-name-field'));
    final addButton = find.byKey(const ValueKey('add-participant-button'));
    expect(
      tester.getTopLeft(addButton).dy,
      greaterThan(tester.getBottomLeft(field).dy),
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
        home: const ExpenseSplitScreen(),
      ),
    ),
  );
}

Future<void> _addParticipant(WidgetTester tester, String name) async {
  await tester.enterText(
    find.byKey(const ValueKey('participant-name-field')),
    name,
  );
  await tester.tap(find.byKey(const ValueKey('add-participant-button')));
  await tester.pump();
}
