# Configuration

Tune a drawer without replacing its structure or gesture implementation.

## Overview

Create a mutable ``DrawerConfiguration``, change the required properties, and pass it into
``Drawer/init(isOpen:configuration:panel:content:)``.

```swift
var configuration: DrawerConfiguration {
    var value = DrawerConfiguration()
    value.width = 300
    value.contentDimOpacity = 0.08
    value.edge = .trailing
    return value
}
```

Invalid numeric values are normalized at the point of use. Opacities and thresholds stay within
`0...1`, radii and gesture dimensions never become negative, and width adapts to the available
container while retaining a 44-point dismissal area.

Disable `isRevealGestureEnabled` where the content owns horizontal gestures, such as a paged view,
carousel, or kanban board. Programmatic opening and drag-to-close remain available.
