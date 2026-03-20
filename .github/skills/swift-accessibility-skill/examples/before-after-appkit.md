# Before/After: AppKit Accessibility

Concrete code transformations for macOS AppKit apps. Each example shows the inaccessible version, the corrected version, and a summary of every change.

Priority tiers:
- **Blocks Assistive Tech** — Element is completely unreachable or unusable
- **Degrades Experience** — Reachable with significant friction
- **Incomplete Support** — Gaps that prevent Nutrition Label claims

## Contents

### Blocks Assistive Tech
- Icon-only NSButton missing label
- Custom NSView not in accessibility tree
- NSTableView row without accessible summary

### Degrades Experience
- Keyboard focus missing on custom view
- Context menu without keyboard equivalent
- Wrong role on custom control

### Incomplete Support
- Hardcoded font sizes (no Dynamic Type)
- Color-only status in NSTableView cell

---

## [Blocks Assistive Tech] Icon-only NSButton missing label

**Problem:** VoiceOver announces "button" with no description. The user cannot tell what the button does.

```swift
// Before
let shareButton = NSButton()
shareButton.image = NSImage(systemSymbolName: "square.and.arrow.up", accessibilityDescription: nil)
shareButton.isBordered = false
shareButton.bezelStyle = .toolbar
```

```swift
// After
let shareButton = NSButton()
shareButton.image = NSImage(
    systemSymbolName: "square.and.arrow.up",
    accessibilityDescription: "Share" // [VERIFY] confirm label matches intent
)
shareButton.isBordered = false
shareButton.bezelStyle = .toolbar
shareButton.toolTip = "Share" // Also serves as VoiceOver label fallback
```

**Changes:**
- Added `accessibilityDescription` to the `NSImage` — VoiceOver reads this as the button label
- Added `toolTip` — serves as fallback label and benefits sighted keyboard users

---

## [Blocks Assistive Tech] Custom NSView not in accessibility tree

**Problem:** A custom-drawn card view exists visually but VoiceOver cannot reach it at all.

```swift
// Before
class ProjectCardView: NSView {
    var title: String = ""
    var status: String = ""

    override func draw(_ dirtyRect: NSRect) {
        // Custom drawing...
    }
}
```

```swift
// After
class ProjectCardView: NSView {
    var title: String = "" {
        didSet { setAccessibilityLabel("\(title), \(status)") }
    }
    var status: String = "" {
        didSet { setAccessibilityLabel("\(title), \(status)") }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setAccessibilityElement(true)
        setAccessibilityRole(.group)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setAccessibilityElement(true)
        setAccessibilityRole(.group)
    }

    override func draw(_ dirtyRect: NSRect) {
        // Custom drawing...
    }
}
```

**Changes:**
- `setAccessibilityElement(true)` — exposes the view to VoiceOver
- `setAccessibilityRole(.group)` — tells VoiceOver this is a grouped element
- `setAccessibilityLabel` — provides a meaningful description, updated when properties change

---

## [Blocks Assistive Tech] NSTableView row without accessible summary

**Problem:** VoiceOver reads individual cells but cannot summarize the row. Users hear fragmented information with no context.

```swift
// Before
class TaskRowView: NSTableRowView {
    var taskName: String = ""
    var assignee: String = ""
    var dueDate: String = ""
}
```

```swift
// After
class TaskRowView: NSTableRowView {
    var taskName: String = "" {
        didSet { updateAccessibility() }
    }
    var assignee: String = "" {
        didSet { updateAccessibility() }
    }
    var dueDate: String = "" {
        didSet { updateAccessibility() }
    }

    private func updateAccessibility() {
        setAccessibilityLabel(taskName)
        setAccessibilityValue("Assigned to \(assignee), due \(dueDate)")
    }
}
```

**Changes:**
- `setAccessibilityLabel` — provides the primary description (task name)
- `setAccessibilityValue` — provides additional context (assignee, due date)
- Properties update accessibility when values change

---

## [Degrades Experience] Keyboard focus missing on custom view

**Problem:** A clickable card responds to mouse clicks but cannot be reached or activated via keyboard.

```swift
// Before
class ClickableCardView: NSView {
    var onClick: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        onClick?()
    }
}
```

```swift
// After
class ClickableCardView: NSView {
    var onClick: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        setAccessibilityLabel("Project card") // [VERIFY]
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        setAccessibilityLabel("Project card") // [VERIFY]
    }

    override func mouseDown(with event: NSEvent) {
        onClick?()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 || event.keyCode == 49 { // Return or Space
            onClick?()
        } else {
            super.keyDown(with: event)
        }
    }

    override func drawFocusRingMask() {
        bounds.fill()
    }

    override var focusRingMaskBounds: NSRect { bounds }
}
```

**Changes:**
- `acceptsFirstResponder` — allows keyboard focus
- `keyDown` — handles Return (36) and Space (49) for activation
- `drawFocusRingMask` / `focusRingMaskBounds` — draws the system focus ring
- Accessibility role set to `.button` so VoiceOver announces it correctly

---

## [Degrades Experience] Context menu without keyboard equivalent

**Problem:** Right-click menu is the only way to access actions. Keyboard and VoiceOver users cannot reach them.

