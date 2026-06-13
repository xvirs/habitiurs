# Guía de publicación — Habitiurs

Pasos manuales que quedan para publicar. Hazlos en orden. Cada fase es
independiente; puedes parar y retomar.

**Datos de tu proyecto** (para copiar/pegar):
- Paquete / bundle ID: `com.habitiurs.app`
- Proyecto Firebase: `habitiurs` (número `819697521102`)
- App Android: `1:819697521102:android:5de8a675de7be642551b9f`
- App iOS: `1:819697521102:ios:ce4ed0eae806329e551b9f`
- Repo: https://github.com/xvirs/habitiurs

---

## FASE 0 — Backup del keystore (HAZLO YA, 2 min)

Si pierdes el keystore **no podrás volver a actualizar la app nunca**. Copia
estos dos archivos a un lugar seguro (Drive cifrado, gestor de contraseñas):

```
android/app/habitiurs-release.jks
android/key.properties
```

> No están en git (a propósito). Si formateas la máquina sin backup, la app muere.

---

## FASE 1 — Documentos legales online (5 min)

Las stores exigen una URL pública de política de privacidad. Ya están escritos
en `docs/`; solo falta activarlos con GitHub Pages.

1. Abre: https://github.com/xvirs/habitiurs/settings/pages
2. En **"Source"** elige **Deploy from a branch**.
3. Branch: `main` (o la que publiques) · carpeta: **`/docs`** · Save.
4. Espera 1-2 min. Verifica que cargan:
   - https://xvirs.github.io/habitiurs/privacidad.html
   - https://xvirs.github.io/habitiurs/terminos.html

> Estas URLs ya están enlazadas dentro de la app (Configuración → Legal) y son
> las que pondrás en las fichas de Play y App Store.
> ⚠️ Los `docs/` se commitearon en la rama `feature/delete-habits`. Para que
> Pages los sirva, mergea esa rama a `main` (o configura Pages sobre esa rama).

---

## FASE 2 — Activar la IA (Firebase, 10 min)

Sin esto la IA cae siempre al modo offline (la app funciona, pero sin Gemini).

### 2.1 Habilitar Firebase AI Logic
1. Abre: https://console.firebase.google.com/project/habitiurs/genai
2. Activa **Firebase AI Logic** y elige el proveedor **Gemini Developer API**
   (funciona en plan gratuito Spark).

### 2.2 Habilitar y configurar App Check
1. Habilita la API: https://console.developers.google.com/apis/api/firebaseappcheck.googleapis.com/overview?project=819697521102 → botón **Enable**.
2. Abre App Check: https://console.firebase.google.com/project/habitiurs/appcheck
3. Pestaña **Apps** → app Android `com.habitiurs.app` → **Play Integrity** → registrar.
4. (iOS, cuando lo trabajes) misma pantalla → app iOS → **App Attest**.

### 2.3 Registrar el token de debug (para probar en tu teléfono)
El token cambia en cada instalación de debug. Para obtener el actual:

```bash
flutter run -d <tu-dispositivo> --debug
# En los logs busca la línea:  "Enter this debug secret ... : XXXXXXXX-...."
```

Copia ese código y pégalo en: App Check → app Android → menú **⋮** →
**Manage debug tokens** → Add.

### 2.4 (Opcional pero recomendado) Forzar App Check
Cuando confirmes que la IA responde en tu teléfono, ve a App Check → pestaña
**APIs** → **Firebase AI Logic** → **Enforce**. Hasta entonces, déjalo en
"monitor" para no bloquearte.

### 2.5 Revocar la API key vieja de Gemini
La key que estaba en el `.env` puede haber quedado en APKs viejos. Bórrala:
1. Abre: https://aistudio.google.com/app/apikey
2. Elimina la key antigua de Gemini (ya no se usa).

---

## FASE 3 — Publicar en Google Play (1-2 h la primera vez)

1. **Cuenta** (pago único 25 USD): https://play.google.com/console/signup
2. **Crear app**: Play Console → Create app · nombre **Habitiurs** · idioma
   español · App · Gratis.
3. **Generar el AAB de subida** (ya verificado que compila):
   ```bash
   flutter build appbundle --release
   # Sale en: build/app/outputs/bundle/release/app-release.aab
   ```
4. **Ficha de la app** (Store listing): descripción, icono 512×512, capturas
   (mín. 2 de teléfono), gráfico destacado 1024×500.
5. **Política de privacidad**: pega la URL de la Fase 1.
6. **Data safety** (Seguridad de los datos): declara que recopilas correo
   (auth), nombre/foto (Google), y "actividad en la app" (hábitos); que se
   cifran en tránsito; y que el usuario **puede solicitar su eliminación**
   (lo cumple el botón Eliminar cuenta).
7. **Content rating**: completa el cuestionario (apto para todos).
8. Sube el AAB en **Testing → Internal testing** primero (te lo apruebas a ti
   mismo), pruébalo, y luego promociona a **Production**.

> Google firma la app por ti (Play App Signing). Tu keystore es la "upload key";
> guárdala igual (Fase 0).

---

## FASE 4 — Publicar en App Store (requiere más trabajo)

Esto lleva más porque falta una funcionalidad y trámites de Apple:

1. **Cuenta Apple Developer** (99 USD/año): https://developer.apple.com/account
2. **Sign in with Apple** — Apple **obliga** a ofrecerlo si ya ofreces login con
   Google (guideline 4.8). Es desarrollo pendiente, no solo configuración.
   👉 Cuando llegues acá, pídemelo y lo implemento.
3. **App Attest**: en Xcode, target Runner → Signing & Capabilities → **+ App
   Attest**. Y registrar el provider en App Check (Fase 2.2, iOS).
4. **Crear la ficha** en App Store Connect (reserva el nombre "Habitiurs" cuanto
   antes): https://appstoreconnect.apple.com
5. **Etiquetas de privacidad** (App Privacy): equivalente al Data Safety de Play.
6. Build con Xcode (necesitas un Mac, ya lo tienes) y subir vía **Transporter**
   o Xcode → Archive.

---

## Orden recomendado

1. **Fase 0** (backup) — ahora mismo.
2. **Fase 1 + Fase 2** — y prueba en tu teléfono que la IA responde de verdad.
3. **Fase 3** (Play) — puedes publicar en Android esta semana.
4. **Fase 4** (App Store) — cuando quieras; avísame para el Sign in with Apple.
