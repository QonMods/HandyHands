# HandyHands

[![Factorio Mod Portal](https://img.shields.io/badge/Factorio_Mod_Portal-HandyHands-orange)](https://mods.factorio.com/mod/HandyHands)
[![GitHub license](https://img.shields.io/badge/license-GNU_GPLv3-blue.svg)](LICENSE)
[![Support on Patreon](https://img.shields.io/badge/Support-Patreon-red.svg)](https://www.patreon.com/)

Automatic handcrafting for Factorio - bringing you the convenience of logistics slots for the early game!

## Features

### 🔄 Automatic Crafting
- Automatically starts handcrafting items when:
  - They are quickbar filtered
  - You have less than 1 stack
  - Your crafting queue is empty
- Works with ammo in your ammo bar
- Treats slots as filtered with whatever you put into them

### ⚙️ Configurable Autocraft Amounts

Configure stack amounts through:
- Hotkeys (Options > Controls > Mods)
- Personal logistics requests (slots unlocked before bot technology)

#### Stack Control
- Use hotkeys to increase/decrease stack amounts (default: U & J)
- Choose between: 0, 0.2, 0.5, 0.8, 1, 2, 3, or 4 stacks
- Empty cursor: Change default amount
- Hold item: Configure specific item limit
- Go below 0 stacks: Drop setting for that item
- Set default stack size below 0: Drop all item settings
- Cancel HandyHands crafting: Temporarily pause autocrafting

### 🎯 Smart Prioritization

1. **Cursor Priority**
   - Items in your cursor get highest priority
   - Prevents running out while placing items

2. **Stack-Based Priority**
   - Prioritizes items with least filled stacks
   - Maintains balanced quantities (e.g., pipes and underground pipes)

## Manual Installation

1. Download from the [Factorio Mod Portal](https://mods.factorio.com/mod/HandyHands)
2. Place in your Factorio mods directory
3. Enable the mod in the game's Mod Menu

## Media

Featured in Xterminator's spotlight video! [Watch Here](https://www.youtube.com/watch?v=CEK8cvn972c)

## Support Development

If you enjoy HandyHands, consider supporting development through [Patreon](https://www.patreon.com/Qon)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request
