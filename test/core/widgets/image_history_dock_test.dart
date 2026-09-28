import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryon2buy/core/widgets/image_history_dock.dart';
import 'package:tryon2buy/features/customer_tryon/domain/entities/dock_garment.dart';
import 'package:tryon2buy/features/customer_tryon/domain/entities/dock_photo.dart';
import 'package:tryon2buy/features/customer_tryon/domain/entities/selfie_record.dart';

const _outfit = DockGarment(
  id: 'prod-1',
  primaryAssetId: 'asset-7',
  title: 'Banarasi Saree',
  tryOnCount: 3,
);

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

  // ── Two categories ──────────────────────────────────────────────────
  //
  // Photos and tried outfits are different things — a person with a privacy
  // clock, and a product with shop activity — so they never share a list.
  // The tab bar exists only when there are outfits, which for a guest is
  // never: `listGarments` is vendor-only.

  testWidgets('a guest dock has no tab bar', (tester) async {
    await tester.pumpWidget(_host(
      dockPhotos: [DockPhoto(id: 'p1', imageUrl: 'https://cdn.test/1.jpg')],
    ));

    expect(find.textContaining('MY PHOTOS'), findsNothing);
    expect(find.textContaining('OUTFITS TRIED'), findsNothing);
  });

  testWidgets('outfits add a tab bar labelled as on the website',
      (tester) async {
    await tester.pumpWidget(_host(
      dockPhotos: [
        DockPhoto(id: 'p1', imageUrl: 'https://cdn.test/1.jpg'),
        DockPhoto(id: 'p2', imageUrl: 'https://cdn.test/2.jpg'),
      ],
      garments: const [_outfit],
    ));

    expect(find.text('MY PHOTOS (2)'), findsOneWidget);
    expect(find.text('OUTFITS TRIED (1)'), findsOneWidget);
  });

  testWidgets('tapping an outfit hands it back; the try-on count is shown',
      (tester) async {
    DockGarment? picked;
    await tester.pumpWidget(_host(
      dockPhotos: [DockPhoto(id: 'p1', imageUrl: 'https://cdn.test/1.jpg')],
      garments: const [_outfit],
      onSelectGarment: (g) => picked = g,
    ));

    await tester.tap(find.text('OUTFITS TRIED (1)'));
    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget, reason: 'the try-on count badge');
    await tester.tap(find.byType(Tooltip));
    expect(picked, _outfit);
  });

  testWidgets('while busy the dock still switches tabs but applies nothing',
      (tester) async {
    // Swapping the garment out from under a running retouch would produce a
    // result belonging to a pair of inputs nobody chose together.
    DockGarment? picked;
    await tester.pumpWidget(_host(
      dockPhotos: [DockPhoto(id: 'p1', imageUrl: 'https://cdn.test/1.jpg')],
      garments: const [_outfit],
      onSelectGarment: (g) => picked = g,
      busy: true,
    ));

    // Browsing is still allowed …
    await tester.tap(find.text('OUTFITS TRIED (1)'));
    await tester.pumpAndSettle();
    expect(find.byType(Tooltip), findsOneWidget);

    // … applying is not.
    await tester.tap(find.byType(Tooltip));
    expect(picked, isNull);
  });

  testWidgets('deleting the last outfit falls back to the photos tab',
      (tester) async {
    Widget build(List<DockGarment> garments) => _host(
          dockPhotos: [DockPhoto(id: 'p1', imageUrl: 'https://cdn.test/1.jpg')],
          garments: garments,
        );

    await tester.pumpWidget(build(const [_outfit]));
    await tester.tap(find.text('OUTFITS TRIED (1)'));
    await tester.pumpAndSettle();

    // The merchant removes it — or a colleague does, on another device.
    await tester.pumpWidget(build(const []));
    await tester.pumpAndSettle();

    // No empty strip with no way back: the tab bar goes and photos return.
    expect(find.textContaining('OUTFITS TRIED'), findsNothing);
    expect(find.byIcon(Icons.add_a_photo_outlined), findsOneWidget);
  });
}

/// The dock on a phone-width screen, with whatever it is being given.
Widget _host({
  List<DockPhoto> dockPhotos = const [],
  List<DockGarment> garments = const [],
  ValueChanged<DockGarment>? onSelectGarment,
  bool busy = false,
}) {
  return MaterialApp(
    home: Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ImageHistoryDock(
            history: const [],
            dockPhotos: dockPhotos,
            garments: garments,
            isRemoteDock: garments.isNotEmpty,
            busy: busy,
            onSelectImage: (_) {},
            onSelectGarment: onSelectGarment,
            onAddImage: () {},
          ),
        ],
      ),
    ),
  );
}
