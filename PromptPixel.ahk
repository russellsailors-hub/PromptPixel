#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================================
;  PromptPixel
;  Press the configured hotkey (default Ctrl+Alt+S) anywhere.
;  Captures the monitor the mouse is currently on, focuses the
;  target app, pastes the image, and optionally types a label.
;  Settings are editable via the GUI (tray icon → Settings).
; ============================================================

#Include Gdip_All.ahk

; ---------- Paths ----------
global SCRIPT_DIR := A_ScriptDir
global INI_FILE   := SCRIPT_DIR "\settings.ini"

; ---------- Defaults ----------
global DEFAULT_HOTKEY := "^!s"

; Reserved combos that would soft-brick the user (clipboard/paste/system shortcuts)
global RESERVED_HOTKEYS := Map(
    "^v", "Ctrl+V is the universal Paste shortcut — binding it would break paste everywhere.",
    "^c", "Ctrl+C is Copy — binding it would break copy everywhere.",
    "^x", "Ctrl+X is Cut — binding it would break cut everywhere.",
    "^z", "Ctrl+Z is Undo — binding it would break undo everywhere.",
    "^y", "Ctrl+Y is Redo — binding it would break redo everywhere.",
    "^a", "Ctrl+A is Select All — binding it would break select-all everywhere.",
    "^s", "Ctrl+S is Save — binding it would break save in every app.",
    "^n", "Ctrl+N is New — binding it would interfere with most apps.",
    "^o", "Ctrl+O is Open — binding it would interfere with most apps.",
    "^p", "Ctrl+P is Print — binding it would interfere with most apps.",
    "^f", "Ctrl+F is Find — binding it would break search everywhere.",
    "!{F4}", "Alt+F4 is Close Window — binding it would break window closing.",
    "^{Esc}", "Ctrl+Esc opens the Start menu — reserved by Windows.",
    "{LWin}", "The Windows key is reserved by Windows.",
    "{RWin}", "The Windows key is reserved by Windows."
)

; ---------- Settings (loaded from INI, saved on Apply) ----------
global Settings := {
    Hotkey:        DEFAULT_HOTKEY,
    AutoTypeOn:    true,
    AutoTypeText:  "See Image",
    TargetMode:    "VSCode",     ; VSCode | Active | Custom
    CustomExe:     "",            ; e.g. chrome.exe
    Paused:        false
}

global CurrentHotkey := ""        ; what's actually bound right now
global MainGui := ""

; ---------- GDI+ ----------
pToken := Gdip_Startup()
if !pToken {
    MsgBox "GDI+ failed to start. Make sure Gdip_All.ahk is next to this script."
    ExitApp
}
OnExit((*) => Gdip_Shutdown(pToken))

; ---------- Tray ----------
if FileExist(A_ScriptDir "\PromptPixel.ico")
    TraySetIcon A_ScriptDir "\PromptPixel.ico"
else
    TraySetIcon "imageres.dll", 70
A_IconTip := "PromptPixel"
BuildTrayMenu()

; ---------- Load + apply settings, bind hotkey ----------
LoadSettings()
ApplyHotkey()

; ---------- Show GUI on first run ----------
if !FileExist(INI_FILE) {
    SaveSettings()       ; create the file with defaults
    ShowGui()
}

return  ; end of auto-execute

; ============================================================
;  Settings persistence
; ============================================================
LoadSettings() {
    global Settings, INI_FILE
    if !FileExist(INI_FILE)
        return
    Settings.Hotkey       := IniRead(INI_FILE, "Main", "Hotkey",       Settings.Hotkey)
    Settings.AutoTypeOn   := IniRead(INI_FILE, "Main", "AutoTypeOn",   Settings.AutoTypeOn ? "1" : "0") = "1"
    Settings.AutoTypeText := IniRead(INI_FILE, "Main", "AutoTypeText", Settings.AutoTypeText)
    Settings.TargetMode   := IniRead(INI_FILE, "Main", "TargetMode",   Settings.TargetMode)
    Settings.CustomExe    := IniRead(INI_FILE, "Main", "CustomExe",    Settings.CustomExe)
}

