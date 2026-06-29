// lib/features/ai_assistant/presentation/widgets/educational_content_section.dart
import 'package:flutter/material.dart';
import '../../domain/entities/educational_content.dart';
import '../../../../shared/widgets/section_header.dart';

class EducationalContentSection extends StatelessWidget {
  final List<EducationalContent> content;

  const EducationalContentSection({Key? key, required this.content})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              icon: Icons.school_outlined,
              title: 'Contenido Educativo',
            ),
            const SizedBox(height: 16),
            _ContentList(content: content),
          ],
        ),
      ),
    );
  }
}

class _ContentList extends StatelessWidget {
  final List<EducationalContent> content;

  const _ContentList({required this.content});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: content.length,
        itemBuilder: (context, index) {
          return _ContentCard(article: content[index]);
        },
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final EducationalContent article;

  const _ContentCard({required this.article});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showContentDialog(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardHeader(context),
                const SizedBox(height: 8),
                _CardTitle(),
                const SizedBox(height: 8),
                _CardPreview(context),
                const Spacer(),
                _CardFooter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _CardHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            article.category,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        if (article.isLocal)
          Icon(Icons.offline_bolt, size: 16, color: Colors.green[600]),
      ],
    );
  }

  Widget _CardTitle() {
    return Text(
      article.title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _CardPreview(BuildContext context) {
    return Text(
      article.content,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _CardFooter(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 14,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(width: 4),
        Text(
          '${article.readTimeMinutes} min',
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const Spacer(),
        Text(
          'Leer más',
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showContentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ContentDialog(article: article),
    );
  }
}

class _ContentDialog extends StatelessWidget {
  final EducationalContent article;

  const _ContentDialog({required this.article});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            _DialogHeader(title: article.title),
            _DialogContent(content: article.content),
          ],
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  final String title;

  const _DialogHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _DialogContent extends StatelessWidget {
  final String content;

  const _DialogContent({required this.content});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
      ),
    );
  }
}
