# quickshell-menus

Shared appearance settings for the quickshell menus (games launcher on `ALT+G`,
wallpaper picker on `ALT+W`). Both menus watch `style.json` and reload live —
you can tweak values while a menu is open.

| Key                 | Default      | Meaning                                          |
| ------------------- | ------------ | ------------------------------------------------ |
| `cornerRadius`      | `16`         | Card corner radius; `0` for fully square corners |
| `backgroundOpacity` | `0.75`       | Darkness of the fullscreen backdrop (0–1)        |
| `fontFamily`        | `"Comfortaa"`| Font used throughout the menus                   |
| `animationMs`       | `150`        | Hover/selection animation duration; `0` disables |
| `titleScrim`        | `true`       | Dark gradient behind titles overlaid on artwork  |
| `hoverScale`        | `1.04`       | Card zoom when hovered/selected; `1.0` disables  |

Missing keys fall back to the defaults above.
