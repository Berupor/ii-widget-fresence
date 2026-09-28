import QtQuick

TileNumber {
    id: form
    readonly property var weather: form.card.weather

    value: form.weather ? `${Math.round(form.weather.temp_c)}°` : "-"
    caption: form.weather?.place ?? ""
}
