import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

ShellRoot {
    id: root

    property string homeDir: Quickshell.env("HOME")
    property string wpPath: homeDir + "/Pictures/Wallpaper"
    property var imageList: []
    property bool folderIsEmpty: true
    property bool isAutomated: false

    // Process to verify and fetch wallpapers on start
    Process {
        id: dirCheckProcess
        command: ["sh", "-c", "mkdir -p '" + root.wpPath + "' && find '" + root.wpPath + "' -type f \\( -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' -o -name '*.webp' \\) | sort"]
        running: true

        stdout: SplitParser {
            onRead: (text) => {
                var line = text.trim();
                if (line.length > 0) {
                    root.imageList.push("file://" + line);
                    root.folderIsEmpty = false;
                }
            }
        }

        onExited: {
            if (!root.folderIsEmpty) {
                for (var i = 0; i < root.imageList.length; i++) {
                    wpModel.append({ "filePath": root.imageList[i] });
                }
            }
        }
    }

    // Direct one-shot process to terminate the loop cleanly
    Process {
        id: stopAutomationProcess
        command: ["pkill", "-f", "wp-changer.sh"]
        running: false
        onExited: {
            running = false;
        }
    }

    // Primary native array worker for setting the image
    Process {
        id: shellWorker
        running: false
        onExited: {
            running = false;
        }
    }

    ListModel {
        id: wpModel
    }

    PanelWindow {
        id: window

        anchors.left: true
        anchors.right: true
        exclusiveZone: 0
        implicitHeight: 240
        color: "transparent"

        Rectangle {
            id: body
            // Force the initial state completely off-screen to the right
            x: parent.width
            y: 10

            width: parent.width - 40
            height: parent.height - 20
            radius: 12

            Behavior on x {
                NumberAnimation {
                    duration: 600
                    easing.type: Easing.OutCubic // Smoothly decelerates as it slides in
                }
            }

            color: Qt.rgba(0, 0, 0, 0.6)
            border.width: 2
            border.color: "#b0ac63"

            Item {
                anchors.fill: parent
                anchors.margins: 15

                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    visible: root.folderIsEmpty

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Wallpaper Folder Is Empty!"
                        color: "#ff6c6b"
                        font.pixelSize: 22
                        font.bold: true
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Please add images to: ~/Pictures/Wallpaper"
                        color: "#b0ac63"
                        font.pixelSize: 14
                    }
                }

                ListView {
                    id: wpListView
                    anchors.fill: parent
                    orientation: ListView.Horizontal
                    spacing: 15
                    clip: true
                    visible: !root.folderIsEmpty
                    model: wpModel

                    header: Item {
                        width: 200
                        height: wpListView.height

                        Column {
                            anchors.centerIn: parent
                            spacing: 16

                            // Toggle Button
                            Rectangle {
                                id: btn
                                width: 140
                                height: 50
                                radius: 6

                                // Palette behaviors (dims on click, brightens on hover)
                                color: btnMouse.containsPress ? "#424330" : (btnMouse.containsMouse ? "#6e7151" : "#595b41")
                                anchors.horizontalCenter: parent.horizontalCenter

                                scale: btnMouse.containsPress ? 0.94 : 1.0
                                Behavior on scale {
                                    NumberAnimation { duration: 100 }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "awww" // Permanent static label
                                    color: "#ffffff"
                                    font.pixelSize: 18
                                    font.bold: true
                                }

                                MouseArea {
                                    id: btnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: {
                                        if (root.isAutomated) {
                                            root.isAutomated = false;
                                            stopAutomationProcess.running = true;
                                        } else {
                                            root.isAutomated = true;
                                            // Fixed with full system path so keybindings can execute it reliably
                                            shellWorker.command = ["sh", "-c", root.homeDir + "/.config/Quickshell/WallpaperChanger/wp-changer.sh &"];
                                            shellWorker.running = true;
                                        }
                                    }
                                }
                            }

                            Text {
                                text: "Automate Wallpaper"
                                color: "#b0ac63"
                                font.pixelSize: 15
                                font.bold: false
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    delegate: Rectangle {
                        width: 280
                        height: wpListView.height
                        color: "#1e1e2e"
                        radius: 6
                        clip: true
                        border.width: 1
                        border.color: "#b0ac63"

                        Image {
                            anchors.fill: parent
                            source: model.filePath
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor

                            onClicked: (mouse) => {
                                if (mouse.button === Qt.LeftButton) {
                                    var purePath = model.filePath.replace("file://", "");

                                    root.isAutomated = false;
                                    stopAutomationProcess.running = true;

                                    shellWorker.command = [
                                        "/usr/bin/awww", "img", purePath,
                                        "--transition-type", "random",
                                        "--transition-duration", "1.5"
                                    ];
                                    shellWorker.running = true;
                                }
                            }
                        }
                    }
                }
            }
        }

        Timer {
            interval: 50 // Decreased to capture the engine layout before rendering frames
            running: true
            repeat: false
            onTriggered: {
                body.x = 20 // Slides smoothly into position, centered with a 20px margin
            }
        }
    }
}
