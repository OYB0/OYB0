# 🌌 Universal Multi-Game Script Loader

An intelligent, all-in-one loader script for Roblox. Instead of maintaining separate script links for each game, this loader detects the player's current game via `PlaceId` and executes the corresponding script automatically.

🌐 **Project Page:** [oybofficial.com/projects/multi-game-script-loader/](https://oybofficial.com/projects/multi-game-script-loader/)

---

## 🔗 Main Script
* 📜 **TheScript.lua:** [View Source Code](TheScript.lua)

## 🎥 Video Guide
Watch how to set up and configure game IDs:
👉 **[Watch the Tutorial on YouTube](https://youtu.be/klf9EnL23So)**

## ✨ Key Features
* 🧠 **Auto Game Detection:** Uses `game.PlaceId` to run the right script instantly.
* 🎨 **Smooth Animated UI Notifications:** Built with `TweenService` for clean user alerts.
* ⚙️ **One Link for Everything:** Update your games in one centralized file without changing the loader URL.

## 🚀 How to Configure
Open `TheScript.lua` and add your place IDs and raw script URLs:

```lua
local SupportedGames = {
    [119579217517090] = "[https://raw.githubusercontent.com/](https://raw.githubusercontent.com/)...", -- Game 1
    [131623223084840] = "[https://raw.githubusercontent.com/](https://raw.githubusercontent.com/)...", -- Game 2
}
