/// The app's privacy policy and terms of service.
///
/// tryon2buy.com's footer links for both are empty anchors, so the app
/// carries its own copy. Everything stated here describes what the app and
/// its backend actually do (see `ApiClient`, `TryonResultsLocalDataSource`
/// and the `tryon_service` routes); keep it that way when behaviour changes.
///
/// Sections are plain paragraphs, headings (`# `) and bullets (`- `),
/// rendered by `LegalScreen`.
library;

enum LegalDocument { privacy, terms }

class LegalContent {
  const LegalContent._();

  static const String company = 'Tryon2Buy Technology';
  static const String contactEmail = 'info@tryon2buy.com';
  static const String effectiveDate = '11 September 2026';

  static String titleOf(LegalDocument doc) => switch (doc) {
        LegalDocument.privacy => 'Privacy Policy',
        LegalDocument.terms => 'Terms of Service',
      };

  static List<String> bodyOf(LegalDocument doc) => switch (doc) {
        LegalDocument.privacy => privacy,
        LegalDocument.terms => terms,
      };

  static const privacy = <String>[
    'This policy explains what the TryOn2Buy app collects, why, and what '
        'happens to it. It applies to the mobile app and to the TryOn2Buy '
        'service it connects to.',
    '# Photos you upload',
    'When you try on a garment, the photo you choose is sent to our servers '
        'and stored in our cloud storage so the try-on can be generated and '
        'so the result keeps working when you reopen or share it. The photo is '
        'processed by the AI models we use to render the try-on. We use your '
        'photos solely to generate the previews you ask for; we do not sell '
        'them or use them for advertising.',
    'Merchants and B2B clients upload garment photos in the same way. Those '
        'images and the studio shots generated from them are stored under the '
        'business account that uploaded them.',
    '# Generated images and share links',
    'Every try-on result has a link you can copy from the app. Anyone who has '
        'that link can open the image, so share it only with people you want '
        'to see it. A merchant who saves a drape to their library publishes it '
        'on their public shop page.',
    '# What stays on your device',
    '- Recent try-on results and the photo used for them are kept on this '
        'device for 20 minutes after their last use, then removed automatically.',
    '- Recent searches are stored on the device until you clear them.',
    '- A merchant or B2B sign-in token is stored on the device until you sign '
        'out or it expires after 7 days. It is excluded from device backups.',
    '# Business accounts',
    'Creating a merchant account stores your email address, your name and '
        'your boutique name. Passwords are stored only as a salted hash. B2B '
        'clients can additionally record a company name, business type and '
        'mobile number in their business profile. We use these details to run '
        'your account and to contact you about it.',
    '# Guest use',
    'You can use the app without an account. To apply the free-tier limit '
        'fairly, our servers count guest generations per network address. '
        'Rate limiting on sign-in also uses the network address.',
    '# What we do not collect',
    'The app contains no advertising or third-party analytics software, does '
        'not read your contacts or location, and only opens the camera or '
        'photo library when you tap a button that needs it.',
    '# Retention and deletion',
    'Photos and generated images are kept so that results, libraries and share '
        'links continue to work. Merchants can delete products from their '
        'catalog in the app. To have any photo, result or account removed, '
        'email $contactEmail from the address on the account, or describe the '
        'image and when it was made, and we will delete it.',
    '# Children',
    'The service is not directed at children under 13 and we do not knowingly '
        'collect their photos. If you believe a child\'s photo has been '
        'uploaded, contact us and we will remove it.',
    '# Changes',
    'If this policy changes, the app will carry the new version and the date '
        'below will be updated. Continuing to use the app after a change means '
        'you accept the updated policy.',
    '# Contact',
    '$company\n$contactEmail',
    'Effective $effectiveDate.',
  ];

  static const terms = <String>[
    'These terms govern your use of the TryOn2Buy app and service, provided '
        'by $company. By using the app you agree to them.',
    '# The service',
    'TryOn2Buy generates AI images that show a garment draped on a studio '
        'model or on a photo you provide. Results are visual previews produced '
        'by an AI model. They approximate fit, drape and colour and are not a '
        'guarantee of how a garment will look or fit in person.',
    '# Accounts and guest use',
    'Shoppers can use the app without an account, subject to a free-tier '
        'limit on the number of generations. Merchants and B2B clients sign in '
        'with an email address and password and are responsible for keeping '
        'those credentials confidential and for activity on their account. '
        'Business accounts receive a number of generation credits; additional '
        'credits are arranged by contacting us.',
    '# Your content',
    'You keep all rights to the photos you upload. You give us permission to '
        'store and process them, and the images generated from them, to the '
        'extent needed to provide the service, including keeping results and '
        'share links available. You confirm that you have the right to use '
        'every photo you upload and that it does not show a person who has '
        'not agreed to it.',
    '# Acceptable use',
    '- Upload only photos of yourself, of people who have agreed, or of '
        'garments you have the right to use.',
    '- Do not upload images of minors, explicit or unlawful content, or '
        'content that infringes someone else\'s rights.',
    '- Do not attempt to circumvent generation limits, probe or overload the '
        'service, or use generated images to deceive or harm anyone.',
    'We may remove content and suspend accounts that breach these rules.',
    '# Generated images',
    'Generated images may contain artefacts and may not reproduce a garment '
        'exactly. Merchants are responsible for reviewing studio shots before '
        'publishing them and for any representations made to their customers.',
    '# Availability and changes',
    'The service depends on third-party infrastructure and AI models and may '
        'be interrupted, changed or discontinued. We may update the app and '
        'these terms; the current version is always shown in the app.',
    '# Liability',
    'The service is provided as is. To the fullest extent permitted by law, '
        '$company is not liable for indirect or consequential losses arising '
        'from use of the app, and our total liability for any claim is limited '
        'to the amount you paid us for the service in the preceding twelve '
        'months.',
    '# Contact',
    'Questions about these terms: $contactEmail.',
    'Effective $effectiveDate.',
  ];
}
