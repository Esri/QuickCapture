import QtQuick 2.5
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1

import ArcGIS.AppFramework 1.0

import ".."
import "../Portal"
import "../Controls"
import "../AppControls"

AppButton {
    iconSource: "images/trash_bin.png"
    text: qsTr("Delete")
    activateDelay: 3000
    activateColor: "#ff4a4d"
    pressedBackgroundColor: "#ffbfc0"
    hoveredBackgroundColor: "#ff8082"
    
}
