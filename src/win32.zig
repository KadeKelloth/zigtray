pub const HWND = *opaque {};
pub const HINSTANCE = *opaque {};
pub const HICON = *opaque {};
pub const HMENU = *opaque {};
pub const HCURSOR = *opaque {};
pub const HBRUSH = *opaque {};
pub const HBITMAP = *opaque {};
pub const HDC = *opaque {};
pub const HGDIOBJ = *opaque {};
pub const HANDLE = *opaque {};
pub const LRESULT = isize;
pub const WPARAM = usize;
pub const LPARAM = isize;
pub const BOOL = i32;
pub const DWORD = u32;
pub const UINT = u32;
pub const WCHAR = u16;
pub const ATOM = u16;

pub const TRUE: BOOL = 1;
pub const FALSE: BOOL = 0;

pub const POINT = extern struct {
    x: i32,
    y: i32,
};

pub const MSG = extern struct {
    hwnd: ?HWND,
    message: UINT,
    wParam: WPARAM,
    lParam: LPARAM,
    time: DWORD,
    pt: POINT,
};

pub const CREATESTRUCTW = extern struct {
    lpCreateParams: ?*anyopaque,
    hInstance: ?HINSTANCE,
    hMenu: ?HMENU,
    hwndParent: ?HWND,
    cy: i32,
    cx: i32,
    y: i32,
    x: i32,
    style: i32,
    lpszName: ?[*:0]const WCHAR,
    lpszClass: ?[*:0]const WCHAR,
    dwExStyle: DWORD,
};

pub const WNDPROC = *const fn (hwnd: ?HWND, msg: UINT, wparam: WPARAM, lparam: LPARAM) callconv(.winapi) LRESULT;

pub const WNDCLASSEXW = extern struct {
    cbSize: UINT = @sizeOf(WNDCLASSEXW),
    style: UINT = 0,
    lpfnWndProc: WNDPROC,
    cbClsExtra: i32 = 0,
    cbWndExtra: i32 = 0,
    hInstance: ?HINSTANCE,
    hIcon: ?HICON = null,
    hCursor: ?HCURSOR = null,
    hbrBackground: ?HBRUSH = null,
    lpszMenuName: ?[*:0]const WCHAR = null,
    lpszClassName: [*:0]const WCHAR,
    hIconSm: ?HICON = null,
};

pub const NOTIFYICONDATAW = extern struct {
    cbSize: DWORD = @sizeOf(NOTIFYICONDATAW),
    hWnd: ?HWND = null,
    uID: UINT = 0,
    uFlags: UINT = 0,
    uCallbackMessage: UINT = 0,
    hIcon: ?HICON = null,
    szTip: [128]WCHAR = @splat(0),
    dwState: DWORD = 0,
    dwStateMask: DWORD = 0,
    szInfo: [256]WCHAR = @splat(0),
    uTimeoutOrVersion: UINT = 0,
    szInfoTitle: [64]WCHAR = @splat(0),
    dwInfoFlags: DWORD = 0,
};

pub const BITMAPINFOHEADER = extern struct {
    biSize: DWORD = @sizeOf(BITMAPINFOHEADER),
    biWidth: i32,
    biHeight: i32,
    biPlanes: u16 = 1,
    biBitCount: u16 = 32,
    biCompression: DWORD = 0,
    biSizeImage: DWORD = 0,
    biXPelsPerMeter: i32 = 0,
    biYPelsPerMeter: i32 = 0,
    biClrUsed: DWORD = 0,
    biClrImportant: DWORD = 0,
};

pub const RGBQUAD = extern struct {
    rgbBlue: u8 = 0,
    rgbGreen: u8 = 0,
    rgbRed: u8 = 0,
    rgbReserved: u8 = 0,
};

pub const BITMAPINFO = extern struct {
    bmiHeader: BITMAPINFOHEADER,
    bmiColors: [1]RGBQUAD = .{.{}},
};

