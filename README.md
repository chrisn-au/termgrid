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
- **tmux Integration**: Optional tmux mode per instance — sessions persist across app restarts
- **Smart Prompt**: Custom shell prompt shows relative path when inside the instance directory, normal path elsewhere
- **Auto-Restart Shell**: Shells automatically restart when exited, so you never get a dead pane
- **Directory Selection**: Set different working directories for each instance via file browser
- **Instance Renaming**: Rename instances and tabs on the fly
- **Window Management**: Jump to existing windows or open new ones; macOS auto-switches Spaces
- **Auto-Saving Configuration**: All customizations automatically saved to JSON config
- **App Icon**: Custom dark icon with terminal grid motif

## Requirements

- macOS 14.0 or later
- Swift 5.9 toolchain (Xcode 15.0+)
- Optional: tmux (for tmux mode — `brew install tmux`)

## Building

### Clone the Repository

```bash
git clone https://github.com/chrisn-au/termgrid.git
cd termgrid
```

### Debug Build

```bash
swift build
.build/debug/TermGrid
```

### Release Build (macOS App Bundle)

```bash
./build.sh
open build/TermGrid.app
```

The build script creates a `.app` bundle in `build/TermGrid.app` with the app icon and Info.plist. Move it to `/Applications` if you like.

## Getting Started

### First Launch

1. Launch the app. The Launcher window opens showing all terminal instances.
2. Click "Add Instance" to create a new instance, or "Open" on an existing one.
3. Each instance opens a window with terminal panes based on its configuration.

### Customizing an Instance

In the Launcher, right-click an instance for:

- **Rename** — Change the instance name
- **Set Directory** — Choose the working directory
- **Clone** — Create a copy with a new name and directory
- **Save as Template** — Save the layout as a reusable template
- **Delete** — Remove the instance

Use Settings (Cmd+,) to edit rows, columns, layout mode, and font size.

### Navigating Instances

- Click an instance name to jump to its window (macOS auto-switches Spaces)
- Click "Open All" to launch all instances

## Configuration

All config is stored at `~/.config/termgrid/config.json` and auto-saves on every change.

```json
{
  "instances": [
    {
      "id": "uuid-string",
      "name": "My Project",
      "directory": "/Users/me/projects/foo",
      "rows": 1,
      "cols": 3,
      "layoutMode": "tabs",
      "fontSize": 12,
      "useTmux": false,
      "tabs": [
        {
          "label": "Editor",
          "splits": 1,
          "fontSizes": [14]
        },
        {
          "label": "Build + Test",
          "splits": 2,
          "colors": ["#0d1b2a", "#0a1f0a"]
        }
      ]
    }
  ]
}
```

You can edit the JSON directly if you prefer. The app picks up changes on next launch.

## Layout Modes

### Split Mode

Terminals arranged in a fixed grid. Drag dividers to resize columns. All widths saved automatically.

### Tabs Mode

Each tab can contain 1-5 side-by-side terminal splits. Right-click a tab to:

- Rename it
- Set the number of splits (1-5)
- Change colors and font sizes per split
- Delete the tab

Click "+" in the tab bar to add tabs.

### Switching Layouts

Click the layout toggle button in the toolbar. Switching from split to tabs auto-migrates your existing configuration.

## tmux Mode

Toggle tmux on/off per instance via the toolbar button (shows "shell" or "tmux" with a green highlight).

- Each terminal pane gets a named tmux session (e.g. `tg-DADD8BF0-t0s0`)
- Sessions persist if you close and reopen the window
- Requires tmux installed (`/opt/homebrew/bin/tmux`, `/usr/local/bin/tmux`, or `/usr/bin/tmux`)
- Switching modes automatically restarts terminals in the new mode

## Custom Prompt

When using native shell mode, TermGrid sets up a custom zsh prompt:

- **Inside the instance directory**: `project-name/src/components %`
- **Outside the instance directory**: `~/other/path %`

This works by setting `ZDOTDIR` to a TermGrid-managed zsh config that sources your existing `.zshrc` first, then overrides the prompt. Your aliases, PATH, and other shell config are preserved.

## Customization

### Terminal Colors

Right-click any terminal pane for 12 preset colors (Midnight Blue, Dracula, Nord, Solarized Dark, etc.) or "Custom Color..." to open the macOS color picker.

### Font Sizes

- **Per-terminal**: Right-click a pane and select from the Font Size menu (8-24pt)
- **Toolbar controls**: A+/A- buttons change the current tab's font (tabs mode) or all tiles (split mode)
- **Settings**: Instance-wide default font size

### Column Widths

Drag the dividers between terminal panes. Minimum width is enforced. Widths are saved per-tab in tabs mode.

## Templates

1. Set up an instance with your preferred layout, colors, fonts, and splits
2. Right-click it in the Launcher and select "Save as Template"
3. Templates appear in a separate section with a "Clone" button
4. Cloning prompts for a name and directory, then creates a new instance with all settings copied

You can also clone any regular instance via right-click.

## Space Pinning

To pin a TermGrid window to a specific macOS Space:

1. Open the instance and move the window to the desired Space
2. Right-click TermGrid in the Dock -> Options -> "Assign To" -> "This Desktop"
3. macOS remembers the assignment across app restarts

Window titles include the instance name and directory for easy identification.

## Keyboard Shortcuts

- **Cmd+,** — Open Settings
- **Cmd+W** — Close window
- **Cmd+Q** — Quit TermGrid
- **Enter** — Confirm dialogs
- **Esc** — Cancel dialogs

## License

MIT
