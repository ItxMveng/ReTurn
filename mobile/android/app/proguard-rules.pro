# ── ML Kit — reconnaissance de texte ─────────────────────────────────────────
# Le plugin google_mlkit_text_recognition référence des recognizers de langues
# optionnelles (chinois, japonais, coréen, devanagari) que l'on n'embarque PAS
# (on n'utilise que le latin). R8 échoue sur ces classes absentes → on lui dit
# de les ignorer. C'est sans effet à l'exécution : ces langues ne sont pas utilisées.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-keep class com.google.mlkit.** { *; }

# ── Flutter / Firebase — sécurité anti-stripping (code appelé par réflexion) ──
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
