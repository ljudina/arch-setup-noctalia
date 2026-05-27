import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
  id: root
  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  readonly property var s: pluginApi?.pluginSettings || pluginApi?.manifest?.metadata?.defaultSettings || {}
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || {}
  readonly property string screenName: screen?.name || ""
  readonly property bool isVertical: ["left", "right"].includes(Settings.getBarPositionForScreen(screenName))

  property int activeIndex: 0
  property string activeKeymap: ""
  property string keyboardName: "main"
  property bool initialized: false

  readonly property string displayLabel: {
    const key = "label" + activeIndex
    return s[key] ?? defaults[key] ?? "??"
  }

  implicitWidth: isVertical ? Style.getBarHeightForScreen(screenName) - Style.marginL : label.implicitWidth + Style.marginM * 2
  implicitHeight: isVertical ? label.implicitHeight + Style.marginS * 2 : Style.getCapsuleHeightForScreen(screenName)

  Rectangle {
    anchors.centerIn: parent
    width: parent.implicitWidth
    height: parent.implicitHeight
    color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
    radius: Style.radiusL
    border { color: Style.capsuleBorderColor; width: Style.capsuleBorderWidth }

    NText {
      id: label
      anchors.centerIn: parent
      text: root.displayLabel
      color: mouseArea.containsMouse ? Color.mOnHover : Color.resolveColorKey(root.s.customColor || "none")
      pointSize: Style.getBarFontSizeForScreen(screenName)
      features: ({"tnum": 1})
    }
  }

  Process {
    id: refresh
    command: ["hyprctl", "devices", "-j"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const devices = JSON.parse(text)
          const kbs = devices.keyboards || []
          let kb = kbs.find(k => k.main) || kbs[0]
          if (kb) {
            const newIndex = kb.active_layout_index ?? 0
            const changed = root.initialized && newIndex !== root.activeIndex
            root.activeIndex = newIndex
            root.activeKeymap = kb.active_keymap ?? ""
            root.keyboardName = kb.name || "main"
            if (changed) {
              // hyprctl reports bare "Serbian" for the Cyrillic rs layout
              // (Latin reports "Serbian (Latin)"); qualify it explicitly.
              const desc = root.activeKeymap === "Serbian" ? "Serbian (Cyrillic)" : root.activeKeymap
              ToastService.showNotice(root.displayLabel, desc)
            }
            root.initialized = true
          }
        } catch (e) {
          Logger.e("LanguageIndicator", "Failed to parse hyprctl output: " + e)
        }
      }
    }
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event.name === "activelayout") {
        refresh.running = true
      }
    }
  }

  Process {
    id: cycler
    command: ["hyprctl", "switchxkblayout", root.keyboardName, "next"]
    running: false
  }

  Component.onCompleted: refresh.running = true

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onEntered: {
      const tip = root.activeKeymap || root.displayLabel
      TooltipService.show(root, tip, BarService.getTooltipDirection(screenName))
    }
    onExited: TooltipService.hide()
    onClicked: (mouse) => {
      if (mouse.button === Qt.LeftButton) {
        cycler.running = true
      } else {
        PanelService.showContextMenu(contextMenu, root, screen)
      }
    }
  }

  NPopupContextMenu {
    id: contextMenu
    model: [
      { label: pluginApi?.tr("menu.settings") || "Widget Settings", action: "settings", icon: "settings" }
    ]
    onTriggered: (action) => {
      contextMenu.close()
      PanelService.closeContextMenu(screen)
      if (action === "settings") BarService.openPluginSettings(screen, pluginApi.manifest)
    }
  }
}
