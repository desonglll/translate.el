# translate.el

`translate.el` is a lightweight, extensible Emacs package for translating text using command-line translation tools. It focuses on simplicity, efficient context detection, and seamless Emacs integration.

## Features

* **Context Aware**: Automatically detects text in the active region or the word at point.
* **Smart Fallback**: If no word is found at the exact cursor position, it intelligently searches for the nearest word.
* **Interactive Input**: Supports manual input via `universal-argument` (`C-u`).
* **Multiple Backends**: Currently supports `translate-shell` (`trans`) and `argos-translate`.
* **Zero-Dependency Core**: Only standard Emacs Lisp.

## Requirements

You must have the underlying command-line tools installed for the translation to work:

1. **For `translate-trans`**: Install [translate-shell](https://github.com/soimort/translate-shell) (often provided as `trans`).
2. **For `translate-argo`**: Install [argos-translate](https://github.com/argosopentech/argos-translate).

## Installation

### Manual

1. Clone this repository or download `translate.el` to your `~/.emacs.d/` or `~/.config/emacs/` directory.
2. Add the following to your `init.el`:

```elisp
(add-to-list 'load-path "/path/to/translate.el/")
(require 'translate)

```

### Doom Emacs

In `packages.el`:

```elisp
(package! translate :recipe (:host github :repo "desonglll/translate"))

```

In `config.el`:

```elisp
(use-package! translate
  :commands (translate-trans translate-argo))

```

## Usage

| Command | Description |
| --- | --- |
| `M-x translate-trans` | Translate text using `trans` (translate-shell). |
| `M-x translate-argo` | Translate text using `argos-translate`. |

### Prefix Arguments

Both commands support the `universal-argument` (`C-u`):

* **Default (No prefix)**: Automatically translates the current selection or the word at point.
* **With `C-u**`: Prompts for manual input in the minibuffer.

### Example Keybinding (Doom)

```elisp
(map! :leader
      (:prefix ("t" . "translate")
       :desc "Translate with trans" "t" #'translate-trans
       :desc "Translate with argo"  "a" #'translate-argo))

```

## License

This file is part of translate.el.

translate.el is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

## Copyright

Copyright (C) 2026 Carl.
