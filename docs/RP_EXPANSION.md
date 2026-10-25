# Robloxia2009 RP Expansion — implementation notes

## Install and sync
- Keep the published place file and its original `ServerStorage` assets. This source module depends on the exact template names already present there.
- Rojo maps `src/ServerScriptService/Robloxia` into ServerScriptService and the notification LocalScript into StarterPlayerScripts.
- Start `MapBootstrap.server.lua`; it builds the existing classic map, then starts RPExpansion under the same map model. The ARG remains controlled by `MapConfig.ARG.Enabled`.

## Included systems
- Three claimable houses using `House`, `House2`, `House3`; one owner at a time. A house is released when its owner leaves.
- Money leaderboard, shift payouts with a server-side cooldown, grocery purchases and five-item bag capacity.
- Refrigerator storage for refrigerated foods, with a maximum of eight items and individual withdrawal prompts.
- TV1 supplied on the default table when claiming a house, TV on/off interaction, RetroRobloxChannel sound and emergency siren display support.
- Procedural Tech Store and PC fallback model; purchased TVs/PCs use `Wood Crate`/`Crate` templates and can be installed on a nearby table while the player is inside their home. Placement rejects occupied surfaces.
- Car 1–4 purchase prompts using `ServerStorage/2009Cars`, selective repainting by body-part names, and repair/car-wash service prompts.
- Rare tornado event: attempts to load asset 7019541974 and falls back to a procedural funnel; siren asset 90738042 and TV channel sound 15930255433 are configured.

## Important limitations before publishing
- This commit has not been run in Roblox Studio. The exact pivot/footprints of user-supplied models, vehicle chassis scripts/seats, and sound permissions need in-Studio verification.
- Static building/house clones have their embedded scripts stripped for safety. Car models keep their scripts so existing vehicle controls may work.
- The TV image ID 301987447 was only approximate in the project notes and is not applied automatically.
- House furniture uses bounding-box-relative positions; adjust after visual inspection if a model's bounding box includes exterior props or roof overhang.
- RP state (money, house ownership, inventory and cars) is session-only; it is not saved between servers yet.
- The existing procedural roleplay houses and ARG secret house are preserved. The RP houses are added as a separate district to avoid replacing the ARG hatch.
- A full publish still requires Roblox Studio or a separately configured, secure Roblox Open Cloud publishing workflow; editing the GitHub repository alone does not change the live place.
