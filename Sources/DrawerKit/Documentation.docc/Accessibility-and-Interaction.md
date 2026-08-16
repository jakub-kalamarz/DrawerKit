# Accessibility and interaction

Keep the open panel usable while treating the main content as temporarily unavailable.

## Overview

While open, DrawerKit disables hit testing and hides the moved main content from accessibility.
The visible main area becomes one dismiss action, so a tap closes the drawer without activating or
scrolling the view underneath. The panel continues to receive taps and scrolling normally.

DrawerKit provides a VoiceOver escape action and suppresses its animation when Reduce Motion is
enabled by default. Set `closeAccessibilityLabel` to a localized value supplied by your app.

Both ``DrawerEdge/leading`` and ``DrawerEdge/trailing`` use logical layout edges and mirror their
drag direction automatically in right-to-left environments.
