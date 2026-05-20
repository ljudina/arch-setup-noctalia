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
  property int updateIntervalMs: cfg.updateIntervalMs ?? defaults.updateIntervalMs ?? 2000

  spacing: Style.marginL

  Component.onCompleted: Logger.i("NetworkToggle", "Settings UI loaded")

  NColorChoice {
    label: pluginApi?.tr("settings.customColor.label") || "Custom color"
    description: pluginApi?.tr("settings.customColor.desc") || "Color used for the network toggle icon."
    currentKey: root.customColor
    onSelected: key => root.customColor = key
  }

  NComboBox {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.updateInterval.label") || "Update interval"
    description: pluginApi?.tr("settings.updateInterval.desc") || "How often the toggle checks NetworkManager state."
    model: [
      { "key": "1000", "name": pluginApi?.tr("settings.interval.one") || "1 second" },
      { "key": "2000", "name": pluginApi?.tr("settings.interval.two") || "2 seconds" },
      { "key": "5000", "name": pluginApi?.tr("settings.interval.five") || "5 seconds" }
    ]
    currentKey: String(root.updateIntervalMs)
    onSelected: key => root.updateIntervalMs = Number(key)
    defaultValue: "2000"
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("NetworkToggle", "Cannot save settings: pluginApi is null")
      return
    }

    pluginApi.pluginSettings.customColor = root.customColor
    pluginApi.pluginSettings.updateIntervalMs = root.updateIntervalMs
    pluginApi.saveSettings()

    Logger.i("NetworkToggle", "Settings saved successfully")
    pluginApi.closePanel(root.screen)
  }
}
