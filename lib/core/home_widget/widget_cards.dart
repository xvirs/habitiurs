// lib/core/home_widget/widget_cards.dart
// Vistas Flutter que se renderizan a imagen (home_widget.renderFlutterWidget)
// para los widgets de pantalla de inicio. Buscan el look de la maqueta: card
// oscura con degradado, tipografía cuidada, acentos de color. Son
// autocontenidas (colores explícitos, sin Theme.of) porque se rendean fuera
// del árbol de la app.
import 'package:flutter/material.dart';

/// Paleta fija (card oscura estilo maqueta, se ve bien sobre cualquier fondo).
class _WC {
  static const bgTop = Color(0xFF20252E);
  static const bgBottom = Color(0xFF191D25);
  static const edge = Color(0x14FFFFFF);
  static const ink = Color(0xFFF3F5F9);
  static const muted = Color(0xFFA6B0C0);
  static const faint = Color(0xFF6B7688);
  static const track = Color(0xFF2A323C);
  static const green = Color(0xFF2FBF6C);
  static const warn = Color(0xFFFF9F43);
  static const accent = Color(0xFF4C86F0);
  static const overdue = Color(0xFFFF5A5F);
}

BoxDecoration _cardDecoration() => BoxDecoration(
  gradient: const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [_WC.bgTop, _WC.bgBottom],
  ),
  borderRadius: BorderRadius.circular(22),
  border: Border.all(color: _WC.edge, width: 1),
);

// ─── Racha ──────────────────────────────────────────────────────────────────

class RachaCard extends StatelessWidget {
  final int current;
  final int best;
  final bool atRisk;
  final int remaining;
  final Size size;

  const RachaCard({
    super.key,
    required this.current,
    required this.best,
    required this.atRisk,
    required this.remaining,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final risk = atRisk && current > 0;
    final numColor = risk ? _WC.warn : _WC.ink;
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Container(
        decoration: _cardDecoration(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              '$current',
              style: TextStyle(
                fontSize: 34,
                height: 1,
                fontWeight: FontWeight.w800,
                color: numColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    risk
                        ? 'EN RIESGO'
                        : (current == 1 ? 'día de racha' : 'días de racha'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: risk ? 11 : 12.5,
                      height: 1.1,
                      fontWeight: risk ? FontWeight.w800 : FontWeight.w500,
                      letterSpacing: risk ? 0.6 : 0,
                      color: risk ? _WC.warn : _WC.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    risk
                        ? (remaining == 1
                            ? 'Falta 1 hoy'
                            : 'Faltan $remaining hoy')
                        : 'Mejor: $best días',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                      color: risk ? _WC.warn : _WC.faint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Constancia (heatmap) ────────────────────────────────────────────────────

class ConstanciaCard extends StatelessWidget {
  final int weeks;
  final List<int> levels; // largo weeks*7, -1 = futuro
  final int best;
  final Size size;

  const ConstanciaCard({
    super.key,
    required this.weeks,
    required this.levels,
    required this.best,
    required this.size,
  });

  Color _cellColor(int level) {
    switch (level) {
      case 1:
        return _WC.green.withValues(alpha: 0.34);
      case 2:
        return _WC.green.withValues(alpha: 0.62);
      case 3:
        return _WC.green;
      case -1:
        return Colors.transparent;
      default:
        return _WC.track;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Container(
        decoration: _cardDecoration(),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'CONSTANCIA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: _WC.muted,
                    ),
                  ),
                ),
                Text(
                  'últimas $weeks sem',
                  style: const TextStyle(fontSize: 10.5, color: _WC.faint),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  const gap = 3.0;
                  final cell = (((c.maxWidth - gap * (weeks - 1)) / weeks)
                          .clamp(4.0, (c.maxHeight - gap * 6) / 7))
                      .toDouble();
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var w = 0; w < weeks; w++) ...[
                        Column(
                          children: [
                            for (var r = 0; r < 7; r++) ...[
                              Container(
                                width: cell,
                                height: cell,
                                decoration: BoxDecoration(
                                  color: _cellColor(
                                    w * 7 + r < levels.length
                                        ? levels[w * 7 + r]
                                        : 0,
                                  ),
                                  borderRadius: BorderRadius.circular(cell * 0.28),
                                ),
                              ),
                              if (r < 6) const SizedBox(height: gap),
                            ],
                          ],
                        ),
                        if (w < weeks - 1) const SizedBox(width: gap),
                      ],
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    best > 0 ? '🔥 Mejor racha: $best días' : 'Empezá tu racha hoy',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.5, color: _WC.muted),
                  ),
                ),
                const Text(
                  'menos ',
                  style: TextStyle(fontSize: 9.5, color: _WC.faint),
                ),
                for (final lvl in const [0, 1, 2, 3]) ...[
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: _cellColor(lvl),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
                const Text(
                  ' más',
                  style: TextStyle(fontSize: 9.5, color: _WC.faint),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Misiones ────────────────────────────────────────────────────────────────

class MissionRowData {
  final String title;
  final int urgency; // 0 vencida, 1 hoy, 2 próxima, 3 sin fecha
  final String due;
  const MissionRowData(this.title, this.urgency, this.due);
}

class MisionesCard extends StatelessWidget {
  final int pending;
  final List<MissionRowData> items;
  final Size size;

  const MisionesCard({
    super.key,
    required this.pending,
    required this.items,
    required this.size,
  });

  Color _dotColor(int urgency) {
    switch (urgency) {
      case 0:
        return _WC.overdue;
      case 1:
        return _WC.accent;
      default:
        return _WC.faint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = items.take(4).toList();
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Container(
        decoration: _cardDecoration(),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'MISIONES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: _WC.muted,
                    ),
                  ),
                ),
                Text(
                  pending == 1 ? '1 pendiente' : '$pending pendientes',
                  style: const TextStyle(fontSize: 10.5, color: _WC.faint),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (visible.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Sin misiones pendientes 🎉',
                    style: TextStyle(fontSize: 13, color: _WC.muted),
                  ),
                ),
              )
            else
              for (final m in visible)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5.5),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _dotColor(m.urgency),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          m.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: _WC.ink),
                        ),
                      ),
                      if (m.due.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          m.due,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _dotColor(m.urgency),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
