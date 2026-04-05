# TermGrid

A native macOS terminal application that organizes multiple terminal sessions into customizable grids and tabs with per-terminal customization.

## Features

- **Split and Tab Layouts**: Switch between side-by-side split terminals or organized tab layouts on the fly
- **Per-Tab Splits**: In tab mode, each tab can have its own number of side-by-side terminals (1-5 splits per tab)
- **Customizable Grid**: Configure the number of rows and columns in split mode (up to 10x10)
- **Per-Terminal Colors**: Set independent background colors for each terminal with 12 presets or custom colors
- **Per-Terminal Font Sizes**: Adjust font size individually for each terminal tile or globally for the instance (8-32pt)
- **Draggable Column Dividers**: Resize split columns by dragging dividers; widths are saved per-layout
- **Tab Management**: Add, rename, and delete tabs; visually distinguish tabs with color indicators
- **Instance Configuration**: Create multiple independent terminal instances with different working directories and layouts
- **Templates**: Save instance configurations as templates to quickly clone new instances with identical setups
- **Directory Selection**: Set different working directories for each instance via file browser
- **Instance Renaming**: Rename instances and tabs on the fly
- **Window Management**: Jump to existing windows or open new ones; track windows by instance
- **Auto-Saving Configuration**: All customizations automatically saved to JSON config
- **Legacy Data Migration**: Automatic migration from old split-mode config to new per-tab model

## Requirements

- macOS 14.0 or later
- Swift 5.9 toolchain (Xcode 15.0+)

## Building

### Clone the Repository

```bash
cd /path/to/parent
git clone <repository-url>
cd termgrid
```

### Debug Build with Swift

For development and debugging:

```bash
swift build
.build/debug/TermGrid
```

### Release Build (macOS App Bundle)

To create a native macOS application bundle:

```bash
./build.sh
open build/TermGrid.app
```

The build script creates a self-contained `.app` bundle in `build/TermGrid.app` that can be moved to Applications or distributed.

## Getting Started

### First Launch

1. Launch the app. The Launcher window opens showing all terminal instances.
2. Click "Add Instance" to create a new terminal instance, or click "Open" on an existing instance.

### Creating a Terminal Instance

1. Click "Add Instance" in the Launcher
2. The app creates a new instance with default settings (3-column split, home directory)
3. Click "Open" to launch the instance

### Customizing an Instance

1. In the Launcher, right-click an instance to access:
   - **Rename** — Change the instance name
   - **Set Directory** — Choose the working directory
   - **Clone** — Create a copy with a new name and directory
   - **Save as Template** — Save the layout as a template for future cloning
   - **Delete** — Remove the instance
2. Use the Settings window (Cmd+,) to edit rows, columns, layout mode, and font size

### Opening a Window

- Click "Open" in the Launcher
- Click an instance name in the Launcher to jump to an existing window
- Click "Open All" to launch all instances at once

## Configuration

### Config File Location

TermGrid stores all configuration in:

```
~/.config/termgrid/config.json
```

The directory is automatically created on first launch.

### Config Structure

The config file contains an array of instances with the following structure:

```json
{
  "instances": [
    {
      "id": "uuid-string",
      "name": "My Terminal",
      "directory": "/path/to/working/dir",
      "rows": 1,
      "cols": 3,
      "layoutMode": "split",
      "fontSize": 11,
      "columnWidths": [0.33, 0.34, 0.33],
      "tileColors": ["#1a1a1f", "#0d1b2a", "#1a0a2e"],
      "tabs": null,
      "isTemplate": false
    }
  ]
}
```

### Config Auto-Save

Every change (colors, font sizes, column widths, names, layout mode, splits) automatically saves to the config file. The app persists all customizations across restarts.

### Manual Config Editing

You can edit the JSON directly. Common adjustments:

- **Change default font size**: Edit `fontSize` (8-32)
- **Adjust column widths**: Edit `columnWidths` as decimal fractions summing to ~1.0
- **Change colors**: Edit `tileColors` as hex strings (e.g., `"#1a1a1f"`)
- **Switch layout mode**: Set `layoutMode` to `"split"` or `"tabs"`

## Layout Modes

### Split Mode

Displays terminals in a fixed grid layout. Each tile occupies a position in an N×M grid.

- Configure rows and columns in Settings or via config
- Right-click any tile for context menu
- Drag column dividers to resize tiles horizontally
- All split widths are saved automatically
- Edit rows/columns in Settings to reorganize the grid

### Tabs Mode

Organizes terminals as tabs, with each tab optionally containing multiple splits.

- Click tab labels to switch between tabs
- Right-click a tab to rename, adjust splits (1-5), or delete
- Each tab can have a different number of side-by-side splits
- Splits within a tab can have independent colors and font sizes
- Drag dividers to resize splits within the current tab
- Click the "+" button to add a new tab

### Switching Layouts

Click the "Switch to Tabs" / "Switch to Split" button in the toolbar to toggle between layouts. The app automatically migrates your configuration.

## Customization

### Terminal Colors

Each terminal tile can have an independent background color.

#### Using Presets

Right-click a terminal tile and select "Background Color", then choose from:

- Default Dark
- Midnight Blue
- Deep Purple
- Forest Green
- Dark Red
- Navy
- Charcoal
- Slate
- Monokai
- Solarized Dark
- Dracula
- Nord

#### Custom Colors

Right-click a terminal and select "Background Color" > "Custom Color..." to open the macOS color picker. The color is applied immediately and saved.

### Font Sizes

#### Per-Terminal Font Size

Right-click a terminal tile and select "Font Size (Npt)" to choose from:

```
8, 9, 10, 11, 12, 13, 14, 16, 18, 20, 24
```

#### Instance-Wide Font Size

Use the font size controls in the toolbar:

- Click the minus icon to decrease font size
- Click the plus icon to increase font size
- The current size displays between the buttons

The toolbar controls adjust all terminals in the current tab (tabs mode) or all tiles (split mode).

### Column Widths (Draggable Dividers)

In both split and tab layouts, drag the vertical divider between columns to resize:

- Drag left to widen the left column
- Drag right to widen the right column
- Minimum width is enforced to prevent accidental collapse
- Widths are saved automatically

### Tab Labels

In tabs mode, right-click a tab and select "Rename Tab..." to customize the label. Labels are displayed in the tab bar.

## Templates

Templates allow you to save instance layouts for quick cloning.

### Creating a Template

1. In the Launcher, configure an instance the way you want (colors, splits, layout, etc.)
2. Right-click the instance and select "Save as Template"
3. The instance becomes a template marked with a document icon

### Using a Template

1. In the Launcher, find the template in the "Templates" section
2. Click "Clone" next to the template name
3. Enter a name for the new instance
4. Choose a working directory
5. The new instance is created with the template's exact layout and colors

### Cloning from Instances

You can also clone any regular instance:

1. Right-click an instance and select "Clone..."
2. Enter a name for the new instance
3. Choose a working directory
4. The clone inherits all layout and customization from the source

## Space Pinning

TermGrid supports macOS Spaces (virtual desktops). To assign a terminal window to a specific Space:

1. Move the terminal window to your desired Space
2. Right-click the window title bar and select "Assign to..."
3. Choose the Space from the menu

The window will open in that Space when you next launch it. This works the same as any native macOS application.

## Keyboard Shortcuts

- **Cmd+,** — Open Settings (instance list and editor)
- **Cmd+W** — Close the current terminal window
- **Cmd+Q** — Quit TermGrid
- **Enter** — Confirm dialogs (Rename, Clone, etc.)
- **Esc** — Cancel dialogs

## License

MIT
