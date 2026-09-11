import 'package:flutter_test/flutter_test.dart';
import 'package:tryon2buy/core/constants/preset_data.dart';

/// The background ids are a contract with the backend's `prompts.js`: the
/// server resolves the scene and its prompt from the id alone. These guard
/// the drift that already happened once, when the app offered eight scenes
/// under names belonging to an older list.
void main() {
  test('offers the fourteen background scenes the server knows', () {
    expect(PresetData.backgrounds, hasLength(14));
    expect(
      PresetData.backgrounds.map((b) => b.id),
      [for (var i = 1; i <= 14; i++) 'bg$i'],
    );
  });

  test('every background has a distinct name and a thumbnail', () {
    final names = PresetData.backgrounds.map((b) => b.name).toSet();
    expect(names, hasLength(PresetData.backgrounds.length));

    for (final bg in PresetData.backgrounds) {
      expect(bg.name.trim(), isNotEmpty, reason: bg.id);
      expect(bg.imageUrl, startsWith('https://'), reason: bg.id);
    }
  });

  test('retoucher options are bundled assets, not hotlinked photos', () {
    final mods = [...PresetData.blouseSleeves, ...PresetData.necklines];
    expect(mods, hasLength(6));
    for (final m in mods) {
      expect(m.imageUrl, startsWith('assets/'), reason: m.id);
      expect(m.id.trim(), isNotEmpty);
    }
  });
}
