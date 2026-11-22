import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page
    property string cfg_style
    property string cfg_place
    property real cfg_lat
    property real cfg_lon
    property string cfg_cc
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
        QQC2.ComboBox {
            id: styleBox
            Kirigami.FormData.label: "Estilo:"
            textRole: "t"
            valueRole: "v"
            model: [
                { t: "Cena animada", v: "scene" },
                { t: "Vidro (fundo desfocado do Plasma)", v: "glass" },
                { t: "Escuro", v: "dark" }
            ]
            Component.onCompleted: currentIndex = Math.max(0, indexOfValue(page.cfg_style))
            onActivated: page.cfg_style = currentValue
        }

        QQC2.Label {
            Kirigami.FormData.label: "Local:"
            text: page.cfg_place ? page.cfg_place : "Automático (localização aproximada pela internet)"
            wrapMode: Text.Wrap
        }

        RowLayout {
            Kirigami.FormData.label: "Procurar cidade:"
            QQC2.TextField {
                id: query
                placeholderText: "Ex.: Viseu"
                Layout.preferredWidth: Kirigami.Units.gridUnit * 14
                onAccepted: page.search()
            }
            QQC2.Button { text: "Procurar"; icon.name: "search"; onClicked: page.search() }
        }

        QQC2.Label { id: status; visible: text.length > 0; opacity: 0.7 }

        ColumnLayout {
            Kirigami.FormData.label: page.results.length ? "Resultados:" : ""
            visible: page.results.length > 0
            Repeater {
                model: page.results
                QQC2.Button {
                    Layout.fillWidth: true
                    flat: true
                    text: modelData.name + (modelData.admin1 ? ", " + modelData.admin1 : "") + (modelData.country ? " · " + modelData.country : "")
                    onClicked: {
                        page.cfg_place = modelData.name
                        page.cfg_lat = modelData.latitude
                        page.cfg_lon = modelData.longitude
                        page.cfg_cc = modelData.country_code || ""
                        page.results = []
                        query.text = ""
                    }
                }
            }
        }

        QQC2.Button {
            text: "Usar localização automática"
            icon.name: "find-location"
            visible: page.cfg_place.length > 0
            onClicked: { page.cfg_place = ""; page.cfg_lat = 0; page.cfg_lon = 0; page.cfg_cc = "" }
        }
    }
}
