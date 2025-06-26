// lib/features/ai_assistant/presentation/widgets/app_guide_section.dart
import 'package:flutter/material.dart';
import 'package:habitiurs/features/ai_assistant/domain/entities/app_guide.dart';

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
  int? _expandedIndex; // Para controlar qué tile está expandida

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
            // ✅ CORRECCIÓN: Eliminar el Card/Container extra dentro del map
            // ExpansionPanelList genera su propio Card-like background,
            // poner un Card adicional a cada ExpansionPanel causa problemas de renderizado.
            Theme( 
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionPanelList(
                elevation: 0, // Elimina la sombra de los paneles
                expandedHeaderPadding: EdgeInsets.zero, // Elimina padding extra en el header expandido
                animationDuration: const Duration(milliseconds: 300),
                expansionCallback: (int index, bool isExpanded) {
                  setState(() {
                    if (isExpanded) {
                      _expandedIndex = null; 
                    } else {
                      _expandedIndex = index; 
                    }
                  });
                },
                children: widget.guides.asMap().entries.map((entry) {
                  final index = entry.key;
                  final guide = entry.value;
                  final isExpanded = _expandedIndex == index;

                  return ExpansionPanel(
                    canTapOnHeader: true,
                    headerBuilder: (context, isExpanded) {
                      return ListTile( // ListTile es un buen widget para el header de ExpansionPanel
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
                      );
                    },
                    body: Padding(
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
                    isExpanded: isExpanded,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}