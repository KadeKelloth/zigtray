const std = @import("std");
const win32 = @import("win32.zig");

const WM_TRAY: win32.UINT = win32.WM_APP + 1;
const WND_CLASS = std.unicode.utf8ToUtf16LeStringLiteral("zigtray_wnd");
const TASKBAR_CREATED = std.unicode.utf8ToUtf16LeStringLiteral("TaskbarCreated");

pub const Icon = union(enum) {
    default,
    handle: win32.HICON,
    path: []const u8,
};

pub const MenuItem = struct {
    id: u16,
    text: []const u8 = "",
    action: ?*const fn (tray: *Tray) void = null,
    icon: ?Icon = null,
    enabled: bool = true,
    checked: bool = false,
    separator: bool = false,
    cached_bitmap: ?win32.HBITMAP = null,
};

pub const Menu = struct {
    items: std.ArrayList(MenuItem),

    pub const empty: Menu = .{ .items = .empty };

    pub fn deinit(self: *Menu, gpa: std.mem.Allocator) void {
        for (self.items.items) |it| {
            if (it.cached_bitmap) |bm| _ = win32.DeleteObject(@ptrCast(bm));
        }
        self.items.deinit(gpa);
    }

    pub fn add(self: *Menu, gpa: std.mem.Allocator, it: MenuItem) !void {
        try self.items.append(gpa, it);
    }

    pub fn addSeparator(self: *Menu, gpa: std.mem.Allocator) !void {
        try self.items.append(gpa, .{ .id = 0, .separator = true });
    }
};

pub const Options = struct {
    tooltip: []const u8 = "zigtray",
    icon: Icon = .default,
    dark_mode: bool = true,
    on_click: ?*const fn (tray: *Tray) void = null,
    on_double_click: ?*const fn (tray: *Tray) void = null,
};

pub const Error = error{
    WindowCreationFailed,
    TrayRegistrationFailed,
    IconLoadFailed,
    OutOfMemory,
};

