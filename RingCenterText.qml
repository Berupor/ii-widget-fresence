import qs.modules.common
import qs.modules.common.widgets
import QtQuick

Column {
    id: root
    required property var card
    required property real innerBox
    property string icon: ""
    property bool showText: true
    readonly property real minCaptionBox: 52
    readonly property bool iconOnly: root.icon.length > 0 && !root.showText
    readonly property bool iconShown: root.icon.length > 0 && (root.iconOnly || root.innerBox >= root.minCaptionBox)
    readonly property bool captionFits: root.showText && root.card.labelText.length > 0 && ringValue.implicitHeight + ringIcon.height + ringCaption.implicitHeight <= root.innerBox && ringCaption.fits

    width: root.innerBox
    spacing: 0

    MaterialSymbol {
        id: ringIcon
        visible: root.iconShown
        width: parent.width
        height: visible ? implicitHeight : 0
        horizontalAlignment: Text.AlignHCenter
        text: root.icon
        iconSize: root.iconOnly ? root.innerBox * 0.6 : root.innerBox * 0.3
        color: root.card.contentColor
    }
    StyledText {
        id: ringValue
        objectName: "ringValue"
        visible: root.showText
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        fontSizeMode: Text.HorizontalFit
        minimumPixelSize: Appearance.font.pixelSize.smallest
        animateChange: true
        font.weight: Font.Medium
        font.letterSpacing: -0.02 * font.pixelSize
        font.features: ({
                "tnum": 1
            })
        text: root.card.shownValueText
        color: root.card.contentColor
        font.pixelSize: Math.max(Appearance.font.pixelSize.smallest, root.innerBox * 0.4)
    }
    ShrinkThenWrapText {
        id: ringCaption
        objectName: "ringCaption"
        visible: root.captionFits
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        largestSize: Appearance.font.pixelSize.smaller
        maxLines: 1
        text: root.card.labelText
        color: root.card.mutedContentColor
    }
}
