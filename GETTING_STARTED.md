# Getting Started with xbdm_gdb_bridge

This guide will help you set up xbdm_gdb_bridge to debug Xbox games running in xemu.

## Prerequisites

Before you begin, make sure you have:

- [ ] **Windows 10/11** with WSL2 installed
- [ ] **xemu** installed and configured
- [ ] **Debug BIOS** for xemu (required for XBDM to work)
- [ ] **xbdm.dll** on your xemu hard drive image (E:\xbdm.dll)
- [ ] xemu set to **Bridged Adapter** networking mode

### Installing WSL (if not already installed)

Open PowerShell as Administrator and run:
```powershell
wsl --install
```
Restart your computer when prompted.

### xemu Network Setup

1. Open xemu
2. Go to **Machine → Settings → Network**
3. Select **Bridged Adapter**
4. Choose your physical network adapter
5. Note the IP address shown in the Xbox dashboard (you'll need this)

## Quick Setup

### Step 1: Run the Setup Wizard

Open PowerShell in the xbdm_gdb_bridge folder and run:

```powershell
.\setup.ps1
```

The wizard will:
- Check that WSL is installed
- Ask for your xemu's IP address
- Test the connection
- Save your configuration

### Step 2: Connect

After setup, you can connect using any of these methods:

**Option A: Double-click `xbdm.bat`**

**Option B: From WSL terminal**
```bash
cd /mnt/c/path/to/xbdm_gdb_bridge
./xbdm
```

**Option C: Run a single command**
```bash
./xbdm -- dmversion
```

## Basic Usage

Once connected, you'll see the xbdm_gdb_bridge shell prompt. Type `?` to see all available commands.

### Common Commands

| Command | Description |
|---------|-------------|
| `?` | List all commands |
| `dmversion` | Show XBDM version |
| `drivelist` | List available drives |
| `ls e:\` | List files on E: drive |
| `/threads` | List threads (requires debugger) |
| `/halt` | Halt execution |
| `/continueall` | Resume execution |
| `reboot` | Reboot the Xbox |
| `screenshot` | Capture screen |
| `quit` | Exit the shell |

### GDB Debugging

To debug with GDB:

```bash
# Terminal 1: Start the bridge with GDB server
./xbdm -s -- gdb :1999

# Terminal 2: Connect GDB
gdb ./your_program.exe
(gdb) target remote 127.0.0.1:1999
(gdb) break main
(gdb) continue
```

### File Transfer

Upload a file to Xbox:
```
putfile local_file.xbe e:\games\myapp -f
```

Download a file from Xbox:
```
getfile e:\games\save.dat ./save.dat
```

## Windows Native Applications (Relay)

Windows applications (like Assembly, custom debuggers, etc.) cannot directly connect to xemu's bridged IP address. The relay solves this problem.

### Why is this needed?

When xemu uses bridged networking on the same PC, there's a Windows networking limitation:
- Windows cannot route traffic to devices on its own bridged network interface
- WSL (Windows Subsystem for Linux) has a separate network stack and CAN reach xemu
- The relay creates a bridge: Windows app -> WSL -> xemu

Here's how traffic flows:

```
Your Windows App          WSL (Linux)              xemu
      |                       |                      |
      |  connect to           |                      |
      |  127.0.0.1:731        |                      |
      |---------------------> |                      |
      |  (netsh portproxy)    |                      |
      |                       |  forward to          |
      |                       |  192.168.x.x:731     |
      |                       |--------------------> |
      |                       |      (socat)         |
```

### Starting the Relay

**Right-click `relay.bat` and select "Run as administrator"**

The relay requires administrator privileges to set up Windows port forwarding. This is a one-time setup per session - no passwords or WSL root access needed.

Keep the relay window open while using your Windows tools.

### Connecting Your Windows Applications

Once the relay is running, configure your Windows apps with:

| Setting | Value |
|---------|-------|
| **IP Address** | `127.0.0.1` |
| **Port** | `731` |

That's it! The relay handles all the routing automatically. You always use `127.0.0.1:731` regardless of xemu's actual IP.

### Application-Specific Notes

**Assembly (Halo modding tool):**
- Go to Settings and set the Xbox IP to `127.0.0.1`
- Make sure "I Don't Own An OG Xbox" is **unchecked** (this forces Xbox 360 mode which uses a different port)

### Check Relay Status

```cmd
relay.bat --status
```

This shows whether the relay is running and the current port forwarding rules.

### Stopping the Relay

Close the relay window, or press `Ctrl+C` in it. The port forwarding rules are automatically cleaned up.

## Troubleshooting

### "Connection refused" or timeout

1. **Is xemu running?** - Start xemu first
2. **Is XBDM loaded?** - You need a debug BIOS
3. **Check the IP** - Verify xemu's IP in the Xbox dashboard
4. **Network mode** - Must be "Bridged Adapter", not NAT

### "WSL not installed"

Run these commands in PowerShell (as Administrator):
```powershell
wsl --install
```
Then restart your computer.

### Can ping but can't connect to port 731

This usually means xemu doesn't have XBDM running:
- Make sure you're using a **debug BIOS**
- Verify **xbdm.dll** exists at E:\xbdm.dll in your HDD image

### Windows can't ping xemu but WSL can

This is normal! Windows host cannot directly reach devices on its own bridged interface. That's why we run the bridge from WSL.

### "Binary not found"

The Linux binary `xbdm_gdb_bridge_linux` must be in the same directory. Either:
- Download a release from GitHub
- Build from source (see README.md)

## Configuration

Your settings are stored in `xbdm_config.ini`:

```ini
[connection]
xbox_ip = 192.168.1.77
xbdm_port = 731

[gdb]
default_port = 1999

[options]
verbosity = 0
```

Edit this file to change your Xbox IP or other settings.

## Tips

- **Keep xemu running** before connecting
- **Use bridged networking** - NAT mode won't work for layer 2 access
- **The `-s` flag** keeps the shell open after running initial commands
- **Type `?`** in the shell to see all available commands
- **Type `? <command>`** to get help on a specific command

## More Information

- Full documentation: [README.md](README.md)
- XBDM protocol: https://xboxdevwiki.net/Xbox_Debug_Monitor
- xemu website: https://xemu.app
