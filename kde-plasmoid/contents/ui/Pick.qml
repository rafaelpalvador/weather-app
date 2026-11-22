import QtQuick
import QtQuick.Controls as QQC2

/* caixa de escolha que lê e escreve um valor (texto ou número) */
QQC2.ComboBox {
    id: box
    property var value
    property var options: []
    signal picked(var v)
    model: options
    textRole: "t"
    valueRole: "v"
    function sync() { var i = indexOfValue(value); currentIndex = i < 0 ? 0 : i }
    Component.onCompleted: sync()
    onValueChanged: sync()
    onActivated: picked(currentValue)
}
