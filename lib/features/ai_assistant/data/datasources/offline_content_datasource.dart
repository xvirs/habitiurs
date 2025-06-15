// lib/features/ai_assistant/data/datasources/offline_content_datasource.dart

import 'package:habitiurs/features/ai_assistant/data/models/ai_recommendation_model.dart';
import 'package:habitiurs/features/ai_assistant/data/models/app_guide_model.dart';
import 'package:habitiurs/features/ai_assistant/domain/entities/educational_content.dart';
import '../models/educational_content_model.dart';

abstract class OfflineContentDatasource {
  Future<List<EducationalContentModel>> getEducationalContent();
  Future<List<AppGuideModel>> getAppGuides();
  Future<List<AIRecommendationModel>> getFallbackRecommendations();
}

class OfflineContentDatasourceImpl implements OfflineContentDatasource {
  @override
  Future<List<EducationalContentModel>> getEducationalContent() async {
    // Contenido hardcodeado basado en "Hábitos Atómicos"
    return [
      EducationalContentModel(
        id: 1,
        title: "La Regla de los 2 Minutos",
        content: """James Clear propone que cuando estés comenzando un nuevo hábito, debería tomar menos de dos minutos realizarlo.

"Leer antes de dormir" se convierte en "leer una página".
"Hacer ejercicio 30 minutos" se convierte en "ponerme las zapatillas de deporte".
"Meditar 10 minutos" se convierte en "respirar profundo tres veces".

La idea es que casi cualquier hábito puede reducirse a una versión de dos minutos. El objetivo no es hacer una cosa en dos minutos, sino dominar el hábito de aparecer.

Una vez que dominas el arte de aparecer, puedes mejorar y refinar el hábito. Es mejor hacer menos de lo que esperas que no hacer nada en absoluto.""",
        category: "Formación de Hábitos",
        readTimeMinutes: 3,
        createdAt: DateTime.now(),
        isLocal: true,
      ),
      EducationalContentModel(
        id: 2,
        title: "El Poder del Apilamiento de Hábitos",
        content: """El apilamiento de hábitos es una forma especial de intención de implementación. En lugar de emparejar tu nuevo hábito con un tiempo y lugar particular, lo emparejas con un hábito actual.

La fórmula es: "Después de [HÁBITO ACTUAL], haré [NUEVO HÁBITO]."

Ejemplos:
• Después de servirme mi café matutino, meditaré durante un minuto.
• Después de quitarme los zapatos del trabajo, inmediatamente me cambiaré la ropa de ejercicio.
• Después de cerrar mi laptop para el día, escribiré una cosa por la que estoy agradecido.

El apilamiento de hábitos funciona mejor cuando el hábito de pila y el nuevo hábito tienen aproximadamente la misma frecuencia.""",
        category: "Formación de Hábitos",
        readTimeMinutes: 4,
        createdAt: DateTime.now(),
        isLocal: true,
      ),
      EducationalContentModel(
        id: 3,
        title: "Diseño del Entorno para el Éxito",
        content: """Tu entorno físico influye enormemente en tus hábitos. Hacer que las señales de los hábitos buenos sean obvias en tu entorno es una forma poderosa de mantenerlos.

Estrategias para diseñar tu entorno:

**Para hábitos positivos:**
• Coloca frutas en un lugar visible
• Deja tu botella de agua donde la veas
• Pon tu libro junto a tu cama
• Deja tu ropa de ejercicio preparada

**Para evitar hábitos negativos:**
• Oculta el control remoto del televisor
• Deja tu teléfono en otra habitación
• No tengas comida chatarra visible

Recuerda: es más fácil cambiar tu entorno que cambiar tu fuerza de voluntad.""",
        category: "Formación de Hábitos",
        readTimeMinutes: 3,
        createdAt: DateTime.now(),
        isLocal: true,
      ),
      EducationalContentModel(
        id: 4,
        title: "La Importancia de la Identidad",
        content: """El cambio de comportamiento más profundo es el cambio de identidad. Cada acción es un voto por el tipo de persona que deseas convertirte.

En lugar de enfocarte en lo que quieres lograr, enfócate en quién quieres convertirte:
• "Quiero leer más" → "Soy una persona que lee"
• "Quiero ejercitarme" → "Soy una persona atlética"
• "Quiero escribir" → "Soy un escritor"

Cada vez que realizas tu hábito, reafirmas tu identidad. Cuando corres, eres un corredor. Cuando escribes, eres un escritor. Cuando ayudas a otros, eres una persona útil.

Tu identidad emerge de tus hábitos. Cada repetición es evidencia de que eres el tipo de persona que quieres ser.""",
        category: "Mindset",
        readTimeMinutes: 4,
        createdAt: DateTime.now(),
        isLocal: true,
      ),
    ];
  }

