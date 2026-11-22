import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory { name: "Local e dados"; icon: "find-location"; source: "configGeneral.qml" }
    ConfigCategory { name: "Aparência"; icon: "preferences-desktop-theme"; source: "configLook.qml" }
    ConfigCategory { name: "Cena"; icon: "weather-few-clouds"; source: "configScene.qml" }
    ConfigCategory { name: "Unidades"; icon: "measure"; source: "configUnits.qml" }
}
