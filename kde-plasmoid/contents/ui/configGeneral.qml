import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page
    property string cfg_place
    property real cfg_lat
    property real cfg_lon
    property string cfg_cc
    property string cfg_source
    property int cfg_sync
    property bool cfg_clickOpen
    property string cfg_openCmd
    property var results: []

    function search() {
        if (!query.text.trim()) return
        status.text = "A procurar…"
        var x = new XMLHttpRequest()
        x.open("GET", "https://geocoding-api.open-meteo.com/v1/search?count=8&language=pt&format=json&name=" + encodeURIComponent(query.text.trim()))
        x.onreadystatechange = function () {
            if (x.readyState !== XMLHttpRequest.DONE) return
            try { page.results = JSON.parse(x.responseText).results || [] } catch (e) { page.results = [] }
            status.text = page.results.length ? "" : "Nada encontrado"
        }
        x.send()
    }

    Kirigami.FormLayout {
        QQC2.Label {
            Kirigami.FormData.label: "Local:"
            text: page.cfg_place ? page.cfg_place : "Automático (localização aproximada pela internet)"
            wrapMode: Text.Wrap
        }
        RowLayout {
            Kirigami.FormData.label: "Procurar cidade:"
            QQC2.TextField { id: query; placeholderText: "Ex.: Viseu"; Layout.preferredWidth: Kirigami.Units.gridUnit * 14; onAccepted: page.search() }
            QQC2.Button { text: "Procurar"; icon.name: "search"; onClicked: page.search() }
        }
        QQC2.Label { id: status; visible: text.length > 0; opacity: 0.7 }
        ColumnLayout {
            visible: page.results.length > 0
            Repeater {
                model: page.results
                QQC2.Button {
                    Layout.fillWidth: true
                    flat: true
                    text: modelData.name + (modelData.admin1 ? ", " + modelData.admin1 : "") + (modelData.country ? " · " + modelData.country : "")
                    onClicked: { page.cfg_place = modelData.name; page.cfg_lat = modelData.latitude; page.cfg_lon = modelData.longitude; page.cfg_cc = modelData.country_code || ""; page.results = []; query.text = "" }
                }
            }
        }
        QQC2.Button {
            text: "Usar localização automática"
            icon.name: "find-location"
            visible: page.cfg_place.length > 0
            onClicked: { page.cfg_place = ""; page.cfg_lat = 0; page.cfg_lon = 0; page.cfg_cc = "" }
        }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Dados" }
        Pick {
            Kirigami.FormData.label: "Fonte da previsão:"
            value: page.cfg_source
            options: [ { t: "Automático (recomendado)", v: "auto" }, { t: "ECMWF IFS 9 km", v: "ecmwf_ifs" } ]
            onPicked: v => page.cfg_source = v
        }
        Pick {
            Kirigami.FormData.label: "Atualizar a cada:"
            value: page.cfg_sync
            options: [ { t: "15 minutos", v: 15 }, { t: "30 minutos", v: 30 }, { t: "1 hora", v: 60 } ]
            onPicked: v => page.cfg_sync = v
        }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Clique no widget" }
        QQC2.CheckBox { text: "Abrir o app Céu ao clicar no widget"; checked: page.cfg_clickOpen; onToggled: page.cfg_clickOpen = checked }
        QQC2.TextField {
            Kirigami.FormData.label: "Comando (opcional):"
            enabled: page.cfg_clickOpen
            text: page.cfg_openCmd
            placeholderText: "Automático (procura o Céu instalado ou o AppImage)"
            Layout.preferredWidth: Kirigami.Units.gridUnit * 20
            onTextEdited: page.cfg_openCmd = text
        }
        QQC2.Label {
            text: "Ex.: /home/rafa/Applications/Ceu-Linux.AppImage"
            opacity: 0.6
        }
    }
}
