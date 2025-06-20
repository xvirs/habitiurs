// lib/features/ai_assistant/presentation/widgets/app_guide_section.dart
import 'package:flutter/material.dart';
import 'package:habitiurs/features/ai_assistant/domain/entities/app_guide.dart';
import 'package:habitiurs/features/ai_assistant/domain/entities/educational_content.dart';

class AppGuideSection extends StatelessWidget {
  final List<AppGuide> guides;

  const AppGuideSection({
    Key? key,
    required this.guides,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Guía de Uso',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...guides.map((guide) => _buildGuideItem(context, guide)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideItem(BuildContext context, AppGuide guide) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 1,
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            radius: 16,
            child: Text(
              '${guide.order}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          title: Text(
            guide.title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                guide.content,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