SaveSettings() {
    global Settings, INI_FILE
    IniWrite Settings.Hotkey,                       INI_FILE, "Main", "Hotkey"
    IniWrite (Settings.AutoTypeOn ? "1" : "0"),     INI_FILE, "Main", "AutoTypeOn"
    IniWrite Settings.AutoTypeText,                 INI_FILE, "Main", "AutoTypeText"
    IniWrite Settings.TargetMode,                   INI_FILE, "Main", "TargetMode"
    IniWrite Settings.CustomExe,                    INI_FILE, "Main", "CustomExe"
}

; ============================================================
;  Hotkey binding
; ============================================================
ApplyHotkey() {
    global Settings, CurrentHotkey
    ; Unbind old
    if (CurrentHotkey != "") {
        try Hotkey CurrentHotkey, "Off"
    }
    ; Bind new
    try {
        Hotkey Settings.Hotkey, (*) => CaptureMouseMonitorToTarget()
        Hotkey Settings.Hotkey, "On"
        CurrentHotkey := Settings.Hotkey
    } catch as e {
        MsgBox "Could not bind hotkey '" Settings.Hotkey "'.`n`n" e.Message,
               "PromptPixel", "Iconx"
    }
}

; ============================================================
;  Capture
; ============================================================
CaptureMouseMonitorToTarget() {
    global Settings
    if Settings.Paused
        return

    CoordMode "Mouse", "Screen"
    MouseGetPos &mx, &my

    monL := monT := monW := monH := 0
    found := false
    Loop MonitorGetCount() {
        MonitorGet A_Index, &L, &T, &R, &B
        if (mx >= L && mx < R && my >= T && my < B) {
            monL := L, monT := T
            monW := R - L, monH := B - T
            found := true
            break
        }
    }
    if !found {
        MonitorGet MonitorGetPrimary(), &L, &T, &R, &B
        monL := L, monT := T, monW := R - L, monH := B - T
    }

    pBitmap := Gdip_BitmapFromScreen(monL "|" monT "|" monW "|" monH)
    if !pBitmap {
        TrayTip "PromptPixel", "Capture failed.", "Iconx"
        return
    }
    Gdip_SetBitmapToClipboard(pBitmap)
    Gdip_DisposeImage(pBitmap)

    ; Focus target
    target := ResolveTargetWinTitle()
    if (target != "" && WinExist(target)) {
        WinActivate
        WinWaitActive target, , 1
        Sleep 80
    }

    Send "^v"

    if Settings.AutoTypeOn && Settings.AutoTypeText != "" {
        Sleep 120
        SendText Settings.AutoTypeText
    }
}

ResolveTargetWinTitle() {
    global Settings
    switch Settings.TargetMode {
        case "VSCode": return "ahk_exe Code.exe"
        case "Active": return ""              ; no focus change
        case "Custom":
            return Settings.CustomExe != "" ? "ahk_exe " Settings.CustomExe : ""
    }
    return "ahk_exe Code.exe"
}

; ============================================================
;  Tray menu
; ============================================================
BuildTrayMenu() {
    tray := A_TrayMenu
    tray.Delete()
    tray.Add "Settings…",                  (*) => ShowGui()
    tray.Add "Capture now",                (*) => CaptureMouseMonitorToTarget()
    tray.Add
    tray.Add "Pause hotkey",               TogglePause
    tray.Add "Reset hotkey to Ctrl+Alt+S", (*) => ResetHotkeyToDefault()
    tray.Add
    tray.Add "Exit",                       (*) => ExitApp()
    tray.Default := "Settings…"
    tray.ClickCount := 2      ; double-click tray icon = Settings
}

