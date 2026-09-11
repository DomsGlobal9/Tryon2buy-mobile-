/// Static copy from tryon2buy.com: the About page, the five Solutions pages
/// and the three Journal posts. Kept verbatim so the app reads exactly like
/// the site.
library;

class SolutionPage {
  final String key;
  final String navName;
  final String navDesc;
  final String title;
  final String tagline;
  final String subtitle;
  final String description;
  final String heroImage;
  final String problemTitle;
  final String problemText;
  final String solutionTitle;
  final List<(String, String)> features;
  final List<(String, String)> impact;

  const SolutionPage({
    required this.key,
    required this.navName,
    required this.navDesc,
    required this.title,
    required this.tagline,
    required this.subtitle,
    required this.description,
    required this.heroImage,
    required this.problemTitle,
    required this.problemText,
    required this.solutionTitle,
    required this.features,
    required this.impact,
  });
}

class JournalPost {
  final String slug;
  final String title;
  final String description;
  final String category;
  final String image;

  /// Paragraphs, headings (`# `), a quote (`> `) and bullets (`- `).
  final List<String> body;

  const JournalPost({
    required this.slug,
    required this.title,
    required this.description,
    required this.category,
    required this.image,
    required this.body,
  });
}

class SiteContent {
  const SiteContent._();

  static const _web = 'https://tryon2buy.com';

