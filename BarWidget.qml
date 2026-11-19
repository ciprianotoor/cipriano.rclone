import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "rclone.activity"
  function injectPanel() { var t = panelLoader.item; if (!t) return; t.bar = root.bar; t.anchorItem = button; t.hostWidget = root }
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened : false
  function open() { if (panelLoader.item) panelLoader.item.openFromHotkey() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function togglePanel() { if (panelLoader.item) panelLoader.item.toggle() }
  function openWeb() { if (panelLoader.item) panelLoader.item.openWeb() }
  function closeForPopoutSwitch() { close() }
  readonly property bool popoutSwitchClosing: false
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  onBarChanged: injectPanel()
  Loader { id: panelLoader; active: true; source: Qt.resolvedUrl("Panel.qml"); visible: false; onLoaded: { root.injectPanel(); Qt.callLater(root.injectPanel) } }
  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: panelLoader.item ? panelLoader.item.icon : "󰆼"
    tooltipText: panelLoader.item ? panelLoader.item.tooltip : "Rclone"
    onPressed: function(b) {
      if (b === Qt.RightButton) root.togglePanel()
      else if (b === Qt.MiddleButton && panelLoader.item) panelLoader.item.refresh()
      else root.togglePanel()
    }
  }
}
