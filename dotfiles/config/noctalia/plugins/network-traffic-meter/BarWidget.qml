import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  readonly property var s: pluginApi?.pluginSettings || pluginApi?.manifest?.metadata?.defaultSettings || {}
  readonly property string screenName: screen?.name || ""
  readonly property bool isVertical: ["left", "right"].includes(Settings.getBarPositionForScreen(screenName))
  readonly property color contentColor: mouseArea.containsMouse ? Color.mOnHover : Color.resolveColorKey(root.s.customColor || "none")
  readonly property bool idle: downBps <= 0 && upBps <= 0
  readonly property bool meterVisible: !(root.s.hideWhenZero === true && idle)

  property real lastRxBytes: -1
  property real lastTxBytes: -1
  property double lastSampleMs: 0
  property real downBps: 0
  property real upBps: 0

  visible: meterVisible
  opacity: meterVisible ? 1.0 : 0.0
  implicitWidth: isVertical ? Style.getBarHeightForScreen(screenName) - Style.marginL : layout.implicitWidth + Style.marginM * 2
  implicitHeight: isVertical ? layout.implicitHeight + Style.marginS * 2 : Style.getCapsuleHeightForScreen(screenName)

  function nowMs() {
    return Date.now()
  }

  function formatRate(bitsPerSecond) {
    const value = Math.max(0, Number(bitsPerSecond) || 0)

    if (value >= 1000000000)
      return (value / 1000000000).toFixed(2) + " Gbits/s"
    if (value >= 1000000)
      return (value / 1000000).toFixed(2) + " Mbits/s"
    return (value / 1000).toFixed(2) + " Kbits/s"
  }

  function parseProcNetDev(text) {
    const lines = text.split("\n")
    let rx = 0
    let tx = 0
    let interfaces = 0

    for (let i = 2; i < lines.length; i++) {
      const line = lines[i].trim()
      if (!line || line.indexOf(":") < 0)
        continue

      const parts = line.split(":")
      const iface = parts[0].trim()
      if (!iface || iface === "lo")
        continue

      const fields = parts[1].trim().split(/\s+/)
      if (fields.length < 16)
        continue

      rx += Number(fields[0]) || 0
      tx += Number(fields[8]) || 0
      interfaces++
    }

    return { rx: rx, tx: tx, interfaces: interfaces }
  }

  function updateTraffic(text) {
    const sample = parseProcNetDev(text)
    const currentMs = nowMs()

    if (lastRxBytes >= 0 && lastTxBytes >= 0 && lastSampleMs > 0) {
      const elapsedSeconds = Math.max(0.001, (currentMs - lastSampleMs) / 1000)
      root.downBps = Math.max(0, (sample.rx - lastRxBytes) * 8 / elapsedSeconds)
      root.upBps = Math.max(0, (sample.tx - lastTxBytes) * 8 / elapsedSeconds)
    }

    lastRxBytes = sample.rx
    lastTxBytes = sample.tx
    lastSampleMs = currentMs
  }

  function meterTooltip() {
    return "Down: " + formatRate(downBps) + "\nUp: " + formatRate(upBps)
  }

  Rectangle {
    anchors.centerIn: parent
    width: parent.implicitWidth
    height: parent.implicitHeight
    color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
    radius: Style.radiusL
    border { color: Style.capsuleBorderColor; width: Style.capsuleBorderWidth }

    NText {
      id: rateWidthProbe
      visible: false
      text: "999.99 Mbits/s"
      pointSize: Style.getBarFontSizeForScreen(screenName)
      features: ({"tnum": 1})
    }

    MouseArea {
      id: mouseArea
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.RightButton
      propagateComposedEvents: true
      onEntered: TooltipService.show(root, root.meterTooltip(), BarService.getTooltipDirection(screenName))
      onExited: TooltipService.hide()
      onClicked: (mouse) => {
        if (mouse.button === Qt.RightButton) {
          PanelService.showContextMenu(contextMenu, root, screen)
        } else {
          mouse.accepted = false
        }
      }
    }

    GridLayout {
      id: layout
      anchors.centerIn: parent
      columns: root.isVertical ? 1 : 4
      rowSpacing: Style.marginXS
      columnSpacing: Style.marginS

      NIcon {
        Layout.alignment: Qt.AlignCenter
        icon: "arrow-down"
        color: root.contentColor
      }

      NText {
        Layout.alignment: Qt.AlignCenter
        Layout.preferredWidth: rateWidthProbe.implicitWidth
        text: root.formatRate(root.downBps)
        color: root.contentColor
        pointSize: Style.getBarFontSizeForScreen(screenName)
        horizontalAlignment: Text.AlignRight
        features: ({"tnum": 1})
      }

      NIcon {
        Layout.alignment: Qt.AlignCenter
        icon: "arrow-up"
        color: root.contentColor
      }

      NText {
        Layout.alignment: Qt.AlignCenter
        Layout.preferredWidth: rateWidthProbe.implicitWidth
        text: root.formatRate(root.upBps)
        color: root.contentColor
        pointSize: Style.getBarFontSizeForScreen(screenName)
        horizontalAlignment: Text.AlignRight
        features: ({"tnum": 1})
      }
    }
  }

  Timer {
    interval: Math.max(500, Number(root.s.updateIntervalMs ?? 1000) || 1000)
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: trafficReader.running = true
  }

  Process {
    id: trafficReader
    command: ["cat", "/proc/net/dev"]
    stdout: StdioCollector {
      onStreamFinished: root.updateTraffic(text)
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
      if (action === "settings")
        BarService.openPluginSettings(screen, pluginApi.manifest)
    }
  }
}
