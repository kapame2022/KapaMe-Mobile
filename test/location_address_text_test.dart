import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kapame/widgets/location_address_text.dart';

void main() {
  testWidgets('bottom sheet labels update after selecting and replacing places',
      (tester) async {
    final pickup = TextEditingController(text: 'Pick Up');
    final destination = TextEditingController(text: 'Destination');
    addTearDown(pickup.dispose);
    addTearDown(destination.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        return Scaffold(
          body: TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (context) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final controller in [pickup, destination])
                    TextButton(
                      onPressed: () async {
                        final address =
                            await Navigator.of(context).push<String>(
                          MaterialPageRoute(
                            builder: (context) => Scaffold(
                              body: TextButton(
                                onPressed: () => Navigator.pop(
                                  context,
                                  controller == pickup
                                      ? 'Blue Hills, Midrand'
                                      : 'Sandton, South Africa',
                                ),
                                child: const Text('Choose location'),
                              ),
                            ),
                          ),
                        );
                        if (address != null) controller.text = address;
                      },
                      child: LocationAddressText(controller: controller),
                    ),
                ],
              ),
            ),
            child: const Text('Open request'),
          ),
        );
      }),
    ));

    await tester.tap(find.text('Open request'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pick Up'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose location'));
    await tester.pumpAndSettle();
    expect(find.text('Blue Hills, Midrand'), findsOneWidget);
    expect(find.text('Pick Up'), findsNothing);
    expect(find.text('Destination'), findsOneWidget);

    await tester.tap(find.text('Destination'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose location'));
    await tester.pumpAndSettle();
    expect(find.text('Sandton, South Africa'), findsOneWidget);
    expect(find.text('Blue Hills, Midrand'), findsOneWidget);

    // A subsequent selection updates the existing label without a parent rebuild.
    pickup.text = 'Blue Hills Shopping Centre';
    await tester.pump();
    expect(find.text('Blue Hills Shopping Centre'), findsOneWidget);
    expect(find.text('Blue Hills, Midrand'), findsNothing);

    // Cancelling the picker preserves the previously selected destination.
    await tester.tap(find.text('Sandton, South Africa'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('Choose location'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Sandton, South Africa'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
