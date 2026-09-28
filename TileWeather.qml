import QtQuick

// "condition · city" elides at 1x1, so the caption keeps only the city
TileNumber {
    id: form
    readonly property var temperature: form.card.valueText.match(/-?\d+°/)
    readonly property string rest: form.card.valueText.replace(form.temperature ? form.temperature[0] : "", "").replace(/^[\s·,-]+|[\s·,-]+$/g, "")

    value: form.temperature ? form.temperature[0] : form.card.valueText
    readonly property string place: form.rest.includes("·") ? form.rest.split("·").pop().trim() : form.rest
    caption: form.place || form.card.labelText
}
