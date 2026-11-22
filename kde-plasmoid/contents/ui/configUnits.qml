import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page
    property string cfg_unitT
    property string cfg_unitW
    property string cfg_unitP
    property string cfg_unitPr

    Kirigami.FormLayout {
        Pick { Kirigami.FormData.label: "Temperatura:"; value: page.cfg_unitT; options: [ { t: "°C", v: "c" }, { t: "°F", v: "f" } ]; onPicked: v => page.cfg_unitT = v }
        Pick { Kirigami.FormData.label: "Vento:"; value: page.cfg_unitW; options: [ { t: "km/h", v: "kmh" }, { t: "m/s", v: "ms" }, { t: "mph", v: "mph" }, { t: "nós", v: "kn" } ]; onPicked: v => page.cfg_unitW = v }
        Pick { Kirigami.FormData.label: "Precipitação:"; value: page.cfg_unitP; options: [ { t: "mm", v: "mm" }, { t: "polegadas", v: "in" } ]; onPicked: v => page.cfg_unitP = v }
        Pick { Kirigami.FormData.label: "Pressão:"; value: page.cfg_unitPr; options: [ { t: "hPa", v: "hpa" }, { t: "mmHg", v: "mmhg" }, { t: "inHg", v: "inhg" } ]; onPicked: v => page.cfg_unitPr = v }
    }
}