pub const MENUITEMINFOW = extern struct {
    cbSize: UINT = @sizeOf(MENUITEMINFOW),
    fMask: UINT = 0,
    fType: UINT = 0,
    fState: UINT = 0,
    wID: UINT = 0,
    hSubMenu: ?HMENU = null,
    hbmpChecked: ?HBITMAP = null,
    hbmpUnchecked: ?HBITMAP = null,
    dwItemData: usize = 0,
    dwTypeData: ?[*]const WCHAR = null,
    cch: UINT = 0,
    hbmpItem: ?HBITMAP = null,
};

pub const NIM_ADD: DWORD = 0x00000000;
pub const NIM_MODIFY: DWORD = 0x00000001;
pub const NIM_DELETE: DWORD = 0x00000002;
pub const NIM_SETFOCUS: DWORD = 0x00000003;
pub const NIM_SETVERSION: DWORD = 0x00000004;

pub const NOTIFYICON_VERSION_4: UINT = 4;

pub const NIF_MESSAGE: UINT = 0x00000001;
pub const NIF_ICON: UINT = 0x00000002;
pub const NIF_TIP: UINT = 0x00000004;
pub const NIF_STATE: UINT = 0x00000008;
pub const NIF_INFO: UINT = 0x00000010;
pub const NIF_SHOWTIP: UINT = 0x00000080;

pub const NIIF_NONE: DWORD = 0x00000000;
pub const NIIF_INFO: DWORD = 0x00000001;
pub const NIIF_WARNING: DWORD = 0x00000002;
pub const NIIF_ERROR: DWORD = 0x00000003;
pub const NIIF_USER: DWORD = 0x00000004;
pub const NIIF_NOSOUND: DWORD = 0x00000010;
pub const NIIF_LARGE_ICON: DWORD = 0x00000020;

pub const WM_NULL: UINT = 0x0000;
pub const WM_CREATE: UINT = 0x0001;
pub const WM_DESTROY: UINT = 0x0002;
pub const WM_CLOSE: UINT = 0x0010;
pub const WM_QUIT: UINT = 0x0012;
pub const WM_COMMAND: UINT = 0x0111;
pub const WM_USER: UINT = 0x0400;
pub const WM_APP: UINT = 0x8000;

pub const NIN_SELECT: UINT = WM_USER + 0;
pub const NIN_KEYSELECT: UINT = WM_USER + 1;
pub const NIN_BALLOONSHOW: UINT = WM_USER + 2;
pub const NIN_BALLOONHIDE: UINT = WM_USER + 3;
pub const NIN_BALLOONTIMEOUT: UINT = WM_USER + 4;
pub const NIN_BALLOONUSERCLICK: UINT = WM_USER + 5;
pub const NIN_POPUPOPEN: UINT = WM_USER + 6;
pub const NIN_POPUPCLOSE: UINT = WM_USER + 7;

pub const WM_LBUTTONUP: UINT = 0x0202;
pub const WM_LBUTTONDBLCLK: UINT = 0x0203;
pub const WM_RBUTTONUP: UINT = 0x0205;
pub const WM_CONTEXTMENU: UINT = 0x007B;

pub const WS_OVERLAPPED: DWORD = 0x00000000;
pub const WS_POPUP: DWORD = 0x80000000;
pub const CW_USEDEFAULT: i32 = @as(i32, @bitCast(@as(u32, 0x80000000)));

pub const TPM_RIGHTBUTTON: UINT = 0x0002;
pub const TPM_RETURNCMD: UINT = 0x0100;

pub const MF_STRING: UINT = 0x00000000;
pub const MF_GRAYED: UINT = 0x00000001;
pub const MF_DISABLED: UINT = 0x00000002;
pub const MF_CHECKED: UINT = 0x00000008;
pub const MF_SEPARATOR: UINT = 0x00000800;

