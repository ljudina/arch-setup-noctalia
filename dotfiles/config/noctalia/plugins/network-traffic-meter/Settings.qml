import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  property string customColor: cfg.customColor ?? defaults.customColor ?? "none"
  property int updateIntervalMs: cfg.updateIntervalMs ?? defaults.updateIntervalMs ?? 1000
  property bool hideWhenZero: cfg.hideWhenZero ?? defaults.hideWhenZero ?? false

  spacing: Style.marginL

  Component.onCompleted: Logger.i("NetworkTrafficMeter", "Settings UI loaded")

  NColorChoice {
    label: pluginApi?.tr("settings.customColor.label") || "Custom color"
    description: pluginApi?.tr("settings.customColor.desc") || "Color used for the meter text and icons."
    currentKey: root.customColor
    onSelected: key => root.customColor = key
  }

  NComboBox {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.updateInterval.label") || "Update interval"
    description: pluginApi?.tr("settings.updateInterval.desc") || "How often the meter samples /proc/net/dev."
    model: [
      { "key": "500", "name": pluginApi?.tr("settings.interval.half") || "0.5 seconds" },
      { "key": "1000", "name": pluginApi?.tr("settings.interval.one") || "1 second" },
      { "key": "2000", "name": pluginApi?.tr("settings.interval.two") || "2 seconds" }
    ]
    currentKey: String(root.updateIntervalMs)
    onSelected: key => root.updateIntervalMs = Number(key)
    defaultValue: "1000"
  }

  NToggle {
    label: pluginApi?.tr("settings.hideWhenZero.label") || "Hide when idle"
    description: pluginApi?.tr("settings.hideWhenZero.desc") || "Hide the widget when both directions are at zero."
    checked: root.hideWhenZero
    onToggled: checked => root.hideWhenZero = checked
    defaultValue: false
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("NetworkTrafficMeter", "Cannot save settings: pluginApi is null")
      return
    }

    pluginApi.pluginSettings.customColor = root.customColor
    pluginApi.pluginSettings.updateIntervalMs = root.updateIntervalMs
    pluginApi.pluginSettings.hideWhenZero = root.hideWhenZero
    pluginApi.saveSettings()

    Logger.i("NetworkTrafficMeter", "Settings saved successfully")
    pluginApi.closePanel(root.screen)
  }
}
