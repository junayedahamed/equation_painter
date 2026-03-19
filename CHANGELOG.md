## 0.0.2+1

* Abstracted equation drawing logic into `EquationPainterWidget` for easier reuse.
* Added interactive pan and zoom capabilities for exploring the visualized equations.
* Introduced mathematical equation parsing functionality, allowing equations to be defined as strings.
* Separated configuration models (e.g., `EquationConfig`) and painter logic to improve code modularity.

## 0.0.2

* Minor bug fixes and performance improvements.

## 0.0.1+1

* Initial release of `eq_visulaization`.
* Supports multiple mathematical equations with beautiful reveal animations.
* Customizable coordinate system with axes, grids, and numerical labels.
* High performance rendering using `Float32List` and `drawRawPoints`.
* Support for different animation types: `radial`, `sequential`, `linearX`, and `linearY`.
* Origin alignment for various quadrant layouts.
