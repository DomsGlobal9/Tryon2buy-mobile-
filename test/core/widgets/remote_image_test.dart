import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryon2buy/core/constants/app_assets.dart';
import 'package:tryon2buy/core/constants/preset_data.dart';
import 'package:tryon2buy/core/widgets/remote_image.dart';

/// Several lists mix bundled artwork with server images: the category rail
/// and the sleeve and neckline pickers ship with the app, while backgrounds
/// and catalogue pieces come from the server. Handing an asset path to the
/// network loader failed silently and drew the fallback icon, so this pins
/// which loader each kind of path reaches.
void main() {
  Future<void> pump(WidgetTester tester, String? url) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: RemoteImage(url: url))),
    );
  }

  testWidgets('a bundled asset path is loaded from the bundle', (tester) async {
    await pump(tester, AppAssets.categorySaree);

    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsNothing);
  });

  testWidgets('a network url still goes to the caching loader', (tester) async {
    await pump(tester, 'https://example.test/photo.jpg');

    expect(find.byType(CachedNetworkImage), findsOneWidget);
  });

  testWidgets('a missing url draws the fallback, not a loader', (tester) async {
    await pump(tester, null);
    expect(find.byType(CachedNetworkImage), findsNothing);

    await pump(tester, '   ');
    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
  });

  testWidgets('every category avatar and retoucher tile is bundled',
      (tester) async {
    final bundled = <String>[
      AppAssets.categorySaree,
      AppAssets.categoryLehenga,
      AppAssets.categoryAnarkali,
      AppAssets.categoryKurti,
      AppAssets.categorySharara,
      ...PresetData.blouseSleeves.map((m) => m.imageUrl),
      ...PresetData.necklines.map((m) => m.imageUrl),
    ];

    for (final path in bundled) {
      await pump(tester, path);
      expect(find.byType(CachedNetworkImage), findsNothing, reason: path);
      expect(find.byType(Image), findsOneWidget, reason: path);
    }
  });
}
