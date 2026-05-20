import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import qs.Widgets

NIconButton {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  readonly property var s: pluginApi?.pluginSettings || pluginApi?.manifest?.metadata?.defaultSettings || {}

  property string networkState: "unknown"
  property string pendingNetworkState: ""

  icon: networkIcon()
  tooltipText: networkTooltip()
  tooltipDirection: BarService.getTooltipDirection(screen?.name)
  baseSize: Style.getCapsuleHeightForScreen(screen?.name)
  applyUiScale: false
  customRadius: Style.radiusL
  colorBg: Style.capsuleColor
  colorFg: Color.resolveColorKey(root.s.customColor || "none")
  border.color: Style.capsuleBorderColor
  border.width: Style.capsuleBorderWidth

  function normalizeNetworkState(text) {
    const state = (text || "").trim().toLowerCase()
    if (state.indexOf("enabled") >= 0)
      return "enabled"
    if (state.indexOf("disabled") >= 0)
      return "disabled"
    return "unknown"
  }

  function networkIcon() {
    if (networkState === "enabled")
      return "wifi"
    if (networkState === "disabled")
      return "wifi-off"
    return "circle-alert"
  }

  function networkTooltip() {
    if (networkState === "enabled")
      return (pluginApi?.tr("tooltip.networkingEnabled") || "NetworkManager networking enabled") + "\n" + (pluginApi?.tr("tooltip.toggleOff") || "Click to turn networking off")
    if (networkState === "disabled")
      return (pluginApi?.tr("tooltip.networkingDisabled") || "NetworkManager networking disabled") + "\n" + (pluginApi?.tr("tooltip.toggleOn") || "Click to turn networking on")
    return (pluginApi?.tr("tooltip.networkingUnknown") || "NetworkManager unavailable") + "\n" + (pluginApi?.tr("tooltip.unavailable") || "Install and run NetworkManager for this toggle")
  }

  onClicked: {
    if (root.networkState === "unknown")
      return

    root.pendingNetworkState = root.networkState === "enabled" ? "disabled" : "enabled"
    toggleNetwork.command = ["nmcli", "networking", root.networkState === "enabled" ? "off" : "on"]
    toggleNetwork.running = true
  }

  onRightClicked: PanelService.showContextMenu(contextMenu, root, screen)

  Component.onCompleted: networkStatus.running = true

  Timer {
    interval: Math.max(1000, Number(root.s.updateIntervalMs ?? 2000) || 2000)
    running: true
    repeat: true
    onTriggered: networkStatus.running = true
  }

  Process {
    id: networkStatus
    command: ["nmcli", "-t", "-f", "NETWORKING", "general", "status"]
    stdout: StdioCollector {
      onStreamFinished: root.networkState = root.normalizeNetworkState(text)
    }
    stderr: StdioCollector {
      onStreamFinished: {
        if ((text || "").trim().length > 0)
          root.networkState = "unknown"
      }
    }
  }

  Process {
    id: toggleNetwork
    stdout: StdioCollector {
      onStreamFinished: networkStatus.running = true
    }
    stderr: StdioCollector {
      onStreamFinished: {
        if ((text || "").trim().length > 0)
          root.networkState = "unknown"
      }
    }
    onExited: {
      if (root.pendingNetworkState.length > 0)
        root.networkState = root.pendingNetworkState
      root.pendingNetworkState = ""
      networkStatus.running = true
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