pub const Tray = struct {
    alloc: std.mem.Allocator,
    hwnd: win32.HWND,
    hinst: ?win32.HINSTANCE,
    hicon: ?win32.HICON,
    icon_owned: bool,
    menu: ?Menu,
    running: bool,
    wm_taskbar_created: win32.UINT,
    nid: win32.NOTIFYICONDATAW,
    on_click: ?*const fn (tray: *Tray) void,
    on_dbl_click: ?*const fn (tray: *Tray) void,

    pub fn init(alloc: std.mem.Allocator, opts: Options) Error!*Tray {
        const hinst = win32.GetModuleHandleW(null);
        var wc: win32.WNDCLASSEXW = .{
            .lpfnWndProc = wndProc,
            .hInstance = hinst,
            .lpszClassName = WND_CLASS,
        };
        _ = win32.RegisterClassExW(&wc);

        const hwnd = win32.CreateWindowExW(
            0,
            WND_CLASS,
            null,
            win32.WS_OVERLAPPED,
            0, 0, 0, 0,
            null, null, hinst, null,
        ) orelse return Error.WindowCreationFailed;

        const self = alloc.create(Tray) catch {
            _ = win32.DestroyWindow(hwnd);
            return Error.OutOfMemory;
        };

        var ico: ?win32.HICON = null;
        var owned = false;

        switch (opts.icon) {
            .default => ico = win32.LoadIconW(null, win32.IDI_APPLICATION),
            .handle => |h| ico = h,
            .path => |p| {
                var p_w: [260]win32.WCHAR = undefined;
                utf8ToWideZ(&p_w, p);
                const raw = win32.LoadImageW(null, &p_w, win32.IMAGE_ICON, 0, 0, win32.LR_LOADFROMFILE | win32.LR_DEFAULTSIZE);
                if (raw) |img| {
                    ico = @ptrCast(img);
                    owned = true;
                } else {
                    ico = win32.LoadIconW(null, win32.IDI_APPLICATION);
                }
            },
        }

        self.* = .{
            .alloc = alloc,
            .hwnd = hwnd,
            .hinst = hinst,
            .hicon = ico,
            .icon_owned = owned,
            .menu = null,
            .running = true,
            .wm_taskbar_created = win32.RegisterWindowMessageW(TASKBAR_CREATED),
            .nid = .{
                .cbSize = @sizeOf(win32.NOTIFYICONDATAW),
                .hWnd = hwnd,
                .uID = 1,
                .uFlags = win32.NIF_MESSAGE | win32.NIF_ICON | win32.NIF_TIP | win32.NIF_SHOWTIP,
                .uCallbackMessage = WM_TRAY,
                .hIcon = ico,
                .uTimeoutOrVersion = win32.NOTIFYICON_VERSION_4,
            },
            .on_click = opts.on_click,
            .on_dbl_click = opts.on_double_click,
        };

        utf8ToWideZ(&self.nid.szTip, opts.tooltip);
        _ = win32.SetWindowLongPtrW(hwnd, win32.GWLP_USERDATA, @intCast(@intFromPtr(self)));

        if (opts.dark_mode) {
            self.setDarkMode(true);
        }

        var ok = false;
        var retries: u32 = 0;
        while (retries < 6) : (retries += 1) {
            if (win32.Shell_NotifyIconW(win32.NIM_ADD, &self.nid) == win32.TRUE) {
                ok = true;
                break;
            }
            win32.Sleep(100);
        }

        if (!ok) {
            _ = win32.DestroyWindow(hwnd);
            if (owned and ico != null) _ = win32.DestroyIcon(ico.?);
            alloc.destroy(self);
            return Error.TrayRegistrationFailed;
        }

        self.nid.uTimeoutOrVersion = win32.NOTIFYICON_VERSION_4;
        _ = win32.Shell_NotifyIconW(win32.NIM_SETVERSION, &self.nid);

        return self;
    }

    pub fn deinit(self: *Tray) void {
        _ = win32.Shell_NotifyIconW(win32.NIM_DELETE, &self.nid);
        _ = win32.DestroyWindow(self.hwnd);
        if (self.icon_owned and self.hicon != null) _ = win32.DestroyIcon(self.hicon.?);
        if (self.menu) |*m| m.deinit(self.alloc);
        self.alloc.destroy(self);
    }

    pub fn setMenu(self: *Tray, m: Menu) void {
        for (m.items.items) |*it| {
            if (it.icon) |ic| {
                it.cached_bitmap = makeMenuBitmap(ic);
            }
        }
        if (self.menu) |*cur| cur.deinit(self.alloc);
        self.menu = m;
    }

    pub fn setTooltip(self: *Tray, txt: []const u8) void {
        utf8ToWideZ(&self.nid.szTip, txt);
        self.nid.uFlags = win32.NIF_TIP | win32.NIF_SHOWTIP;
        _ = win32.Shell_NotifyIconW(win32.NIM_MODIFY, &self.nid);
        self.nid.uFlags = win32.NIF_MESSAGE | win32.NIF_ICON | win32.NIF_TIP | win32.NIF_SHOWTIP;
    }

    pub fn setIcon(self: *Tray, ic: Icon) void {
        if (self.icon_owned and self.hicon != null) {
            _ = win32.DestroyIcon(self.hicon.?);
            self.icon_owned = false;
        }

        switch (ic) {
            .default => self.hicon = win32.LoadIconW(null, win32.IDI_APPLICATION),
            .handle => |h| self.hicon = h,
            .path => |p| {
                var p_w: [260]win32.WCHAR = undefined;
                utf8ToWideZ(&p_w, p);
                const raw = win32.LoadImageW(null, &p_w, win32.IMAGE_ICON, 0, 0, win32.LR_LOADFROMFILE | win32.LR_DEFAULTSIZE);
                if (raw) |img| {
                    self.hicon = @ptrCast(img);
                    self.icon_owned = true;
                }
            },
        }

        self.nid.hIcon = self.hicon;
        self.nid.uFlags = win32.NIF_ICON;
        _ = win32.Shell_NotifyIconW(win32.NIM_MODIFY, &self.nid);
        self.nid.uFlags = win32.NIF_MESSAGE | win32.NIF_ICON | win32.NIF_TIP | win32.NIF_SHOWTIP;
    }

    pub fn showNotification(self: *Tray, title: []const u8, body: []const u8) void {
        utf8ToWideZ(&self.nid.szInfoTitle, title);
        utf8ToWideZ(&self.nid.szInfo, body);
        self.nid.uFlags = win32.NIF_INFO;
        self.nid.dwInfoFlags = win32.NIIF_INFO;
        _ = win32.Shell_NotifyIconW(win32.NIM_MODIFY, &self.nid);
        self.nid.uFlags = win32.NIF_MESSAGE | win32.NIF_ICON | win32.NIF_TIP | win32.NIF_SHOWTIP;
    }

    pub fn step(self: *Tray) bool {
        var msg: win32.MSG = undefined;
        while (win32.PeekMessageW(&msg, null, 0, 0, win32.PM_REMOVE) != 0) {
            if (msg.message == win32.WM_QUIT) {
                self.running = false;
                return false;
            }
            _ = win32.TranslateMessage(&msg);
            _ = win32.DispatchMessageW(&msg);
        }
        return self.running;
    }

    pub fn run(self: *Tray) void {
        self.running = true;
        var msg: win32.MSG = undefined;
        while (self.running and win32.GetMessageW(&msg, null, 0, 0) > 0) {
            _ = win32.TranslateMessage(&msg);
            _ = win32.DispatchMessageW(&msg);
        }
        self.running = false;
    }

    pub fn stop(self: *Tray) void {
        self.running = false;
        win32.PostQuitMessage(0);
    }

    pub fn setDarkMode(self: *Tray, enable: bool) void {
        const uxtheme_dll = std.unicode.utf8ToUtf16LeStringLiteral("uxtheme.dll");
        const h = win32.LoadLibraryW(uxtheme_dll) orelse return;

        if (win32.GetProcAddress(h, @as([*:0]const u8, @ptrFromInt(135)))) |proc| {
            const set_app_mode: *const fn (mode: i32) callconv(.winapi) i32 = @ptrCast(proc);
            _ = set_app_mode(if (enable) 1 else 0);
        }
        if (win32.GetProcAddress(h, @as([*:0]const u8, @ptrFromInt(133)))) |proc| {
            const allow_wnd: *const fn (wnd: win32.HWND, allow: win32.BOOL) callconv(.winapi) win32.BOOL = @ptrCast(proc);
            _ = allow_wnd(self.hwnd, if (enable) win32.TRUE else win32.FALSE);
        }
        if (win32.GetProcAddress(h, @as([*:0]const u8, @ptrFromInt(136)))) |proc| {
            const flush_menus: *const fn () callconv(.winapi) void = @ptrCast(proc);
            flush_menus();
        }
    }

    fn popupMenu(self: *Tray, x: i32, y: i32) void {
        const m = self.menu orelse return;
        if (m.items.items.len == 0) return;

        var pt: win32.POINT = .{ .x = x, .y = y };
        if (x == 0 and y == 0) {
            _ = win32.GetCursorPos(&pt);
        }
        _ = win32.SetForegroundWindow(self.hwnd);

        const hmenu = win32.CreatePopupMenu() orelse return;
        defer _ = win32.DestroyMenu(hmenu);

        var label_w: [256]win32.WCHAR = undefined;
        for (m.items.items, 0..) |it, idx| {
            if (it.separator) {
                var mii: win32.MENUITEMINFOW = .{
                    .fMask = win32.MIIM_FTYPE,
                    .fType = win32.MFT_SEPARATOR,
                };
                _ = win32.InsertMenuItemW(hmenu, @intCast(idx), win32.TRUE, &mii);
                continue;
            }

            utf8ToWideZ(&label_w, it.text);

            var mask: win32.UINT = win32.MIIM_ID | win32.MIIM_STRING | win32.MIIM_STATE;
            var state: win32.UINT = if (it.enabled) win32.MFS_ENABLED else win32.MFS_DISABLED;
            if (it.checked) state |= win32.MFS_CHECKED;

            if (it.cached_bitmap != null) {
                mask |= win32.MIIM_BITMAP;
            }

            var mii: win32.MENUITEMINFOW = .{
                .fMask = mask,
                .fState = state,
                .wID = it.id,
                .dwTypeData = &label_w,
                .hbmpItem = it.cached_bitmap,
            };
            _ = win32.InsertMenuItemW(hmenu, @intCast(idx), win32.TRUE, &mii);
        }

        const cmd = win32.TrackPopupMenu(hmenu, win32.TPM_RIGHTBUTTON | win32.TPM_RETURNCMD, pt.x, pt.y, 0, self.hwnd, null);
        _ = win32.PostMessageW(self.hwnd, win32.WM_NULL, 0, 0);

        if (cmd > 0) {
            const picked_id: u16 = @truncate(@as(u32, @bitCast(cmd)));
            for (m.items.items) |it| {
                if (it.id == picked_id) {
                    if (it.action) |act| act(self);
                    break;
                }
            }
        }
    }
};

