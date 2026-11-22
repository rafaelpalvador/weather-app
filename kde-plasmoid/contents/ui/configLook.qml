import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page
    property string cfg_style
    property int cfg_radius
    property int cfg_opacity
    property bool cfg_showCity
    property bool cfg_showUpd
    property bool cfg_showHilo
    property bool cfg_showHours
    property int cfg_nHours

    Kirigami.FormLayout {
        Pick {
            Kirigami.FormData.label: "Estilo:"
            value: page.cfg_style
            options: [
                { t: "Cena animada", v: "scene" },
                { t: "Vidro do Plasma (desfocado, cantos do tema)", v: "glass" },
                { t: "Vidro translúcido (cantos à tua escolha)", v: "clear" },
                { t: "Escuro", v: "dark" }
            ]
            onPicked: v => page.cfg_style = v
        }
        RowLayout {
            Kirigami.FormData.label: "Arredondamento:"
            enabled: page.cfg_style !== "glass"
            QQC2.Slider { from: 0; to: 100; stepSize: 5; value: page.cfg_radius; Layout.preferredWidth: Kirigami.Units.gridUnit * 12; onMoved: page.cfg_radius = value }
            QQC2.Label { text: page.cfg_radius === 0 ? "Quadrado" : page.cfg_radius >= 100 ? "Pílula" : page.cfg_radius + "%" }
        }
        QQC2.Label {
            visible: page.cfg_style === "glass"
            text: "No vidro do Plasma os cantos seguem o tema do KDE."
            opacity: 0.7
            wrapMode: Text.Wrap
            Layout.maximumWidth: Kirigami.Units.gridUnit * 20
        }
        RowLayout {
            Kirigami.FormData.label: "Opacidade do fundo:"
            enabled: page.cfg_style === "dark" || page.cfg_style === "clear"
            QQC2.Slider { from: 10; to: 100; stepSize: 5; value: page.cfg_opacity; Layout.preferredWidth: Kirigami.Units.gridUnit * 12; onMoved: page.cfg_opacity = value }
            QQC2.Label { text: page.cfg_opacity + "%" }
        }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Mostrar" }
        QQC2.CheckBox { text: "Nome da cidade"; checked: page.cfg_showCity; onToggled: page.cfg_showCity = checked }
        QQC2.CheckBox { text: "Hora da última atualização"; checked: page.cfg_showUpd; onToggled: page.cfg_showUpd = checked }
        QQC2.CheckBox { text: "Máxima e mínima"; checked: page.cfg_showHilo; onToggled: page.cfg_showHilo = checked }
        QQC2.CheckBox { text: "Próximas horas"; checked: page.cfg_showHours; onToggled: page.cfg_showHours = checked }
        QQC2.SpinBox {
            Kirigami.FormData.label: "Número de horas:"
            enabled: page.cfg_showHours
            from: 3; to: 8
            value: page.cfg_nHours
            onValueModified: page.cfg_nHours = value
        }
    }
}
