import 'app_assets.dart';

class PresetBackground {
  final String id;
  final String name;
  final String imageUrl;

  const PresetBackground({
    required this.id,
    required this.name,
    required this.imageUrl,
  });
}

class PresetModification {
  final String id;
  final String name;
  final String imageUrl;

  const PresetModification({
    required this.id,
    required this.name,
    required this.imageUrl,
  });
}

class PresetData {
  static const String _bucket =
      'https://gsriztjnocjwgqkaxhhz.supabase.co/storage/v1/object/public/tryon-fits';

  /// The fourteen background scenes the server can composite into, copied
  /// from `BACKGROUND_PROMPTS` in the backend's `prompts.js`.
  ///
  /// Two rules, both learned the hard way:
  ///
  ///  * **The id is the contract, the file name is not.** `bg2` is drawn
  ///    with `bg10.png`, `bg5` with `bg2.png`. The server resolves the
  ///    prompt from the id alone, so never infer one from the other.
  ///  * **Names must match the server's.** They drifted once: the app
  ///    offered "Designer Boutique" and the shopper was composited into a
  ///    temple, because the labels were written against an older preset
  ///    list while the ids kept resolving to the current one.
  ///
  /// When the backend adds or renames a scene, this list is what changes.
  static const List<PresetBackground> backgrounds = [
    PresetBackground(id: 'bg1', name: 'Temple Colonnade', imageUrl: '$_bucket/bg1.png'),
    PresetBackground(id: 'bg2', name: 'Banana Leaf Mandap', imageUrl: '$_bucket/bg10.png'),
    PresetBackground(id: 'bg3', name: 'Rose Haveli Alcove', imageUrl: '$_bucket/bg13.png'),
    PresetBackground(id: 'bg4', name: 'Candlelit Barn Chapel', imageUrl: '$_bucket/bg14.png'),
    PresetBackground(id: 'bg5', name: 'Diwali Palace Corridor', imageUrl: '$_bucket/bg2.png'),
    PresetBackground(id: 'bg6', name: 'Marigold Haldi Stage', imageUrl: '$_bucket/bg15.png'),
    PresetBackground(id: 'bg7', name: 'Mountain Floral Aisle', imageUrl: '$_bucket/bg16.png'),
    PresetBackground(id: 'bg8', name: 'Marigold Temple Steps', imageUrl: '$_bucket/bg17.png'),
    PresetBackground(id: 'bg9', name: 'Haldi Flower Curtain', imageUrl: '$_bucket/bg18.png'),
    PresetBackground(id: 'bg10', name: 'Bougainvillea Courtyard', imageUrl: '$_bucket/bg5.jpg'),
    PresetBackground(id: 'bg11', name: 'Starlit Garden Aisle', imageUrl: '$_bucket/bg20.png'),
    PresetBackground(id: 'bg12', name: 'Sunflower Terrace Mandap', imageUrl: '$_bucket/bg21.png'),
    PresetBackground(id: 'bg13', name: 'Marigold Doorway', imageUrl: '$_bucket/bg22.png'),
    PresetBackground(id: 'bg14', name: 'Tuberose Gateway', imageUrl: '$_bucket/bg23.png'),
  ];

  // Sleeve Modifications
  static const List<PresetModification> blouseSleeves = [
    PresetModification(
      id: 'elbow-sleeve',
      name: 'Elbow Sleeve',
      imageUrl: AppAssets.sleeveElbow,
    ),
    PresetModification(
      id: 'full-sleeve',
      name: 'Full Sleeve',
      imageUrl: AppAssets.sleeveFull,
    ),
    PresetModification(
      id: 'sleeveless',
      name: 'Sleeveless',
      imageUrl: AppAssets.sleeveLess,
    ),
  ];

  // Neckline Modifications
  static const List<PresetModification> necklines = [
    PresetModification(
      id: 'boat-neck',
      name: 'Boat Neck',
      imageUrl: AppAssets.neckBoat,
    ),
    PresetModification(
      id: 'round-neck',
      name: 'Round Neck',
      imageUrl: AppAssets.neckRound,
    ),
    PresetModification(
      id: 'collar-neck',
      name: 'Collar Neck',
      imageUrl: AppAssets.neckCollar,
    ),
  ];
}
