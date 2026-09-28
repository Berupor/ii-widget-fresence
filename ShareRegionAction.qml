import qs.modules.widgets
import QtQuick

/** Region selector action: post the selection to the room. */
QtObject {
    readonly property bool available: Fresence.canShare

    function perform(path: string, x: real, y: real, width: real, height: real): void {
        Fresence.postRegion(path, x, y, width, height);
    }
}
