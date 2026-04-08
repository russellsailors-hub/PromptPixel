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

; ---------- Settings (loaded from INI, saved on Apply) ----------
global Settings := {
    Hotkey:        "^!s",
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
    tray.Add "Settings…",     (*) => ShowGui()
    tray.Add "Capture now",   (*) => CaptureMouseMonitorToTarget()
    tray.Add
    tray.Add "Pause hotkey",  TogglePause
    tray.Add
    tray.Add "Exit",          (*) => ExitApp()
    tray.Default := "Settings…"
    tray.ClickCount := 2      ; double-click tray icon = Settings
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

    MainGui := Gui("+AlwaysOnTop +ToolWindow", "PromptPixel — Settings")
    MainGui.OnEvent "Close", (*) => MainGui.Hide()
    MainGui.SetFont "s10", "Segoe UI"
    MainGui.MarginX := 14
    MainGui.MarginY := 14

    ; --- Hotkey ---
    MainGui.Add "Text", "xm w380", "Hotkey  (click the box, then press your combo)"
    hkCtrl := MainGui.Add("Hotkey", "xm w380 vHK", Settings.Hotkey)

    ; --- Target app ---
    MainGui.Add "Text", "xm y+12 w380", "Where to paste the screenshot:"
    targets := ["VSCode (Claude extension)", "Whatever window is active", "Custom app (.exe name)"]
    ddIndex := (Settings.TargetMode = "Active") ? 2 : (Settings.TargetMode = "Custom") ? 3 : 1
    ddTarget := MainGui.Add("DropDownList", "xm w380 vTarget Choose" ddIndex, targets)

    MainGui.Add "Text", "xm y+10 w380", "Custom .exe name (only used for 'Custom app'):"
    edCustom := MainGui.Add("Edit", "xm w380 vCustomExe", Settings.CustomExe)

    ; --- Auto-type ---
    cbAuto := MainGui.Add("Checkbox", "xm y+14 vAutoTypeOn", "After pasting, auto-type this text:")
    cbAuto.Value := Settings.AutoTypeOn ? 1 : 0
    edText := MainGui.Add("Edit", "xm w380 vAutoTypeText", Settings.AutoTypeText)

    ; --- Buttons ---
    btnSave := MainGui.Add("Button", "xm y+18 w110 Default", "Save")
    btnTest := MainGui.Add("Button", "x+8 w110", "Capture now")
    btnHide := MainGui.Add("Button", "x+8 w110", "Hide to tray")

    btnSave.OnEvent "Click", SaveBtnClicked
    btnTest.OnEvent "Click", (*) => (MainGui.Hide(), SetTimer(() => CaptureMouseMonitorToTarget(), -300))
    btnHide.OnEvent "Click", (*) => MainGui.Hide()

    MainGui.Add "Text", "xm y+14 w380 cGray",
        "Tip: tray icon → right-click for Pause / Exit. Double-click tray icon to reopen this window."

    MainGui.Show "AutoSize"
}

SaveBtnClicked(*) {
    global MainGui, Settings
    saved := MainGui.Submit(false)   ; don't hide

    Settings.Hotkey       := saved.HK != "" ? saved.HK : Settings.Hotkey
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
