import QtQuick
import QtQuick.Layouts
import QtWebEngine
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

/* Céu para o KDE Plasma: mostra o modo widget do app (a mesma página do Céu) dentro do ambiente de trabalho.
   No estilo "Vidro" é o próprio Plasma que desenha o fundo translúcido e desfocado. */
PlasmoidItem {
    id: root
    readonly property string style: Plasmoid.configuration.style || "scene"
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: style === "glass" ? PlasmaCore.Types.DefaultBackground : PlasmaCore.Types.NoBackground

    fullRepresentation: Item {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 21
        Layout.preferredHeight: Kirigami.Units.gridUnit * 11
        Layout.minimumWidth: Kirigami.Units.gridUnit * 12
        Layout.minimumHeight: Kirigami.Units.gridUnit * 6

        WebEngineView {
            id: web
            anchors.fill: parent
            backgroundColor: "transparent"
            settings.localContentCanAccessRemoteUrls: true
            settings.localContentCanAccessFileUrls: true
            settings.showScrollBars: false
            url: Qt.resolvedUrl("app/index.html")
                 + "?widget=1&kde=1&style=" + root.style
                 + "&lat=" + Plasmoid.configuration.lat
                 + "&lon=" + Plasmoid.configuration.lon
                 + "&cc=" + encodeURIComponent(Plasmoid.configuration.cc || "")
                 + "&name=" + encodeURIComponent(Plasmoid.configuration.place || "")
            onContextMenuRequested: request => { request.accepted = true }
        }
    }
}
