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
  // 8 Background Presets matching backend prompts.js
  static const List<PresetBackground> backgrounds = [
    PresetBackground(
      id: 'bg1',
      name: 'Ancient Temple',
      imageUrl: 'https://gsriztjnocjwgqkaxhhz.supabase.co/storage/v1/object/public/tryon-fits/bg1.png',
    ),
    PresetBackground(
      id: 'bg2',
      name: 'Festive Palace',
      imageUrl: 'https://gsriztjnocjwgqkaxhhz.supabase.co/storage/v1/object/public/tryon-fits/bg2.png',
    ),
    // Thumbnails are the ones the website shows (bg13/bg12/bg14); the ids
    // are what the server resolves.
    PresetBackground(
      id: 'bg3',
      name: 'Designer Boutique',
      imageUrl: 'https://gsriztjnocjwgqkaxhhz.supabase.co/storage/v1/object/public/tryon-fits/bg13.png',
    ),
    PresetBackground(
      id: 'bg4',
      name: 'Luxury Hotel Lobby',
      imageUrl: 'https://gsriztjnocjwgqkaxhhz.supabase.co/storage/v1/object/public/tryon-fits/bg12.png',
    ),
    PresetBackground(
      id: 'bg5',
      name: 'Floral Garden Archway',
      imageUrl: 'https://gsriztjnocjwgqkaxhhz.supabase.co/storage/v1/object/public/tryon-fits/bg14.png',
    ),
    PresetBackground(
      id: 'bg6',
      name: 'Golden Palace',
      imageUrl: 'https://gsriztjnocjwgqkaxhhz.supabase.co/storage/v1/object/public/tryon-fits/bg6.jpg',
    ),
    PresetBackground(
      id: 'bg7',
      name: 'Tropical Garden',
      imageUrl: 'https://gsriztjnocjwgqkaxhhz.supabase.co/storage/v1/object/public/tryon-fits/bg7.jpg',
    ),
    PresetBackground(
      id: 'bg8',
      name: 'Beach Resort Sunset',
      imageUrl: 'https://gsriztjnocjwgqkaxhhz.supabase.co/storage/v1/object/public/tryon-fits/bg11.png',
    ),
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
