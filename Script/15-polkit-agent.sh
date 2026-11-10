#!/usr/bin/env bash
# 15-polkit-agent.sh : Panel: password dialog (polkit)
# The password window for admin actions (PolkitDialog.qml).
#   bash Script/15-polkit-agent.sh          install / restore this part (safe to run again; run it inside your Snow folder, any folder name works)
#   bash Script/15-polkit-agent.sh check    read-only check
MOD="15-polkit-agent"; TITLE="Panel: password dialog (polkit)"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
QS="$HOME/.config/quickshell/snow"; BIN="$HOME/.config/snow/bin"; HYPR="$HOME/.config/hypr"; KITTY="$HOME/.config/kitty"; CONF="$HOME/.config/snow"
ITEMS=(
  "u|.config/quickshell/snow/polkit/PolkitDialog.qml|644|0"
)
emit() {
case "$1" in
"u/.config/quickshell/snow/polkit/PolkitDialog.qml")
cat <<'SNOW_FILE_END_4b7d'
// ============================================================================
//  PolkitDialog.qml  —  PASSWORD WINDOW  ("Authentication")
// ----------------------------------------------------------------------------
//  KAB AATI HAI : Jab koi program admin permission maange (jaise pkexec, disk mount, settings badalna).
//  DIKHTA KYA HAI : Chhoti window: "Authentication", niche likha ki KYA manga ja raha hai (message + action id),
//                   phir password box. Keyboard seedha password box me hota hai.
//  KAISE CHALTA HAI : Enter = password bhejo | Esc = cancel | galat password = box laal + "Wrong password".
//  YE hyprpolkitagent KI JAGAH LETI HAI. Agar ye file load na ho to shell.qml hyprpolkitagent chalu kar deta hai,
//  taaki hamesha EXACTLY EK agent rahe.
//  TEST : terminal me   pkexec true
//  BADLO (SETTINGS) : width (window ki chaudai).
//  NOTE : shell.qml isse code se load karta hai.
// ============================================================================
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Polkit
import QtQuick
import qs.core

