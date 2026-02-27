# Windows 10 Time Server Configuration

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?logo=windows)](https://www.microsoft.com/windows)

> **Quick guide to change NTP (Network Time Protocol) server on Windows 10/11**

## 📋 Table of Contents

- [Why Change Time Server?](#why-change-time-server)
- [Recommended Time Servers](#recommended-time-servers)
- [Methods](#methods)
  - [Method 1: Command Prompt (Recommended)](#method-1-command-prompt-recommended)
  - [Method 2: Registry Editor](#method-2-registry-editor)
  - [Method 3: GUI (Limited)](#method-3-gui-limited)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## 🤔 Why Change Time Server?

- **Better accuracy**: Some servers are more precise than default `time.windows.com`
- **Lower latency**: Choose geographically closer servers
- **Reliability**: Use redundant server pools
- **Compliance**: Meet corporate or security requirements

---

## 🌐 Recommended Time Servers

| Server | Provider | Notes |
|--------|----------|-------|
| `pool.ntp.org` | **NTP Pool Project** | ⭐ **RECOMMENDED** - Global pool, auto-selects closest servers |
| `time.google.com` | Google | Fast, reliable, global infrastructure |
| `time.cloudflare.com` | Cloudflare | Privacy-focused, stratum 1 |
| `time.windows.com` | Microsoft | Default Windows server |
| `0.ro.pool.ntp.org` | NTP Pool (Romania) | Regional pool for Romania |
| `europe.pool.ntp.org` | NTP Pool (Europe) | European regional pool |

> 💡 **Best choice**: `pool.ntp.org` - works worldwide with automatic server selection

---

## 🛠️ Methods

### Method 1: Command Prompt (Recommended)

**Fastest and most reliable method**

1. **Open Command Prompt as Administrator**
   - Press `Windows + X`
   - Select **"Command Prompt (Admin)"** or **"Windows PowerShell (Admin)"**

2. **Run these commands:**

```cmd
w32tm /config /manualpeerlist:"pool.ntp.org" /syncfromflags:manual /reliable:YES /update
net stop w32time
net start w32time
w32tm /resync
```

3. **Done!** ✅

#### For multiple servers (better redundancy):

```cmd
w32tm /config /manualpeerlist:"0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org" /syncfromflags:manual /reliable:YES /update
net stop w32time
net start w32time
w32tm /resync
```

---

### Method 2: Registry Editor

**Use when GUI doesn't allow custom servers**

1. **Open Registry Editor**
   - Press `Windows + R`
   - Type `regedit` and press Enter

2. **Navigate to:**
   ```
   HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime\Servers
   ```

3. **Add new server:**
   - Right-click in the right pane → **New** → **String Value**
   - Name it with the next number (e.g., `4`, `5`, etc.)
   - Double-click and set value to: `pool.ntp.org`

4. **Set as default:**
   - Double-click on **(Default)**
   - Set value to the number you created (e.g., `4`)

5. **Restart Windows Time service:**
   - Press `Windows + R` → type `services.msc`
   - Find **Windows Time** → Right-click → **Restart**

---

### Method 3: GUI (Limited)

**Note**: Windows 10 GUI doesn't allow adding custom servers easily, but you can select from existing ones.

1. Right-click **clock** in taskbar → **"Adjust date/time"**
2. Scroll down → **"Add clocks for different time zones"**
3. Click **"Internet Time"** tab
4. Click **"Change settings..."**
5. Select from dropdown or type server address
6. Click **"Update Now"** → **"OK"**

⚠️ **Limitation**: Dropdown only shows pre-configured servers. Use Method 1 or 2 for custom servers.

---

## ✅ Verification

Check if synchronization is working:

```cmd
w32tm /query /status
```

**Expected output:**
```
Leap Indicator: 0(no warning)
Stratum: 3 (secondary reference - syncd by (S)NTP)
Precision: -23 (119.209ns per tick)
Root Delay: 0.0156250s
Root Dispersion: 7.7968750s
ReferenceId: 0x0A0A0A0A (source IP: 10.10.10.10)
Last Successful Sync Time: [timestamp]
Source: pool.ntp.org
Poll Interval: 10 (1024s)
```

### Check current configuration:

```cmd
w32tm /query /configuration
```

### Force immediate sync:

```cmd
w32tm /resync /force
```

---

## 🔧 Troubleshooting

### ❌ Error: "The service has not been started"

**Solution:**
```cmd
net start w32time
```

### ❌ Error: "The computer did not resync because no time data was available"

**Solutions:**

1. **Check internet connection**
2. **Allow NTP through firewall** (UDP port 123)
3. **Try different server:**
   ```cmd
   w32tm /config /manualpeerlist:"time.google.com" /syncfromflags:manual /update
   w32tm /resync
   ```

### ❌ Time keeps drifting

**Enable automatic startup:**
```cmd
sc config w32time start= auto
```

### 🔍 View detailed logs:

```cmd
w32tm /stripchart /computer:pool.ntp.org /samples:5 /dataonly
```

---

## 📝 Additional Commands

### Reset to Windows defaults:

```cmd
w32tm /unregister
w32tm /register
net start w32time
w32tm /resync
```

### Check peer list:

```cmd
w32tm /query /peers
```

### Monitor sync in real-time:

```cmd
w32tm /monitor
```

---

## 📜 License

This guide is licensed under the [MIT License](LICENSE).

---

## 🤝 Contributing

Feel free to submit issues or pull requests to improve this guide!

---

## ⭐ Credits

- [NTP Pool Project](https://www.pool.ntp.org/)
- [Microsoft Documentation](https://docs.microsoft.com/en-us/windows-server/networking/windows-time-service/)

---

**Made with ❤️ for the community**

---

### 📌 Quick Copy-Paste

```cmd
# One-liner to set pool.ntp.org
w32tm /config /manualpeerlist:"pool.ntp.org" /syncfromflags:manual /reliable:YES /update && net stop w32time && net start w32time && w32tm /resync
```
