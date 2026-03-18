#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn VarUnset, Off

global g_data := { snippets: [] }
global g_filtered := []
global g_scriptDir := A_ScriptDir
global g_undoStack := []
global myGui, lvSnippets, edSearch, btnClose, btnAdd, titleBar
global g_dlgHwnd := 0
global panelVisible := false
global edPanelTitle, edPanelContent, btnPanelSave, btnPanelCancel, btnPanelDel, g_editIdx := 0

LoadData()
CreateGui()

A_TrayMenu.Delete()
A_TrayMenu.Add("显示/隐藏", (*) => ToggleWindow())
A_TrayMenu.Add("开机自启", (*) => ToggleAutoStart())
A_TrayMenu.Add("退出", (*) => ExitApp())

hk := g_data.HasProp("hotkey") ? g_data.hotkey : "^``"
Hotkey(hk, (*) => ToggleWindow())

; ═══════════════════════════════════════════════
; JSON
; ═══════════════════════════════════════════════
ParseJSON(str) {
    str := Trim(str)
    pos := 1
    return ParseValue(str, &pos)
}
ParseValue(str, &pos) {
    SkipWS(str, &pos)
    ch := SubStr(str, pos, 1)
    if ch = '"'
        return ParseString(str, &pos)
    if ch = '{'
        return ParseObject(str, &pos)
    if ch = '['
        return ParseArray(str, &pos)
    if ch = 't' {
        pos += 4
        return true
    }
    if ch = 'f' {
        pos += 5
        return false
    }
    if ch = 'n' {
        pos += 4
        return ""
    }
    return ParseNumber(str, &pos)
}
ParseString(str, &pos) {
    pos++
    result := ""
    loop {
        ch := SubStr(str, pos, 1)
        if ch = '"' {
            pos++
            return result
        }
        if ch = '\' {
            pos++
            esc := SubStr(str, pos, 1)
            pos++
            if esc = 'n'
                result .= '`n'
            else if esc = 't'
                result .= '`t'
            else
                result .= esc
        } else {
            result .= ch
            pos++
        }
    }
}
ParseNumber(str, &pos) {
    start := pos
    while pos <= StrLen(str) && InStr("0123456789.-+eE", SubStr(str, pos, 1))
        pos++
    return Number(SubStr(str, start, pos - start))
}
ParseObject(str, &pos) {
    pos++
    obj := {}
    SkipWS(str, &pos)
    if SubStr(str, pos, 1) = '}' {
        pos++
        return obj
    }
    loop {
        SkipWS(str, &pos)
        key := ParseString(str, &pos)
        SkipWS(str, &pos)
        pos++
        val := ParseValue(str, &pos)
        obj.%key% := val
        SkipWS(str, &pos)
        ch := SubStr(str, pos, 1)
        pos++
        if ch = '}'
            return obj
    }
}
ParseArray(str, &pos) {
    pos++
    arr := []
    SkipWS(str, &pos)
    if SubStr(str, pos, 1) = ']' {
        pos++
        return arr
    }
    loop {
        val := ParseValue(str, &pos)
        arr.Push(val)
        SkipWS(str, &pos)
        ch := SubStr(str, pos, 1)
        pos++
        if ch = ']'
            return arr
    }
}
SkipWS(str, &pos) {
    while pos <= StrLen(str) && InStr(" `t`n`r", SubStr(str, pos, 1))
        pos++
}
ToJSON(val) {
    if IsObject(val) {
        if val is Array {
            parts := []
            for item in val
                parts.Push(ToJSON(item))
            return "[" . JoinArr(parts, ",") . "]"
        }
        parts := []
        for k, v in val.OwnProps()
            parts.Push('"' . k . '":' . ToJSON(v))
        return "{" . JoinArr(parts, ",") . "}"
    }
    if val is String
        return '"' . StrReplace(StrReplace(StrReplace(val, '\', '\\'), '"', '\"'), '`n', '\n') . '"'
    return String(val)
}
JoinArr(arr, sep) {
    result := ""
    for i, v in arr {
        if i > 1
            result .= sep
        result .= v
    }
    return result
}

; ═══════════════════════════════════════════════
; 数据
; ═══════════════════════════════════════════════
LoadData() {
    global g_data
    f := g_scriptDir "\snippets.json"
    if !FileExist(f) {
        g_data := { hotkey: "^``", snippets: [] }
        SaveData()
        return
    }
    try {
        g_data := ParseJSON(FileRead(f, "UTF-8"))
    } catch {
        g_data := { hotkey: "^``", snippets: [] }
    }
}
SaveData() {
    global g_data, g_scriptDir
    f := g_scriptDir "\snippets.json"
    fh := FileOpen(f, "w", "UTF-8")
    fh.Write(ToJSON(g_data))
    fh.Close()
}

; ═══════════════════════════════════════════════
; GUI
; ═══════════════════════════════════════════════
CreateGui() {
    global myGui, lvSnippets, edSearch, btnClose, btnAdd, titleBar
    global edPanelTitle, edPanelContent, btnPanelSave, btnPanelCancel, btnPanelDel

    myGui := Gui("-Caption +ToolWindow +Resize", "Snippets")
    myGui.BackColor := "2d2d2d"
    myGui.SetFont("s10 cD4D4D4", "Segoe UI")
    myGui.MarginX := 0
    myGui.MarginY := 0

    ; 标题文字（不拦截鼠标，用 SS_NOTIFY 让点击穿透到窗口）
    titleBar := myGui.Add("Text", "x0 y0 w220 h28 +0x200 cFFFFFF Center", "Snippets")
    titleBar.SetFont("s10 Bold cFFFFFF")
    titleBar.OnEvent("Click", DragWindow)

    btnClose := myGui.Add("Button", "x274 y4 w22 h20", "✕")
    btnClose.SetFont("s9")
    btnClose.OnEvent("Click", (*) => myGui.Hide())

    btnAdd := myGui.Add("Button", "x246 y4 w24 h20", "+")
    btnAdd.SetFont("s9")
    btnAdd.OnEvent("Click", (*) => ShowEditPanel(0))

    ; 搜索框
    edSearch := myGui.Add("Edit", "x8 y34 w284 h26 +Background1e1e1e", "")
    edSearch.SetFont("s10 cD4D4D4")
    edSearch.OnEvent("Change", (*) => RefreshList())

    ; 列表
    lvSnippets := myGui.Add("ListView",
        "x0 y66 w300 h284 +Background1e1e1e cD4D4D4 -Multi Grid NoSort",
        ["序号", "标题", "内容"])
    lvSnippets.SetFont("s9 cD4D4D4")
    lvSnippets.ModifyCol(1, 45)
    lvSnippets.ModifyCol(2, 100)
    lvSnippets.ModifyCol(3, 150)
    lvSnippets.OnEvent("Click", OnSnippetDblClick)
    lvSnippets.OnEvent("DoubleClick", OnSnippetCopy)

    ; 编辑面板（初始隐藏）
    edPanelTitle := myGui.Add("Edit", "x8 y355 w284 h22 +Background1e1e1e cD4D4D4")
    edPanelTitle.SetFont("s9")
    SendMessage(0x1501, 0, StrPtr("标题"), edPanelTitle)
    edPanelTitle.OnEvent("Change", (*) => 0)
    edPanelContent := myGui.Add("Edit", "x8 y382 w284 h60 Multi +Background1e1e1e cD4D4D4 +VScroll")
    edPanelContent.SetFont("s9")
    SendMessage(0x1501, 0, StrPtr("内容（Ctrl+Enter保存）"), edPanelContent)
    btnPanelSave := myGui.Add("Button", "x8 y448 w80 h24", "保存")
    btnPanelSave.OnEvent("Click", (*) => SaveEditPanel())
    btnPanelCancel := myGui.Add("Button", "x96 y448 w80 h24", "取消")
    btnPanelCancel.OnEvent("Click", (*) => HideEditPanel())
    btnPanelDel := myGui.Add("Button", "x184 y448 w80 h24", "删除")
    btnPanelDel.OnEvent("Click", (*) => DeleteSnippet())
    edPanelTitle.Opt("+Hidden")
    edPanelContent.Opt("+Hidden")
    btnPanelSave.Opt("+Hidden")
    btnPanelCancel.Opt("+Hidden")
    btnPanelDel.Opt("+Hidden")

    myGui.OnEvent("Escape", (*) => myGui.Hide())
    myGui.OnEvent("Size", OnGuiSize)
    ; 标题框回车保存，内容框 Ctrl+Enter 保存
    HotIfWinActive("ahk_id " . myGui.Hwnd)
    Hotkey("Enter", (*) => SaveEditPanel())
    Hotkey("+Enter", (*) => Send("`n"))
    Hotkey("^z", (*) => UndoLast())
    HotIf()

    ; 初始隐藏编辑面板区域，窗口高度只显示列表
    RefreshList()
}

ShowEditPanel(idx) {
    global myGui, edPanelTitle, edPanelContent, g_editIdx, g_filtered, panelVisible
    global btnPanelSave, btnPanelCancel, btnPanelDel
    g_editIdx := idx
    if idx = 0 {
        edPanelTitle.Value := ""
        edPanelContent.Value := ""
    } else {
        s := g_filtered[idx]
        edPanelTitle.Value := s.title
        edPanelContent.Value := s.content
    }
    panelVisible := true
    edPanelTitle.Opt("-Hidden")
    edPanelContent.Opt("-Hidden")
    btnPanelSave.Opt("-Hidden")
    btnPanelCancel.Opt("-Hidden")
    btnPanelDel.Opt("-Hidden")
    myGui.Show("h490")
    edPanelTitle.Focus()
}

HideEditPanel() {
    global myGui, panelVisible, g_editIdx
    global edPanelTitle, edPanelContent, btnPanelSave, btnPanelCancel, btnPanelDel
    panelVisible := false
    g_editIdx := 0
    edPanelTitle.Opt("+Hidden")
    edPanelContent.Opt("+Hidden")
    btnPanelSave.Opt("+Hidden")
    btnPanelCancel.Opt("+Hidden")
    btnPanelDel.Opt("+Hidden")
    myGui.Show("h350")
}

SaveEditPanel() {
    global g_data, g_filtered, g_editIdx, edPanelTitle, edPanelContent, g_undoStack
    title := Trim(edPanelTitle.Value)
    content := Trim(edPanelContent.Value)
    if content = "" {
        MsgBox("内容不能为空", "提示", 48)
        return
    }
    if title = ""
        title := SubStr(content, 1, 5)
    if g_editIdx = 0 {
        maxId := 0
        for s in g_data.snippets
            if s.id > maxId
                maxId := s.id
        g_data.snippets.Push({ id: maxId + 1, title: title, content: content })
    } else {
        s := g_filtered[g_editIdx]
        for item in g_data.snippets {
            if item.id = s.id {
                item.title := title
                item.content := content
                break
            }
        }
    }
    SaveData()
    RefreshList()
    HideEditPanel()
}

DeleteSnippet() {
    global g_data, g_filtered, g_editIdx, g_scriptDir
    if g_editIdx = 0
        return
    ; 删除前备份
    UndoPush(ToJSON(g_data))
    s := g_filtered[g_editIdx]
    for i, item in g_data.snippets {
        if item.id = s.id {
            g_data.snippets.RemoveAt(i)
            break
        }
    }
    f := g_scriptDir "\snippets.json"
    fh := FileOpen(f, "w", "UTF-8")
    fh.Write(ToJSON(g_data))
    fh.Close()
    RefreshList()
    HideEditPanel()
}

RefreshList() {
    global lvSnippets, edSearch, g_data, g_filtered
    keyword := StrLower(edSearch.Value)
    g_filtered := []
    lvSnippets.Delete()
    for s in g_data.snippets {
        if keyword != "" && !InStr(StrLower(s.title), keyword) && !InStr(StrLower(s.content), keyword)
            continue
        g_filtered.Push(s)
        preview := SubStr(s.content, 1, 60) . (StrLen(s.content) > 60 ? "…" : "")
        lvSnippets.Add(, g_filtered.Length, s.title, preview)
    }
    ; 末尾加一行空白行用于新增
    lvSnippets.Add(, "", "", "")
}

OnSnippetCopy(lv, row) {
    global g_filtered, myGui
    if row < 1 || row > g_filtered.Length
        return
    s := g_filtered[row]
    myGui.Hide()
    Sleep(100)
    A_Clipboard := s.content
    ToolTip("已复制: " . s.title)
    SetTimer(() => ToolTip(), -1500)
}

OnSnippetDblClick(lv, row) {
    global g_filtered
    if row < 1
        return
    if row > g_filtered.Length {
        ; 点击空白行，新增
        ShowEditPanel(0)
        return
    }
    ShowEditPanel(row)
}

DragWindow(*) {
    global myGui
    PostMessage(0xA1, 2, 0, , myGui)
}

OnGuiSize(gui, minMax, w, h) {
    global myGui, lvSnippets, edSearch, btnClose, btnAdd, titleBar
    global edPanelTitle, edPanelContent, btnPanelSave, btnPanelCancel, btnPanelDel, panelVisible
    if minMax = -1
        return
    titleBar.Move(0, 0, w - 60, 28)
    btnClose.Move(w - 26, 4, 22, 20)
    btnAdd.Move(w - 52, 4, 24, 20)
    edSearch.Move(8, 34, w - 16, 26)
    panelH := panelVisible ? 140 : 0
    listH := h - 66 - panelH
    lvSnippets.Move(0, 66, w, listH)
    lvSnippets.ModifyCol(3, w - 45 - 100 - 4)
    if panelVisible {
        panelY := h - 138
        edPanelTitle.Move(8, panelY, w - 16, 22)
        edPanelContent.Move(8, panelY + 26, w - 16, 60)
        btnPanelSave.Move(8, panelY + 92, 80, 24)
        btnPanelCancel.Move(96, panelY + 92, 80, 24)
        btnPanelDel.Move(184, panelY + 92, 80, 24)
    }
}

OnActivateApp(wParam, lParam, msg, hwnd) {
    global myGui, g_dlgHwnd
    if wParam = 0
        SetTimer(CheckHide, -200)
}
CheckHide() {
    global myGui, g_dlgHwnd
    if g_dlgHwnd != 0
        return
    activeHwnd := WinExist("A")
    if activeHwnd = myGui.Hwnd
        return
    pid := WinGetPID("ahk_id " activeHwnd)
    if pid = DllCall("GetCurrentProcessId")
        return
    myGui.Hide()
}

ToggleWindow() {
    global myGui, edSearch, panelVisible, g_editIdx
    global edPanelTitle, edPanelContent, btnPanelSave, btnPanelCancel, btnPanelDel
    if WinExist("ahk_id " . myGui.Hwnd) && DllCall("IsWindowVisible", "Ptr", myGui.Hwnd) {
        myGui.Hide()
    } else {
        panelVisible := false
        g_editIdx := 0
        edPanelTitle.Opt("+Hidden")
        edPanelContent.Opt("+Hidden")
        btnPanelSave.Opt("+Hidden")
        btnPanelCancel.Opt("+Hidden")
        btnPanelDel.Opt("+Hidden")
        MouseGetPos(&mx, &my)
        x := Max(0, Min(mx - 150, A_ScreenWidth - 300))
        y := Max(0, Min(my - 50, A_ScreenHeight - 460))
        myGui.Show("x" x " y" y " w300 h350")
        edSearch.Value := ""
        RefreshList()
        edSearch.Focus()
    }
}

DlgClose(*) {
    global g_dlgHwnd
    g_dlgHwnd := 0
}

ToggleAutoStart() {
    regKey := "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
    appName := "Snippets"
    exePath := A_ScriptFullPath
    if A_IsCompiled
        exePath := A_ScriptFullPath
    else
        exePath := '"' A_AhkPath '" "' A_ScriptFullPath '"'
    existing := ""
    try existing := RegRead(regKey, appName)
    if existing != "" {
        RegDelete(regKey, appName)
        ToolTip("已关闭开机自启")
    } else {
        RegWrite(exePath, "REG_SZ", regKey, appName)
        ToolTip("已开启开机自启")
    }
    SetTimer(() => ToolTip(), -1500)
}

UndoPush(snapshot) {
    global g_undoStack
    g_undoStack.Push(snapshot)
    if g_undoStack.Length > 20
        g_undoStack.RemoveAt(1)
}

UndoLast() {
    global g_data, g_undoStack, g_scriptDir
    if g_undoStack.Length = 0 {
        ToolTip("没有可撤销的操作")
        SetTimer(() => ToolTip(), -1500)
        return
    }
    prev := g_undoStack.Pop()
    g_data := ParseJSON(prev)
    f := g_scriptDir "\snippets.json"
    fh := FileOpen(f, "w", "UTF-8")
    fh.Write(prev)
    fh.Close()
    RefreshList()
    ToolTip("已撤销，剩余 " g_undoStack.Length " 步")
    SetTimer(() => ToolTip(), -1500)
}
