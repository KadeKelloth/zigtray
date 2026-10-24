# zigtray

Lightweight, zero-dependency Windows system tray library for Zig (0.17+).

## Features

- **Zero dependencies**: direct Win32 API bindings (`user32`, `shell32`, `gdi32`), no libc or external C wrappers required.
- **Icon support**: load `.ico` from disk, pass raw `HICON`, or use the default executable icon.
- **Context menus**: items with actions, toggle checks, separators, and 32-bit PARGB icons.
- **Taskbar recovery**: automatically restores the tray icon if `explorer.exe` restarts (`TaskbarCreated`).
- **Callbacks**: click and double-click handlers.
- **Tooltips & notifications**: native hover tooltips and balloon notifications.
- **Event loops**: blocking (`tray.run()`) or poll-based (`tray.step()`) for games and custom message loops.
- **Unicode**: proper UTF-8 to UTF-16 conversion.

## Requirements

- Zig `0.17.0` or newer
- Target OS: Windows

## Installation

Add to your project:

```bash
zig fetch --save https://github.com/KadeKelloth/zigtray/archive/refs/tags/v0.1.0.tar.gz
```

Or add directly to `build.zig.zon`:

```zig
.dependencies = .{
    .zigtray = .{
        .url = "https://github.com/KadeKelloth/zigtray/archive/refs/tags/v0.1.0.tar.gz",
        .hash = "N-V-__8AAKh1AABuYVG5jljOsRN7SXy8ZFL_HOXs_HVck4rX",
    },
},
```

In your `build.zig`:

```zig
const zigtray = b.dependency("zigtray", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("zigtray", zigtray.module("zigtray"));
```

## Quick Start

```zig
const std = @import("std");
const zigtray = @import("zigtray");

fn onHello(t: *zigtray.Tray) void {
    t.showNotification("zigtray", "Notification from tray!");
}

fn onExit(t: *zigtray.Tray) void {
    t.stop();
}

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;

    var tray = try zigtray.Tray.init(gpa, .{
        .tooltip = "My App",
        .icon = .default,
    });
    defer tray.deinit();

    var menu: zigtray.Menu = .empty;
    try menu.add(gpa, .{
        .id = 1,
        .text = "Show Notification",
        .action = onHello,
        .icon = .default,
    });
    try menu.addSeparator(gpa);
    try menu.add(gpa, .{
        .id = 2,
        .text = "Exit",
        .action = onExit,
    });

    tray.setMenu(menu);
    tray.run();
}
```

### Non-blocking Loop

If you run your own main loop (e.g. game engine or renderer):

```zig
while (tray.step()) {
    // your frame update / render logic
}
```

## License

MIT
