// lib/features/ai_assistant/data/datasources/offline_content_datasource.dart
import '../models/app_guide_model.dart';
import '../models/educational_content_model.dart';

abstract class OfflineContentDatasource {
  Future<List<EducationalContentModel>> getEducationalContent();
  Future<List<AppGuideModel>> getAppGuides();
}

class OfflineContentDatasourceImpl implements OfflineContentDatasource {
  @override
  Future<List<EducationalContentModel>> getEducationalContent() async {
    return [
      EducationalContentModel(
        id: 1,
        title: "La Regla de los 2 Minutos",
        content:
            """James Clear propone que cuando estés comenzando un nuevo hábito, debería tomar menos de dos minutos realizarlo.

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
        content:
            """El apilamiento de hábitos es una forma especial de intención de implementación. En lugar de emparejar tu nuevo hábito con un tiempo y lugar particular, lo emparejas con un hábito actual.

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
        content:
            """Tu entorno físico influye enormemente en tus hábitos. Hacer que las señales de los hábitos buenos sean obvias en tu entorno es una forma poderosa de mantenerlos.

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
        content:
            """El cambio de comportamiento más profundo es el cambio de identidad. Cada acción es un voto por el tipo de persona que deseas convertirte.

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
        content:
            """Habitiurs es tu compañero para construir hábitos duraderos de manera simple y efectiva.

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
        content:
            """La cuadrícula semanal es el corazón de Habitiurs. Aquí es donde visualizas tu progreso de manera clara y motivadora.

**Cómo funciona:**
• Cada fila representa un hábito
• Cada columna representa un día de la semana
• Los números del lado izquierdo identifican cada hábito

**Estados posibles:**
🟢 Verde con ✓ = Completado
🔴 Rojo con ✗ = Saltado (decidiste no hacerlo)
⚪ Gris con • = Pendiente (aún no decidido)

**Interacciones:**
• **Tap en día actual:** Cambia el estado (Pendiente → Completado → Saltado → Pendiente)
• **Mantén presionado en días pasados:** Abre un modal para modificar el estado de ese día específico

**Nota:** Puedes modificar cualquier día pasado, útil si olvidaste marcar un hábito que sí completaste.

**Tip:** Usa la cuadrícula para identificar patrones. ¿Hay días específicos donde te cuesta más? ¿Ciertos hábitos son más difíciles que otros?""",
        section: "weekly_grid",
        order: 2,
      ),
      AppGuideModel(
        id: 3,
        title: "Interpretando tus Estadísticas",
        content:
            """Las estadísticas te dan una perspectiva objetiva de tu progreso a lo largo del tiempo.

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
        title: "Creando Hábitos con IA",
        content:
            """Al crear un nuevo hábito, puedes usar la **Evaluación con IA** para validar que tu hábito sea efectivo.

**¿Qué evalúa la IA?**
La IA verifica que tu hábito cumpla 3 criterios:
1. ¿Es una ACCIÓN específica? (no un estado mental o meta abstracta)
2. ¿Se puede REPETIR todos los días? (no depende de eventos externos)
3. ¿Es MEDIBLE sin ambigüedad? (sabes si lo completaste o no)

**Ejemplos de hábitos BUENOS:**
✅ "Leer 10 páginas"
✅ "Meditar 5 minutos"
✅ "Beber un vaso de agua al despertar"

**Ejemplos de hábitos MALOS:**
❌ "Ser feliz" → Es un estado emocional, no una acción
❌ "Conquistar el mundo" → Meta grandiosa, no acción diaria
❌ "Ganar la lotería" → No depende de ti

**Tip:** La IA NUNCA sugerirá horarios específicos (ej: "por la mañana"). Habitiurs se enfoca en que HAGAS el hábito cada día, sin importar CUÁNDO lo hagas.""",
        section: "ai_features",
        order: 4,
      ),
      AppGuideModel(
        id: 5,
        title: "Asistente de IA Personalizado",
        content:
            """El Asistente de IA analiza tus datos reales y te da recomendaciones específicas y accionables.

**¿Qué analiza?**
• Tus hábitos actuales
• Tu tasa de cumplimiento promedio
• Tu racha actual
• Hábitos con los que estás teniendo dificultades

**Formato de la recomendación:**
**[EMOJI] Estado:** Evaluación honesta de tu situación actual
**💡 Acción clave:** UNA cosa específica que puedes hacer HOY
**⚠️ Alerta:** (Si aplica) Hábitos problemáticos y por qué fallan

**Niveles de rendimiento:**
🔥 Excelente (≥80%): Mantén el momentum
💪 Buen ritmo (60-79%): Identifica patrones
📈 En desarrollo (40-59%): Enfócate en 1 hábito
⚡ Necesita atención (<40%): Simplifica radicalmente

**Nota:** El asistente es DIRECTO y HONESTO. Si vas mal, te lo dirá claramente. No encontrarás motivación vacía, solo feedback accionable.""",
        section: "ai_features",
        order: 5,
      ),
      AppGuideModel(
        id: 6,
        title: "Modificando Días Pasados",
        content:
            """A veces olvidas marcar un hábito que sí completaste. Habitiurs te permite corregir días pasados.

**Cómo modificar un día pasado:**
1. Ve a la cuadrícula semanal en la página principal
2. **Mantén presionado** sobre la casilla del día que quieres modificar
3. Se abrirá un modal con el nombre del hábito y la fecha
4. Selecciona el nuevo estado: **Completado** o **Saltado**
5. El cambio se guarda automáticamente

**Restricciones:**
• Solo puedes modificar días PASADOS (no el día actual ni futuros)
• El día actual se modifica con un tap simple, no con mantener presionado

**Caso de uso común:**
"Ayer leí 10 páginas pero olvidé marcarlo. Ahora puedo mantener presionado sobre ese día y marcarlo como completado."

**Tip:** Esto NO es para hacer trampa. La honestidad en el seguimiento es clave para el progreso real.""",
        section: "features",
        order: 6,
      ),
      AppGuideModel(
        id: 7,
        title: "Eliminando Hábitos",
        content:
            """Si un hábito ya no te sirve o quieres reemplazarlo, puedes eliminarlo fácilmente.

**Cómo eliminar un hábito:**
1. Ve a la cuadrícula semanal
2. **Mantén presionado sobre el número** del hábito (lado izquierdo)
3. Aparecerá un diálogo de confirmación
4. Confirma la eliminación

**⚠️ Advertencia:**
Esta acción es IRREVERSIBLE. Se eliminarán:
• El hábito
• Todo su historial de registros
• Sus estadísticas asociadas

**Alternativa:**
Si solo quieres "pausar" un hábito temporalmente, considera simplemente no marcarlo en lugar de eliminarlo. Así conservas tu historial.

**Mejor práctica:**
Mantén solo 3-5 hábitos activos. La calidad supera la cantidad.""",
        section: "features",
        order: 7,
      ),
      AppGuideModel(
        id: 8,
        title: "Mejores Prácticas",
        content: """**1. Comienza pequeño**
Es mejor ser consistente con hábitos pequeños que fallar con hábitos grandes. Aplica la regla de los 2 minutos.

**2. Usa la evaluación de IA al crear hábitos**
Deja que la IA valide que tu hábito sea una acción concreta, repetible y medible.

**3. Sé honesto contigo mismo**
Marca "Saltado" cuando corresponda. La honestidad en el seguimiento es crucial para el progreso real.

**4. Revisa el Asistente de IA regularmente**
Usa sus recomendaciones para ajustar tu estrategia. Si te dice que estás sobrecargado, escucha.

**5. Enfócate en la constancia, no en la perfección**
El objetivo no es nunca fallar, sino aparecer consistentemente. Una semana con 6/7 días es mejor que una semana perfecta seguida de dos semanas sin registro.

**6. Usa las estadísticas para identificar patrones**
¿Siempre fallas los fines de semana? Prepara una estrategia específica para esos días.

**7. Mantén 3-5 hábitos activos**
Más hábitos = energía dispersa. La calidad supera la cantidad.

**8. Corrige errores del pasado**
Si olvidaste marcar un hábito completado, usa el mantener presionado para corregirlo.""",
        section: "best_practices",
        order: 8,
      ),
    ];
  }
}
