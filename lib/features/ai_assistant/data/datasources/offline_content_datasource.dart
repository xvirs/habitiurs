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
    final now = DateTime.now();
    return [
      EducationalContentModel(
        id: 1,
        title: 'La regla de los 2 minutos',
        content: '''
Cuando empieces un hábito nuevo, que hacerlo te tome menos de dos minutos.

• "Leer antes de dormir" → "leer una página".
• "Entrenar 30 minutos" → "ponerme las zapatillas".
• "Meditar 10 minutos" → "respirar hondo tres veces".

La idea no es hacer poco para siempre, sino **dominar el arte de aparecer**. Primero volvés automático el gesto de empezar; después, subir la exigencia es fácil.

En Habitiurs esto se traduce en definir hábitos chicos y marcarlos todos los días. Es mejor un 6/7 constante que una semana perfecta seguida de dos en blanco.''',
        category: 'Formación de hábitos',
        readTimeMinutes: 2,
        createdAt: now,
        isLocal: true,
      ),
      EducationalContentModel(
        id: 2,
        title: 'Apilá hábitos nuevos sobre viejos',
        content: '''
En vez de atar un hábito a una hora, atalo a algo que **ya hacés todos los días**.

La fórmula: "Después de [HÁBITO ACTUAL], haré [HÁBITO NUEVO]".

Ejemplos:
• Después de servirme el café, medito un minuto.
• Después de dejar los zapatos del trabajo, me pongo la ropa de entrenar.
• Después de cerrar la laptop, anoto una cosa que agradezco.

Funciona mejor cuando ambos hábitos tienen la misma frecuencia. El hábito viejo es el recordatorio del nuevo, sin depender de tu memoria.''',
        category: 'Formación de hábitos',
        readTimeMinutes: 3,
        createdAt: now,
        isLocal: true,
      ),
      EducationalContentModel(
        id: 3,
        title: 'Diseñá tu entorno',
        content: '''
Tu entorno pesa más que tu fuerza de voluntad. Hacé **obvias** las señales de los hábitos buenos y **invisibles** las de los malos.

**Para los buenos:**
• Fruta a la vista, botella de agua en el escritorio.
• El libro sobre la almohada, la ropa de gym lista la noche anterior.

**Para los malos:**
• El control remoto guardado, el teléfono en otra habitación.
• Nada de comida chatarra a la vista.

Es más fácil cambiar el ambiente una vez que pelear con la tentación todos los días.''',
        category: 'Formación de hábitos',
        readTimeMinutes: 2,
        createdAt: now,
        isLocal: true,
      ),
      EducationalContentModel(
        id: 4,
        title: 'Los hábitos construyen identidad',
        content: '''
El cambio más profundo no es de resultado, es de **identidad**. Cada acción es un voto por la persona que querés ser.

En vez de enfocarte en la meta, enfocate en quién querés convertirte:
• "Quiero leer más" → "Soy una persona que lee".
• "Quiero entrenar" → "Soy una persona que se cuida".

Cada vez que cumplís un hábito, sumás evidencia de esa identidad. Por eso en Habitiurs la racha importa: no es un puntaje, es la prueba acumulada de quién estás siendo.''',
        category: 'Mentalidad',
        readTimeMinutes: 3,
        createdAt: now,
        isLocal: true,
      ),
      EducationalContentModel(
        id: 5,
        title: 'Nunca falles dos veces seguidas',
        content: '''
Fallar un día no rompe nada: lo que rompe el hábito es fallar **dos veces seguidas**. Un traspié es un accidente; dos, el comienzo de un patrón.

La regla es simple: si ayer no pudiste, hoy es innegociable. No hace falta compensar ni hacer el doble, solo volver.

En la pestaña Hábitos, marcá "Saltado" con honestidad cuando no lo hiciste; y en el mapa de Constancia (Estadísticas) vas a ver que un hueco aislado casi no se nota, pero dos juntos sí.''',
        category: 'Constancia',
        readTimeMinutes: 2,
        createdAt: now,
        isLocal: true,
      ),
      EducationalContentModel(
        id: 6,
        title: 'Hábitos vs. objetivos',
        content: '''
Los objetivos marcan una dirección; los **hábitos** son el sistema que te lleva ahí. Ganás no cuando alcanzás la meta, sino cuando sostenés el sistema.

• Objetivo: "correr una maratón". Hábito: "salir a correr".
• Objetivo: "aprender inglés". Hábito: "estudiar 10 minutos".

Problema de vivir para la meta: sos "un fracaso" hasta cumplirla y quedás a la deriva después. Con un buen hábito, cada día ya es un pequeño éxito.

Por eso Habitiurs no te pide metas: te pide aparecer. Definí la acción diaria y dejá que el resultado llegue solo.''',
        category: 'Mentalidad',
        readTimeMinutes: 3,
        createdAt: now,
        isLocal: true,
      ),
      EducationalContentModel(
        id: 7,
        title: 'Menos hábitos, más constancia',
        content: '''
Arrancar con diez hábitos a la vez es la forma más rápida de abandonar. La energía se reparte y ninguno se afianza.

Mantené **3 a 5 hábitos activos**. Cuando uno se vuelve automático (deja de costarte pensarlo), recién ahí sumás otro.

Si el Asistente IA te dice que estás sobrecargado, hacele caso: bajá la cantidad. La calidad de la constancia le gana siempre a la cantidad de intenciones.''',
        category: 'Constancia',
        readTimeMinutes: 2,
        createdAt: now,
        isLocal: true,
      ),
    ];
  }

  @override
  Future<List<AppGuideModel>> getAppGuides() async {
    return [
      AppGuideModel(
        id: 1,
        title: 'Bienvenido a Habitiurs',
        content: '''
Habitiurs es tu compañero para construir hábitos duraderos, de forma simple y sin ruido.

**Su filosofía:**
• Simplicidad sobre complejidad.
• Constancia sobre perfección.
• Progreso sobre resultados inmediatos.
• Datos claros para decidir mejor.

**Las tres pestañas de abajo:**
• **Estadísticas** — cómo venís en el tiempo.
• **Hábitos** — tu día a día (es la pantalla central).
• **Misiones** — tareas de una sola vez (trámites, turnos).

El **Asistente IA** y el resto de accesos viven en el menú lateral (☰, arriba a la izquierda).''',
        section: 'overview',
        order: 1,
      ),
      AppGuideModel(
        id: 2,
        title: 'La pestaña Hábitos',
        content: '''
Es el corazón de la app. Tiene dos partes:

**1) Tablero de vista semanal (arriba, siempre visible):**
• Cada fila es un hábito (con su ícono a la izquierda); cada columna, un día.
• Verde = completado, rojo = saltado, gris = pendiente.
• **Tocá** la celda de HOY para cambiar el estado.
• **Mantené presionada** una celda de un día pasado para corregirlo.

**2) Hábitos de hoy (abajo, scrollea):**
• Muestra los hábitos que tocan hoy y tu progreso (ej. 2/3).
• **Deslizá a la derecha** para marcar hecho.
• **Deslizá a la izquierda** para eliminar.
• **Mantené presionado** para editar.
• El 🔥 al lado de un hábito indica los días de racha que llevás.

Con el botón **+** agregás un hábito nuevo.''',
        section: 'habits',
        order: 2,
      ),
      AppGuideModel(
        id: 3,
        title: 'Crear un buen hábito (con IA)',
        content: '''
Al crear un hábito podés usar la **evaluación con IA** para chequear que sea efectivo. Verifica 3 criterios:

1. ¿Es una **acción** concreta? (no un estado de ánimo ni una meta abstracta)
2. ¿Se puede **repetir** todos los días? (no depende de terceros)
3. ¿Es **medible** sin dudas? (sabés si lo cumpliste o no)

**Buenos:**
✅ "Leer 10 páginas" · ✅ "Meditar 5 minutos" · ✅ "Un vaso de agua al despertar"

**Malos:**
❌ "Ser feliz" (estado, no acción) · ❌ "Ganar la lotería" (no depende de vos)

La IA **nunca** te va a fijar un horario ("a la mañana"). Habitiurs se enfoca en que lo HAGAS cada día, no en cuándo.''',
        section: 'habits',
        order: 3,
      ),
      AppGuideModel(
        id: 4,
        title: 'La pestaña Misiones',
        content: '''
Las misiones son **tareas de una sola vez**: un trámite, un turno médico, una llamada. No son recurrentes como los hábitos.

**Cómo usarlas:**
• Tocá **＋ Nueva** (arriba) para crear una, con nota y fecha límite opcional.
• **Deslizá a la derecha** para completarla; **a la izquierda** para borrarla.
• **Mantené presionada** para editarla.

**Colores por urgencia:**
🔴 Vencida · 🔵 Hoy · 🟠 Próxima · 🟢 Sin fecha.

Al completar, la misión pasa a **Hechas hoy** (queda a la vista, tachada). Las de días anteriores se guardan en **Completadas anteriores**, abajo. Si una misión tiene fecha, te llega un **recordatorio** ese día.''',
        section: 'missions',
        order: 4,
      ),
      AppGuideModel(
        id: 5,
        title: 'La pestaña Estadísticas',
        content: '''
Te da una lectura objetiva de tu constancia, sin dramatismo.

**Números clave (arriba):**
🔥 Racha actual · 🏆 Mejor racha · % de este mes · total de completados.

**Mapa de Constancia:**
Una cuadrícula estilo GitHub: cada celda es un día y se pinta más verde cuanto más cumpliste. De un vistazo ves tus rachas y tus huecos — la meta es "no cortar la cadena".

**Tendencia por mes** y **mejor/peor día de la semana** te ayudan a detectar patrones (¿se te complican los fines de semana?).

Es una herramienta, no un juicio: usala para ajustar, no para castigarte.''',
        section: 'statistics',
        order: 5,
      ),
      AppGuideModel(
        id: 6,
        title: 'Widgets en tu pantalla de inicio',
        content: '''
Habitiurs trae widgets para que veas (y marques) tus hábitos sin abrir la app. Para agregarlos: mantené presionada la pantalla de inicio → Widgets → buscá "Habitiurs".

**Disponibles:**
• **Hoy** — tus hábitos del día. En la versión lista podés **marcarlos tocándolos**, sin abrir la app.
• **Racha** — tu racha actual; se pone en alerta si el día quedó incompleto.
• **Constancia** — el mapa de calor, siempre a la vista.
• **Misiones** — tus pendientes más urgentes.

Se actualizan solos cuando marcás hábitos o misiones.''',
        section: 'widgets',
        order: 6,
      ),
      AppGuideModel(
        id: 7,
        title: 'El Asistente IA',
        content: '''
Analiza tus **datos reales** y te da una recomendación concreta y accionable. Lo abrís desde el menú lateral (☰).

**Qué mira:** tus hábitos, tu cumplimiento promedio, tu racha y con cuáles te está costando.

**Qué te devuelve:**
**Estado:** una lectura honesta de cómo venís.
**💡 Acción clave:** UNA cosa para hacer hoy.
**⚠️ Alerta:** (si aplica) hábitos que están fallando y por qué.

**Niveles:** 🔥 Excelente (≥80%) · 💪 Buen ritmo (60–79%) · 📈 En desarrollo (40–59%) · ⚡ Necesita atención (<40%).

Es directo y honesto: si vas mal, te lo dice. No hay motivación vacía, solo feedback útil. **Deslizá hacia abajo** para regenerarlo.''',
        section: 'ai_features',
        order: 7,
      ),
      AppGuideModel(
        id: 8,
        title: 'Menú lateral y ajustes',
        content: '''
El menú lateral (☰, arriba a la izquierda) es tu centro de control:

**Accesos:**
• **Asistente IA** — tus recomendaciones.
• **Hábitos archivados** — los que guardaste sin borrar (conservan su historial).

**Ajustes rápidos:**
• **Recordatorios** — activá/desactivá el aviso diario y elegí la hora.

Más abajo, fijos: **Configuración** (legal, cuenta, versión) y **Cerrar sesión**. Tus datos se sincronizan en la nube al iniciar sesión con Google.''',
        section: 'navigation',
        order: 8,
      ),
      AppGuideModel(
        id: 9,
        title: 'Corregir y eliminar',
        content: '''
**Corregir un día pasado:** a veces cumplís un hábito y olvidás marcarlo. En el tablero semanal, **mantené presionada** la celda del día pasado y elegí el estado correcto. El día de HOY se cambia con un toque simple. (No es para hacer trampa: la honestidad es lo que hace que el progreso sea real.)

**Eliminar un hábito:** deslizalo a la izquierda en "Hábitos de hoy". Ojo: se borra su **historial completo**. Si solo querés pausarlo, mejor archivalo (desde su edición) — así conservás los datos y podés recuperarlo desde "Hábitos archivados".

**Deshacer:** al borrar una misión aparece un "Deshacer" por unos segundos.''',
        section: 'features',
        order: 9,
      ),
      AppGuideModel(
        id: 10,
        title: 'Buenas prácticas',
        content: '''
**1. Empezá chico.** Mejor ser constante con algo mínimo que fallar con algo grande (regla de los 2 minutos).

**2. Validá con la IA.** Dejá que confirme que tu hábito es acción concreta, repetible y medible.

**3. Sé honesto.** Marcá "Saltado" cuando corresponda; el autoengaño arruina las estadísticas.

**4. Constancia, no perfección.** El objetivo no es nunca fallar, es aparecer seguido. Nunca falles dos veces seguidas.

**5. Mirá los patrones.** Usá Estadísticas para ver dónde se te complica y armá una estrategia para esos días.

**6. Mantené 3–5 hábitos.** Más hábitos, energía dispersa. La calidad supera a la cantidad.

**7. Escuchá al Asistente.** Si te dice que simplifiques, simplificá.''',
        section: 'best_practices',
        order: 10,
      ),
    ];
  }
}
