# XR Halo - VR Object Manipulation System

A VR interaction system for Godot 4 that enables intuitive object manipulation through a XR Halo interface. Inspired by the "Squeak Halo" concept, adapted for immersive XR environments.

## Project Overview

XR Halo allows end-users to manipulate 3D objects in VR through an intuitive radial menu system. Users can move, scale, rotate, and reset objects directly in the virtual environment.

##  Requirements

- **Godot Engine:** 4.5 or higher
- **VR Headset:** Meta Quest 3/Pro (or any OpenXR-compatible headset)
- **Plugins Required:**
  - Godot XR Tools (included in `addons/godot-xr-tools/`)
  - Godot OpenXR Vendors (included in `addons/godotopenxrvendors/`)

## Project Structure

```
3d-land/
├── game/                          # Main game implementation
│   ├── assets/                    # Visual assets and materials
│   ├── scenes/                    # Game scenes
│   └── scripts/                   # Core interaction scripts
├── export/                        # apk of exported Game
```

## Core Systems

### Interaction Manager (`interaction_manager.gd`)

The central hub that coordinates all XR interactions:
- Manages object selection and state
- Coordinates feature activation (Move/Scale/Rotate)
- Emits signals for object pickup/drop events
- Interfaces with the radial menu system

**Exported Variables:**
- `fp`: First-person controller reference
- `controller`: Right hand controller
- `left_controller`: Left hand controller
- `radial_menu_feature`: Reference to radial menu
- `feature_moving`: Movement feature
- `feature_scaling`: Scaling feature
- `feature_rotating`: Rotation feature

### Feature System

Each feature is a modular node that handles specific interactions:

#### 1. **Feature Moving** (`feature_moving.gd`)
- Moves objects along the raycast direction
- Includes collision detection and resolution
- Prevents object overlap
- Uses physics queries for safe placement

**Exports:**
- `collision_buffer`: Distance to keep from other objects
- `max_collision_checks`: Number of adjustment attempts
- `enable_debug`: Toggle collision debugging

#### 2. **Feature Scaling** (`feature_scaling.gd`)
- Height-based scaling: move hand up/down to scale
- Uses left hand Y-position for control
- Includes deadzone to prevent jitter

**Exports:**
- `sensitivity`: Scaling speed (default: 1.5)
- `deadzone`: Minimum hand movement threshold (default: 0.05)

#### 3. **Feature Rotation** (`feature_all_in_one.gd`)
- Thumbstick-controlled rotation
- Left/Right: Horizontal spin (Y-axis)
- Up/Down: Tilt (local X-axis)

**Exports:**
- `rotation_speed`: Rotation speed multiplier (default: 3.0)

### Radial Menu System

#### **Feature_RadialMenu.gd**
Controls the radial menu lifecycle:
- Opens on grip button press
- Tracks thumbstick for selection
- Confirms with trigger button
- "Sticky selection" - maintains choice after thumbstick release



#### **RadialMenu3D.gd**
The visual 3D radial menu:
- Circular menu with 4 options: Move, Scale, Rotate, Reset
- Highlights selected option
- Shows active feature icon when closed
- Audio feedback for selections

## 🚀 Getting Started

### 1. Clone the Repository

### 2. Open in Godot

1. Launch **Godot 4.x**
2. Click **Import**
3. Navigate to the project folder
4. Select `project.godot`
5. Click **Import & Edit**

### 3. Enable Required Plugins

1. Go to **Project → Project Settings → Plugins**
2. Enable:
   - Godot XR Tools
   - Godot OpenXR Vendors

### 4. Configure for VR

https://developers.meta.com/horizon/documentation/native/android/mobile-device-setup/
https://docs.godotengine.org/en/stable/tutorials/xr/deploying_to_android.html


## How to Use

### Basic Controls

| Action | Input                      | Description |
|--------|----------------------------|-------------|
| **Point** | Right hand / Right Trigger | Aim raycast at objects |
| **Navigate Menu** | Left Thumbstick            | Select feature (Move/Scale/Rotate) |
| **Confirm** | Left Trigger               | Activate selected feature |
| **Move Object** | Right hand raycast         | Moves to raycast point |
| **Scale Object** | Left hand up/down          | Raise/lower hand to scale |
| **Rotate Object** | Left Thumbstick            | Horizontal/vertical rotation |
| **Drop Object** | Left Grip                  | Release object |

### Interaction Workflow

1. **Point** at an object with your right hand
3. **Move Left Thumbstick** to highlight a feature (Move/Scale/Rotate/Reset)
4. **Press Left Trigger** to confirm selection
5. The menu closes and shows the active feature icon
6. **Perform the action**:
   - **Move**: Raycast with right hand to place object
   - **Scale**: Move left hand up/down
   - **Rotate**: Use left thumbstick
7. **Press Left Grip** again to deselect and drop object

## Customization

### Adding New Features

1. Create a new script extending `Node`
2. Implement the `setup()` function
3. Connect to `object_picked_up` and `object_dropped` signals
4. Add your feature logic in `_process()`
5. Add the feature to `interaction_manager.gd` exports


### Modifying the Radial Menu

Edit `RadialMenu3D.gd`:
- `option_ids`: Array of feature names
- `option_icons`: Array of textures for each option
- `outer_radius` / `inner_radius`: Menu size
- `color_normal` / `color_hover`: Menu colors

## Troubleshooting

### VR Not Working
- Ensure OpenXR plugins are enabled
- Check that your headset is in developer mode
- Verify Godot's XR interface is set to OpenXR
