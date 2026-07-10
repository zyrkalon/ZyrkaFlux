# ZyrkaFlux

**ZyrkaFlux** is an all-in-one Roblox executor utility featuring ESP (player highlighting), aim assist, and flight movement.

## Features

### ESP 
- Player highlights with customizable fill & outline colors
- 2D boxes, name labels, distance display, health bars
- Tracers & bone skeleton overlay
- Team Check — hides teammates, with live detection when players switch teams
- Configurable text size

### Aimbot
- Smooth aimbot with adjustable strength (1%–30%)
- FOV circle (visible radius) with color picker
- Target bone selection: Head, UpperTorso, HumanoidRootPart
- Wall check — skips targets behind obstacles
- Team Check integration — never aims at teammates (syncs with ESP setting)

### Flight
- Fly mode with WASD + Space/Ctrl controls
- Adjustable fly speed (0–100)

## Usage

Run via any Roblox executor that supports `loadstring`. The script loads the Rayfield UI library automatically.

```
loadstring(game:HttpGet(''))()
```

## Configuration

All settings are saved automatically via Rayfield's configuration system (folder: `PlayerESPTool`, file: `ESPConfig`).
