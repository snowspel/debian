#!/usr/bin/env bash
# 09-launcher.sh : Panel: app launcher
# Super+Space launcher (Launcher.qml).
#   bash Script/09-launcher.sh          install / restore this part (safe to run again; run it inside your Snow folder, any folder name works)
#   bash Script/09-launcher.sh check    read-only check
MOD="09-launcher"; TITLE="Panel: app launcher"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
QS="$HOME/.config/quickshell/snow"; BIN="$HOME/.config/snow/bin"; HYPR="$HOME/.config/hypr"; KITTY="$HOME/.config/kitty"; CONF="$HOME/.config/snow"
ITEMS=(
  "u|.config/quickshell/snow/launcher/Launcher.qml|644|0"
)
emit() {
case "$1" in
"u/.config/quickshell/snow/launcher/Launcher.qml")
cat <<'SNOW_FILE_END_4b7d'
// ============================================================================
//  Launcher.qml  —  APP LAUNCHER  (Super+Space)
// ----------------------------------------------------------------------------
//  DIKHTA KYA HAI : Upar-beech me ek khali search bar.
//  KAISE CHALTA HAI:
//     - Kuch type karo      -> sirf installed apps ki list (naam se, phir keywords se match)
//     - Up / Down           -> list me upar-neeche
//     - Enter ya click      -> app chalu
//     - TAB key (khali search par) -> saari apps GRID me (4 ek line me, search bar jitni chaudai)
//                              Grid me arrow keys se ghumo, Enter = chalu. Kuch type karo = wapas list.
//     - Esc ya bahar click  -> band
//  KHOLNE KI KEY : ~/.config/hypr/snow-panel-keys.lua me "SUPER + space".
//  BADLO (SETTINGS) : barWidth, gridCols, maxListRows, maxGridRows neeche.
// ============================================================================
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.core

