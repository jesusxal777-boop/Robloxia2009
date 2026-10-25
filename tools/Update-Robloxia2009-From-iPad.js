// Robloxia2009 — iPad Open Cloud updater (Scriptable app)
// Uses Roblox's beta Engine Instances API to update the existing MapBootstrap Script source.
// It does not publish a new binary place file. Requires universe-place-instances read/write,
// collaborative editing enabled for the place, and no open Studio script editor for this script.
// API key is requested at runtime and is never written to the repo or saved by this script.

const REPO_BUNDLE_URL = "https://raw.githubusercontent.com/jesusxal777-boop/Robloxia2009/main/tools/MapBootstrap.OpenCloud.lua";
const DEFAULT_UNIVERSE_ID = "10772817556";
const DEFAULT_PLACE_ID = "136071426230589";
const API_ROOT = "https://apis.roblox.com/cloud/v2";

async function askForSettings() {
  const alert = new Alert();
  alert.title = "Robloxia2009 — Open Cloud";
  alert.message = "Usa una API key de Roblox Open Cloud con universe-place-instances (Read + Write). No pegues la clave en GitHub ni en ChatGPT.";
  alert.addSecureTextField("Roblox API key", "");
  alert.addTextField("Universe ID", DEFAULT_UNIVERSE_ID);
  alert.addTextField("Place ID", DEFAULT_PLACE_ID);
  alert.addAction("Continuar");
  alert.addCancelAction("Cancelar");
  const choice = await alert.present();
  if (choice < 0) return null;
  const key = alert.textFieldValue(0).trim();
  const universeId = alert.textFieldValue(1).trim();
  const placeId = alert.textFieldValue(2).trim();
  if (!key || !universeId || !placeId) throw new Error("Completa la API key, Universe ID y Place ID.");
  return { key, universeId, placeId };
}

async function apiJSON(url, key, method = "GET", body = null) {
  const request = new Request(url);
  request.method = method;
  request.headers = { "x-api-key": key };
  if (body !== null) {
    request.headers["Content-Type"] = "application/json";
    request.body = JSON.stringify(body);
  }
  const result = await request.loadJSON();
  const status = request.response ? request.response.statusCode : 0;
  if (status && (status < 200 || status >= 300)) {
    throw new Error("Roblox Open Cloud respondió HTTP " + status + ": " + JSON.stringify(result));
  }
  return result;
}

