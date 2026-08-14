// lib/features/creator/presentation/widgets/creator_loading_skeleton.dart
import 'package:flutter/material.dart';

class CreatorLoadingSkeleton extends StatelessWidget {
  final int count;

  const CreatorLoadingSkeleton({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: count,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBlock(60, 60, shape: BoxShape.circle),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShimmerBlock(double.infinity, 16),
                      const SizedBox(height: 8),
                      _buildShimmerBlock(120, 12),
                      const SizedBox(height: 8),
                      _buildShimmerBlock(200, 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerBlock(double width, double height, {BoxShape shape = BoxShape.rectangle}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.2),
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? BorderRadius.circular(8) : null,
      ),
    );
  }
}
