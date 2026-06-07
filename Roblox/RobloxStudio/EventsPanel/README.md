# 🛡️ OYB Admin & Global Events System (V2)

Welcome to the updated OYB Events System! This system has been revamped to include a **Smart Auto-Setup** feature, making installation faster and more secure.

## 🔗 Resources

* 📦 **Get the Model:** [OYB Events Panel on Roblox](https://create.roblox.com/store/asset/71640449795118/MainModule-of-OYB-Panel)
* 🎥 **Video Tutorial:** [Watch the Updated Setup Guide](https://youtu.be/Zx0taEAkBBM)

---

## 🛠️ Installation Guide (New Method)

Follow these steps to set up the system. The new version handles file distribution automatically!

### 1. API Access & Security ⚙️
To allow the system to save data and function correctly:
*   Open **Game Settings** in Roblox Studio.
*   Go to the **Security** tab.
*   Enable **"Allow Studio Access to API Services"** and click **Save**.

### 2. Owner Configuration 🔑
*   Locate the `Settings` script inside the main project folder.
*   Replace the placeholder ID with your **Roblox User ID** to gain full access.

### 3. Avatar Setup (Global Events) 🎭
*   Use the **AlreadyPro** plugin to load your avatar.
*   Rename the spawned character model **EXACTLY** to: `OYB_DivineDummy`.
*   Move this model into: `OYB_Assets` -> `OYBEVENT`.

### 4. Client Script Setup 💻
*   Create a new **LocalScript** inside the `OYB_Assets` folder.
*   Rename it **EXACTLY** to: `OYB_PlayerClient`.
*   Get the `OYB_PlayerClient` script code from [this GitHub link](https://github.com/OYB0/OYB0/blob/main/Roblox/RobloxStudio/EventsPanel/OYB_PlayerClient) and paste it inside your new LocalScript.

### 5. Final Step: Auto-Setup 🎉
*   Simply press **"Play"**! 
*   The system will automatically detect all components and move them to their correct locations (ReplicatedStorage, ServerScriptService, etc.).

---

## ⚙️ Requirements
*   **HTTP Requests:** Must be enabled if you are using external webhooks.
*   **API Services:** Required for the Admin List and DataStores.

---

## 📜 Copyright & Terms of Use

Created by **OYB**.

*   ✅ **Allowed:** Using this system in your games and personal modifications.
*   ❌ **Prohibited:** Re-uploading, distributing, or selling this script/model (modified or not) to the Roblox Library or other platforms.

---

## ✨ Community & Support
Need help? Join our community or check our latest updates:
*   **YouTube:** [OYB Channel](https://youtube.com/@OYBOfficial)
*   **GitHub:** [OYB Projects](https://github.com/oyb0/oyb0)
