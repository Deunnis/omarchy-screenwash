var colors = [
  { r: 255, g: 0,   b: 0   },
  { r: 0,   g: 255, b: 0   },
  { r: 0,   g: 0,   b: 255 },
  { r: 255, g: 255, b: 255 }
]

function getWashColor(progress) {
  var p = Math.max(0, Math.min(1, progress))
  var segmentCount = colors.length
  var segment = p * segmentCount
  var idx = Math.floor(segment)
  var frac = segment - idx

  if (idx >= segmentCount - 1) {
    var last = colors[segmentCount - 1]
    return Qt.rgba(last.r / 255, last.g / 255, last.b / 255, 1.0)
  }

  var c1 = colors[idx]
  var c2 = colors[idx + 1]
  var r = c1.r + (c2.r - c1.r) * frac
  var g = c1.g + (c2.g - c1.g) * frac
  var b = c1.b + (c2.b - c1.b) * frac
  return Qt.rgba(r / 255, g / 255, b / 255, 1.0)
}