fn makeMenuBitmap(ic: Icon) ?win32.HBITMAP {
    var temp_icon_owned = false;
    const hico: win32.HICON = switch (ic) {
        .default => win32.LoadIconW(null, win32.IDI_APPLICATION) orelse return null,
        .handle => |h| h,
        .path => |p| blk: {
            var p_w: [260]win32.WCHAR = undefined;
            utf8ToWideZ(&p_w, p);
            const raw = win32.LoadImageW(
                null,
                &p_w,
                win32.IMAGE_ICON,
                win32.GetSystemMetrics(win32.SM_CXSMICON),
                win32.GetSystemMetrics(win32.SM_CYSMICON),
                win32.LR_LOADFROMFILE,
            ) orelse return null;
            temp_icon_owned = true;
            break :blk @ptrCast(raw);
        },
    };
    defer if (temp_icon_owned) {
        _ = win32.DestroyIcon(hico);
    };

    const cx = win32.GetSystemMetrics(win32.SM_CXSMICON);
    const cy = win32.GetSystemMetrics(win32.SM_CYSMICON);

    const hdc_scr = win32.GetDC(null) orelse return null;
    defer _ = win32.ReleaseDC(null, hdc_scr);

    const hdc_mem = win32.CreateCompatibleDC(hdc_scr) orelse return null;
    defer _ = win32.DeleteDC(hdc_mem);

    var bmi: win32.BITMAPINFO = .{
        .bmiHeader = .{ .biWidth = cx, .biHeight = cy },
    };

    var bits: ?*anyopaque = null;
    const hbm = win32.CreateDIBSection(hdc_scr, &bmi, win32.DIB_RGB_COLORS, &bits, null, 0) orelse return null;

    const old_obj = win32.SelectObject(hdc_mem, @ptrCast(hbm));
    defer _ = win32.SelectObject(hdc_mem, old_obj);

    _ = win32.DrawIconEx(hdc_mem, 0, 0, hico, cx, cy, 0, null, win32.DI_NORMAL);

    if (bits) |raw| {
        const total: usize = @intCast(cx * cy);
        const px: [*][4]u8 = @ptrCast(@alignCast(raw));
        var has_alpha = false;
        for (0..total) |i| {
            if (px[i][3] != 0) {
                has_alpha = true;
                break;
            }
        }
        if (!has_alpha) {
            for (0..total) |i| {
                if (px[i][0] != 0 or px[i][1] != 0 or px[i][2] != 0) px[i][3] = 255;
            }
        }
    }

    return hbm;
}