  static const solutions = <SolutionPage>[
    SolutionPage(
      key: 'saree',
      navName: 'Saree Try-On',
      navDesc: 'Nivi, Bengali & Regional drapes',
      title: 'AI Saree Try-On',
      tagline: 'Accurate Drape Rendering.',
      subtitle: 'Sarees are six yards of drape, not a dress.',
      description:
          'TryOn2Buy is the only virtual try-on platform trained on real saree draping physics — Nivi, Bengali, seedha pallu, and regional variants. Shoppers see how the saree will actually look. Brands see return rates drop.',
      heroImage: '$_web/gg.png',
      problemTitle: 'The Saree Visualization Problem',
      problemText:
          "A saree photograph doesn't tell you how it drapes. Flat lay shows color and pattern. Hanger shot shows fabric weight. Neither shows how six yards of silk will move, fold, and fall on an actual body. Generic AI tools trained on fitted Western garments fail—they flatten drape, miss regional conventions, and render six yards of fabric as if it were a dress.",
      solutionTitle: 'Why TryOn2Buy Is Different',
      features: [
        ('Trained on Real Physics', 'Our AI is trained on how saree fabric actually behaves — weight, movement, fold patterns, how the pallu falls across the shoulder.'),
        ('Regional Draping Styles', 'Nivi drape, Bengali drape, Seedha pallu, Coorgi drape. We render each with regional authenticity.'),
        ('No Photoshoot Required', 'Start with flat lay, hanger, or mannequin shots. We generate try-ons across body types and skin tones automatically.'),
        ('Catalog Scale Automation', 'Upload your entire catalog and get back rendered try-ons for multiple body types and draping styles.'),
      ],
      impact: [
        ('-30%', 'Reduction in return rates for try-on-enabled SKUs'),
        ('+18%', 'AOV lift on saree categories'),
        ('+40%', 'Increase in product page time-on-page'),
      ],
    ),
    SolutionPage(
      key: 'lehenga',
      navName: 'Lehenga Try-On',
      navDesc: 'Accurate flare & volume physics',
      title: 'AI Lehenga Try-On',
      tagline: 'Flare, Volume, and Movement.',
      subtitle: "A lehenga is not one garment; it's three — skirt, choli, dupatta.",
      description:
          'TryOn2Buy is trained on lehenga physics: skirt flare, fabric weight, how the choli sits, and exactly how the dupatta falls. With our proprietary Dupatta Drape Matrix, shoppers can visualize specific draping styles flawlessly. Brands see return rates drop.',
      heroImage: '$_web/content%20(4).png',
      problemTitle: 'The Lehenga Visualization Challenge',
      problemText:
          "A lehenga is a physics problem. A skirt with flare and volume depends on the wearer's body, movement, and how the fabric sits. A choli's fit depends on how it's tailored and how it pairs with the skirt. Furthermore, the dupatta isn't just an accessory—how it's draped completely changes the silhouette. Generic AI tools hallucinate bad anatomy when trying to guess how a heavy dupatta covers the arm or shoulder. They simply can't handle multi-piece layering.",
      solutionTitle: 'Why TryOn2Buy Is Different',
      features: [
        ('Proprietary Dupatta Drape Matrix', 'We solved the dupatta hallucination problem. Shoppers can select specific draping styles (pleated shoulder, open fall, waist tuck) and our Matrix ensures the physical drape is anatomically perfect.'),
        ('Multi-Piece Rendering', 'Lehenga is skirt + choli + dupatta. We render all three together, showing how they interact, layer, and drape on a body.'),
        ('Fabric Weight & Volume', 'Heavy silks behave differently than georgettes. Our AI models fabric-specific behavior so the skirt flare looks authentic.'),
        ('No Photoshoot Required', 'Start with a flat lay. We reconstruct the skirt volume, fit the choli, and apply the exact dupatta drape style automatically.'),
      ],
      impact: [
        ('-35%', 'Reduction in return rates for try-on-enabled SKUs'),
        ('+20%', 'AOV lift on bridal and festive categories'),
        ('+50%', 'Increase in product page engagement'),
      ],
    ),
    SolutionPage(
      key: 'anarkali',
      navName: 'Anarkali Try-On',
      navDesc: 'Floor-length flow & fit',
      title: 'AI Anarkali Try-On',
      tagline: 'Floor-Length Flow and Fit.',
      subtitle: 'The beauty of an Anarkali lies in its seamless flow from the bodice to the floor.',
      description:
          'TryOn2Buy renders the majestic sweep and volume of Anarkali suits with unparalleled physical accuracy. Shoppers see the true majesty of the garment. Brands see return rates drop.',
      heroImage: '$_web/ChatGPT%20Image%20Aug%204,%202026,%2002_42_31%20PM.png',
      problemTitle: 'The Anarkali Visualization Challenge',
      problemText:
          'An Anarkali is defined by its fitted bodice (choli) that flares out into a long, umbrella-like skirt (kali). Flat photography makes this garment look like a shapeless triangle. To truly understand an Anarkali, a shopper must see how the fabric drapes across the chest, cinches at the waist, and billows out to the floor.',
      solutionTitle: 'Why TryOn2Buy Is Different',
      features: [
        ('Precise Bodice Fit', 'Our AI understands that the upper half of an Anarkali must look sharply tailored, contrasting with the flow of the skirt.'),
        ('Kali (Panel) Rendering', "We accurately model the 'kalis' (vertical panels) that give the Anarkali its signature umbrella flare."),
        ('Floor-Length Physics', 'We render how heavy fabrics pool or sweep across the floor, giving a true sense of length and grandeur.'),
        ('Dupatta Integration', 'Seamlessly models how the dupatta interacts with the voluminous skirt and fitted bodice.'),
      ],
      impact: [
        ('-28%', 'Reduction in return rates for Anarkali suits'),
        ('+22%', 'AOV lift on luxury ethnic wear'),
        ('-35%', "Drop in 'fit/length was wrong' complaints"),
      ],
    ),
    SolutionPage(
      key: 'sharara',
      navName: 'Sharara Try-On',
      navDesc: 'Trouser volume & layering',
      title: 'AI Sharara Try-On',
      tagline: 'Trouser Volume and Layering.',
      subtitle: "A sharara's signature is its dramatic flare from the knee down.",
      description:
          'TryOn2Buy renders sharara sets with accurate fit and volume. Shoppers see how the multi-layered trouser will actually move and drape. Brands see return rates drop.',
      heroImage: '$_web/ChatGPT%20Image%20Aug%204,%202026,%2002_51_46%20PM.png',
      problemTitle: 'The Sharara Visualization Challenge',
      problemText:
          'A sharara is defined by its silhouette—fitted at the thighs and dramatically flared below the knee. A flat lay cannot capture this volume, and a generic hanger shot fails to show how the layers of fabric fall around the legs. Shoppers need to see the fit of the short kurti combined with the volume of the trousers.',
      solutionTitle: 'Why TryOn2Buy Is Different',
      features: [
        ('Accurate Trouser Volume', "Our AI specifically models the 'gota' (knee joint) gather and the subsequent flare of the sharara bottom."),
        ('Multi-Piece Ensemble Rendering', 'We accurately layer the short kurti over the flared trousers, maintaining the correct proportions.'),
        ('Fabric-Specific Drape', "Whether it's heavy brocade or light georgette, the AI renders the flare according to the fabric's actual physical properties."),
        ('No Photoshoot Required', 'Generate full-ensemble try-ons from simple flat lays of the individual pieces.'),
      ],
      impact: [
        ('-25%', 'Reduction in return rates for Sharara sets'),
        ('+15%', 'AOV lift on festive and bridal wear'),
        ('+45%', 'Increase in product page engagement'),
      ],
    ),
    SolutionPage(
      key: 'kurti',
      navName: 'Kurti Try-On',
      navDesc: 'Regional tailoring conventions',
      title: 'AI Kurti Try-On',
      tagline: 'Fit, Structure, and Regional Tailoring.',
      subtitle: "A kurti's fit is everything.",
      description:
          'TryOn2Buy is trained on how kurtis sit on different body types and how regional tailoring conventions affect the final look. Shoppers see fit, not just style. Brands see return rates drop.',
      heroImage: '$_web/ChatGPT%20Image%20Aug%204,%202026,%2002_47_43%20PM.png',
      problemTitle: 'The Kurti Fit Problem',
      problemText:
          "A kurti's fit depends on shoulder width, torso length, chest fullness, and how the hemline hits the body. A flat lay shows the pattern and color. A hanger shot shows the silhouette. Neither shows how it will actually fit on a real body. Generic try-on tools don't understand regional kurti cuts. A Rajasthani kurti is not a Bengal kurti.",
      solutionTitle: 'Why TryOn2Buy Is Different',
      features: [
        ('Trained on Regional Tailoring', 'Our AI understands how regional kurti cuts affect fit. Rajasthani, Bengali, Punjabi, Lucknowi — each has distinct proportions.'),
        ('Fit Across Body Types', 'How a kurti sits on different shoulder widths, how length works on different heights — our AI models real-world variation.'),
        ('For Sets and Layering', 'Kurti sets (kurti + pajama or palazzo) are handled as ensembles. We show how pieces layer and interact.'),
        ('No Photoshoot Required', 'Start with hanger, flat lay, or model shots. We generate fit-accurate try-ons across body types automatically.'),
      ],
      impact: [
        ('-20%', 'Reduction in return rates for fit-related issues'),
        ('+15%', 'AOV lift on kurti categories'),
        ('-40%', "Drop in 'sleeves too long' complaints"),
      ],
    ),
  ];

