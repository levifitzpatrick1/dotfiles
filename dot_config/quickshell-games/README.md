# quickshell-games

Fullscreen game launcher (`ALT+G`). `shell.qml` renders the grid; `games` is a
wrapper that rebuilds `games.go` on demand and prints the game list as TSV.

Appearance (corner radius, backdrop opacity, font, animations, title scrim) is
shared with the wallpaper menu and configured in
`~/.config/quickshell-menus/style.json` — see the README there.

## Box art

Art for each game is resolved in this order:

1. Manual override: `~/.config/quickshell-games/box-art/<title-slug>.{png,jpg,jpeg,webp}`
2. Steam grid art you set in Steam itself (`userdata/*/config/grid`)
3. Steam's local library cache
4. Steam CDN (real Steam appids)
5. SteamGridDB lookup by game name (needs the free API key below)
6. Steam store search by name → CDN
7. Wikipedia article cover image — keyless, works for well-known titles
   (WoW, Alan Wake 2, …); drops trailing words like "Co-op" if the exact
   title has no article, and only accepts portrait images

Downloads are cached in `~/.cache/quickshell-games/art/`. Games with no art
found get a `.miss` marker so the network isn't retried for 3 days.

### SteamGridDB (optional)

The Wikipedia fallback covers most games with no setup. For obscure titles
or nicer alternate grids, get a free API key at
<https://www.steamgriddb.com/profile/preferences/api> and save it to:

    ~/.config/quickshell-games/steamgriddb-key

(or export `STEAMGRIDDB_API_KEY`).

## Commands

    games --list                       # print all games as TSV (what the menu uses)
    games --art "World of Warcraft" cover.png   # set art manually (file or URL)
    games --refresh                    # clear .miss markers, retry art downloads
