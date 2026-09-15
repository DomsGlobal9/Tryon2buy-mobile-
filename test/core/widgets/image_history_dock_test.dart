import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryon2buy/core/widgets/image_history_dock.dart';
import 'package:tryon2buy/features/customer_tryon/domain/entities/selfie_record.dart';

/// The dock keeps up to ten recent selfies. It used to shrink-wrap the
/// thumbnail strip inside a min-width row, so the row grew with every photo
/// and overflowed a phone screen (yellow-and-black stripes in debug, clipped
/// thumbnails in release) from about the sixth selfie on.
void main() {
  testWidgets('a full history fits a narrow phone without overflowing',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    final history = [
      for (var i = 0; i < 10; i++)
        SelfieRecord(
          id: '$i',
          imageUrl: 'https://cdn.test/selfie-$i.jpg',
          lastUsedAt: now,
          isActive: i == 0,
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ImageHistoryDock(
                history: history,
                activeImageId: '0',
                onSelectImage: (_) {},
                onAddImage: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    // A RenderFlex overflow is reported through FlutterError, which the
    // tester collects here.
    expect(tester.takeException(), isNull);

    final dock = tester.getSize(find.byType(ImageHistoryDock));
    expect(dock.width, lessThanOrEqualTo(360 - 32));
  });

  testWidgets('an empty history renders nothing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ImageHistoryDock(
            history: const [],
            onSelectImage: (_) {},
            onAddImage: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.add_a_photo_outlined), findsNothing);
  });
}
