# translate.el

`translate.el` is a lightweight, extensible Emacs package for translating text using command-line translation tools. It focuses on simplicity, efficient context detection, and seamless Emacs integration.

## Features

* **Context Aware**: Automatically detects text in the active region or the word at point.
* **Smart Fallback**: If no word is found at the exact cursor position, it intelligently searches for the nearest word.
* **Interactive Input**: Supports manual input via `universal-argument` (`C-u`).
* **Multiple Backends**: Currently supports `translate-shell` (`trans`), `argos-translate`, Volcengine machine translation, and Volcengine Ark.
* **Zero-Dependency Core**: Only standard Emacs Lisp.

## Requirements

You must have the underlying command-line tools installed for the translation to work:

1. **For `translate-trans`**: Install [translate-shell](https://github.com/soimort/translate-shell) (often provided as `trans`).
2. **For `translate-argo`**: Install [argos-translate](https://github.com/argosopentech/argos-translate).
3. **For `translate-volcengine`**: Set `VOLCENGINE_TRANSLATE_API_KEY` or configure `translate-volcengine-api-key`.
4. **For `translate-volcengine-ark`**: Set `ARK_API_KEY` or `VOLCENGINE_ARK_API_KEY`.

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
  :commands (translate-trans translate-argo translate-volcengine translate-volcengine-ark))

```

## Usage

| Command | Description |
| --- | --- |
| `M-x translate-trans` | Translate text using `trans` (translate-shell). |
| `M-x translate-argo` | Translate text using `argos-translate`. |
| `M-x translate-volcengine` | Translate text using Volcengine machine translation. |
| `M-x translate-volcengine-ark` | Translate text using Volcengine Ark. |

### Prefix Arguments

Translation commands support the `universal-argument` (`C-u`):

* **Default (No prefix)**: Automatically translates the current selection or the word at point.
* **With `C-u` for `translate-trans`, `translate-argo`, and `translate-volcengine`**: Prompts for manual input in the minibuffer.
* **With `C-u` for `translate-volcengine-ark`**: Selects and saves the target language before translating.

### Volcengine

`translate-volcengine` uses the Volcengine machine translation API with the
new console `X-Api-Key` authentication method.

```elisp
(setq translate-volcengine-api-key
      (getenv "VOLCENGINE_TRANSLATE_API_KEY"))
```

By default it translates to Chinese:

```elisp
(setq translate-volcengine-target-language "zh")
```

### Volcengine Ark

`translate-volcengine-ark` uses the Volcengine Ark Responses API with
Bearer token authentication. By default it reads `ARK_API_KEY` or
`VOLCENGINE_ARK_API_KEY` and uses `doubao-seed-translation-250915`. You can
also set `translate-volcengine-ark-model` to a Volcengine Ark endpoint id.

```elisp
(setq translate-volcengine-ark-api-key
      (or (getenv "ARK_API_KEY")
          (getenv "VOLCENGINE_ARK_API_KEY")))

(setq translate-volcengine-ark-model "doubao-seed-translation-250915")

(setq translate-volcengine-ark-target-language "en")

(setq translate-volcengine-ark-target-languages
      '(("Chinese" . "zh")
        ("English" . "en")
        ("Japanese" . "ja")
        ("Korean" . "ko")))
```

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
