import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.widgets

ColumnLayout {
    id: root

    // A spin box clamps to its minimum before the value binding lands and reports
    // that as a change, so on a fresh store every number would save as its minimum
    property bool ready: false
    Component.onCompleted: root.ready = true

    function setOption(key, value) {
        if (!root.ready || Fresence.opt(key) === value) // Controls write back their own value on load
            return;
        WidgetsStore.setOption(Fresence.widgetId, key, value);
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: root.spacing

        ContentSubsection {
            title: Translation.tr("Incognito")

            ConfigSwitch {
                buttonIcon: "touch_app"
                text: Translation.tr('Hold your own row to hide')
                checked: Fresence.opt("incognito")
                onCheckedChanged: setOption("incognito", checked)
                StyledToolTip {
                    text: Translation.tr("Hold your avatar in the presence tab, slide onto how long, let go.\nThis device stops sharing its state until the time runs out")
                }
            }

            ConfigSwitch {
                buttonIcon: "toast"
                text: Translation.tr('Remind me in the bar')
                checked: Fresence.opt("incognitoIndicator")
                onCheckedChanged: setOption("incognitoIndicator", checked)
                StyledToolTip {
                    text: Translation.tr("An icon while you're hiding, so you don't stay dark for a week by accident.\nClick it to be visible again")
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Photos")

            ConfigSwitch {
                buttonIcon: "add_a_photo"
                text: Translation.tr('Share photos yourself')
                checked: Fresence.opt("photoShare")
                onCheckedChanged: setOption("photoShare", checked)
                StyledToolTip {
                    text: Translation.tr("Middle-click your own card for share actions.\nMiddle-drag in the region selector shares that region right away")
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("GIFs")

            ConfigSwitch {
                buttonIcon: "gif_box"
                text: Translation.tr("Pause GIFs after a few seconds")
                checked: Fresence.opt("pauseGifs")
                onCheckedChanged: setOption("pauseGifs", checked)
                StyledToolTip {
                    text: Translation.tr("A GIF picture on a card plays for a few seconds, then stops on its first frame instead of looping forever")
                }
            }

            ConfigSpinBox {
                visible: Fresence.opt("pauseGifs")
                icon: "timer"
                text: Translation.tr("Freeze after (seconds)")
                value: Fresence.opt("gifPauseSeconds")
                from: 1
                to: 30
                stepSize: 1
                onValueChanged: {
                    setOption("gifPauseSeconds", value);
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Wallpaper card")

            ConfigSwitch {
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Fresence.opt("wallpaperCard")
                onCheckedChanged: setOption("wallpaperCard", checked)
                StyledToolTip {
                    text: Translation.tr("Same rows as the left sidebar's presence tab, as a card on the wallpaper.\nNeeds a linked fresence agent")
                }
            }

            ConfigSelectionArray { // Its own row, so Enable keeps the axis every other switch is on
                Layout.fillWidth: true
                currentValue: Fresence.opt("wallpaperPlacement")
                onSelected: newValue => {
                    setOption("wallpaperPlacement", newValue);
                }
                options: [
                    {
                        displayName: Translation.tr("Draggable"),
                        icon: "drag_pan",
                        value: "free"
                    },
                    {
                        displayName: Translation.tr("Least busy"),
                        icon: "category",
                        value: "leastBusy"
                    },
                    {
                        displayName: Translation.tr("Most busy"),
                        icon: "shapes",
                        value: "mostBusy"
                    },
                ]
            }

            ConfigSwitch {
                buttonIcon: "person_off"
                text: Translation.tr("Hide offline members")
                checked: Fresence.opt("wallpaperHideOffline")
                onCheckedChanged: setOption("wallpaperHideOffline", checked)
            }

            ConfigSpinBox {
                icon: "fit_width"
                text: Translation.tr("Width")
                value: Fresence.opt("wallpaperWidth")
                from: 200
                to: 800
                stepSize: 20
                onValueChanged: {
                    setOption("wallpaperWidth", value);
                }
            }

            ConfigSpinBox {
                icon: "format_list_numbered"
                text: Translation.tr("Max rows (0 for everyone)")
                value: Fresence.opt("wallpaperMaxRows")
                from: 0
                to: 20
                stepSize: 1
                onValueChanged: {
                    setOption("wallpaperMaxRows", value);
                }
            }
        }
    }
}
