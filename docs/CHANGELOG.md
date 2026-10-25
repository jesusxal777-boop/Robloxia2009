# CHANGELOG — Robloxia 2009

## [0.1.0] — 2026-10-24
### Añadido
- Estructura completa de carpetas (Workspace + ServerScriptService)
- MapConfig con Asset IDs verificados y flags de seguridad
- MapBuilder modular: casa clásica, patio de construcción, plaza, roleplay district, obby, naturaleza, carteles
- Sistema de secretos + sótano único en una casa
- Transición ARG completa por código (reset + cambio de mundo)
- AssetRegistry con carga segura + fallback procedural
- Respaldos documentados
- Spawn seguro + checkpoints básicos de obby

### Notas
- Todo el mapa se genera por código si los assets fallan.
- El ARG se activa solo al pasar por la puerta del sótano de la casa "secreta".
- Sin interfaces complejas (el usuario se encarga de UI).

## [0.6.0] — 2026-10-24
### Corregido
- Spawn principal y comienzo del obby alineados con la baseplate.
- Happy Home importada posicionada por su bounding box en vez de quedar en el origen.
- Muebles con altura consistente y mejor distribución en casas.
- La casa secreta ahora tiene una abertura real en el suelo para el hatch y un paso abierto en la pared del sótano.
- Hatch y PC muestran prompts de proximidad compatibles con E y clic/toque.
- Edd se localiza por HumanoidRootPart/Head y su dialogo del mapa alternativo confirma el giro de la historia.



## 2026-10-24 — Interaction prompt visibility
- Explicitly enable Roblox ProximityPromptService and use the default Roblox prompt style for the hatch, PC, and Edd.
- Increase prompt range to 16 studs and remove the short hold delay for immediate E/click interaction.
- Add a clickable E prompt to pick up the sword when the stored asset is a Tool.
- Preserve the previous ARGSystem.lua at `backups/pre-interaction-fix-2026-10-24/ARGSystem.lua`.

## 2026-10-24 — Edd reveal spawn fix
- Spawn or relocate Edd into the blood map near the player after the code reveal, so he is visible where the final dialogue starts.
- Generate a simple blocky fallback NPC if no Edd model was placed in Workspace.
- Keep the basement message/blackout transition unchanged; only initialize Edd when the reveal map loads.
