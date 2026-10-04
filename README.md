# macOS Sleep Display Menu Bar Button

A free, open-source menu bar app that puts your Mac's display to sleep with one click. It runs `pmset displaysleepnow` for you, so you don't have to type it in Terminal or reach for the power button.

Your Mac keeps running. Downloads continue, music keeps playing, and builds finish. Only the screen goes dark.

## Features

- One click on the power icon in the menu bar opens a small panel. Press **Sleep Display** and the screen sleeps.
- The panel hangs directly under its icon, like the system's own menu bar popouts. It uses native macOS materials, so it follows light and dark mode.
- It waits until you stop touching the mouse and keyboard (0.3 seconds), because any input wakes a sleeping display.
- No Dock icon, no windows, no dependencies, no `sudo`.
- Native Swift and SwiftUI. Under 200 lines of code.

## Install

You need macOS 14 or later and the Xcode command line tools (`xcode-select --install`).

```sh
git clone https://github.com/codeclawd/macos-sleep-display-menu-bar.git
cd macos-sleep-display-menu-bar
./build.sh
open "build/Display Sleep.app"
```

Drag `build/Display Sleep.app` to `/Applications` to keep it. To start it at login, add it under System Settings, General, Login Items.

The build is ad-hoc signed. If macOS blocks the first launch, right-click the app and choose Open.

## Usage

1. Click the power icon in the menu bar.
2. Press **Sleep Display**.
3. Move the mouse or press a key to wake the screen.

Press Esc or click anywhere else to close the panel without sleeping. **Quit** is at the bottom.

If you use a menu bar manager such as Thaw and the icon is hidden, drag it into the visible section. The panel then opens right under it. With the icon hidden, the panel opens at the top right of the screen.

## How it works

`Sources/main.swift` creates a status bar item and a borderless panel. Pressing the button waits for input to go quiet, then launches `/usr/bin/pmset displaysleepnow`. That command needs no administrator rights. `Sources/PanelView.swift` holds the SwiftUI panel.

## FAQ

**How do I turn off my Mac display without putting the Mac to sleep?**
Run `pmset displaysleepnow` in Terminal, or use this app to run it from the menu bar.

**Does it need sudo or special permissions?**
No. `pmset displaysleepnow` works for a normal user, and the app is not sandboxed.

**Why does the screen sleep a moment after I click?**
Mouse movement wakes a sleeping display. The app waits 0.3 seconds for your hand to settle so the screen stays off. Change the threshold in `sleepOnceInputIsIdle` in `Sources/main.swift`.

**Will my Mac lock when the display sleeps?**
That depends on System Settings, Lock Screen, "Require password after screen saver begins or display is turned off". The app does not change it.

## License

MIT. See [LICENSE](LICENSE).
