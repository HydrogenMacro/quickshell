# My Quickshell Dots
Contains an audio visualizer widget, powered by a Pipewire-based C program at [`/audiowiz`](/audiowiz).

## Features
 - Transparent floating window
 - Scrolling title
 - RGB dual-channel audio visualizer
 - Basic controls (previous, next, pause/play)
 - Seeking
 - Time labels
 - Command-powered panel show/hide

## Installation & Usage
 - Clone this into `~/.config/quickshell`
 - Install [quickshell](https://quickshell.org/) from your distro
 - To compile the C program (in `/audiowiz`), install [`just`](https://www.just.systems) and run `just build-audiowiz` (or just copy the respective command from the justfile)
 - Run `quickshell` to show the panel. You can run this command automatically on startup using systemd.
 - To toggle the panel open, run `quickshell ipc call musicPanel toggleOpen`. You may bind this to a key or a shortcut.
    - On KDE Plasma, you can go to System Settings > Keyboard > Shortcuts > Add New > Command or Script.
 - `musicPanel isOpen` and `musicPanel setOpen <boolean>` commands are also defined.