  @override
  Future<List<AppGuideModel>> getAppGuides() async {
    return [
      AppGuideModel(
        id: 1,
        title: "Bienvenido a Habitiurs",
        content: """Habitiurs es tu compañero para construir hábitos duraderos de manera simple y efectiva.

**¿Por qué Habitiurs?**
Esta aplicación está diseñada con principios científicos de formación de hábitos. No encontrarás gamificación complicada ni recordatorios molestos, solo las herramientas esenciales para el seguimiento consistente.

**Filosofía de la app:**
• Simplicidad sobre complejidad
• Constancia sobre perfección
• Progreso sobre resultados inmediatos
• Datos claros para tomar mejores decisiones

Habitiurs te ayuda a enfocarte en lo que realmente importa: aparecer cada día y hacer el trabajo.""",
        section: "overview",
        order: 1,
      ),
      AppGuideModel(
        id: 2,
        title: "Entendiendo la Cuadrícula Semanal",
        content: """La cuadrícula semanal es el corazón de Habitiurs. Aquí es donde visualizas tu progreso de manera clara y motivadora.

**Cómo funciona:**
• Cada fila representa un hábito
• Cada columna representa un día de la semana
• Los números del lado izquierdo identifican cada hábito

**Estados posibles:**
🟢 Verde con ✓ = Completado
🔴 Rojo con ✗ = No realizado conscientemente
⚪ Gris con + = Pendiente (aún no decidido)

**Solo el día actual es editable.** Los días pasados se muestran para referencia visual de tu progreso.

**Tip:** Usa la cuadrícula para identificar patrones. ¿Hay días específicos donde te cuesta más? ¿Ciertos hábitos son más difíciles que otros?""",
        section: "weekly_grid",
        order: 2,
      ),
      AppGuideModel(
        id: 3,
        title: "Interpretando tus Estadísticas",
        content: """Las estadísticas te dan una perspectiva objetiva de tu progreso a lo largo del tiempo.

**Sección 1 - Resumen del Mes:**
Muestra las semanas completas del mes actual con hábitos cumplidos y no cumplidos por semana.

**Sección 2 - Vista Anual:**
Lista todos los meses del año con:
• Porcentaje de constancia mensual
• Contador de hábitos completados/no completados/pendientes

**Sección 3 - Gráfico Histórico:**
Visualiza tu tendencia de constancia a lo largo del tiempo.

**Interpretación:**
• Un 70%+ de constancia es excelente
• 40-70% es bueno, hay espacio para mejorar
• <40% sugiere revisar tus hábitos o estrategia

Recuerda: las estadísticas son una herramienta, no un juicio. Úsalas para identificar patrones y ajustar tu enfoque.""",
        section: "statistics",
        order: 3,
      ),
      AppGuideModel(
        id: 4,
        title: "Mejores Prácticas",
        content: """**1. Comienza pequeño**
Es mejor ser consistente con hábitos pequeños que fallar con hábitos grandes. Aplica la regla de los 2 minutos.

**2. Sé honesto contigo mismo**
Marca "No realizado" cuando corresponda. La honestidad en el seguimiento es crucial para el progreso real.

**3. Enfócate en la constancia, no en la perfección**
El objetivo no es nunca fallar, sino aparecer consistentemente. Una semana con 6/7 días es mejor que una semana perfecta seguida de dos semanas sin registro.

**4. Revisa tus estadísticas regularmente**
Usa las estadísticas semanalmente para identificar patrones y ajustar tu estrategia.

**5. Mantén tus hábitos actualizados**
Elimina hábitos que ya no te sirven y agrega nuevos gradualmente. 3-5 hábitos activos es un buen número para empezar.

**6. Usa el contexto de días**
La cuadrícula te muestra el día de la semana. Usa esta información para identificar si ciertos días son más desafiantes.""",
        section: "best_practices",
        order: 4,
      ),
    ];
  }

  @override
  Future<List<AIRecommendationModel>> getFallbackRecommendations() async {
    final now = DateTime.now();
    return [
      AIRecommendationModel(
        id: "fallback_1",
        content: "Recuerda que los hábitos pequeños y consistentes superan a los grandes y esporádicos. Si has fallado algunos días, simplemente vuelve a empezar mañana. Lo importante es la tendencia general, no la perfección absoluta.",
        timestamp: now,
        type: RecommendationType.motivation,
        isFromAI: false,
      ),
      AIRecommendationModel(
        id: "fallback_2",
        content: "Identifica qué está funcionando bien en tus hábitos actuales y trata de aplicar esas mismas estrategias a los hábitos que te cuestan más trabajo. A menudo, el éxito en un área puede transferirse a otras.",
        timestamp: now,
        type: RecommendationType.improvement,
        isFromAI: false,
      ),
      AIRecommendationModel(
        id: "fallback_3",
        content: "¡Excelente progreso! Mantener una racha es un logro significativo. Para consolidar estos hábitos, considera agregar una recompensa pequeña después de completar tu rutina diaria. Esto refuerza el ciclo positivo.",
        timestamp: now,
        type: RecommendationType.streak,
        isFromAI: false,
      ),
      AIRecommendationModel(
        id: "fallback_4",
        content: "No te desanimes por romper una racha. El valor real está en volver a empezar rápidamente. Reflexiona sobre qué causó la interrupción y ajusta tu entorno o rutina para hacer el hábito más fácil mañana.",
        timestamp: now,
        type: RecommendationType.recovery,
        isFromAI: false,
      ),
      AIRecommendationModel(
        id: "fallback_5",
        content: "Considera revisar tus hábitos actuales. ¿Siguen siendo relevantes para tus objetivos? A veces es mejor enfocarse en 2-3 hábitos importantes que intentar mantener muchos a medias. La calidad supera a la cantidad.",
        timestamp: now,
        type: RecommendationType.general,
        isFromAI: false,
      ),
    ];
  }
}