; Recovery: forces hotkey back to Ctrl+Alt+S even if the GUI is unreachable
ResetHotkeyToDefault() {
    global Settings, DEFAULT_HOTKEY
    Settings.Hotkey := DEFAULT_HOTKEY
    SaveSettings()
    ApplyHotkey()
    TrayTip "PromptPixel", "Hotkey reset to Ctrl+Alt+S.", "Iconi"
}

; Returns "" if ok, otherwise a human-readable reason it's blocked
ValidateHotkey(hk) {
    global RESERVED_HOTKEYS
    if (hk = "")
        return "Hotkey cannot be empty."
    norm := StrLower(hk)
    for reserved, reason in RESERVED_HOTKEYS {
        if (StrLower(reserved) = norm)
            return reason
    }
    return ""
}

TogglePause(itemName, *) {
    global Settings
    Settings.Paused := !Settings.Paused
    A_TrayMenu.Rename "Pause hotkey",   Settings.Paused ? "Resume hotkey" : "Pause hotkey"
    A_TrayMenu.Rename "Resume hotkey",  Settings.Paused ? "Resume hotkey" : "Pause hotkey"
    A_IconTip := "PromptPixel" (Settings.Paused ? "  (paused)" : "")
}

; ============================================================
;  Settings GUI
; ============================================================
ShowGui() {
    global MainGui, Settings
    if (MainGui != "" && WinExist("ahk_id " MainGui.Hwnd)) {
        WinActivate "ahk_id " MainGui.Hwnd
        return
    }

    ; Brand colors
    BG       := "0xF7F8FA"   ; near-white panel
    HEADERBG := "0x1E40AF"   ; deep blue (matches icon)
    ACCENT   := "0x3B82F6"   ; bright blue
    MUTED    := "0x6B7280"   ; gray text

    MainGui := Gui("+AlwaysOnTop +ToolWindow -MaximizeBox -MinimizeBox", "PromptPixel — Settings")
    MainGui.OnEvent "Close", (*) => MainGui.Hide()
    MainGui.BackColor := BG
    MainGui.SetFont "s10", "Segoe UI"
    MainGui.MarginX := 0
    MainGui.MarginY := 0

    W := 440  ; total content width

    ; ============ HEADER STRIP ============
    MainGui.AddProgress("x0 y0 w" W " h64 Background" HEADERBG, 0)
    if FileExist(A_ScriptDir "\PromptPixel.ico")
        MainGui.AddPicture("x18 y14 w36 h36 BackgroundTrans", A_ScriptDir "\PromptPixel.ico")

    MainGui.SetFont "s14 cWhite Bold", "Segoe UI"
    MainGui.AddText("x64 y14 w" (W-80) " h22 BackgroundTrans", "PromptPixel")
    MainGui.SetFont "s9 cWhite Norm", "Segoe UI"
    MainGui.AddText("x64 y36 w" (W-80) " h18 BackgroundTrans", "One hotkey. Screenshot to clipboard. Paste into any AI.")

    ; ============ BODY ============
    MainGui.SetFont "s9 c333333 Bold", "Segoe UI"
    MainGui.AddText("xm+18 y+18 w" (W-36), "HOTKEY")
    MainGui.SetFont "s9 cBlack Norm", "Segoe UI"
    MainGui.AddText("xm+18 y+4 w" (W-36) " c" MUTED, "Click the box, then press your combo. Reserved keys (Ctrl+V, etc.) are blocked.")
    hkCtrl := MainGui.Add("Hotkey", "xm+18 y+6 w" (W-36) " h26 vHK", Settings.Hotkey)

    MainGui.SetFont "s9 c333333 Bold", "Segoe UI"
    MainGui.AddText("xm+18 y+18 w" (W-36), "WHERE TO PASTE")
    MainGui.SetFont "s9 cBlack Norm", "Segoe UI"
    targets := ["VSCode (Claude extension)", "Whatever window is active", "Custom app (.exe name)"]
    ddIndex := (Settings.TargetMode = "Active") ? 2 : (Settings.TargetMode = "Custom") ? 3 : 1
    ddTarget := MainGui.Add("DropDownList", "xm+18 y+4 w" (W-36) " vTarget Choose" ddIndex, targets)

    MainGui.AddText("xm+18 y+8 w" (W-36) " c" MUTED, "Custom .exe name (only used for 'Custom app'):")
    edCustom := MainGui.Add("Edit", "xm+18 y+4 w" (W-36) " vCustomExe", Settings.CustomExe)

    MainGui.SetFont "s9 c333333 Bold", "Segoe UI"
    MainGui.AddText("xm+18 y+18 w" (W-36), "AFTER PASTING")
    MainGui.SetFont "s9 cBlack Norm", "Segoe UI"
    cbAuto := MainGui.Add("Checkbox", "xm+18 y+4 vAutoTypeOn", "Auto-type this text after pasting:")
    cbAuto.Value := Settings.AutoTypeOn ? 1 : 0
    edText := MainGui.Add("Edit", "xm+18 y+4 w" (W-36) " vAutoTypeText", Settings.AutoTypeText)

    ; ============ BUTTON ROW ============
    MainGui.AddText("xm+18 y+20 w" (W-36) " h1 Background" ACCENT)  ; thin separator line

    btnW := 96
    btnSave  := MainGui.Add("Button", "xm+18 y+12 w" btnW " h30 Default", "Save")
    btnReset := MainGui.Add("Button", "x+6 w" btnW " h30",                "Reset hotkey")
    btnTest  := MainGui.Add("Button", "x+6 w" btnW " h30",                "Capture now")
    btnHide  := MainGui.Add("Button", "x+6 w" btnW " h30",                "Hide to tray")

    btnSave.OnEvent  "Click", SaveBtnClicked
    btnReset.OnEvent "Click", (*) => (ResetHotkeyToDefault(), MainGui.Hide(), ShowGui())
    btnTest.OnEvent  "Click", (*) => (MainGui.Hide(), SetTimer(() => CaptureMouseMonitorToTarget(), -300))
    btnHide.OnEvent  "Click", (*) => MainGui.Hide()

    ; ============ FOOTER ============
    MainGui.SetFont "s8 c" MUTED, "Segoe UI"
    MainGui.AddText("xm+18 y+16 w" (W-36),
        "Tray icon: right-click for Pause / Reset / Exit. Double-click to reopen this window.")
    MainGui.AddText("xm+18 y+4 w" (W-36),
        "v1.0  ·  github.com/russellsailors-hub/PromptPixel")

    ; bottom padding
    MainGui.AddText("xm y+14 w" W " h1")

    MainGui.Show "AutoSize"
}

SaveBtnClicked(*) {
    global MainGui, Settings
    saved := MainGui.Submit(false)   ; don't hide

    ; Reject reserved hotkeys BEFORE saving
    newHotkey := saved.HK != "" ? saved.HK : Settings.Hotkey
    blockReason := ValidateHotkey(newHotkey)
    if (blockReason != "") {
        MsgBox blockReason "`n`nPlease pick a different combination.",
               "PromptPixel — Hotkey not allowed", "Iconx"
        return  ; leave GUI open so user can fix
    }

    Settings.Hotkey       := newHotkey
    Settings.AutoTypeOn   := saved.AutoTypeOn = 1
    Settings.AutoTypeText := saved.AutoTypeText
    Settings.CustomExe    := saved.CustomExe
    Settings.TargetMode   := (saved.Target = "Whatever window is active") ? "Active"
                           : (saved.Target = "Custom app (.exe name)")    ? "Custom"
                           :                                                  "VSCode"

    SaveSettings()
    ApplyHotkey()
    TrayTip "PromptPixel", "Settings saved. Hotkey: " Settings.Hotkey, "Iconi"
    MainGui.Hide()
}
