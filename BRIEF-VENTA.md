# BRIEF DE VENTA — Habitiurs

**Una frase:** App móvil (iOS/Android) de seguimiento de hábitos con asistente de IA integrado que analiza tu progreso y te recomienda cómo sostener tus hábitos, para gente de habla hispana que quiere construir rutinas y las abandona.

## 1. Qué hace (y qué NO hace todavía)

**Funciona hoy (confirmado en código, no en promesas):**
- CRUD completo de hábitos con evaluación diaria por estados, grilla semanal y archivado.
- Estadísticas: resumen del mes en curso, gráfico histórico y listado anual.
- **Asistente de IA** (Gemini 2.5 Flash vía Firebase AI Logic + App Check): recomendaciones basadas en el contexto real de tus hábitos, contenido educativo y guía de la app, con fallback offline (contenido estático) si no hay red.
- Login con Google, Apple y Firebase Auth; **sincronización a Firestore** (backup multi-dispositivo). La app es local-first (sqflite): funciona sin cuenta.
- Notificaciones locales programadas (alarmas inexactas — decisión deliberada para evitar la declaración de permisos de Play).
- **Widgets de pantalla de inicio en iOS (SwiftUI + App Groups) y Android (RemoteViews).**
- Onboarding, ajustes con eliminación de cuenta, páginas legales publicadas.

**No existe / a medio hacer:**
- **Monetización: cero.** No hay in_app_purchase, RevenueCat, paywall ni pantalla de pricing.
- **Analytics de producto: cero.** No hay firebase_analytics ni ningún tracking de eventos → hoy no se puede medir activación, retención ni funnel.
- Un solo idioma (español). Sin inglés.
- 1 solo archivo de test (cobertura mínima). README es el boilerplate de Flutter (sin doc de producto).

## 2. Estado actual

- **Plataforma(s):** iOS + Android (Flutter, base de código única).
- **¿Publicado / en vivo?:** **NO público.** Play Store: solo prueba interna/cerrada (verificado vía API oficial el 2026-07-06: track `internal` v3 y `alpha` v2 completados, track `production` **vacío**). iOS: build 1.1.1+6 subido con éxito a App Store Connect/TestFlight (workflow verde del 2026-07-07); estado de revisión/publicación en App Store: NO ENCONTRADO en el repo.
- **¿Gratis o pago hoy?:** Gratis (no existe forma de cobrar).
- **¿Funciona end-to-end hoy?:** Sí como producto gratuito: compila, CI verde, deploy automatizado a ambas stores con un comando (`/release`). La IA depende de Firebase AI Logic habilitado en la consola (la guía interna lo listaba como paso manual; el código está integrado y migrado a `firebase_ai`).
- **Stack técnico principal:** Flutter 3.35.7 / Dart ^3.7, BLoC, sqflite (local-first), Firebase (Auth, Firestore, AI Logic/Gemini 2.5 Flash, App Check), GitHub Actions con CI/CD completo a Play + App Store.
- **Dependencias externas con costo:** Firebase plan Blaze (Firestore + llamadas a Gemini: variable por uso), Apple Developer US$99/año, Play US$25 único. Sin servidor propio; landing/legales en GitHub Pages (gratis).

## 3. Usuario y mercado

- **¿Quién lo usa o pagaría?:** consumidor final hispanohablante, 18-45, interesado en productividad/bienestar, que ya intentó sostener hábitos y falló (gym, lectura, meditación, estudio).
- **B2C o B2B:** B2C puro, compra por impulso/motivación.
- **Rubro(s):** self-improvement, productividad, salud/bienestar.
- **Dolor que resuelve y urgencia:** **bajo-medio.** "Abandono mis hábitos" es un dolor universal pero no urgente ni caro: la alternativa gratis (no hacer nada, notas, otro tracker gratuito) siempre está disponible. El mercado es enorme pero el dolor no fuerza la compra; la compra es aspiracional (pico en enero y lunes).

## 4. Propuesta de valor y diferenciador

Frente a la alternativa real (papel/notas/no hacer nada o un tracker gratuito tipo Loop): Habitiurs suma **un coach de IA que lee tu historial real y te dice qué ajustar**, algo que los trackers puros no hacen, más widgets en la pantalla de inicio (fricción cero para marcar) y funcionamiento offline con sync opcional. Frente a los competidores pagos (Habitify, Fabulous), el ángulo defendible hoy es: **IA contextual + español nativo + gratis**. Honestidad: la diferenciación es moderada — "habit tracker con IA" ya existe en inglés; la ventaja real es ejecución en español y costo cero de entrada.

## 5. Feedback real recibido

NO ENCONTRADO. No hay registro de feedback de usuarios ni testers en el repo (la prueba interna de Play parece limitada al propio desarrollador).

## 6. Monetización posible

- **Modelo natural: freemium + suscripción**, con la IA como feature premium (es lo único con costo marginal por uso, lo que alinea costo e ingreso). Tracker básico gratis, coach IA + estadísticas avanzadas pagas.
- **Precio sugerido:** US$2,99-3,99/mes o US$19,99-24,99/año — por debajo de Habitify/Fabulous para el mercado hispano, por encima del piso psicológico de "app de $1". (Referencias de mercado por conocimiento general, no del repo.)
- **¿Recurrente o one-shot?:** recurrente (suscripción) — es la norma de la categoría y la IA lo justifica.
- **¿Ya puede cobrar?: NO.** Falta integrar compras in-app (StoreKit/Play Billing o RevenueCat), paywall y gating de features. Es el bloqueante #1 para vender.