pub const MIIM_STATE: UINT = 0x00000001;
pub const MIIM_ID: UINT = 0x00000002;
pub const MIIM_SUBMENU: UINT = 0x00000004;
pub const MIIM_CHECKMARKS: UINT = 0x00000008;
pub const MIIM_TYPE: UINT = 0x00000010;
pub const MIIM_DATA: UINT = 0x00000020;
pub const MIIM_STRING: UINT = 0x00000040;
pub const MIIM_BITMAP: UINT = 0x00000080;
pub const MIIM_FTYPE: UINT = 0x00000100;

pub const MFT_STRING: UINT = 0x00000000;
pub const MFT_SEPARATOR: UINT = 0x00000800;

pub const MFS_ENABLED: UINT = 0x00000000;
pub const MFS_DISABLED: UINT = 0x00000003;
pub const MFS_CHECKED: UINT = 0x00000008;
pub const MFS_UNCHECKED: UINT = 0x00000000;

pub const SM_CXSMICON: i32 = 49;
pub const SM_CYSMICON: i32 = 50;
pub const DIB_RGB_COLORS: UINT = 0;
pub const DI_NORMAL: UINT = 0x0003;

pub const IDI_APPLICATION: ?[*:0]const WCHAR = @as(?[*:0]const WCHAR, @ptrFromInt(32512));
pub const IMAGE_ICON: UINT = 1;
pub const LR_LOADFROMFILE: UINT = 0x00000010;
pub const LR_DEFAULTSIZE: UINT = 0x00000040;

pub const GWLP_USERDATA: i32 = -21;
pub const PM_REMOVE: UINT = 0x0001;

pub extern "shell32" fn Shell_NotifyIconW(dwMessage: DWORD, lpData: *NOTIFYICONDATAW) callconv(.winapi) BOOL;

