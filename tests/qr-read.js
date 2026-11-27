// tests/qr-read.js: reads back the QR codes common/auster draws (B7, AU_QR_JS), for V7's tests. Run as
//   osascript -l JavaScript tests/qr-read.js FILE
// FILE is what a test's AU_SCREEN received. Each run of lines that begin with the drawing's colours is one
// code, two module rows a line in half-block characters; each is made into an image, eight pixels a module,
// and read by Core Image's CIDetector, as phase 2 read its code back (docs/phase-2.md, section 7). It prints
// one line for each code, in order: the text it holds, or `unreadable`. Pure ASCII.
ObjC.import("AppKit");
ObjC.import("CoreImage");

var COLOURS = "\u001b[38;5;16;48;5;231m", RESET = "\u001b[0m";

function decode(rows) {
  var s = 8, w = rows[0].length * s, h = rows.length * s, x, y;
  var rep = $.NSBitmapImageRep.alloc.initWithBitmapDataPlanesPixelsWidePixelsHighBitsPerSampleSamplesPerPixelHasAlphaIsPlanarColorSpaceNameBytesPerRowBitsPerPixel(
    null, w, h, 8, 1, false, false, $.NSDeviceWhiteColorSpace, 0, 0);
  var black = $.NSColor.colorWithDeviceWhiteAlpha(0, 1), white = $.NSColor.colorWithDeviceWhiteAlpha(1, 1);
  for (y = 0; y < h; y++) for (x = 0; x < w; x++) rep.setColorAtXY(rows[Math.floor(y / s)][Math.floor(x / s)] ? black : white, x, y);
  var image = $.CIImage.alloc.initWithBitmapImageRep(rep);
  var options = $.NSDictionary.dictionaryWithObjectForKey($.CIDetectorAccuracyHigh, $.CIDetectorAccuracy);
  var found = $.CIDetector.detectorOfTypeContextOptions($.CIDetectorTypeQRCode, $.CIContext.context, options).featuresInImage(image);
  if (Number(found.count) !== 1) return "unreadable";
  var text = ObjC.unwrap(found.objectAtIndex(0).messageString);
  return typeof text === "string" ? text : "unreadable";
}

function run(argv) {
  var d = $.NSData.dataWithContentsOfFile(argv[0]);
  if (d.isNil()) return "";
  var t = ObjC.unwrap($.NSString.alloc.initWithDataEncoding(d, $.NSUTF8StringEncoding));
  if (typeof t !== "string") return "";
  var lines = t.split("\n"), codes = [], rows = null, i, j, l, c, top, bottom;
  for (i = 0; i <= lines.length; i++) {
    l = i < lines.length ? lines[i] : "";
    if (l.indexOf(COLOURS) !== 0) { if (rows) codes.push(rows); rows = null; continue; }
    l = l.slice(COLOURS.length);
    if (l.slice(-RESET.length) === RESET) l = l.slice(0, -RESET.length);
    top = []; bottom = [];
    for (j = 0; j < l.length; j++) {
      c = l.charAt(j);
      top.push(c === "\u2588" || c === "\u2580");
      bottom.push(c === "\u2588" || c === "\u2584");
    }
    rows = rows || [];
    rows.push(top, bottom);
  }
  return codes.map(decode).join("\n");
}
