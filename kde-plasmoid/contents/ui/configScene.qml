import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "monuments.js" as Mon

KCM.SimpleKCM {
    id: page
    property string cfg_scene
    property string cfg_monument
    property string cfg_anim
    property string cfg_xmas

    Kirigami.FormLayout {
        Pick {
            Kirigami.FormData.label: "Cena de fundo:"
            value: page.cfg_scene
            options: Mon.scenes
            onPicked: v => page.cfg_scene = v
        }
        Pick {
            Kirigami.FormData.label: "Monumento:"
            visible: page.cfg_scene === "monument"
            value: page.cfg_monument
            options: Mon.list
            Layout.preferredWidth: Kirigami.Units.gridUnit * 22
            onPicked: v => page.cfg_monument = v
        }
        Pick {
            Kirigami.FormData.label: "Animação:"
            value: page.cfg_anim
            options: [ { t: "Animada", v: "on" }, { t: "Estática (poupa energia)", v: "static" }, { t: "Desligada", v: "off" } ]
            onPicked: v => page.cfg_anim = v
        }
        Pick {
            Kirigami.FormData.label: "Decoração de Natal:"
            value: page.cfg_xmas
            options: [ { t: "Automática (1 a 26 de dezembro)", v: "auto" }, { t: "Sempre", v: "on" }, { t: "Desligada", v: "off" } ]
            onPicked: v => page.cfg_xmas = v
        }
        QQC2.Label {
            text: "Só se vê nos estilos Cena animada."
            opacity: 0.7
        }
    }
}
