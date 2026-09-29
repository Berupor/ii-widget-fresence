//@ probe fresence -g 420x560 -s 2500
/**
 * The chess forms in one detail grid: a square board with its delta chip beside a
 * two-row rating with the best line, a wide board, a 1x1 rating, and a one-row rating
 * with the chart beside the queen. A second friend has no `last` game: the board
 * hides, the rating stays.
 */
import ".."
import "../CardLayouts.js" as CardLayouts
import "lib"
import "lib/DemoSnapshot.js" as Demo
import "lib/DemoItems.js" as Items
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    readonly property var history: [1180, 1204, 1196, 1231, 1219, 1247, 1262, 1251, 1279, 1293, 1288, 1310]
    readonly property string endgame: "8/5pk1/6p1/8/3R4/8/5PPP/6K1 w - - 0 40"
    readonly property var chessWidgets: [Demo.widget("chess", [0, 0, 2, 2], {
            "form": "board"
        }), Demo.widget("chess", [2, 0, 2, 2], {
            "form": "rating"
        }), Demo.widget("chess", [0, 2, 3, 1], {
            "form": "board"
        }), Demo.widget("chess", [3, 2, 1, 1], {
            "form": "rating"
        }), Demo.widget("chess", [0, 3, 4, 1], {
            "form": "rating"
        })]

    readonly property var snapshot: Demo.snapshot([Demo.device({
                "id": "dev-self",
                "account": "You"
            })], [Demo.room("room-a", [Demo.member("acc-gil", [Demo.device({
                            "id": "dev-gil",
                            "account": "Gil",
                            "row": [],
                            "detail": root.chessWidgets,
                            "state": {
                                "chess": Demo.chess("rapid", 1310, root.history, {
                                    "best": 1342,
                                    "last": Demo.chessGame(root.endgame, "white", "win", {
                                        "ending": "checkmate",
                                        "opponent": "kasparov_fan",
                                        "opponent_rating": 1284,
                                        "moves": 40,
                                        "delta": 8
                                    })
                                })
                            }
                        })]), Demo.member("acc-ann", [Demo.device({
                            "id": "dev-ann",
                            "account": "Ann",
                            "row": [],
                            "detail": root.chessWidgets.slice(0, 2),
                            "state": {
                                "chess": Demo.chess("blitz", 980, [])
                            }
                        })])])])

    function chessTiles(row): var {
        return Items.tiles(row).filter(t => t.type === "chess");
    }

    function checks() {
        const rookAndKing = "8/8/8/8/8/8/8/R6k";
        return [
            {
                "name": "every tile's form loads",
                "got": Items.brokenForms(root),
                "want": []
            },
            {
                "name": "each chess form is drawn as asked, none dimmed",
                "got": root.chessTiles(gilRow).map(t => [t.form, t.dimmed]),
                "want": [["board", false], ["rating", false], ["board", false], ["rating", false], ["rating", false]]
            },
            {
                "name": "a card without a last game hides its board and keeps its rating",
                "got": root.chessTiles(annRow).map(t => t.form),
                "want": ["rating"]
            },
            {
                "name": "white sees its own side at the bottom",
                "got": [CardLayouts.boardSquares(rookAndKing, "white")[7][0], CardLayouts.boardSquares(rookAndKing, "white")[7][7]],
                "want": ["R", "k"]
            },
            {
                "name": "black sees the board turned around",
                "got": [CardLayouts.boardSquares(rookAndKing, "black")[0][7], CardLayouts.boardSquares(rookAndKing, "black")[0][0]],
                "want": ["R", "k"]
            },
            {
                "name": "the delta chip takes the first corner clear of pieces",
                "got": CardLayouts.freeCorner(CardLayouts.boardSquares(rookAndKing, "white"), 2, 1),
                "want": {
                    "top": true,
                    "start": false
                }
            },
            {
                "name": "a gain carries a plus sign, a loss its own minus",
                "got": [CardLayouts.deltaText(8), CardLayouts.deltaText(-11)],
                "want": ["+8", "-11"]
            }
        ];
    }

    DemoCoverSeed {
        onSeeded: Fresence.ingest(JSON.stringify(root.snapshot))
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        PresenceRow {
            id: gilRow
            Layout.fillWidth: true
            modelData: "acc-gil"
            showDetails: true
        }

        PresenceRow {
            id: annRow
            Layout.fillWidth: true
            modelData: "acc-ann"
            showDetails: true
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
