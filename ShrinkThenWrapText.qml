import qs.modules.common
import qs.modules.common.widgets
import QtQuick

StyledText {
    id: fitText
    property real largestSize: Appearance.font.pixelSize.huge
    property real minSize: 10
    property int maxLines: 2
    property bool value: false
    property real fittedSize: fitText.largestSize
    property bool fits: true
    readonly property real valueLetterSpacing: -0.02

    font.pixelSize: fitText.fittedSize
    font.weight: fitText.value ? Font.Medium : Font.Normal
    font.letterSpacing: fitText.value ? fitText.valueLetterSpacing * fitText.fittedSize : 0
    font.features: fitText.value ? ({
            "tnum": 1
        }) : ({})
    wrapMode: Text.WordWrap
    maximumLineCount: fitText.maxLines
    elide: Text.ElideRight
    textFormat: Text.PlainText

    function fitsAt(size: real): bool {
        probe.font.pixelSize = size;
        probe.font.letterSpacing = fitText.value ? fitText.valueLetterSpacing * size : 0;
        return probe.lineCount <= fitText.maxLines && probe.contentWidth <= fitText.width;
    }

    function fit(): void {
        const upper = fitText.largestSize;
        const lower = Math.min(fitText.minSize, upper);
        if (fitText.width <= 0 || fitText.text.length === 0) {
            fitText.fits = true;
            fitText.fittedSize = upper;
            return;
        }
        probe.font = fitText.font;
        probe.width = fitText.width;
        probe.text = fitText.text;
        const steps = Math.floor(upper - lower);
        let low = 0;
        let high = steps + 1;
        while (low < high) {
            const mid = (low + high) >> 1;
            if (fitText.fitsAt(upper - mid))
                high = mid;
            else
                low = mid + 1;
        }
        fitText.fits = low <= steps;
        fitText.fittedSize = fitText.fits ? upper - low : lower;
    }

    onTextChanged: fitText.fit()
    onWidthChanged: fitText.fit()
    onLargestSizeChanged: fitText.fit()
    onMinSizeChanged: fitText.fit()
    onMaxLinesChanged: fitText.fit()
    onValueChanged: fitText.fit()
    onFontChanged: fitText.fit()
    Component.onCompleted: fitText.fit()

    Text {
        id: probe
        visible: false
        wrapMode: Text.WordWrap
        textFormat: Text.PlainText
    }
}