fn wndProc(hwnd: ?win32.HWND, msg: win32.UINT, wp: win32.WPARAM, lp: win32.LPARAM) callconv(.winapi) win32.LRESULT {
    const raw = win32.GetWindowLongPtrW(hwnd, win32.GWLP_USERDATA);
    if (raw == 0) return win32.DefWindowProcW(hwnd, msg, wp, lp);

    const self: *Tray = @ptrFromInt(@as(usize, @intCast(raw)));

    if (msg == self.wm_taskbar_created and self.wm_taskbar_created != 0) {
        if (win32.Shell_NotifyIconW(win32.NIM_ADD, &self.nid) == win32.TRUE) {
            self.nid.uTimeoutOrVersion = win32.NOTIFYICON_VERSION_4;
            _ = win32.Shell_NotifyIconW(win32.NIM_SETVERSION, &self.nid);
        }
        return 0;
    }

    switch (msg) {
        WM_TRAY => {
            const ev: u16 = @truncate(@as(usize, @bitCast(lp)));
            const pt_x: i32 = @as(i16, @truncate(@as(isize, @bitCast(wp))));
            const pt_y: i32 = @as(i16, @truncate(@as(isize, @bitCast(wp >> 16))));
            switch (ev) {
                win32.NIN_SELECT, win32.NIN_KEYSELECT, win32.WM_LBUTTONUP => if (self.on_click) |cb| cb(self),
                win32.WM_LBUTTONDBLCLK => if (self.on_dbl_click) |cb| cb(self),
                win32.WM_CONTEXTMENU, win32.WM_RBUTTONUP => self.popupMenu(pt_x, pt_y),
                else => {},
            }
            return 0;
        },
        win32.WM_DESTROY => {
            win32.PostQuitMessage(0);
            return 0;
        },
        else => return win32.DefWindowProcW(hwnd, msg, wp, lp),
    }
}

pub fn utf8ToWideZ(dst: []win32.WCHAR, src: []const u8) void {
    if (dst.len == 0) return;
    const max_len = dst.len - 1;
    var written: usize = 0;
    var v = std.unicode.Utf8View.init(src) catch {
        dst[0] = 0;
        return;
    };
    var it = v.iterator();
    while (it.nextCodepointSlice()) |slice| {
        var tmp: [2]u16 = undefined;
        const n = std.unicode.utf8ToUtf16Le(&tmp, slice) catch break;
        if (written + n > max_len) break;
        @memcpy(dst[written .. written + n], tmp[0..n]);
        written += n;
    }
    dst[written] = 0;
}
