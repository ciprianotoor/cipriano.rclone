import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Panel {
  id: root
  moduleName: "cipriano.rclone"
  ipcTarget: "cipriano.rclone"
  manageIpc: false
  property var anchorItem: null
  property var hostWidget: null
  property string activity: "Sin actividad reciente"
  property string lastAction: ""
  property string lastPath: ""
  property int lastDeletes: 0
  property string transfer: ""
  property string transfers: "No hay archivos sincronizándose ahora"
  property string serviceState: "comprobando…"
  readonly property string icon: "󰆼"
  readonly property string tooltip: "Rclone: " + serviceState + (transfer === "" ? "" : " · " + transfer)
  function openFromHotkey() { root.controller.show(); refresh() }
  function toggle() { opened ? close() : openFromHotkey() }
  function close() { root.controller.hide() }
  function refresh() {
    serviceCheck.running = true
    stats.running = true
    log.running = false
    Qt.callLater(function() { log.running = true })
  }
  function openWeb() { root.lastAction = "Interfaz web abierta"; if (root.bar) root.bar.run("xdg-open http://127.0.0.1:5572") }
  Process {
    id: serviceCheck
    command: ["systemctl", "--user", "is-active", "rclone-onedrive.service"]
    stdout: StdioCollector { onStreamFinished: root.serviceState = text.trim() === "active" ? "activo" : "detenido" }
  }
  Process {
    id: stats
    command: ["rclone", "rc", "--url", "http://127.0.0.1:5572", "core/stats"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var v = JSON.parse(text)
          var b = Number(v.bytes || 0)
          root.transfer = b > 0 ? (b / 1048576).toFixed(1) + " MiB transferidos" : "sin transferencias"
          var deletes = Number(v.deletes || 0)
          if (deletes > root.lastDeletes && root.lastDeletes > 0) root.lastAction = "Archivo eliminado de OneDrive"
          root.lastDeletes = deletes
          var active = v.transferring || []
          if (active.length > 0) {
            var names = []
            for (var i = 0; i < Math.min(active.length, 6); i++) {
              var item = active[i]
              var remoteName = String(item.name || item.path || "archivo en transferencia")
              var localName = remoteName.indexOf("/") === 0 ? remoteName : "/OneDrive/" + remoteName
              names.push(localName)
            }
            root.transfers = names.join("\n")
          } else {
            root.transfers = "No hay archivos sincronizándose ahora"
          }
        } catch (e) {
          root.transfer = "sin estadísticas"
          root.transfers = "No se pudieron consultar las transferencias"
        }
      }
    }
  }
  Process {
    id: log
    command: ["/home/cipriano/.local/bin/rclone-latest-activity.sh"]
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = text.trim().split("\n")
        var useful = []
        for (var i = 0; i < lines.length; i++) {
          var line = lines[i].trim()
          var lower = line.toLowerCase()
          var fields = line.split("|")
          if (fields.length >= 3) root.lastPath = fields.slice(2).join("|")
          if (line === "" || lower.indexOf("error") >= 0 || lower.indexOf("warn") >= 0 || lower.indexOf("failed") >= 0 || lower.indexOf("webgui") >= 0 || lower.indexOf("gui") >= 0 || lower.indexOf("serving") >= 0 || lower.indexOf("release") >= 0 || lower.indexOf("downloaded") >= 0) continue
          useful.push(fields.length >= 3 ? fields[0] + "  " + fields[1] + "  " + fields.slice(2).join("|") : line)
        }
        root.activity = useful.length > 0 ? useful.slice(-2).join("\n") : "Sin actividad reciente"
      }
    }
  }
  Process { id: openActivity; command: ["xdg-open", root.lastPath]; onExited: root.lastAction = "Actividad abierta" }
  readonly property string homeActivityLog: Quickshell.env("HOME") + "/.local/state/rclone/activity.log"
  Timer { interval: 1000; running: true; repeat: true; onTriggered: root.refresh() }
  Component.onCompleted: refresh()
  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    centerOnBar: false
    contentWidth: Style.space(460)
    contentHeight: Style.space(420)
    content: Column {
      anchors.fill: parent
      anchors.margins: Style.space(10)
      clip: true
      Column {
        id: contentColumn
        width: parent.width - Style.space(12)
        anchors.left: parent.left
        anchors.leftMargin: Style.space(6)
      spacing: Style.space(12)
      Row {
        width: parent.width
        spacing: Style.space(10)
        Text { text: "󰆼"; textFormat: Text.PlainText; color: Commons.Color.accent; font.pixelSize: 30 }
        Column {
          spacing: Style.space(2)
          Text { text: "RCLONE"; textFormat: Text.PlainText; color: root.bar.foreground; font.pixelSize: Style.font.pixelSizeLarge; font.bold: true }
          Text { text: "OneDrive"; textFormat: Text.PlainText; color: Qt.darker(root.bar.foreground, 1.35); font.pixelSize: 12 }
        }
        Item { Layout.fillWidth: true }
        Text { text: root.serviceState === "activo" ? "● ACTIVO" : "● DETENIDO"; textFormat: Text.PlainText; color: root.serviceState === "activo" ? Commons.Color.accent : Commons.Color.urgent; font.pixelSize: 12; font.bold: true }
      }
      Rectangle {
        width: parent.width
        height: 1
        color: Qt.darker(root.bar.foreground, 3.0)
      }
      Rectangle {
        width: parent.width
        height: Style.space(64)
        radius: Style.space(8)
        color: Qt.darker(root.bar.foreground, 3.5)
        border.width: 1
        border.color: Qt.darker(root.bar.foreground, 2.8)
        Column {
          anchors.fill: parent
          anchors.margins: Style.space(10)
          spacing: Style.space(4)
          Text { text: "ACTIVIDAD"; textFormat: Text.PlainText; color: Qt.darker(root.bar.foreground, 1.4); font.pixelSize: 11; font.bold: true }
          Text { text: root.transfer === "" ? "Sin transferencias" : root.transfer; textFormat: Text.PlainText; color: Commons.Color.accent; font.bold: true }
          Text { text: "Destino  /OneDrive"; textFormat: Text.PlainText; color: Qt.darker(root.bar.foreground, 1.25); font.pixelSize: 11 }
        }
      }
      Text { text: "TRANSFERENCIAS"; textFormat: Text.PlainText; color: Qt.darker(root.bar.foreground, 1.4); font.pixelSize: 11; font.bold: true }
      Rectangle {
        width: parent.width
        height: Style.space(52)
        radius: Style.space(8)
        color: Qt.darker(root.bar.foreground, 3.8)
        Text { id: transferText; anchors.fill: parent; anchors.margins: Style.space(10); text: root.transfers; textFormat: Text.PlainText; color: root.bar.foreground; height: Style.space(32); maximumLineCount: 2; elide: Text.ElideRight; wrapMode: Text.NoWrap; clip: true }
      }
      Text { text: "ÚLTIMA ACTIVIDAD"; textFormat: Text.PlainText; color: Qt.darker(root.bar.foreground, 1.4); font.pixelSize: 11; font.bold: true }
      Rectangle {
        width: parent.width
        height: Style.space(44)
        radius: Style.space(7)
        color: activityMouse.containsMouse && root.lastPath !== "" ? Style.hoverFillFor(root.bar.foreground, Commons.Color.accent) : Style.normalFillFor(root.bar.foreground, Commons.Color.background)
        Behavior on color { ColorAnimation { duration: Style.duration(160) } }
        Text { anchors.fill: parent; anchors.margins: Style.space(10); text: root.activity !== "Sin actividad reciente" ? root.activity : (root.lastAction !== "" ? root.lastAction : "Sin actividad reciente"); textFormat: Text.PlainText; color: root.bar.foreground; maximumLineCount: 2; elide: Text.ElideRight; wrapMode: Text.NoWrap; clip: true }
        MouseArea { id: activityMouse; anchors.fill: parent; hoverEnabled: true; onClicked: if (root.lastPath !== "") { openActivity.command = ["xdg-open", root.lastPath]; openActivity.running = true; root.close() } }
      }
      Row {
        spacing: Style.space(8)
        Rectangle {
          width: Style.space(112); height: Style.space(30); radius: Style.space(6); color: webMouse.containsMouse ? Style.hoverStateColor(root.bar.foreground, Commons.Color.accent) : Style.normalFillFor(root.bar.foreground, Commons.Color.accent)
          Behavior on color { ColorAnimation { duration: Style.duration(160) } }
          Text { anchors.centerIn: parent; text: "Interfaz web"; textFormat: Text.PlainText; color: root.bar.foreground; font.pixelSize: 11; font.bold: true }
          MouseArea { id: webMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { root.openWeb(); root.close() } }
        }
        Rectangle {
          width: Style.space(112); height: Style.space(30); radius: Style.space(6); color: folderMouse.containsMouse ? Style.hoverStateColor(root.bar.foreground, Commons.Color.accent) : Style.normalFillFor(root.bar.foreground, Commons.Color.background)
          Behavior on color { ColorAnimation { duration: Style.duration(160) } }
          Text { anchors.centerIn: parent; text: "Abrir carpeta"; textFormat: Text.PlainText; color: root.bar.foreground; font.pixelSize: 11 }
          MouseArea { id: folderMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { root.lastAction = "Carpeta OneDrive abierta"; if (root.bar) root.bar.run("xdg-open /OneDrive"); root.close() } }
        }
        Rectangle {
          width: Style.space(34); height: Style.space(30); radius: Style.space(6); color: refreshMouse.containsMouse ? Style.hoverStateColor(root.bar.foreground, Commons.Color.accent) : Style.normalFillFor(root.bar.foreground, Commons.Color.background)
          Behavior on color { ColorAnimation { duration: Style.duration(160) } }
          Text { anchors.centerIn: parent; text: "↻"; textFormat: Text.PlainText; color: root.bar.foreground; font.pixelSize: 18 }
          MouseArea { id: refreshMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { root.lastAction = "Actividad actualizada"; root.refresh(); root.close() } }
        }
      }
    }
    }
  }
}
