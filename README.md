# 🛠️ Fix: DNS Server Not Responding (Windows 10)

This guide helps resolve the error:

> **"Your computer appears to be correctly configured, but the device or resource (DNS server) is not responding."**

Even when the network adapter is working correctly (e.g., Realtek PCIe GbE Family Controller), Windows may fail to communicate with the DNS server.

---

## 📌 Problem Description

Windows Network Diagnostics shows:

- ✅ Network adapter working properly
- ✅ Driver status OK (Device Manager Code: 0)
- ❌ DNS server not responding
- ❌ Internet access unavailable

Example adapter:
- **Realtek PCIe GbE Family Controller**
- Driver Version: 10.56.119.2022
- Windows 10 x64

---

# ✅ Solutions (Step-by-Step)

Follow these steps in order.

---

## 🔹 1. Restart Network Devices

1. Shut down your PC.
2. Unplug router and modem.
3. Wait 5 minutes.
4. Plug router/modem back in.
5. Wait for full connection.
6. Turn PC back on.

---

## 🔹 2. Reset Network Stack (Recommended)

Open **Command Prompt as Administrator** and run:

```bash
ipconfig /flushdns
ipconfig /release
ipconfig /renew
netsh int ip reset
netsh winsock reset
```

Restart your computer.

---

## 🔹 3. Manually Set Google DNS

1. Press `Windows + R`
2. Type: `ncpa.cpl`
3. Right-click **Ethernet**
4. Click **Properties**
5. Select **Internet Protocol Version 4 (TCP/IPv4)**
6. Click **Properties**

Select:

```
Use the following DNS server addresses
```

Enter:

```
Preferred DNS:  8.8.8.8
Alternate DNS:  8.8.4.4
```

Click OK → Restart PC.

---

## 🔹 4. Test Connectivity

Open Command Prompt:

### Test IP connection:
```bash
ping 8.8.8.8
```

If this works ✅ → Internet is working but DNS is broken.

### Test DNS resolution:
```bash
ping google.com
```

If this fails ❌ → DNS issue confirmed.

---

## 🔹 5. Check Router Settings

Access router (usually):

```
192.168.1.1
```

Check:
- WAN Status
- DNS Settings

Set DNS manually if needed:
```
8.8.8.8
8.8.4.4
```

---

# 🔍 Possible Causes

- ISP DNS outage
- Router DNS misconfiguration
- Corrupted Windows network stack
- Firewall blocking DNS
- Malware modifying DNS

---

# 🧪 Optional: Full Network Reset (Windows 10)

Go to:

```
Settings → Network & Internet → Status → Network Reset
```

⚠ This removes all network adapters and reinstalls them.

---

# 📎 System Example

```
OS: Windows 10 x64
Adapter: Realtek PCIe GbE Family Controller
Driver: 10.56.119.2022
Architecture: x64
```
