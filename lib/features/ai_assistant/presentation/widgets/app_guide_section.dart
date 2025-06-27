// lib/features/ai_assistant/presentation/widgets/app_guide_section.dart
import 'package:flutter/material.dart';
import '../../domain/entities/app_guide.dart';

class AppGuideSection extends StatefulWidget {
  final List<AppGuide> guides;

  const AppGuideSection({
    Key? key,
    required this.guides,
  }) : super(key: key);

  @override
  State<AppGuideSection> createState() => _AppGuideSectionState();
}

class _AppGuideSectionState extends State<AppGuideSection> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(),
            const SizedBox(height: 16),
            _GuideExpansionList(
              guides: widget.guides,
              expandedIndex: _expandedIndex,
              onExpansionChanged: _handleExpansionChanged,
            ),
          ],
        ),
      ),
    );
  }

  void _handleExpansionChanged(int index) {
    setState(() {
      _expandedIndex = _expandedIndex == index ? null : index;
    });
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}

class _GuideExpansionList extends StatelessWidget {
  final List<AppGuide> guides;
  final int? expandedIndex;
  final Function(int) onExpansionChanged;

  const _GuideExpansionList({
    required this.guides,
    required this.expandedIndex,
    required this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionPanelList(
      expansionCallback: (panelIndex, isExpanded) {
        onExpansionChanged(panelIndex);
      },
      elevation: 0,
      dividerColor: Colors.transparent,
      children: guides.asMap().entries.map((entry) {
        final index = entry.key;
        final guide = entry.value;
        
        return ExpansionPanel(
          headerBuilder: (context, isExpanded) {
            return _GuideHeader(
              guide: guide,
              isExpanded: isExpanded,
            );
          },
          body: _GuideBody(content: guide.content),
          isExpanded: expandedIndex == index,
          canTapOnHeader: true,
          backgroundColor: Colors.transparent,
        );
      }).toList(),
    );
  }
}

class _GuideHeader extends StatelessWidget {
  final AppGuide guide;
  final bool isExpanded;

  const _GuideHeader({
    required this.guide,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _GuideNumber(order: guide.order),
          const SizedBox(width: 12),
          Expanded(
            child: _GuideTitle(title: guide.title),
          ),
        ],
      ),
    );
  }
}

class _GuideNumber extends StatelessWidget {
  final int order;

  const _GuideNumber({required this.order});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      radius: 16,
      child: Text(
        '$order',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _GuideTitle extends StatelessWidget {
  final String title;

  const _GuideTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
    );
  }
}

class _GuideBody extends StatelessWidget {
  final String content;

  const _GuideBody({required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Text(
        content,
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          color: Colors.grey[700],
        ),
      ),
    );
  }
}