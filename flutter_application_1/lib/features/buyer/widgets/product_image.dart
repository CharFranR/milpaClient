import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    this.imageSrc,
    required this.emoji,
    this.emojiSize = 48,
  });

  final String? imageSrc;
  final String emoji;
  final double emojiSize;

  @override
  Widget build(BuildContext context) {
    final String? src = imageSrc;
    if (src == null || src.isEmpty) {
      return _EmojiFallback(emoji: emoji, size: emojiSize);
    }
    return Image.network(
      src,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : _EmojiFallback(emoji: emoji, size: emojiSize),
      errorBuilder: (context, error, stackTrace) =>
          _EmojiFallback(emoji: emoji, size: emojiSize),
    );
  }
}

class _EmojiFallback extends StatelessWidget {
  const _EmojiFallback({required this.emoji, required this.size});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(emoji, style: TextStyle(fontSize: size)),
    );
  }
}
