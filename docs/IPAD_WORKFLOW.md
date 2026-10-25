# Alternativa desde iPad: Roblox Open Cloud (beta)

Esta ruta permite actualizar el código de un Script existente sin ejecutar Roblox Studio, usando la API beta de Engine Instances de Roblox y una herramienta local como Scriptable para iPad. Está separada del flujo normal de Rojo.

## Antes de usarla
- El lugar debe tener la edición colaborativa habilitada.
- Crea una API key en Creator Dashboard para el sistema `universe-place-instances`, con permisos de lectura y escritura limitados a Robloxia2009.
- No compartas la API key en ChatGPT, GitHub, capturas o mensajes. El script de Scriptable la pide al ejecutarse y no la escribe en el repositorio.
- Roblox indica que la API está en beta, solo permite leer/actualizar Script, LocalScript y ModuleScript, no puede actualizar scripts que estén abiertos en Studio, y limita los cuerpos de solicitud a 200 KB.
- Este método actualiza el Source de un Script existente. No crea instancias nuevas ni sustituye una subida binaria completa de `.rbxl`; puede que aún necesites comprobar/guardar/publicar el lugar según el estado de colaboración.

## Archivos
- `tools/MapBootstrap.OpenCloud.lua`: versión de un solo archivo, con RPExpansion integrado dentro de MapBootstrap y notificaciones creadas por el servidor. Está generada desde los módulos del repositorio.
- `tools/Update-Robloxia2009-From-iPad.js`: script para la app Scriptable. Busca `ServerScriptService/Robloxia/MapBootstrap` usando la API, guarda una copia local del Source actual y luego pide confirmación antes de actualizarlo.

## Uso general
1. Instala/abre Scriptable en el iPad y crea un script nuevo.
2. Copia el contenido de `Update-Robloxia2009-From-iPad.js` desde GitHub y ejecútalo.
3. Introduce la API key en el diálogo de la app; no la envíes a nadie.
4. Confirma la actualización solo si el script ha encontrado `ServerScriptService/Robloxia/MapBootstrap` y guardó el respaldo.
5. Si la API rechaza la petición por falta de colaboración/permisos o por una restricción beta, cancela y usa el flujo de Rojo/Studio más adelante. No desactives la seguridad de la cuenta para forzar la operación.

La ruta oficial y sus limitaciones están documentadas en:
- https://create.roblox.com/docs/cloud/guides/instance
- https://create.roblox.com/docs/cloud/guides/usage-place-publishing

## Regeneración del bundle
Cuando cambie `RPExpansion.lua` o `MapBootstrap.server.lua`, vuelve a generar el bundle para que refleje los últimos cambios. No edites el bundle a mano como fuente principal.
