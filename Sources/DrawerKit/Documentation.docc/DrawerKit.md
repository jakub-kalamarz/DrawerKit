# ``DrawerKit``

Build a native-feeling navigation drawer from ordinary SwiftUI views.

@Metadata {
    @PageImage(purpose: icon, source: "drawerkit-logo.png")
    @PageColor(blue)
}

## Overview

DrawerKit places a panel behind your main content and moves the content aside when the drawer
opens. The panel stays interactive. The moved content cannot tap or scroll, and tapping it closes
the drawer without forwarding the action to the underlying view.

```swift
@State private var isOpen = false

Drawer(isOpen: $isOpen) {
    NavigationPanel()
} content: {
    MainContent(openDrawer: { isOpen = true })
}
```

Use ``DrawerConfiguration`` to tune width, gestures, animation, appearance, feedback, side, and
accessibility behavior.

### Interaction model

- Drag inward from the configured edge to reveal the panel.
- Drag the moved content back toward the panel to close it.
- Tap anywhere in the moved content to close without activating content underneath.
- Change the `isOpen` binding directly for programmatic control.
- Use VoiceOver's escape gesture to close.

The default ``DrawerEdge/leading`` edge follows the environment's layout direction. Use
``DrawerEdge/trailing`` when navigation belongs on the opposite logical side.

## Topics

### Essentials

- ``Drawer``
- ``DrawerConfiguration``
- ``DrawerEdge``

### Guides

- <doc:Configuration>
- <doc:Accessibility-and-Interaction>
