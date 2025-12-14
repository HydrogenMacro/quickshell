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
 - Run `quickshell` automatically, such as by appending it to your `~/.bashrc`.
 - To toggle the panel open, run `quickshell ipc call musicPanel toggleOpen`. You may bind this to a key or a shortcut.
    - On KDE Plasma, you can go to System Settings > Keyboard > Shortcuts > Add New > Command or Script.
 - `musicPanel isOpen` and `musicPanel setOpen <boolean>` commands are also defined.
