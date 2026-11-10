#!/usr/bin/env bash
# 14-notifications.sh : Panel: notifications
# Own notification popups (replaces mako/dunst).
#   bash Script/14-notifications.sh          install / restore this part (safe to run again; run it inside your Snow folder, any folder name works)
#   bash Script/14-notifications.sh check    read-only check
MOD="14-notifications"; TITLE="Panel: notifications"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
QS="$HOME/.config/quickshell/snow"; BIN="$HOME/.config/snow/bin"; HYPR="$HOME/.config/hypr"; KITTY="$HOME/.config/kitty"; CONF="$HOME/.config/snow"
ITEMS=(
  "u|.config/quickshell/snow/notifications/Notifs.qml|644|0"
)
emit() {
case "$1" in
"u/.config/quickshell/snow/notifications/Notifs.qml")
cat <<'SNOW_FILE_END_4b7d'
// ============================================================================
//  Notifs.qml  —  NOTIFICATION POP-UPS  (hum khud notification daemon hain)
// ----------------------------------------------------------------------------
//  DIKHTA KYA HAI : Screen ke upar-daayein chhote cards: title, text, aur agar app de to action buttons.
//  KAISE CHALTA HAI:
//     - Card par click (left/right) = band.     - Aam notification ~6 second me apne aap jati hai.
//     - Mouse card par rakho to timer ruk jata hai (padhne ke liye); hatate hi phir chalta hai.
//     - Ek saath maxCards (4) se zyada nahi dikhti: baaki line me rukti hain aur neeche "+N more" dikhta hai.
//       Urgent notification hamesha dikhti hai.
//     - Upar chhota app icon + app ka naam dikhta hai (jab app bataye ya icon mil jaye).
//     - Urgent (critical) notification tab tak rehti hai jab tak tum click na karo (laal patti).
//     - Text hamesha PLAIN hota hai (HTML / remote image nahi) — safety ke liye.
//  TEST : notify-send "Hello" "body"      urgent test: notify-send -u critical "Urgent" "click me"
//  BADLO (SETTINGS) : defaultSeconds, maxSeconds, cardWidth, maxCards.
//  NOTE : shell.qml isse code se load karta hai, taki module na mile to shell na toote.
// ============================================================================
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import qs.core