## 7. Unit economics (inferido)

- **Costo por usuario/mes:** muy bajo. Gemini 2.5 Flash cuesta fracciones de centavo por consulta; un usuario activo con 1-3 consultas/día ≈ US$0,05-0,20/mes (estimación). Firestore free tier cubre miles de usuarios livianos. Costos fijos: US$99/año Apple.
- **Margen bruto estimado:** >90% sobre una suscripción de ~US$3/mes (descontando ~15-30% de comisión de stores, sigue >60-80% neto).
- **LTV estimado:** no calculable — no hay datos de retención (no hay analytics ni usuarios). En la categoría, la retención a 3 meses suele ser baja; asumir LTV de 3-6 meses de suscripción hasta tener datos.
- **Riesgo de costo:** si la IA queda gratis sin límite, el costo crece con usuarios que no pagan — hace falta rate-limit o gating antes de escalar adquisición.

## 8. Competencia y precios de mercado

El repo no contiene análisis de competencia (NO ENCONTRADO en el repo). Por conocimiento general del mercado: Habitify (~US$5/mes o ~US$35/año), Streaks (iOS, ~US$5 pago único), Fabulous (~US$40/año), Loop Habit Tracker (Android, gratis/open source), Habitica (gamificado, freemium). "Habit tracker + AI coach" ya existe en inglés; en español nativo la oferta es más floja — ahí hay hueco.

## 9. Activos de venta que YA existen

- **Ícono de app:** `icon.png` (raíz del repo).
- **Página pública mínima:** https://xvirs.github.io/habitiurs/ (`docs/index.html`) — es un índice de páginas legales, NO una landing de venta.
- **Legales publicados** (requisito de stores, ya resuelto): privacidad, términos y eliminación de cuenta (`docs/*.html`, en vivo vía GitHub Pages).
- **Fichas creadas en ambas consolas** (Play Console y App Store Connect) con el pipeline de publicación automatizado y funcionando (workflows verdes del 2026-07-07).
- **Widget iOS/Android** como material demostrable en capturas.
- Screenshots de store, video/demo, dominio propio, testimonios: **NO ENCONTRADO**.

## 10. Qué falta para poder VENDERLO

**Técnico:**
1. Paywall + compras in-app (RevenueCat o nativo) — sin esto no hay negocio.
2. Analytics de eventos (activación, retención, conversión) — sin esto Meta Ads es volar a ciegas.
3. Pasar Play de prueba cerrada a **producción** (cuenta personal: requiere 12 testers/14 días + solicitar acceso) y confirmar/enviar la revisión de iOS en App Store Connect.
4. Localización a inglés si se quiere escalar más allá del mercado hispano.
5. Rate-limit de la IA para usuarios free.

**Comercial:**
1. No hay landing de venta ni dominio propio.
2. No hay pricing definido ni copy de venta.
3. No hay screenshots/video para las fichas de store (ASO desde cero).
4. No hay canal de feedback ni base de usuarios inicial.

## 11. Riesgos y limitaciones honestas

- **Categoría saturada con dolor de baja urgencia:** CAC en Meta Ads puede superar fácilmente un LTV de pocos dólares; los habit trackers viven de volumen y retención, y la retención típica de la categoría es mala.
- **Sin datos de nada:** cero usuarios reales medidos, cero feedback, cero analytics → cualquier proyección de conversión es especulativa.
- **Costo variable sin ingreso:** IA gratis e ilimitada + campaña de adquisición = factura de Firebase creciendo sin revenue que la compense.
- **Mercado hispano paga menos** por suscripciones de bienestar que el anglo; el precio techo es bajo.
- **Un solo idioma** limita el mercado direccionable; traducir es barato pero el ASO/soporte en inglés compite contra jugadores fuertes.
- **Deuda de calidad:** 1 test; regresiones posibles al agregar paywall. Dependencia total de Firebase (lock-in).
- **Aún no está públicamente disponible:** hoy no se puede mandar tráfico a ningún link de descarga público.

## 12. Fuentes leídas

- `README.md` (boilerplate), `GUIA_PUBLICACION.md`, `pubspec.yaml` (v1.1.1+6, dependencias)
- Estructura completa de `lib/` (135 archivos Dart): `features/{habits,statistics,ai_assistant,settings,auth,onboarding,app}`, `core/{ai,sync,notifications,home_widget,auth,database}`
- `lib/core/ai/services/gemini_service.dart` (modelo `gemini-2.5-flash`)
- `docs/{index,privacidad,terminos,eliminar-cuenta}.html` + estado de GitHub Pages (API: built, https://xvirs.github.io/habitiurs/)
- `android/app/src/main/AndroidManifest.xml` (permisos), `ios/HabitiursWidget/` (widget SwiftUI)
- `.github/workflows/{ci,release-android,release-ios}.yml` + `gh run list` (releases v1.1.1 verdes, 2026-07-07)
- `test/` (1 archivo), `lib/l10n/` (solo `app_es.arb`)
- API Google Play Developer (tracks reales de `com.habitiurs.app`, consulta del 2026-07-06) y API App Store Connect (app registrada en el team)
