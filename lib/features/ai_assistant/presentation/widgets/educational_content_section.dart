// lib/features/ai_assistant/presentation/widgets/educational_content_section.dart
import 'package:flutter/material.dart';
import '../../domain/entities/educational_content.dart';
import '../../../../core/ai/models/ai_response_model.dart';
import '../../../../core/ai/services/ai_fallback_service.dart'; 

class EducationalContentSection extends StatelessWidget {
  final List<EducationalContent> content;
  
  // ✅ ELIMINADO: atomicHabitsConcepts
  // final AIResponse? atomicHabitsConcepts; 
  // ✅ ELIMINADO: isAtomicConceptsLoading
  // final bool isAtomicConceptsLoading; 
  // ✅ ELIMINADO: onRefreshAtomicConcepts
  // final VoidCallback onRefreshAtomicConcepts; 

  const EducationalContentSection({
    Key? key,
    required this.content,
    // ✅ ELIMINADO: atomicHabitsConcepts
    // this.atomicHabitsConcepts, 
    // ✅ ELIMINADO: isAtomicConceptsLoading
    // this.isAtomicConceptsLoading = false, 
    // ✅ ELIMINADO: onRefreshAtomicConcepts
    // required this.onRefreshAtomicConcepts, 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Widget> cards = [];

    // ✅ ELIMINADO: La tarjeta de AI Concepts ya no se añade
    // cards.add(_buildAtomicConceptsCard(context)); 
    // Solo se añade el contenido educativo offline
    cards.addAll(content.map((article) => _buildContentCard(context, article))); 

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
                  Icons.school_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Contenido Educativo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220, 
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  return cards[index];
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard(BuildContext context, EducationalContent article) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () => _showContentFullScreenDialog(
            context,
            article.title,
            article.content,
          ),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        article.category,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (article.isLocal)
                      Icon(
                        Icons.offline_bolt,
                        size: 16,
                        color: Colors.green[600],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  article.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    article.content,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 4, 
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${article.readTimeMinutes} min',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ ELIMINADO: Método _buildAtomicConceptsCard ya no es necesario
  // Widget _buildAtomicConceptsCard(...) { ... }

  // Función de diálogo universal para mostrar contenido completo
  void _showContentFullScreenDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    content,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}