Scope {
    id: root

    property bool wrong: false              // pichhla password galat tha?
    property bool busy: false               // password check ho raha hai?

    function submit(): void {
        if (!agent.flow || field.text.length === 0) return
        root.busy = true
        agent.flow.submit(field.text)
        field.text = ""
    }

    function cancel(): void {
        if (agent.flow) agent.flow.cancelAuthenticationRequest()
    }

    // SAFETY: 2 minute tak kisi ne jawab nahi diya to cancel (isse keyboard bhi wapas mil jata hai — bhoola hua dialog keyboard pakde na rahe)
    Timer {
        id: safety
        interval: 120000
        running: agent.isActive
        onTriggered: root.cancel()
    }

    PolkitAgent {
        id: agent
        onAuthenticationRequestStarted: { root.wrong = false; root.busy = false; field.text = ""; safety.restart() }
    }

    Connections {
        target: agent.flow
        ignoreUnknownSignals: true
        function onAuthenticationFailed() {
            root.busy = false
            root.wrong = true
            field.text = ""
            field.forceActiveFocus()
        }
        function onAuthenticationSucceeded() { root.busy = false; root.wrong = false }
    }

    // 3 second baad check: register hua ya nahi (doosra agent chal raha ho to hum register nahi ho paate)
    Timer {
        interval: 3000
        running: true
        onTriggered: if (!agent.isRegistered) console.warn("snow: Polkit agent was not registered (is hyprpolkitagent still running?)")
    }

    PanelWindow {
        id: win
        visible: agent.isActive
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: 360                           // SETTINGS: window ki chaudai
        implicitHeight: 226 + card.extra             // 226 + jitna message ke liye jagah chahiye

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "snow-polkit"
        WlrLayershell.keyboardFocus: agent.isActive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        onVisibleChanged: if (visible) { field.text = ""; field.forceActiveFocus(); focusTimer.restart() }
        // keyboard focus window ke baad aata hai: 80ms baad dobara maango
        Timer { id: focusTimer; interval: 80; onTriggered: field.forceActiveFocus() }

        Rectangle {
            antialiasing: true
            id: card
            anchors.fill: parent
            radius: Theme.rCard + 2
            color: Theme.cardBg
            border.width: 1
            border.color: Theme.hairline
            // message aur action-id ki lines ke liye extra unchai
            readonly property real extra: (msgText.text !== "" ? msgText.implicitHeight + 4 : 0) + (actText.text !== "" ? actText.implicitHeight + 2 : 0)

            Rectangle {                             // round lock badge
                width: 52; height: 52; radius: 26
                anchors.horizontalCenter: parent.horizontalCenter
                y: 22
                color: Qt.alpha(Theme.accent, 0.16)
                border.width: 1
                border.color: Qt.alpha(Theme.accent, 0.35)
                Text {
                    anchors.centerIn: parent
                    text: String.fromCodePoint(0xe897)
                    font.family: Theme.iconFont; renderType: Text.NativeRendering; font.pixelSize: 28
                    font.variableAxes: ({ "FILL": 1 })
                    color: Theme.accent
                }
            }

            Text {
                x: 28; y: 82
                width: parent.width - 56
                horizontalAlignment: Text.AlignHCenter
                text: "Authentication"
                font.family: Theme.uiFont; font.pixelSize: Theme.fsTitle + 2; font.weight: Font.DemiBold; color: Theme.text
            }

            Text {                                  // KYA manga ja raha hai (program ka message)
                id: msgText
                x: 28; y: 112
                width: parent.width - 56
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
                textFormat: Text.PlainText
                text: (agent.flow && agent.flow.message) ? agent.flow.message : ""
                font.family: Theme.uiFont; font.pixelSize: Theme.fsBody; color: Theme.text
            }
            Text {                                  // action id (jaise org.freedesktop.policykit.exec)
                id: actText
                x: 28
                y: msgText.y + (msgText.text !== "" ? msgText.implicitHeight + 2 : 0)
                width: parent.width - 56
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideMiddle
                textFormat: Text.PlainText
                text: (agent.flow && agent.flow.actionId) ? agent.flow.actionId : ""
                font.family: Theme.uiFont; font.pixelSize: Theme.fsTiny; color: Theme.muted
            }

            Rectangle {                             // password box
                antialiasing: true
                x: 24
                y: 134 + card.extra
                width: parent.width - 48
                height: 42
                radius: 21
                color: Theme.field
                border.width: 1.5
                border.color: root.wrong ? Theme.danger : (field.activeFocus ? Qt.alpha(Theme.accent, 0.6) : "transparent")

                TextInput {
                    id: field
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    font.family: Theme.uiFont
                    font.pixelSize: 15
                    color: Theme.text
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.accentText
                    clip: true
                    focus: true

                    onAccepted: root.submit()
                    Keys.onEscapePressed: root.cancel()
                    onTextChanged: if (text.length > 0) root.wrong = false

                    Text {                           // box khali ho tab dikhne wala hint
                        visible: field.text.length === 0
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.busy ? "Checking…" : (root.wrong ? "Wrong password" : "Password")
                        font.family: Theme.uiFont
                        font.pixelSize: 15
                        color: root.wrong ? Theme.danger : Theme.muted
                    }
                }
            }
            Text {                                  // small hint under the password box
                x: 24
                y: 134 + card.extra + 50
                width: parent.width - 48
                horizontalAlignment: Text.AlignHCenter
                text: "Enter = confirm  ·  Esc = cancel"
                font.family: Theme.uiFont; font.pixelSize: Theme.fsTiny; color: Theme.muted
            }
        }
    }
}
SNOW_FILE_END_4b7d
;;
*) return 1 ;;
esac
}
pre() {
apt_install polkitd
}
extra_check() {
for n in polkit/PolkitDialog; do qml_ok "$QS/$n.qml"; done
}
component_main "$@"