function operationURL(path) {
  if (path.startsWith("https://")) return path;
  let clean = path.replace(/^\/+/, "");
  clean = clean.replace(/^cloud\/v2\//, "");
  return API_ROOT + "/" + clean;
}

async function pollOperation(path, key) {
  const url = operationURL(path);
  for (let attempt = 0; attempt < 15; attempt++) {
    const result = await apiJSON(url, key);
    if (result.done === true) {
      if (result.error) throw new Error("Operación Roblox fallida: " + JSON.stringify(result.error));
      return result;
    }
    await new Promise(resolve => Timer.schedule(2, false, resolve));
  }
  throw new Error("Roblox tardó demasiado en responder. No vuelvas a ejecutar de inmediato; comprueba el estado primero.");
}

async function listChildren(universeId, placeId, instanceId, key) {
  const url = API_ROOT + "/universes/" + universeId + "/places/" + placeId + "/instances/" + encodeURIComponent(instanceId) + ":listChildren";
  const initial = await apiJSON(url, key);
  const result = initial.done === true ? initial : await pollOperation(initial.path, key);
  const instances = result.response && result.response.instances;
  if (!Array.isArray(instances)) throw new Error("Roblox no devolvió la lista de instancias esperada.");
  return instances;
}

async function getInstance(universeId, placeId, instanceId, key) {
  const url = API_ROOT + "/universes/" + universeId + "/places/" + placeId + "/instances/" + encodeURIComponent(instanceId);
  const initial = await apiJSON(url, key);
  return initial.done === true ? initial : await pollOperation(initial.path, key);
}

function engineInfo(item) {
  return item && (item.engineInstance || item.response && item.response.engineInstance) || {};
}

function instanceId(item) {
  const engine = engineInfo(item);
  return engine.Id || engine.id || item.name || item.path;
}

function findByName(items, name) {
  return items.find(item => {
    const engine = engineInfo(item);
    return engine.Name === name || engine.name === name;
  });
}

async function findMapBootstrap(universeId, placeId, key) {
  const root = await listChildren(universeId, placeId, "root", key);
  const serverScriptService = findByName(root, "ServerScriptService");
  if (!serverScriptService) throw new Error("No encontré ServerScriptService en el lugar.");
  const sssId = instanceId(serverScriptService);
  const serverChildren = await listChildren(universeId, placeId, sssId, key);
  const robloxia = findByName(serverChildren, "Robloxia");
  if (!robloxia) throw new Error("No encontré ServerScriptService/Robloxia.");
  const robloxiaChildren = await listChildren(universeId, placeId, instanceId(robloxia), key);
  const bootstrap = findByName(robloxiaChildren, "MapBootstrap");
  if (!bootstrap) throw new Error("No encontré el Script MapBootstrap. No se cambió nada.");
  const engine = engineInfo(bootstrap);
  const className = engine.ClassName || engine.className || "";
  if (className && className !== "Script") {
    throw new Error("MapBootstrap no es un Script de servidor; se canceló para evitar sobrescribir otro objeto.");
  }
  return { item: bootstrap, id: instanceId(bootstrap) };
}

function extractScriptSource(result) {
  const engine = result.response && result.response.engineInstance
    ? result.response.engineInstance
    : result.engineInstance || result.response || result;
  const details = engine.Details || engine.details || {};
  const script = details.Script || details.script || {};
  return script.Source !== undefined ? script.Source : script.source;
}

async function confirmApply(bundleBytes, scriptId) {
  const alert = new Alert();
  alert.title = "Confirmar actualización";
  alert.message = "Se actualizará el Source del Script MapBootstrap existente.\n\nTamaño del bundle: " + bundleBytes + " caracteres.\nInstance ID: " + scriptId + "\n\nEl script actual se guardará primero en la carpeta Documents de Scriptable. Esto no es una publicación de archivo .rbxl y la API está en beta.";
  alert.addDestructiveAction("Respaldar y actualizar");
  alert.addCancelAction("Cancelar");
  return (await alert.present()) === 0;
}

async function main() {
  const settings = await askForSettings();
  if (!settings) return;

  const bundleRequest = new Request(REPO_BUNDLE_URL);
  const bundle = await bundleRequest.loadString();
  if (!bundle || bundle.length < 30000) {
    throw new Error("El bundle descargado está vacío o es inesperadamente pequeño; no se cambió nada.");
  }
  if (bundle.length > 190000) {
    throw new Error("El bundle supera el margen seguro de 190 KB para el límite de la API.");
  }

  const target = await findMapBootstrap(settings.universeId, settings.placeId, settings.key);
  const currentResult = await getInstance(settings.universeId, settings.placeId, target.id, settings.key);
  const currentSource = extractScriptSource(currentResult);
  if (typeof currentSource !== "string" || currentSource.length < 100) {
    throw new Error("No pude leer el Source actual de MapBootstrap; no se cambió nada.");
  }
  if (!(await confirmApply(bundle.length, target.id))) return;

  // Back up the existing source locally before attempting any write.
  const fm = FileManager.local();
  const backupDir = fm.joinPath(fm.documentsDirectory(), "Robloxia2009-Backups");
  if (!fm.fileExists(backupDir)) fm.createDirectory(backupDir, true);
  const stamp = new Date().toISOString().replace(/[:.]/g, "-");
  const backupPath = fm.joinPath(backupDir, "MapBootstrap-before-RP-" + stamp + ".lua");
  fm.writeString(backupPath, currentSource);

  const url = API_ROOT + "/universes/" + settings.universeId + "/places/" + settings.placeId + "/instances/" + encodeURIComponent(target.id);
  const body = {
    engineInstance: {
      Details: {
        Script: {
          Source: bundle
        }
      }
    }
  };
  const initial = await apiJSON(url, settings.key, "PATCH", body);
  if (initial.done !== true && initial.path) {
    await pollOperation(initial.path, settings.key);
  } else if (initial.error) {
    throw new Error("Roblox rechazó la actualización: " + JSON.stringify(initial.error));
  }

  const done = new Alert();
  done.title = "Solicitud completada";
  done.message = "Roblox aceptó la actualización de MapBootstrap.\n\nRespaldo local: " + backupPath + "\n\nComprueba la colaboración del lugar y verifica el resultado en Creator Dashboard. La API de instancias está en beta y esto no equivale a subir un archivo .rbxl binario.";
  done.addAction("OK");
  await done.present();
}

try {
  await main();
} catch (error) {
  const alert = new Alert();
  alert.title = "No se aplicaron cambios o falta verificar";
  alert.message = String(error);
  alert.addAction("OK");
  await alert.present();
}