Scope {
    id: root

    // ---------------- SETTINGS (yahan badlo) ----------------
    readonly property int defaultSeconds: 6     // app ne time nahi bataya to kitni der dikhe
    readonly property int maxSeconds: 15        // app ne bahut bada time manga to bhi itna hi
    readonly property int cardWidth: 360
    readonly property int maxCards: 4           // ek saath kitni cards dikhein (urgent ko chhodke)

    // kitni (urgent nahi wali) notifications line me ruki hain aur abhi chhupi hain
    readonly property int hiddenCount: {
        const l = server.trackedNotifications.values
        let h = 0
        for (let i = root.maxCards; i < l.length; ++i) if (l[i].urgency !== NotificationUrgency.Critical) h++
        return h
    }

    // app ka icon dhoondo: app ka diya icon -> app ki .desktop file ka icon -> app ke naam wala icon.
    // Sirf local files / icon-theme ke naam; http(s) wali link kabhi load nahi hoti (safety).
    function iconFor(n) {
        try {
            var ic = n.appIcon || ""
            if (ic.indexOf("file://") === 0) return ic
            if (ic.charAt(0) === "/") return "file://" + ic
            var p
            if (ic !== "" && ic.indexOf("://") < 0) { p = Quickshell.iconPath(ic, true); if (p) return p }
            var e
            var de = n.desktopEntry || ""
            if (de !== "") {
                e = DesktopEntries.heuristicLookup(de)
                if (e && e.icon) { p = Quickshell.iconPath(e.icon, true); if (p) return p }
            }
            var nm = n.appName || ""
            if (nm !== "") {
                p = Quickshell.iconPath(nm.toLowerCase(), true); if (p) return p
                e = DesktopEntries.heuristicLookup(nm)
                if (e && e.icon) { p = Quickshell.iconPath(e.icon, true); if (p) return p }
            }
        } catch (err) { }
        return ""
    }

    NotificationServer {
        id: server
        keepOnReload: false
        bodySupported: true
        bodyMarkupSupported: false              // plain text only
        actionsSupported: true
        imageSupported: true
        onNotification: (n) => { n.tracked = true }     // track karo, tabhi dikhegi
    }

    PanelWindow {
        id: win
        visible: server.trackedNotifications.values.length > 0
        color: "transparent"
        anchors { top: true; right: true }
        margins { top: 16; right: 16 }
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: root.cardWidth
        implicitHeight: Math.max(1, col.implicitHeight)
        mask: Region { item: col }               // sirf cards click lete hain, baaki jagah click-through

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "snow-notify"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Column {
            id: col
            width: parent.width
            spacing: 10

            Repeater {
                model: server.trackedNotifications

                delegate: Rectangle {
                    antialiasing: true
                    id: card
                    required property var modelData
                    required property int index
                    readonly property bool critical: modelData.urgency === NotificationUrgency.Critical
                    readonly property bool shown: index < root.maxCards || critical     // baaki line me rukti hain
                    readonly property string iconSrc: root.iconFor(modelData)
                    readonly property string appLabel: modelData.appName || ""
                    // "default" action ko chhodke baaki saare buttons
                    readonly property var acts: {
                        const a = []
                        const l = modelData.actions
                        for (let i = 0; i < l.length; ++i) if (l[i].identifier !== "default") a.push(l[i])
                        return a
                    }

                    visible: shown
                    width: col.width
                    height: body.implicitHeight + 28
                    radius: Theme.rCard - 2
                    color: Theme.cardBg
                    border.width: 1
                    border.color: Theme.hairline
                    opacity: 0
                    Component.onCompleted: opacity = 1
                    Behavior on opacity { NumberAnimation { duration: 180 } }

                    // laal / accent patti (left)
                    Rectangle { antialiasing: true; x: 8; y: 16; width: 3; height: parent.height - 32; radius: 1.5; color: card.critical ? Theme.danger : Theme.accent }

                    // mouse card par ho to timer ruk jata hai (hatate hi poora time phir se)
                    HoverHandler { id: hov }

                    // apne aap jaane ka timer (urgent ke liye nahi; chhupi hui card ka bhi nahi)
                    Timer {
                        running: !card.critical && card.shown && !hov.hovered
                        interval: (card.modelData.expireTimeout > 0 ? Math.min(card.modelData.expireTimeout, root.maxSeconds) : root.defaultSeconds) * 1000
                        onTriggered: card.modelData.expire()
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: card.modelData.dismiss()
                    }

                    Column {
                        id: body
                        x: 22
                        y: 14
                        width: parent.width - 40
                        spacing: 4

                        Row {                                            // app icon + app ka naam
                            visible: card.iconSrc !== "" || card.appLabel !== ""
                            spacing: 6
                            Image {
                                visible: card.iconSrc !== ""
                                width: 16; height: 16
                                sourceSize.width: 32; sourceSize.height: 32
                                source: card.iconSrc
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                            }
                            Text {
                                textFormat: Text.PlainText
                                visible: text !== ""
                                height: 16
                                verticalAlignment: Text.AlignVCenter
                                width: Math.min(implicitWidth, card.width - 40 - (card.iconSrc !== "" ? 22 : 0))
                                text: card.appLabel
                                font.family: Theme.uiFont; font.pixelSize: Theme.fsTiny; color: Theme.muted
                                elide: Text.ElideRight
                            }
                        }
                        Text {                                           // title
                            textFormat: Text.PlainText
                            width: parent.width
                            visible: text !== ""
                            text: card.modelData.summary
                            font.family: Theme.uiFont; font.pixelSize: 14; font.weight: Font.DemiBold; color: Theme.text
                            elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.Wrap
                        }
                        Text {                                           // body
                            textFormat: Text.PlainText
                            width: parent.width
                            visible: text !== ""
                            text: card.modelData.body
                            font.family: Theme.uiFont; font.pixelSize: Theme.fsBody; color: Theme.muted
                            elide: Text.ElideRight; maximumLineCount: 3; wrapMode: Text.Wrap
                        }
                        Row {                                            // action buttons
                            visible: card.acts.length > 0
                            spacing: 6
                            topPadding: 4
                            Repeater {
                                model: card.acts
                                delegate: Rectangle {
                                    antialiasing: true
                                    id: chip
                                    required property var modelData
                                    width: lbl.implicitWidth + 24
                                    height: 28
                                    radius: 14
                                    color: chipArea.containsMouse ? Theme.pressed : Theme.hover
                                    Text {
                                        id: lbl
                                        textFormat: Text.PlainText
                                        anchors.centerIn: parent
                                        text: chip.modelData.text
                                        font.family: Theme.uiFont; font.pixelSize: Theme.fsSmall; color: Theme.text
                                    }
                                    MouseArea {
                                        id: chipArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: { chip.modelData.invoke(); card.modelData.dismiss() }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // line me ruki hui notifications ka chhota nishan (sirf dikhane ke liye)
            Rectangle {
                antialiasing: true
                visible: root.hiddenCount > 0
                x: col.width - width
                width: moreTxt.implicitWidth + 24
                height: 26
                radius: 13
                color: Theme.cardBg
                border.width: 1
                border.color: Theme.hairline
                Text {
                    id: moreTxt
                    anchors.centerIn: parent
                    text: "+" + root.hiddenCount + " more"
                    font.family: Theme.uiFont; font.pixelSize: Theme.fsSmall; color: Theme.muted
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
pre() {
apt_install libnotify-bin
}
extra_check() {
for n in notifications/Notifs; do qml_ok "$QS/$n.qml"; done
}
component_main "$@"
