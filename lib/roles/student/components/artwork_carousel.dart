import 'package:flutter/material.dart';

import '../models/artwork.dart';
import '../theme_colors.dart';

class ArtworkCarousel extends StatefulWidget {
  const ArtworkCarousel({super.key, required this.artworks});

  final List<Artwork> artworks;

  @override
  State<ArtworkCarousel> createState() => _ArtworkCarouselState();
}

class _ArtworkCarouselState extends State<ArtworkCarousel> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    const count = 2;
    final visible = expanded ? widget.artworks : widget.artworks.take(count).toList();

    return Card(
      color: ThemeColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Artworks',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ...visible.map(
              (art) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                height: 88,
                decoration: BoxDecoration(
                  color: ThemeColors.panelTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(art.title),
              ),
            ),
            if (widget.artworks.length > count)
              TextButton.icon(
                onPressed: () => setState(() => expanded = !expanded),
                icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                label: Text(expanded ? 'Show Less' : 'Show More'),
              )
          ],
        ),
      ),
    );
  }
}