Scope {
    id: root

    // ---------------- SETTINGS (yahan badlo) ----------------
    readonly property int barWidth: 560       // search bar (aur grid) ki chaudai
    readonly property int barHeight: 56       // search bar ki unchai
    readonly property int topGap: 64          // screen ke upar se doori
    readonly property int gridCols: 4         // grid me ek line me kitni apps
    readonly property int maxListRows: 8      // list me ek saath kitni line dikhein
    readonly property int maxGridRows: 5      // grid me ek saath kitni line dikhein
    readonly property int rowH: 48            // list ki ek line ki unchai
    readonly property int cellH: 112          // grid ke ek dabbe ki unchai

    // ---------------- haalat ----------------
    property bool open: false
    property string query: ""                 // search me jo type kiya
    property int selected: 0                  // kaun si app chuni hui hai
    property bool showAll: false              // true = Tab wala grid dikh raha hai

    // match hui apps (query ya showAll badalte hi apne aap dobara banti hai)
    readonly property var results: compute(query, showAll)

    // ---------------- apps dhundhne ka logic ----------------
    // score jitna chhota, utna upar: 0 = naam usi se shuru, 1 = naam ke kisi shabd se shuru,
    // 2 = naam me kahin bhi, 3 = generic naam / keywords me
    function compute(raw: string, everything: bool): var {
        const q = raw.trim().toLowerCase()
        if (!everything && q === "") return []

        const apps = DesktopEntries.applications.values
        const found = []
        for (let i = 0; i < apps.length; i++) {
            const e = apps[i]
            if (e.noDisplay || !e.name) continue          // chhupi hui apps skip

            const name = e.name.toLowerCase()
            let score = -1
            if (everything) score = 0
            else if (name.startsWith(q)) score = 0
            else if (name.indexOf(" " + q) >= 0) score = 1
            else if (name.indexOf(q) >= 0) score = 2
            else {
                const extra = ((e.genericName || "") + " " + Array.prototype.join.call(e.keywords || [], " ")).toLowerCase()
                if (extra.indexOf(q) >= 0) score = 3
            }
            if (score >= 0) found.push({ entry: e, score: score, name: e.name })
        }
        found.sort((a, b) => (a.score - b.score) || a.name.localeCompare(b.name))
        return found.map(x => x.entry)
    }

    function dismiss(): void { open = false }

    function launch(entry): void {
        if (!entry) return
        dismiss()
        entry.execute()
    }

    onOpenChanged: if (open) { showAll = false; input.text = ""; query = ""; selected = 0 }
    onQueryChanged: selected = 0
    onShowAllChanged: selected = 0
    onSelectedChanged: {                       // chuni hui app hamesha screen par dikhe
        if (results.length === 0) return
        if (showAll) gv.positionViewAtIndex(selected, GridView.Contain)
        else lv.positionViewAtIndex(selected, ListView.Contain)
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { if (root.open) root.dismiss(); else root.open = true }
        function show(): void { root.open = true }
        function hide(): void { root.dismiss() }
    }

    PanelWindow {
        id: win
        visible: root.open
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "snow-launcher"
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        onVisibleChanged: if (visible) input.forceActiveFocus()

        // bahar click = band
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: root.dismiss()
        }

        // ========== 1) SEARCH BAR ==========
        Rectangle {
            antialiasing: true
            id: bar
            width: root.barWidth
            height: root.barHeight
            radius: height / 2
            y: root.topGap
            anchors.horizontalCenter: parent.horizontalCenter
            color: Theme.cardBg
            border.width: 1
            border.color: input.activeFocus ? Qt.alpha(Theme.accent, 0.45) : Theme.hairline

            Rectangle { antialiasing: true; z: -1; x: -3; y: 2; width: parent.width + 6; height: parent.height + 6; radius: height / 2; color: Qt.rgba(0, 0, 0, 0.06) }
            MouseArea { anchors.fill: parent }                // bar par click = band na ho

            Text {                                            // search icon
                x: 22
                anchors.verticalCenter: parent.verticalCenter
                text: Icons.search
                font.family: Theme.iconFont
                font.pixelSize: 24
                color: Theme.muted
            }

            TextInput {
                id: input
                x: 58
                width: parent.width - 84
                anchors.verticalCenter: parent.verticalCenter
                font.family: Theme.uiFont
                font.pixelSize: 18
                color: Theme.text
                selectionColor: Theme.accent
                selectedTextColor: Theme.accentText
                clip: true
                focus: true

                // type karte hi grid band, list wapas
                onTextChanged: { root.query = text; root.showAll = false }

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        root.dismiss(); event.accepted = true
                    } else if (event.key === Qt.Key_Down) {
                        if (root.results.length > 0) root.selected = Math.min(root.selected + (root.showAll ? root.gridCols : 1), root.results.length - 1)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Up) {
                        root.selected = Math.max(root.selected - (root.showAll ? root.gridCols : 1), 0)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Tab) {
                        // TAB: search khali ho aur grid band ho to saari apps grid me; warna agli item par jao
                        if (!root.showAll && input.text === "") {
                            root.showAll = true
                            root.selected = 0
                        } else if (root.results.length > 0) {
                            root.selected = Math.min(root.selected + 1, root.results.length - 1)
                        }
                        event.accepted = true
                    } else if (event.key === Qt.Key_Backtab) {
                        root.selected = Math.max(root.selected - 1, 0)
                        event.accepted = true
                    } else if (root.showAll && event.key === Qt.Key_Right) {
                        if (root.results.length > 0) root.selected = Math.min(root.selected + 1, root.results.length - 1)
                        event.accepted = true
                    } else if (root.showAll && event.key === Qt.Key_Left) {
                        root.selected = Math.max(root.selected - 1, 0)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (root.results.length > 0) root.launch(root.results[root.selected])
                        event.accepted = true
                    }
                }
            }
        }

        // ========== 2) RESULTS LIST (type karne par) ==========
        Rectangle {
            antialiasing: true
            id: listBox
            visible: !root.showAll && root.results.length > 0
            width: bar.width
            height: Math.min(root.results.length, root.maxListRows) * root.rowH + 16
            radius: Theme.rCard + 2
            y: bar.y + bar.height + 10
            anchors.horizontalCenter: parent.horizontalCenter
            color: Theme.cardBg
            border.width: 1
            border.color: Theme.hairline

            Rectangle { antialiasing: true; z: -1; x: -3; y: 3; width: parent.width + 6; height: parent.height + 6; radius: parent.radius + 3; color: Qt.rgba(0, 0, 0, 0.06) }
            MouseArea { anchors.fill: parent }

            ListView {
                id: lv
                anchors.fill: parent
                anchors.margins: 8
                clip: true
                model: root.showAll ? [] : root.results
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    antialiasing: true
                    id: row
                    required property var modelData
                    required property int index
                    width: ListView.view.width
                    height: root.rowH
                    radius: Theme.rTile - 2
                    color: row.index === root.selected ? Theme.accentSoft : "transparent"

                    Image {                                    // app ka icon
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28
                        sourceSize.width: 56
                        sourceSize.height: 56
                        asynchronous: true
                        source: Quickshell.iconPath(row.modelData.icon || "application-x-executable", true)
                    }

                    Text {                                     // app ka naam
                        x: 56
                        width: parent.width - 72
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.name
                        elide: Text.ElideRight
                        font.family: Theme.uiFont
                        font.pixelSize: 15
                        color: Theme.text
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPositionChanged: root.selected = row.index
                        onClicked: root.launch(row.modelData)
                    }
                }
            }
        }

        // ========== 3) SAARI APPS GRID (Tab key) ==========
        Rectangle {
            antialiasing: true
            id: gridBox
            visible: root.showAll && root.results.length > 0
            width: bar.width                                     // search bar jitni hi chaudai
            height: Math.min(Math.ceil(root.results.length / root.gridCols), root.maxGridRows) * root.cellH + 24
            radius: Theme.rCard + 4
            y: bar.y + bar.height + 10
            anchors.horizontalCenter: parent.horizontalCenter
            color: Theme.cardBg
            border.width: 1
            border.color: Theme.hairline

            Rectangle { antialiasing: true; z: -1; x: -3; y: 3; width: parent.width + 6; height: parent.height + 6; radius: parent.radius + 3; color: Qt.rgba(0, 0, 0, 0.06) }
            MouseArea { anchors.fill: parent }

            GridView {
                id: gv
                anchors.fill: parent
                anchors.margins: 12
                clip: true
                cellWidth: Math.floor(width / root.gridCols)
                cellHeight: root.cellH
                model: root.showAll ? root.results : []
                boundsBehavior: Flickable.StopAtBounds

                delegate: Item {
                    id: cell
                    required property var modelData
                    required property int index
                    width: GridView.view.cellWidth
                    height: GridView.view.cellHeight

                    Rectangle {
                        antialiasing: true
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: Theme.rTile
                        color: cell.index === root.selected ? Theme.accentSoft : "transparent"

                        Image {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 12
                            width: 48
                            height: 48
                            sourceSize.width: 96
                            sourceSize.height: 96
                            asynchronous: true
                            source: Quickshell.iconPath(cell.modelData.icon || "application-x-executable", true)
                        }

                        Text {
                            x: 6
                            y: 66
                            width: parent.width - 12
                            height: 34
                            text: cell.modelData.name
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignTop
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.fsSmall
                            color: Theme.text
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPositionChanged: root.selected = cell.index
                            onClicked: root.launch(cell.modelData)
                        }
                    }
                }
            }
        }
    }
}
SNOW_FILE_END_4b7d
;;
*) return 1 ;;
esac
}
extra_check() {
for n in launcher/Launcher; do qml_ok "$QS/$n.qml"; done
}
component_main "$@"
