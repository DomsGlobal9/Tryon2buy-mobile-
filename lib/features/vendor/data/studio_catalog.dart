/// Static data the merchant studio needs, copied from the website's
/// `TryonWorkspace.jsx` and `SampleWorkspaceModal.jsx`.
///
/// The category keys are the backend's spellings (`LEHANGA`, `KURTHI`), not
/// dictionary ones: the server picks default models and upload slots by these
/// exact strings.
library;

class StudioCategory {
  final String key;
  final String label;

  const StudioCategory(this.key, this.label);
}

class UploadSlot {
  final String id;
  final String label;
  final bool required;

  const UploadSlot(this.id, this.label, {required this.required});
}

/// A studio model. Lehenga models carry per-dupatta variants; the website
/// swaps the model image when a dupatta style is chosen.
class StudioModel {
  final String name;
  final String imageUrl;
  final String? style1Url;
  final String? style2Url;

  const StudioModel(this.name, this.imageUrl, {this.style1Url, this.style2Url});

  /// The image to send as `human_image_url` for [dupattaStyleUrl].
  String imageFor(String? dupattaStyleUrl) {
    if (dupattaStyleUrl == DupattaStyle.classicSingleShoulder.url) {
      return style1Url ?? imageUrl;
    }
    if (dupattaStyleUrl == DupattaStyle.traditionalFrontPleat.url) {
      return style2Url ?? imageUrl;
    }
    return imageUrl;
  }
}

class DupattaStyle {
  final String id;
  final String name;
  final String url;

  const DupattaStyle._(this.id, this.name, this.url);

  static const classicSingleShoulder = DupattaStyle._(
    'style_1',
    'Classic Single-Shoulder',
    'https://gsriztjnocjwgqkaxhhz.supabase.co/storage/v1/object/public/tryon-fits/lehanga_duppatta1.jpg',
  );
  static const traditionalFrontPleat = DupattaStyle._(
    'style_2',
    'Traditional Front Pleat',
    'https://gsriztjnocjwgqkaxhhz.supabase.co/storage/v1/object/public/tryon-fits/lehangaduppatta2.jpg',
  );

  static const all = [classicSingleShoulder, traditionalFrontPleat];
}

/// A ready-made garment set the merchant can load instead of uploading.
class SampleSet {
  final String name;

  /// slot id → hosted image URL.
  final Map<String, String> slots;

  const SampleSet(this.name, this.slots);
}

class StudioCatalog {
  const StudioCatalog._();

  static const String saree = 'SAREE';
  static const String lehanga = 'LEHANGA';
  static const String anarkali = 'ANARKALI';
  static const String kurthi = 'KURTHI';
  static const String sharara = 'SHARARA';

  static const categories = <StudioCategory>[
    StudioCategory(saree, 'Saree'),
    StudioCategory(lehanga, 'Lehanga'),
    StudioCategory(anarkali, 'Anarkali'),
    StudioCategory(kurthi, 'Kurthi'),
    StudioCategory(sharara, 'Sharara'),
  ];

  static const _sareeSlots = <UploadSlot>[
    UploadSlot('saree', 'Saree', required: true),
    UploadSlot('blouse', 'Blouse', required: false),
  ];

  static const _threeViewSlots = <UploadSlot>[
    UploadSlot('full', 'Full', required: true),
    UploadSlot('top', 'Top', required: true),
    UploadSlot('bottom', 'Bottom', required: true),
  ];

  static List<UploadSlot> slotsFor(String category) =>
      category == saree ? _sareeSlots : _threeViewSlots;

  /// The advisory note above the upload slots.
  static String uploadNoteFor(String category) => category == saree
      ? 'Upload the saree as a flat lay or draped on a mannequin. Blouse is '
          'optional — if not uploaded, the blouse from the saree image will be used.'
      : 'Please upload flat lay or mannequin photos of the actual stitched '
          '${category.toLowerCase()}. Do not upload unstitched fabric pieces. '
          'Ensure each specific garment part is uploaded into its corresponding '
          'slot below for optimal draping.';

  static const _base =
      'https://gsriztjnocjwgqkaxhhz.supabase.co/storage/v1/object/public/tryon-fits/default%20models';

  static const _modelsByCategory = <String, List<StudioModel>>{
    saree: [
      StudioModel('Model 1', '$_base/41.jpeg'),
      StudioModel('Model 2', '$_base/42.jpeg'),
      StudioModel('Model 3', '$_base/43.jpeg'),
      StudioModel('Model 4', '$_base/44.jpeg'),
    ],
    lehanga: [
      StudioModel(
        'Model 1',
        '$_base/lehanga/lehanga1_default.png',
        style1Url: '$_base/lehanga/lehanga1_duppat.png',
        style2Url: '$_base/lehanga/lehanga1_default.png',
      ),
      StudioModel(
        'Model 2',
        '$_base/lehanga/lehanga2_default.png',
        style1Url: '$_base/lehanga/lehanga2_duppat.png',
        style2Url: '$_base/lehanga/lehanga2_default.png',
      ),
      StudioModel(
        'Model 3',
        '$_base/lehanga/lehanga3_default.png',
        style1Url: '$_base/lehanga/lehanga3_duppa.png',
        style2Url: '$_base/lehanga/lehanga3_default.png',
      ),
      StudioModel(
        'Model 4',
        '$_base/lehanga/lehanga4_default.png',
        style1Url: '$_base/lehanga/lehanga4_duppata.png',
        style2Url: '$_base/lehanga/lehanga4_default.png',
      ),
    ],
    anarkali: [
      StudioModel('Model 1', '$_base/anarkali/ChatGPT%20Image%20Aug%2020,%202026,%2005_55_11%20PM.png'),
      StudioModel('Model 2', '$_base/anarkali/ChatGPT%20Image%20Aug%2020,%202026,%2005_55_23%20PM.png'),
      StudioModel('Model 3', '$_base/anarkali/ChatGPT%20Image%20Aug%2020,%202026,%2005_55_52%20PM.png'),
      StudioModel('Model 4', '$_base/anarkali/ChatGPT%20Image%20Aug%2020,%202026,%2005_56_15%20PM.png'),
    ],
    kurthi: [
      StudioModel('Model 1', '$_base/kurti/kurti1.jpg'),
      StudioModel('Model 2', '$_base/kurti/kurti2.jpg'),
      StudioModel('Model 3', '$_base/kurti/kurti3.jpg'),
      StudioModel('Model 4', '$_base/kurti/kurti4.jpg'),
    ],
    sharara: [
      StudioModel('Model 1', '$_base/sharara/shrara1.jpg'),
      StudioModel('Model 2', '$_base/sharara/shrara2.jpg'),
      StudioModel('Model 3', '$_base/sharara/shrara3.jpg'),
      StudioModel('Model 4', '$_base/sharara/sharara4.jpg'),
    ],
  };

