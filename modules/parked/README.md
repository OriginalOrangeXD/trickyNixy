# Parked modules

These modules are **intentionally retained but currently unreferenced** — they
belonged to hosts that were decommissioned (`aibox`, `bastion`, `homeserver`,
removed in commit 359392c). They are kept here so the capability can be revived
on a future machine without rewriting it from scratch. Nothing imports them, so
they do not affect evaluation of the live hosts (`agentbox`, `mediaserver`).

| Module | Came from | What it does |
|--------|-----------|--------------|
| `vlm.nix` | homeserver | llama.cpp + Qwen3-VL video-analysis backend for the UniFi / Home-Assistant stack |
| `gpu.nix` | homeserver | generic GPU enablement for the inference box |
| `fan-control.nix` | homeserver | fan-curve control for the homeserver chassis |
| `sunshine.nix` | aibox | Sunshine (Moonlight) game/desktop streaming; KMS capture |
| `steamos.nix` | aibox | SteamOS / Steam Big-Picture session for the gaming box |

The `jovian` flake input (SteamOS layer, used by the gaming build) is likewise
parked-in-place — left in `flake.nix` inputs but unreferenced.

## Reviving one

1. Move it back: `git mv modules/parked/<name>.nix modules/`
2. Add its path to the target host's module list in `flake.nix` (or to that
   host's `configuration.nix` `imports`).
3. For the gaming modules, re-wire the `jovian` input as that host needs it.
4. If a parked module needs a secret, add the host as a recipient in
   `secrets/secrets.nix` and re-encrypt.
