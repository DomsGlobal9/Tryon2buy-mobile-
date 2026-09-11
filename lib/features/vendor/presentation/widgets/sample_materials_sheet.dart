import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/remote_image.dart';
import '../../data/studio_catalog.dart';

/// The website's "Sample Materials" modal as a bottom sheet.
///
/// Sarees are picked per slot (any saree with any blouse); the other
/// categories offer complete full / top / bottom sets. Every tap is reported
/// through [onPicked] immediately, so dismissing the sheet never loses a
/// choice.
class SampleMaterialsSheet extends StatefulWidget {
  final String category;
  final Map<String, String> current;
  final ValueChanged<Map<String, String>> onPicked;

  const SampleMaterialsSheet._({
    required this.category,
    required this.current,
    required this.onPicked,
  });

  static Future<void> show(
    BuildContext context, {
    required String category,
    required Map<String, String> current,
    required ValueChanged<Map<String, String>> onPicked,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SampleMaterialsSheet._(
        category: category,
        current: current,
        onPicked: onPicked,
      ),
    );
  }

  @override
  State<SampleMaterialsSheet> createState() => _SampleMaterialsSheetState();
}

class _SampleMaterialsSheetState extends State<SampleMaterialsSheet> {
  late final Map<String, String> _picked = Map.of(widget.current);

  static const _gold = Color(0xFF7F5700);

  String get _subtitle => widget.category == StudioCatalog.saree
      ? 'Select a saree and blouse to automatically load them into your workspace. You can close this window at any time.'
      : 'Select ${widget.category.toLowerCase()} views to automatically load them into your workspace. You can close this window at any time.';

  void _pick(Map<String, String> slots) {
    setState(() => _picked.addAll(slots));
    widget.onPicked(slots);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text('Sample Materials', style: AppTypography.studioHeading(size: 22)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
            child: Text(
              _subtitle,
              style: AppTypography.bodyMedium.copyWith(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: widget.category == StudioCatalog.saree
                  ? _sareeSections()
                  : _setSections(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _sareeSections() => [
        _Panel(
          title: 'Saree & Blouse Samples',
          children: [
            _SlotPicker(
              title: 'Pick Saree',
              urls: StudioCatalog.sareeSamples,
              selected: _picked['saree'],
              onPick: (url) => _pick({'saree': url}),
            ),
            const SizedBox(height: 16),
            _SlotPicker(
              title: 'Pick Blouse',
              urls: StudioCatalog.blouseSamples,
              selected: _picked['blouse'],
              onPick: (url) => _pick({'blouse': url}),
            ),
          ],
        ),
      ];

  List<Widget> _setSections() {
    final sets = StudioCatalog.sampleSetsFor(widget.category);
    if (sets.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 40),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDCD6CC), width: 2),
          ),
          child: Text(
            'NO SAMPLE MATERIALS AVAILABLE FOR ${widget.category} YET.',
            textAlign: TextAlign.center,
            style: AppTypography.monoLabel(size: 10, color: AppColors.textMuted),
          ),
        ),
      ];
    }

    final title = switch (widget.category) {
      StudioCatalog.lehanga => 'Lehenga Samples',
      StudioCatalog.kurthi => 'Kurta Samples',
      StudioCatalog.anarkali => 'Anarkali Samples',
      _ => 'Sharara Samples',
    };

    return [
      _Panel(
        title: title,
        children: [
          for (var i = 0; i < sets.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            _SetPicker(
              sampleSet: sets[i],
              selected: _picked['full'] == sets[i].slots['full'],
              onPick: () => _pick(sets[i].slots),
            ),
          ],
        ],
      ),
    ];
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Panel({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.studioHeading(size: 16)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _SlotPicker extends StatelessWidget {
  final String title;
  final List<String> urls;
  final String? selected;
  final ValueChanged<String> onPick;

  const _SlotPicker({
    required this.title,
    required this.urls,
    required this.selected,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Rule(title: title, done: selected != null),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < urls.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: _SampleTile(
                  url: urls[i],
                  selected: selected == urls[i],
                  onTap: () => onPick(urls[i]),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _SetPicker extends StatelessWidget {
  final SampleSet sampleSet;
  final bool selected;
  final VoidCallback onPick;

  const _SetPicker({
    required this.sampleSet,
    required this.selected,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    const order = ['full', 'top', 'bottom'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Rule(title: sampleSet.name, done: selected),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < order.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _SampleTile(
                  url: sampleSet.slots[order[i]] ?? '',
                  badge: order[i],
                  selected: selected,
                  onTap: onPick,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  final String title;
  final bool done;
  const _Rule({required this.title, required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.ink.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title.toUpperCase(), style: AppTypography.monoLabel(size: 9.5))),
          if (done) const Icon(Icons.check, size: 14, color: Color(0xFF16A34A)),
        ],
      ),
    );
  }
}

class _SampleTile extends StatelessWidget {
  final String url;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  const _SampleTile({
    required this.url,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _SampleMaterialsSheetState._gold : Colors.black.withValues(alpha: 0.05),
              width: 2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RemoteImage(url: url, fallbackIcon: Icons.checkroom, decodeWidth: 400),
              if (badge != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(badge!.toUpperCase(), style: AppTypography.monoLabel(size: 7, color: Colors.white, letterSpacing: 1)),
                  ),
                ),
              if (selected)
                const Positioned(
                  top: 6,
                  left: 6,
                  child: CircleAvatar(
                    radius: 9,
                    backgroundColor: _SampleMaterialsSheetState._gold,
                    child: Icon(Icons.check, size: 11, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