  static List<StudioModel> modelsFor(String category) =>
      _modelsByCategory[category] ?? _modelsByCategory[saree]!;

  // ── Sample materials ───────────────────────────────────────────────────

  static const _garments =
      'https://gsriztjnocjwgqkaxhhz.supabase.co/storage/v1/object/public/tryon-fits/garments';
  static const _cloud = 'https://res.cloudinary.com/doiezptnn/image/upload';

  static const sareeSamples = <String>[
    '$_garments/_DSC0149.jpg',
    '$_garments/91be8c6a-9213-4627-b78d-088db18a08f3.jpg',
  ];

  static const blouseSamples = <String>[
    '$_garments/blouse1.JPG',
    '$_garments/blouse2.JPG',
  ];

  static const _samplesByCategory = <String, List<SampleSet>>{
    anarkali: [
      SampleSet('Pink Anarkali Suit', {
        'full': '$_cloud/v1784805925/content_3_oudsco.jpg',
        'top': '$_cloud/v1784805925/content_5_ljagq5.jpg',
        'bottom': '$_cloud/v1784805925/content_4_neb0xd.jpg',
      }),
      SampleSet('Green Anarkali Suit', {
        'full': '$_cloud/v1784806111/content_xaru3w.jpg',
        'top': '$_cloud/v1784806100/content_1_faort2.jpg',
        'bottom': '$_cloud/v1784806110/content_7_c3zqmk.jpg',
      }),
    ],
    lehanga: [
      SampleSet('Pink Lehenga Set', {
        'full': '$_cloud/v1785320656/debb32ea-b3f7-45a3-ac54-bdd9994a4cc1_nvldkp.png',
        'top': '$_cloud/v1785320702/c3e089f3-070d-4d78-a34d-f0de46218ec9_drdbdl.png',
        'bottom': '$_cloud/v1785320694/c782961e-3680-4040-a45a-64ea894d74aa_nmppvx.png',
      }),
      SampleSet('Blue Lehenga Set', {
        'full': '$_cloud/v1785320827/a6d2f9bd-311f-48a0-a5f1-dcd17810f051_jfgvhk.png',
        'top': '$_cloud/v1785320841/b2e11fea-e1a6-443b-b5d3-927fecb3d7a9_lamxsr.png',
        'bottom': '$_cloud/v1785320829/acb9c58c-dafc-4a2d-8256-e601916ca0ae_bg86yu.png',
      }),
    ],
    kurthi: [
      SampleSet('Navy Blue Kurta Set', {
        'full': '$_cloud/v1785320942/e7f57e95-ebda-44d0-89fe-b707d44cc03b_ddvj8t.png',
        'top': '$_cloud/v1785320961/1ce21892-55e1-4eb0-8722-16d0a103d83e_rgyedx.png',
        'bottom': '$_cloud/v1785320951/b0990a70-4d69-4bb6-ac51-c88ed9f5dab3_yzzq1f.png',
      }),
      SampleSet('Olive Green Kurta Set', {
        'full': '$_cloud/v1785321138/1d12a54e-ee96-4fff-9665-b61b964efff6_pgumoy.png',
        'top': '$_cloud/v1785321165/ce64fd21-a18f-488a-a1ec-00c6e1e4302f_fsznty.png',
        'bottom': '$_cloud/v1785321148/92b1b0db-647a-406c-a105-bb02845e1a48_gokm1t.png',
      }),
    ],
    sharara: [
      SampleSet('Peach Sharara Suit', {
        'full': '$_cloud/v1785411910/e0687f57-d87a-41ac-a419-e41f898dd693_xpjjrt.png',
        'top': '$_cloud/v1785411923/58c545d2-641f-4b8e-8103-bcd2503ac445_zuoopf.png',
        'bottom': '$_cloud/v1785411917/440841db-9cda-482f-a787-89775b245cd9_vm86hm.png',
      }),
      SampleSet('Maroon & Taupe Embroidered Sharara', {
        'full': '$_cloud/v1785411930/13518b41-1197-49b3-9410-b76da5d129c0_eocv0e.png',
        'top': '$_cloud/v1785412086/44346846-408e-4e72-a390-7b6adb550a78_nwjbsq.png',
        'bottom': '$_cloud/v1785411950/29ab400e-a62f-4b76-b23d-bfb055850b6c_jucwky.png',
      }),
    ],
  };

  /// Sample sets for three-view categories. Saree samples are picked per
  /// slot instead; see [sareeSamples] and [blouseSamples].
  static List<SampleSet> sampleSetsFor(String category) =>
      _samplesByCategory[category] ?? const [];
}
