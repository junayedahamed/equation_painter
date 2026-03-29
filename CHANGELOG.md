## 0.1.0+7

* Updated README with new example screenshots showcasing heart curve and cosine wave with value inspection.
* Removed Bangla text from README for consistency.

## 0.1.0+6

* Updated README with new example screenshots showcasing heart curve and cosine wave with value inspection.
* Version bump for minor updates and improved documentation.
 
## 0.1.0+5

* Updated README with new logo and
 
## 0.1.0+4

* Updated README with new logo and profile links.
* Version bump for minor updates.

## 0.1.0+3

* Added `EquationParser.parseOrNull` for safer equation parsing with error feedback.
* Refactored `example` to support dynamic equation entry, custom $x/y$ range limits, and inequality type selection.
* Removed redundant `showHint` parameter and simplified `EquationPainter` internal layout.
* Updated default $y$-axis color to match $x$-axis (red).
* Improved code robustness by handling uninitialized state in example app.
* On hover, display equation details in a tooltip for better user experience.


## 0.1.0+1

* Renamed `EquationPainterWidget` to `EquationPainter` for better clarity and ease of use.
* Minor code cleanup and performance improvements.

## 0.0.2+2

* Added `showHint` parameter to `EquationPainterWidget` for optional troubleshooting guidance.
* Fixed overflow issues when displaying hints by utilizing `Stack` and `Positioned` layouts.
* Improved default `unitsPerSquare` and interactivity settings for better out-of-the-box experience.

## 0.0.2+1

* Abstracted equation drawing logic into `EquationPainterWidget` for easier reuse.
* Added interactive pan and zoom capabilities for exploring the visualized equations.
* Introduced mathematical equation parsing functionality, allowing equations to be defined as strings.
* Separated configuration models (e.g., `EquationConfig`) and painter logic to improve code modularity.

## 0.0.2

* Minor bug fixes and performance improvements.

## 0.0.1+1

* Initial release of `equation_painter`.
* Supports multiple mathematical equations with beautiful reveal animations.
* Customizable coordinate system with axes, grids, and numerical labels.
* High performance rendering using `Float32List` and `drawRawPoints`.
* Support for different animation types: `radial`, `sequential`, `linearX`, and `linearY`.
* Origin alignment for various quadrant layouts.
