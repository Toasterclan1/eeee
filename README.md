# EverLight v2.0 — Enhanced Animal Company Mod Menu

![Version](https://img.shields.io/badge/version-2.0.0-blue)
![Platform](https://img.shields.io/badge/platform-iOS%2013+-brightgreen)
![License](https://img.shields.io/badge/license-MIT-orange)

A powerful iOS tweak for Animal Company featuring a beautiful galaxy-themed UI, 10-attempt item spawning system, and an extensive Overpowered (OP) tab with 25+ game-changing mods.

---

## ✨ Features

### 🎯 Core Features
- **10-Attempt Item Spawning** — Automatically retries up to 10 times to ensure items spawn
- **Galaxy-Themed UI** — Beautiful nebula purple interface with animated stars
- **Draggable Menu** — Move the menu anywhere on screen
- **Category Filtering** — Quickly find items by category
- **Search Function** — Search through 80+ items instantly

### 📦 Item Categories
- All Items (80+)
- Fishing Rods
- Fish
- Baits
- Weapons (Alpha Blade, RPG, Shotguns, etc.)
- Valuables (Gold, Gems, Diamonds)
- Food & Consumables

### 🔥 Overpowered (OP) Tab Features

#### Player Manipulation
| Feature | Description |
|---------|-------------|
| 💥 Mass Fling All | Fling all players with force |
| 💰 Give $999,999 | Max money hack |
| 📍 Teleport to Me | Bring all players to your location |
| 💀 Instant Kill All | Eliminate everyone |
| 😵 Stun Everyone | 10-second stun effect |
| 🦨 Make Everyone Stinky | Apply stink effect |

#### Self Mods
| Feature | Description |
|---------|-------------|
| 🦸 Super Speed | 10x movement speed |
| 👻 Invisibility | Become invisible to others |
| 🎯 Rapid Fire | No weapon cooldown |
| ♾️ Infinite Ammo | Never reload |
| 🪐 Change Color | Random HSV color |
| 🎭 Jellify Self | Become jelly-like |
| 🔊 Squeak Voice | High-pitch voice effect |
| 🔇 Muffle Voice | Low-pitch voice effect |

#### World Manipulation
| Feature | Description |
|---------|-------------|
| 💣 Spawn Item Rain | Drop items everywhere |
| 📳 Screen Shake All | Shake everyone's screen |
| 🎁 Spawn All Weapons | Give every weapon at once |
| 💎 Spawn All Valuables | Give all valuables |
| 🍔 Spawn All Food | Give all food items |
| 🎣 Spawn All Fish | Give all fish types |

#### Trolling
| Feature | Description |
|---------|-------------|
| 🐜 Shrink Everyone | Make players tiny |
| 🗼 Grow Everyone | Make players giant |
| 🪨 Set Max Mass | Make everyone heavy |
| 🎲 Random Buff Everyone | Apply random buffs |
| 🌪️ Chaos Mode | Enable ALL effects at once |

---

## 🎮 RPC Functions Included

The tweak includes declarations for these Unity RPC functions:

```objc
RPC_Teleport        // Teleport players
RPC_AddForce        // Fling players with physics
RPC_PlayerHit       // Deal damage to players
RPC_PlayerStun      // Stun players
RPC_AddPlayerMoney  // Give money
RPC_SetColorHSV     // Change player colors
RPC_TagAsStinky     // Apply stink effect
RPC_ApplyBuff       // Apply buffs/debuffs
RPC_Jellify         // Jellify players
RPC_MuffleVoice     // Muffle voice
RPC_SqueakVoice     // Squeaky voice
RPC_ShakeScreen     // Screen shake effect
RPC_SpawnPickup_Internal // Spawn pickups
SetNormalizedScaleModifier // Shrink/grow players
SetMass             // Set item/player mass
get_IsMine          // Check if local player
```

---

## 📥 Installation

### Method 1: Jailbroken Device (Recommended)

1. Install the `.deb` package using **Filza** or **SSH**:
   ```bash
   dpkg -i com.everlight.tweak_2.0.0_iphoneos-arm.deb
   ```
2. Respring your device
3. Launch Animal Company
4. Tap the ✦ floating button to open the menu

### Method 2: Sideloadly (Non-Jailbroken)

1. Download the Animal Company IPA
2. Open **Sideloadly**
3. Load the IPA
4. Enable **"Inject Dylib"** option
5. Select `EverLight.dylib` from the source folder
6. Sideload the modified IPA
7. Launch the game and enjoy!

### Method 3: Build from Source

**Requirements:**
- macOS with Xcode installed
- [Theos](https://github.com/theos/theos) framework
- iOS SDK

**Build Steps:**
```bash
# Clone the repository
git clone <repo-url>
cd EverLight

# Build the tweak
make package FINALPACKAGE=1

# The .deb will be in the packages/ folder
```

---

## 🛠️ Building the .deb

### Automatic Build
```bash
chmod +x build.sh
./build.sh
```

### Manual Build with Theos
```bash
export THEOS=~/theos
make clean
make package FINALPACKAGE=1
```

---

## 📁 Project Structure

```
EverLight/
├── Tweak.mm              # Main tweak source code
├── Makefile              # Theos build configuration
├── control               # Package metadata
├── EverLight.plist       # Substrate filter (when to inject)
├── build.sh              # Automated build script
├── README.md             # This file
└── packages/             # Output directory
    ├── com.everlight.tweak_2.0.0_iphoneos-arm.deb
    ├── EverLight-v2.0-source.tar.gz
    └── EverLight-v2.0-source.zip
```

---

## 🎨 UI Preview

```
┌─────────────────────────────┐
│  ✕  ✦ EVERLIGHT ✦       ↻  │
├─────────────────────────────┤
│ [Items] [Settings] [🔥OP]   │
├─────────────────────────────┤
│ [All][Rods][Fish][Weapons]  │
│ ✦ Search items...           │
├─────────────────────────────┤
│ ✦ ITEM SPAWNER       80 items│
│ ┌─────────────────────────┐ │
│ │ item_alphablade         │ │
│ │ item_arena_pistol  ←─── │ │
│ │ item_rpg                │ │
│ │ ...                     │ │
│ └─────────────────────────┘ │
│ Qty: 1 [−] [+]  Slot: leftHand│
│ [✦  SPAWN (10x Retry)] [🗑] │
└─────────────────────────────┘
```

---

## ⚠️ Disclaimer

**Use at your own risk!** This tweak modifies game behavior and may:
- Result in account bans
- Cause game instability
- Violate Terms of Service

The developers are not responsible for any consequences of using this tweak.

---

## 🐛 Troubleshooting

### Menu not appearing?
- Ensure the tweak is properly injected
- Check that you're running Animal Company
- Try respringing/restarting the app

### Items not spawning?
- The 10-attempt system will retry automatically
- Check that the config file path is accessible
- Verify write permissions

### Game crashes?
- Disable some OP features
- Ensure you're using a compatible game version
- Check for conflicting tweaks

---

## 📝 Changelog

### v2.0.0
- ✅ Added 10-attempt item spawning system
- ✅ Added Overpowered (OP) tab with 25+ mods
- ✅ Added RPC function declarations
- ✅ Improved UI with galaxy theme
- ✅ Added category filtering
- ✅ Added search functionality
- ✅ Compatible with Sideloadly

---

## 🤝 Credits

- **EverLight Team** — Development
- **Theos** — iOS tweak development framework
- **Animal Company** — The amazing game

---

## 📄 License

MIT License — Feel free to modify and distribute!

---

## 💬 Support

For issues, suggestions, or contributions:
- Open an issue on GitHub
- Join our Discord community

---

**Made with ❤️ by the EverLight Team**

*Compatible with iOS 13+ and Animal Company latest version*