pub extern "user32" fn RegisterClassExW(lpwcx: *const WNDCLASSEXW) callconv(.winapi) ATOM;
pub extern "user32" fn UnregisterClassW(lpClassName: [*:0]const WCHAR, hInstance: ?HINSTANCE) callconv(.winapi) BOOL;
pub extern "user32" fn CreateWindowExW(
    dwExStyle: DWORD,
    lpClassName: [*:0]const WCHAR,
    lpWindowName: ?[*:0]const WCHAR,
    dwStyle: DWORD,
    X: i32,
    Y: i32,
    nWidth: i32,
    nHeight: i32,
    hWndParent: ?HWND,
    hMenu: ?HMENU,
    hInstance: ?HINSTANCE,
    lpParam: ?*anyopaque,
) callconv(.winapi) ?HWND;
pub extern "user32" fn DefWindowProcW(hWnd: ?HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(.winapi) LRESULT;
pub extern "user32" fn DestroyWindow(hWnd: ?HWND) callconv(.winapi) BOOL;
pub extern "user32" fn GetMessageW(lpMsg: *MSG, hWnd: ?HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT) callconv(.winapi) BOOL;
pub extern "user32" fn PeekMessageW(lpMsg: *MSG, hWnd: ?HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT, wRemoveMsg: UINT) callconv(.winapi) BOOL;
pub extern "user32" fn TranslateMessage(lpMsg: *const MSG) callconv(.winapi) BOOL;
pub extern "user32" fn DispatchMessageW(lpMsg: *const MSG) callconv(.winapi) LRESULT;
pub extern "user32" fn PostQuitMessage(nExitCode: i32) callconv(.winapi) void;
pub extern "user32" fn PostMessageW(hWnd: ?HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(.winapi) BOOL;
pub extern "user32" fn SetForegroundWindow(hWnd: ?HWND) callconv(.winapi) BOOL;
pub extern "user32" fn GetCursorPos(lpPoint: *POINT) callconv(.winapi) BOOL;
pub extern "user32" fn CreatePopupMenu() callconv(.winapi) ?HMENU;
pub extern "user32" fn DestroyMenu(hMenu: ?HMENU) callconv(.winapi) BOOL;
pub extern "user32" fn AppendMenuW(hMenu: ?HMENU, uFlags: UINT, uIDNewItem: usize, lpNewItem: ?[*]const WCHAR) callconv(.winapi) BOOL;
pub extern "user32" fn TrackPopupMenu(hMenu: ?HMENU, uFlags: UINT, x: i32, y: i32, nReserved: i32, hWnd: ?HWND, prcRect: ?*anyopaque) callconv(.winapi) BOOL;
pub extern "user32" fn LoadIconW(hInstance: ?HINSTANCE, lpIconName: ?[*:0]const WCHAR) callconv(.winapi) ?HICON;
pub extern "user32" fn LoadImageW(hInst: ?HINSTANCE, name: ?[*]const WCHAR, type_: UINT, cx: i32, cy: i32, fuLoad: UINT) callconv(.winapi) ?*anyopaque;
pub extern "user32" fn DestroyIcon(hIcon: ?HICON) callconv(.winapi) BOOL;
pub extern "user32" fn SetWindowLongPtrW(hWnd: ?HWND, nIndex: i32, dwNewLong: isize) callconv(.winapi) isize;
pub extern "user32" fn GetWindowLongPtrW(hWnd: ?HWND, nIndex: i32) callconv(.winapi) isize;
pub extern "user32" fn RegisterWindowMessageW(lpString: [*:0]const WCHAR) callconv(.winapi) UINT;

pub extern "user32" fn IsWindow(hWnd: ?HWND) callconv(.winapi) BOOL;
pub extern "user32" fn GetDC(hWnd: ?HWND) callconv(.winapi) ?HDC;
pub extern "user32" fn ReleaseDC(hWnd: ?HWND, hDC: ?HDC) callconv(.winapi) i32;
pub extern "user32" fn GetSystemMetrics(nIndex: i32) callconv(.winapi) i32;
pub extern "user32" fn DrawIconEx(hdc: ?HDC, xLeft: i32, yTop: i32, hIcon: ?HICON, cxWidth: i32, cyWidth: i32, istepIfAniCur: UINT, hbrFlickerFreeDraw: ?HBRUSH, diFlags: UINT) callconv(.winapi) BOOL;
pub extern "user32" fn InsertMenuItemW(hmenu: ?HMENU, item: UINT, fByPosition: BOOL, lpmi: *const MENUITEMINFOW) callconv(.winapi) BOOL;

pub extern "gdi32" fn CreateCompatibleDC(hdc: ?HDC) callconv(.winapi) ?HDC;
pub extern "gdi32" fn DeleteDC(hdc: ?HDC) callconv(.winapi) BOOL;
pub extern "gdi32" fn SelectObject(hdc: ?HDC, h: ?HGDIOBJ) callconv(.winapi) ?HGDIOBJ;
pub extern "gdi32" fn CreateDIBSection(hdc: ?HDC, pbmi: *const BITMAPINFO, usage: UINT, ppvBits: *?*anyopaque, hSection: ?HANDLE, offset: DWORD) callconv(.winapi) ?HBITMAP;
pub extern "gdi32" fn DeleteObject(ho: ?HGDIOBJ) callconv(.winapi) BOOL;

pub extern "kernel32" fn GetModuleHandleW(lpModuleName: ?[*:0]const WCHAR) callconv(.winapi) ?HINSTANCE;
pub extern "kernel32" fn LoadLibraryW(lpLibFileName: [*:0]const WCHAR) callconv(.winapi) ?HINSTANCE;
pub extern "kernel32" fn FreeLibrary(hLibModule: ?HINSTANCE) callconv(.winapi) BOOL;
pub extern "kernel32" fn GetProcAddress(hModule: ?HINSTANCE, lpProcName: [*:0]const u8) callconv(.winapi) ?*const anyopaque;
pub extern "kernel32" fn GetLastError() callconv(.winapi) DWORD;
pub extern "kernel32" fn Sleep(dwMilliseconds: DWORD) callconv(.winapi) void;
