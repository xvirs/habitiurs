// lib/features/ai_assistant/presentation/widgets/rich_content.dart
import 'package:flutter/material.dart';

/// Renderiza texto con markdown liviano: **negrita** y viñetas (•/-).
/// Reemplaza el render plano que mostraba los asteriscos literales.
class RichContent extends StatelessWidget {
  final String text;
  final double fontSize;

  const RichContent(this.text, {super.key, this.fontSize = 14});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.onSurfaceVariant;
    final lines = text.trim().split('\n');
    final children = <Widget>[];

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) {
        children.add(const SizedBox(height: 9));
        continue;
      }

      final isBullet = line.startsWith('• ') || line.startsWith('- ');
      final content = isBullet ? line.substring(2) : line;
      final textWidget = Text.rich(
        _parseBold(content, theme),
        style: TextStyle(fontSize: fontSize, height: 1.45, color: base),
      );

      if (isBullet) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7, right: 9, left: 2),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(child: textWidget),
              ],
            ),
          ),
        );
      } else {
        children.add(
          Padding(padding: const EdgeInsets.only(bottom: 5), child: textWidget),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  /// Divide por `**` alternando normal/negrita (la negrita resalta en
  /// onSurface para que se lea como subtítulo o énfasis).
  TextSpan _parseBold(String line, ThemeData theme) {
    final parts = line.split('**');
    final spans = <TextSpan>[];
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      final bold = i.isOdd;
      spans.add(
        TextSpan(
          text: parts[i],
          style:
              bold
                  ? TextStyle(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  )
                  : null,
        ),
      );
    }
    return TextSpan(children: spans);
  }
}

/// Versión en texto plano (sin markdown) para vistas previas/truncadas.
String plainPreview(String markdown) =>
    markdown
        .replaceAll('**', '')
        .replaceAll('• ', '')
        .replaceAll('- ', '')
        .trim();
