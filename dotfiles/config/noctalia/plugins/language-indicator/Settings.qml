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

  property string label0: cfg.label0 ?? defaults.label0 ?? "EN"
  property string label1: cfg.label1 ?? defaults.label1 ?? "SR"
  property string label2: cfg.label2 ?? defaults.label2 ?? "RS"
  property string customColor: cfg.customColor ?? defaults.customColor ?? "none"

  spacing: Style.marginL

  Component.onCompleted: Logger.i("LanguageIndicator", "Settings UI loaded")

  NColorChoice {
    label: pluginApi?.tr("settings.customColor.label") || "Custom color"
    description: pluginApi?.tr("settings.customColor.desc") || "Color used for the label text."
    currentKey: root.customColor
    onSelected: key => root.customColor = key
  }

  NTextInput {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.label0.label") || "Layout 0 label (English US)"
    description: pluginApi?.tr("settings.label0.desc") || "Short code shown when layout index 0 is active."
    text: root.label0
    placeholderText: "EN"
    onEditingFinished: root.label0 = text
  }

  NTextInput {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.label1.label") || "Layout 1 label (Serbian Cyrillic)"
    description: pluginApi?.tr("settings.label1.desc") || "Short code shown when layout index 1 is active."
    text: root.label1
    placeholderText: "SR"
    onEditingFinished: root.label1 = text
  }

  NTextInput {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.label2.label") || "Layout 2 label (Serbian Latin)"
    description: pluginApi?.tr("settings.label2.desc") || "Short code shown when layout index 2 is active."
    text: root.label2
    placeholderText: "RS"
    onEditingFinished: root.label2 = text
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("LanguageIndicator", "Cannot save settings: pluginApi is null")
      return
    }
    pluginApi.pluginSettings.label0 = root.label0
    pluginApi.pluginSettings.label1 = root.label1
    pluginApi.pluginSettings.label2 = root.label2
    pluginApi.pluginSettings.customColor = root.customColor
    pluginApi.saveSettings()
    Logger.i("LanguageIndicator", "Settings saved successfully")
    pluginApi.closePanel(root.screen)
  }
}
