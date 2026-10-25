# RoboLook robot-football strategy — v5.2

A cleaned, source-only release of a three-robot football strategy developed for the **QC-iLoboke small robot football platform** and the SOM strategy environment.

> **Version note:** `v5.2` is the public project release. The original runtime folder was named `SOM v3.4.2`; that is a platform/runtime identifier, not this repository's project version.

## Project context

The official RAICOM product page describes QC-iLoboke as a small football-robot platform for education and competition. It supports single-robot control, multi-robot matches and visual simulation, and brings together motion control, sensing, wireless communication, vision, multi-robot cooperation, decision-making and real-time planning.

Official platform reference: <https://www.raicom.com.cn/product-item.html?id=44>

This repository preserves the **reviewable strategy layer** from the supplied competition package. It does not redistribute the proprietary SOM application, executable runtime, compiled DLL skills, Qt libraries or encrypted submission package.

## What the strategy does

The Lua layer maps referee/game states to role-specific actions for a three-robot team:

- **Goalie** — goal protection and goalkeeper-specific behaviours;
- **Kicker** — ball acquisition, passing and shooting;
- **Receiver** — receiving positions, return passes and defensive support.

The state-machine scripts cover:

- normal attack and defence;
- role selection based on ball distance and possession;
- pass–receive–shoot sequences;
- kick-off and kick-off defence;
- front, middle, back and corner set plays;
- penalties, ball placement, stop, halt and game-over states;
- blue/yellow team configuration and opponent profiles.

For example, `NormalPlayDefend.lua` switches between ball acquisition, return passing and shooting while keeping a goalie active. The `RUIKANG/` package contains competition-specific multi-stage passing and shooting sequences.

## Repository layout

```text
strategy/
├── SelectPlay.lua             # referee-message and play selection
├── Play.lua                   # state-machine runner
├── config_blue.json           # three-role blue-team configuration
├── config_yellow.json         # yellow-team/test configuration
├── play/
│   ├── Package/               # competition and set-play strategies
│   ├── Ref/                   # referee-state routing
│   └── Test/                  # retained strategy experiments
├── skill/                     # role-to-skill mappings
└── worldmodel/                # task bindings
config/                        # robot and kick parameters
scripts/validate_repository.py # source-only and syntax checks
SOURCE_MANIFEST.json           # file hashes and provenance
```

## Requirements

The scripts were authored for the SOM/PlayBot environment and call host-provided functions such as `CGetRefMsg`, `CIsGetBall`, `CRole2BallDir` and `CGetLuaState`. They are **not a standalone Lua application**.

To validate this public repository without the proprietary runtime:

```bash
python -m pip install -r requirements-dev.txt
python scripts/validate_repository.py
```

The validator checks:

1. every Lua file parses as Lua syntax;
2. JSON and XML configuration files parse;
3. no compiled binaries or build artifacts are present;
4. every retained source file is represented in `SOURCE_MANIFEST.json`.

## Public-release boundary

Included:

- Lua strategy and role scripts;
- JSON/XML/CFG configuration required to understand the strategy;
- source manifest and validation tooling.

Excluded:

- SOM and PlayBot executables;
- DLL/LIB/PDB/OBJ build products;
- Qt and Visual C++ runtime files;
- logs, dumps, visual recordings and serial data;
- encrypted competition submission archives;
- third-party platform binaries;
- native C++ skill source, which was not present in the supplied `SOM v3.4.2.7z` attachment.

Because the original platform and compiled skills are not redistributed, a full match cannot be reproduced from this repository alone. The repository is intended for source review and portfolio evidence.

## Provenance and licensing

The project code is published for portfolio review. No blanket open-source licence is granted for the competition strategy or vendor platform interfaces. `strategy/json.lua` retains its original MIT licence notice and copyright attribution.

See [`NOTICE.md`](NOTICE.md) for the release boundary and third-party attribution.
