import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerCard extends StatelessWidget {
  final double height;
  const ShimmerCard({super.key, this.height = 100});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base  = isDark ? const Color(0xFF1E293B) : Colors.grey.shade200;
    final high  = isDark ? const Color(0xFF2D3748) : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: high,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class ShimmerList extends StatelessWidget {
  final int count;
  final double itemHeight;
  const ShimmerList({super.key, this.count = 4, this.itemHeight = 100});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: count,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, _) => ShimmerCard(height: itemHeight),
    );
  }
}