```swift
// Before
class DocumentView: NSView {
    override func menu(for event: NSEvent) -> NSMenu? {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Duplicate", action: #selector(duplicateDocument), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Delete", action: #selector(deleteDocument), keyEquivalent: ""))
        return menu
    }
}
```

```swift
// After
class DocumentView: NSView {
    override func menu(for event: NSEvent) -> NSMenu? {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Duplicate", action: #selector(duplicateDocument), keyEquivalent: "d"))
        menu.addItem(NSMenuItem(title: "Delete", action: #selector(deleteDocument), keyEquivalent: "\u{8}")) // Delete key
        return menu
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setAccessibilityCustomActions([
            NSAccessibilityCustomAction(
                name: "Duplicate",
                target: self,
                selector: #selector(duplicateDocument)
            ),
            NSAccessibilityCustomAction(
                name: "Delete",
                target: self,
                selector: #selector(deleteDocument)
            )
        ])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setAccessibilityCustomActions([
            NSAccessibilityCustomAction(
                name: "Duplicate",
                target: self,
                selector: #selector(duplicateDocument)
            ),
            NSAccessibilityCustomAction(
                name: "Delete",
                target: self,
                selector: #selector(deleteDocument)
            )
        ])
    }
}
```

**Changes:**
- Added `keyEquivalent` to menu items for keyboard access
- Added `setAccessibilityCustomActions` — VoiceOver users can access these via the Actions rotor

---

## [Degrades Experience] Wrong role on custom control

**Problem:** A custom toggle is exposed as a generic group. VoiceOver doesn't announce it as a toggle or report its state.

```swift
// Before
class CustomToggleView: NSView {
    var isOn = false

    override func mouseDown(with event: NSEvent) {
        isOn.toggle()
        needsDisplay = true
    }
}
```

```swift
// After
class CustomToggleView: NSView {
    var isOn = false {
        didSet {
            setAccessibilityValue(isOn ? "1" : "0")
            needsDisplay = true
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setAccessibilityElement(true)
        setAccessibilityRole(.checkBox)
        setAccessibilityLabel("Feature toggle") // [VERIFY]
        setAccessibilityValue(isOn ? "1" : "0")
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setAccessibilityElement(true)
        setAccessibilityRole(.checkBox)
        setAccessibilityLabel("Feature toggle") // [VERIFY]
        setAccessibilityValue(isOn ? "1" : "0")
    }

    override func mouseDown(with event: NSEvent) {
        isOn.toggle()
    }

    override func accessibilityPerformPress() -> Bool {
        isOn.toggle()
        return true
    }
}
```

**Changes:**
- `setAccessibilityRole(.checkBox)` — VoiceOver announces "checkbox" with state
- `setAccessibilityValue` — reports "1" (on) or "0" (off), updated on toggle
- `accessibilityPerformPress()` — VoiceOver can activate it
- `setAccessibilityLabel` — provides the control's name

---

## [Incomplete Support] Hardcoded font sizes

**Problem:** Text doesn't scale with the system Dynamic Type setting. macOS users who increase text size in System Settings see no change.

```swift
// Before
let titleLabel = NSTextField(labelWithString: "Project Name")
titleLabel.font = NSFont.systemFont(ofSize: 18, weight: .bold)

let bodyLabel = NSTextField(labelWithString: "Description")
bodyLabel.font = NSFont.systemFont(ofSize: 14)
```

```swift
// After
let titleLabel = NSTextField(labelWithString: "Project Name")
titleLabel.font = NSFont.preferredFont(forTextStyle: .headline)

let bodyLabel = NSTextField(labelWithString: "Description")
bodyLabel.font = NSFont.preferredFont(forTextStyle: .body)
```

**Changes:**
- Replaced `systemFont(ofSize:)` with `preferredFont(forTextStyle:)` — scales with user's text size setting
- Available text styles: `.largeTitle`, `.title1`, `.title2`, `.title3`, `.headline`, `.body`, `.callout`, `.subheadline`, `.footnote`, `.caption1`, `.caption2`

---

## [Incomplete Support] Color-only status in NSTableView cell

**Problem:** A green/red dot indicates task status. In grayscale or for color-blind users, the dots are indistinguishable.

```swift
// Before
let statusDot = NSView()
statusDot.wantsLayer = true
statusDot.layer?.backgroundColor = task.isComplete ? NSColor.green.cgColor : NSColor.red.cgColor
statusDot.layer?.cornerRadius = 5
```

```swift
// After
let statusDot = NSView()
statusDot.wantsLayer = true
statusDot.layer?.backgroundColor = task.isComplete ? NSColor.systemGreen.cgColor : NSColor.systemRed.cgColor
statusDot.layer?.cornerRadius = 5

let statusIcon = NSImageView()
statusIcon.image = NSImage(
    systemSymbolName: task.isComplete ? "checkmark.circle.fill" : "xmark.circle.fill",
    accessibilityDescription: task.isComplete ? "Complete" : "Incomplete"
)
statusIcon.contentTintColor = task.isComplete ? .systemGreen : .systemRed
```

**Changes:**
- Added icon alongside color — shape differentiates status without relying on color alone
- Used `systemGreen`/`systemRed` — semantic colors that adapt to appearance settings
- Added `accessibilityDescription` on the image — VoiceOver announces the status