  static SolutionPage? solution(String key) {
    for (final s in solutions) {
      if (s.key == key) return s;
    }
    return null;
  }

  static const journal = <JournalPost>[
    JournalPost(
      slug: 'how-ai-virtual-try-on-reduces-returns',
      title: 'How AI Virtual Try-On Reduces Fashion Returns',
      description:
          "40% of Indian fashion orders are returned. Most are because the shopper's expectation didn't match reality. Learn how accurate visualization fixes this.",
      category: 'Ecommerce Strategy',
      image: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&w=1200&q=80',
      body: [
        "40% of Indian fashion orders are returned — nearly double the global apparel return rate of 16.5%. Most of those returns are not because the product is defective or mislabeled. They're because the shopper's expectation didn't match reality.",
        "A saree that photographs flat doesn't convey how its drape will fall on a body. A lehenga that looks good on a hanger doesn't show how its volume will flare when worn. A kurta that seems fine in a flat lay might not fit as expected when it arrives. The visualization gap is the problem.",
        '# The Returns Problem in Indian Fashion',
        "Ethnic wear is complex to visualize. A saree is six yards of drape. A lehenga is three pieces — skirt, choli, dupatta — each with its own behavior. A kurta's fit depends on regional tailoring conventions. A sherwani's structure changes based on body type. None of this comes across clearly in a flat lay or even a hanger shot.",
        "Traditional photography — flat lay, mannequin, or model shots — captures color, pattern, and basic silhouette. It doesn't capture drape, movement, fit, or how a garment will actually look on a real body. Result: mismatched expectations.",
        '# How Virtual Try-On Changes the Picture',
        'Virtual try-on gives shoppers a way to preview how a garment will actually look on a body like theirs before ordering. When the try-on is accurate — rendering real drape physics and regional styling conventions — shoppers see fit, drape, and proportions. Their expectation becomes closer to reality. Return risk drops.',
        "The key is accuracy. Generic AI trained on fitted Western garments fails on draped and layered Indian wear. It flattens drape, misses regional conventions, and renders six yards of fabric as if it were a dress. Shoppers see bad try-ons and don't trust them.",
        '> TryOn2Buy is trained specifically on Indian ethnic wear physics: how saree fabric drapes, how lehenga volume behaves, and how kurtas fit across body types.',
        '# The Data: Return Rate Impact',
        '- Saree try-on: 20–30% reduction in return rates for products with try-on enabled',
        '- Lehenga try-on: 25–35% reduction (higher due to fit complexity)',
        '- Kurta try-on: 15–20% reduction',
        '- Overall: 15–25% reduction in return rates across Indian ethnic wear categories',
      ],
    ),
    JournalPost(
      slug: 'saree-draping-styles',
      title: 'Saree Draping Styles Explained',
      description:
          'Nivi, Bengali, seedha pallu, and more. Understand how draping style affects silhouette, fit, and why generic AI gets it wrong.',
      category: 'Fashion Physics',
      image: '$_web/gg.png',
      body: [
        'A saree is six yards of fabric. How those six yards are draped—the placement of the pallu, the number and depth of pleats, how the saree sits on the hips and shoulders—determines everything about how it looks on a body.',
        "For ecommerce, understanding draping style is critical. A saree that photographs beautifully as a flat lay might look completely different when draped according to a specific regional convention. Here's a guide to the most common draping styles.",
        '# Nivi Drape (South Indian Classic)',
        'The Nivi drape is the most common saree draping style across India. The saree is wrapped around the body with approximately 9-12 deep, evenly-spaced pleats pinned at the center front. The pallu is brought up from the back over the left shoulder.',
        'Why it matters: Nivi drape requires accurate pallu placement, precise pleat depth, and correct shoulder draping. The pallu should flow naturally from the shoulder, not sit stiffly.',
        '# Bengali Drape',
        'The Bengali saree drape is structurally distinct from Nivi. The saree is wrapped around the body with the pallu brought from the back to the front, wrapping around the hip or waist before being draped across the body. The pleats are typically fewer and looser than in Nivi drape.',
        '# Seedha Pallu (Straight Pleated)',
        'Seedha pallu is a more structured approach. The pallu is draped straight down the front of the body, typically pleated vertically in neat, consistent folds. The pleats are tighter and more organized than in Nivi style. The overall look is more formal and geometric.',
        "> When AI virtual try-on gets the draping style wrong, the visualization becomes untrustworthy. That's why generic AI fails on Indian ethnic wear.",
      ],
    ),
    JournalPost(
      slug: 'lehenga-silhouettes',
      title: 'Understanding Lehenga Silhouettes',
      description:
          "A lehenga is not one garment; it's three. A complete guide to flare, volume, fit, and how different body types change the final look.",
      category: 'Fashion Physics',
      image: '$_web/content%20(4).png',
      body: [
        "A lehenga is not one garment; it's three—a skirt, a choli (blouse), and a dupatta (scarf). Each piece affects the overall silhouette, proportions, and how the ensemble looks on a body.",
        'For shoppers buying a lehenga online, visualization is everything. A lehenga that looks modest as a flat lay might have dramatic flare when worn. A choli that seems perfect on a hanger might not fit the way the wearer expects.',
        '# Understanding Flare and Volume',
        "Flare—how much the skirt spreads out from the waist—is determined by several factors: the cut of the skirt, the weight of the fabric, the number of layers, and how the wearer's body shape affects how the fabric sits.",
        "Fabric weight is critical. Heavy fabrics hold their shape and create structured flare. Light fabrics move more and can look limp if the cut doesn't support volume. Layered skirts create more volume than single-layer skirts.",
        '# Fit Across Body Types',
        "A lehenga's fit changes based on the wearer's body shape. A choli that fits perfectly on an hourglass figure might be too loose on a pear shape. A skirt that looks proportional on a tall figure might overwhelm a shorter frame.",
        '# The AI Hallucination Problem & The Dupatta Matrix',
        "The biggest challenge in virtual try-on for lehengas isn't the skirt—it's the dupatta. The dupatta isn't just an accessory; it is heavily draped over the choli, the shoulder, and sometimes the arms. When generic generative AI tries to process a lehenga, it frequently \"hallucinates\" the anatomy underneath the dupatta. If the fabric covers an arm in the source image, the AI often guesses the arm's shape incorrectly, resulting in deformed, unnatural generations.",
        "To solve this, TryOn2Buy developed the Proprietary Dupatta Drape Matrix. Instead of forcing the AI to blindly guess how fabric interacts with human anatomy, our matrix intelligently separates the drape geometry from the fabric texture. Shoppers can select specific, anatomically-perfect draping styles (like a pleated shoulder drape, an open fall, or a waist tuck), and the AI strictly maps the seller's fabric onto that flawless physical geometry. The result? Zero anatomical hallucinations and a perfect representation of the three-piece ensemble.",
        '> Lehengas are complex three-piece ensembles. Our Dupatta Drape Matrix ensures that whether the dupatta is pleated or free-flowing, the underlying anatomy remains perfect.',
        '# Bridal vs. Festive Lehengas',
        'Bridal lehengas are typically heavier, more ornate, and designed to make a dramatic statement. They often have maximum flare and volume. Festive and everyday lehengas tend to be lighter, more wearable, and designed for comfort as well as looks.',
      ],
    ),
  ];

  static JournalPost? post(String slug) {
    for (final p in journal) {
      if (p.slug == slug) return p;
    }
    return null;
  }
}
