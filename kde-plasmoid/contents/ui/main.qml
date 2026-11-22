import QtQuick
import QtQuick.Layouts
import QtWebEngine
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

/* Céu para o KDE Plasma: mostra o modo widget do app (a mesma página do Céu) no ambiente de trabalho.
   Todas as definições vêm de "Configurar" e são passadas à página. No estilo "Vidro do Plasma"
   é o próprio Plasma que desenha o fundo translúcido e desfocado. */
PlasmoidItem {
    id: root
    readonly property var c: Plasmoid.configuration
    readonly property string style: c.style || "scene"
    readonly property string opts: JSON.stringify({
        r: c.radius, op: c.opacity, nh: c.nHours,
        hours: c.showHours, upd: c.showUpd, hilo: c.showHilo, city: c.showCity,
        scene: c.scene, monument: c.monument, anim: c.anim, xmas: c.xmas,
        source: c.source, sync: c.sync,
        units: { t: c.unitT, w: c.unitW, p: c.unitP, pr: c.unitPr },
        click: c.clickOpen
    })

    /* abrir o app Céu: comando escolhido nas definições, ou procura o programa instalado (.deb/pacote) ou o AppImage */
    readonly property string autoCmd: 'for c in Ceu ceu ceu-tempo; do command -v "$c" >/dev/null 2>&1 && exec "$c"; done; '
        + 'f=$(ls -t "$HOME"/Applications/*[Cc]eu*.AppImage "$HOME"/Aplicativos/*[Cc]eu*.AppImage "$HOME"/.local/bin/*[Cc]eu*.AppImage "$HOME"/Downloads/*[Cc]eu*.AppImage "$HOME"/Transferências/*[Cc]eu*.AppImage "$HOME"/*[Cc]eu*.AppImage 2>/dev/null | head -n 1); '
        + 'if [ -n "$f" ]; then chmod +x "$f"; exec "$f"; fi; '
        + 'xdg-open https://github.com/rafaelpalvador/weather-app/releases/latest'
    P5Support.DataSource {
        id: runner
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => disconnectSource(source)
    }
    function openApp() {
        const cmd = (c.openCmd && c.openCmd.trim().length) ? c.openCmd.trim() : autoCmd
        runner.connectSource(cmd + " #" + Date.now())
    }
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: style === "glass" ? PlasmaCore.Types.DefaultBackground : PlasmaCore.Types.NoBackground

    fullRepresentation: Item {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 21
        Layout.preferredHeight: Kirigami.Units.gridUnit * 11
        Layout.minimumWidth: Kirigami.Units.gridUnit * 8
        Layout.minimumHeight: Kirigami.Units.gridUnit * 5

        WebEngineView {
            anchors.fill: parent
            backgroundColor: "transparent"
            settings.localContentCanAccessRemoteUrls: true
            settings.localContentCanAccessFileUrls: true
            settings.showScrollBars: false
            url: Qt.resolvedUrl("app/index.html")
                 + "?widget=1&kde=1&style=" + root.style
                 + "&lat=" + root.c.lat + "&lon=" + root.c.lon
                 + "&cc=" + encodeURIComponent(root.c.cc || "")
                 + "&name=" + encodeURIComponent(root.c.place || "")
                 + "&o=" + encodeURIComponent(root.opts)
            onContextMenuRequested: request => { request.accepted = true }
            onJavaScriptConsoleMessage: (level, message, lineNumber, sourceID) => { if (message === "CEU_OPEN") root.openApp() }
        }
    }
}
