import 'package:flutter/material.dart';

import '../app.dart';

class ArtworkCarousel extends StatefulWidget {
  const ArtworkCarousel({super.key, this.imagePaths = const []});

  final List<String> imagePaths;

  @override
  State<ArtworkCarousel> createState() => _ArtworkCarouselState();
}

class _ArtworkCarouselState extends State<ArtworkCarousel> {
  late final PageController _controller = PageController();
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final items = widget.imagePaths.isEmpty
        ? ['assets/images/elikhalogo.png', 'assets/images/elikhalogolarge.png']
        : widget.imagePaths;

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (value) => setState(() => _index = value),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                  ),
                  child: Center(
                    child: Image.asset(items[index], fit: BoxFit.contain),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(items.length, (dotIndex) {
            final selected = _index == dotIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: selected ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: selected ? brandBlue : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }
}
