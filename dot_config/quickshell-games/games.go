package main

import (
	"bufio"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"hash/crc32"
	"image"
	"image/color"
	_ "image/gif"
	"image/jpeg"
	_ "image/png"
	"io"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"time"
)

type game struct {
	name, label, icon, source, kind string
	command                         []string
}

type vdfValue struct {
	text     string
	number   uint32
	children map[string]vdfValue
}

var (
	manifestAppID = regexp.MustCompile(`(?m)^\s*"appid"\s+"(\d+)"`)
	manifestName  = regexp.MustCompile(`(?m)^\s*"name"\s+"([^"]+)"`)
	libraryPath   = regexp.MustCompile(`(?m)^\s*"path"\s+"([^"]+)"`)
	slugUnsafe    = regexp.MustCompile(`[^a-z0-9]+`)
	supportTitle  = regexp.MustCompile(`(?i)^(Proton(?: Experimental| Hotfix| \d)|Steam Linux Runtime|Steamworks Common Redistributables)`)
	utilities     = map[string]bool{
		"battle.net":                 true,
		"path of building 1 (rusty)": true, "path of building 2 (rusty)": true,
		"piper": true, "protonup-qt": true, "steam": true, "wagoapp": true,
	}
	httpClient = &http.Client{Timeout: 8 * time.Second}
)

func homeDir() string {
	home, err := os.UserHomeDir()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	return home
}

func existingSteamRoots(home string) []string {
	seen := map[string]bool{}
	queue := []string{filepath.Join(home, ".local/share/Steam"), filepath.Join(home, ".steam/steam")}
	var roots []string
	for len(queue) > 0 {
		root := queue[0]
		queue = queue[1:]
		absolute, _ := filepath.Abs(root)
		if seen[absolute] {
			continue
		}
		if info, err := os.Stat(absolute); err != nil || !info.IsDir() {
			continue
		}
		seen[absolute] = true
		roots = append(roots, absolute)
		for _, file := range []string{filepath.Join(absolute, "steamapps/libraryfolders.vdf"), filepath.Join(absolute, "config/libraryfolders.vdf")} {
			data, err := os.ReadFile(file)
			if err != nil {
				continue
			}
			for _, match := range libraryPath.FindAllSubmatch(data, -1) {
				queue = append(queue, strings.ReplaceAll(string(match[1]), `\\`, `\`))
			}
		}
	}
	return roots
}

func imageFile(path string) bool {
	info, err := os.Stat(path)
	return err == nil && !info.IsDir()
}

func firstImage(candidates ...string) string {
	for _, candidate := range candidates {
		if imageFile(candidate) {
			return candidate
		}
	}
	return ""
}

func firstGlobImage(pattern string) string {
	matches, _ := filepath.Glob(pattern)
	sort.Strings(matches)
	for _, match := range matches {
		if imageFile(match) {
			return match
		}
	}
	return ""
}

func titleSlug(title string) string {
	slug := strings.Trim(slugUnsafe.ReplaceAllString(strings.ToLower(title), "-"), "-")
	if slug == "" {
		return strings.ToLower(title)
	}
	return slug
}

func boxArtDir(home string) string {
	return filepath.Join(home, ".config/quickshell-games/box-art")
}

// customBoxArt returns art the user dropped into the box-art directory,
// named either after the exact title or its slug.
func customBoxArt(home, title string) string {
	for _, name := range []string{title, titleSlug(title)} {
		base := filepath.Join(boxArtDir(home), name)
		if path := firstImage(base+".png", base+".jpg", base+".jpeg", base+".webp"); path != "" {
			return path
		}
	}
	return ""
}

func steamGridPortrait(home, appID string) string {
	patterns := []string{
		filepath.Join(home, ".local/share/Steam/userdata/*/config/grid/"+appID+"p.*"),
		filepath.Join(home, ".steam/steam/userdata/*/config/grid/"+appID+"p.*"),
		filepath.Join(home, ".local/share/Steam/userdata/*/config/grid/"+appID+"_library_600x900.*"),
		filepath.Join(home, ".steam/steam/userdata/*/config/grid/"+appID+"_library_600x900.*"),
	}
	for _, pattern := range patterns {
		if path := firstGlobImage(pattern); path != "" {
			return path
		}
	}
	return ""
}

func libraryCachePortrait(appID string, roots []string) string {
	for _, root := range roots {
		cache := filepath.Join(root, "appcache/librarycache", appID)
		if path := firstImage(filepath.Join(cache, "library_600x900.jpg")); path != "" {
			return path
		}
		if path := firstGlobImage(filepath.Join(cache, "*", "library_600x900.jpg")); path != "" {
			return path
		}
	}
	return ""
}

func libraryCacheLandscape(appID string, roots []string) string {
	for _, root := range roots {
		cache := filepath.Join(root, "appcache/librarycache", appID)
		for _, name := range []string{"library_header.jpg", "header.jpg", "logo.png"} {
			if path := firstImage(filepath.Join(cache, name)); path != "" {
				return path
			}
			if path := firstGlobImage(filepath.Join(cache, "*", name)); path != "" {
				return path
			}
		}
	}
	return ""
}

// ── Art fetching ──────────────────────────────────────────────────────────────

func artCacheDir(home string) string {
	return filepath.Join(home, ".cache/quickshell-games/art")
}

func missPath(home, cacheID string) string {
	return filepath.Join(artCacheDir(home), cacheID+".miss")
}

func recentMiss(home, cacheID string) bool {
	info, err := os.Stat(missPath(home, cacheID))
	return err == nil && time.Since(info.ModTime()) < 72*time.Hour
}

// userAgent identifies us politely; Wikimedia rejects Go's default UA outright.
const userAgent = "quickshell-games/1.0 (personal game launcher)"

func downloadFile(fileURL, target string) error {
	request, err := http.NewRequest("GET", fileURL, nil)
	if err != nil {
		return err
	}
	request.Header.Set("User-Agent", userAgent)
	resp, err := httpClient.Do(request)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("bad status: %d", resp.StatusCode)
	}
	out, err := os.Create(target)
	if err != nil {
		return err
	}
	defer out.Close()
	_, err = io.Copy(out, resp.Body)
	return err
}

func fetchJSON(endpoint, bearer string, target any) error {
	request, err := http.NewRequest("GET", endpoint, nil)
	if err != nil {
		return err
	}
	request.Header.Set("User-Agent", userAgent)
	if bearer != "" {
		request.Header.Set("Authorization", "Bearer "+bearer)
	}
	resp, err := httpClient.Do(request)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("bad status: %d", resp.StatusCode)
	}
	return json.NewDecoder(resp.Body).Decode(target)
}

func steamCDNArt(appID, target string) bool {
	for _, base := range []string{
		"https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/",
		"https://steamcdn-a.akamaihd.net/steam/apps/",
	} {
		if downloadFile(base+appID+"/library_600x900.jpg", target) == nil {
			return true
		}
	}
	return false
}

func steamGridDBKey(home string) string {
	if key := strings.TrimSpace(os.Getenv("STEAMGRIDDB_API_KEY")); key != "" {
		return key
	}
	data, err := os.ReadFile(filepath.Join(home, ".config/quickshell-games/steamgriddb-key"))
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(data))
}

// steamGridDBArt looks a game up by name on SteamGridDB and downloads its top
// 600x900 grid. Needs a free API key from steamgriddb.com/profile/preferences/api.
func steamGridDBArt(home, title, target string) bool {
	key := steamGridDBKey(home)
	if key == "" {
		return false
	}
	var search struct {
		Data []struct {
			ID int `json:"id"`
		} `json:"data"`
	}
	endpoint := "https://www.steamgriddb.com/api/v2/search/autocomplete/" + url.PathEscape(title)
	if err := fetchJSON(endpoint, key, &search); err != nil || len(search.Data) == 0 {
		return false
	}
	var grids struct {
		Data []struct {
			URL string `json:"url"`
		} `json:"data"`
	}
	endpoint = fmt.Sprintf("https://www.steamgriddb.com/api/v2/grids/game/%d?dimensions=600x900&types=static", search.Data[0].ID)
	if err := fetchJSON(endpoint, key, &grids); err != nil || len(grids.Data) == 0 {
		return false
	}
	return downloadFile(grids.Data[0].URL, target) == nil
}

// steamStoreAppID searches the Steam storefront by name; only accepts a result
// whose name closely matches to avoid grabbing art for the wrong game.
func steamStoreAppID(title string) string {
	var result struct {
		Items []struct {
			ID   json.Number `json:"id"`
			Name string      `json:"name"`
		} `json:"items"`
	}
	endpoint := "https://store.steampowered.com/api/storesearch/?cc=us&l=en&term=" + url.QueryEscape(title)
	if err := fetchJSON(endpoint, "", &result); err != nil {
		return ""
	}
	want := titleSlug(title)
	for _, item := range result.Items {
		got := titleSlug(item.Name)
		if got == want || strings.Contains(want, got) || strings.Contains(got, want) {
			return item.ID.String()
		}
	}
	return ""
}

// wikipediaPageArt downloads the lead image of the Wikipedia article named
// query, if the article exists and its image is portrait-shaped (box art is
// always taller than wide; logos and screenshots are not).
func wikipediaPageArt(query, target string) bool {
	var result struct {
		Query struct {
			Pages map[string]struct {
				Thumbnail struct {
					Source string `json:"source"`
					Width  int    `json:"width"`
					Height int    `json:"height"`
				} `json:"thumbnail"`
			} `json:"pages"`
		} `json:"query"`
	}
	endpoint := "https://en.wikipedia.org/w/api.php?action=query&format=json&redirects=1&prop=pageimages&piprop=thumbnail&pithumbsize=600&pilicense=any&titles=" + url.QueryEscape(query)
	if err := fetchJSON(endpoint, "", &result); err != nil {
		return false
	}
	for _, page := range result.Query.Pages {
		thumb := page.Thumbnail
		if thumb.Source != "" && thumb.Height > thumb.Width {
			return downloadFile(thumb.Source, target) == nil
		}
	}
	return false
}

// wikipediaArt fetches cover art from Wikipedia — a keyless last resort for
// titles Steam can't resolve. Tries the exact title, then drops up to two
// trailing words ("Elden Ring Co-op" → "Elden Ring"), never below two words.
func wikipediaArt(title, target string) bool {
	words := strings.Fields(title)
	for length := len(words); length > 0 && length >= len(words)-2; length-- {
		if length < len(words) && length < 2 {
			break
		}
		if wikipediaPageArt(strings.Join(words[:length], " "), target) {
			return true
		}
	}
	return false
}

// fetchArt returns cached or freshly downloaded vertical art for a game, or "".
// steamAppID is set only for real Steam appids where the CDN can be used directly.
func fetchArt(home, cacheID, title, steamAppID string) string {
	_ = os.MkdirAll(artCacheDir(home), 0755)
	target := filepath.Join(artCacheDir(home), cacheID+".jpg")
	if imageFile(target) {
		return target
	}
	if recentMiss(home, cacheID) {
		return ""
	}
	if steamAppID != "" && steamCDNArt(steamAppID, target) {
		return target
	}
	if steamGridDBArt(home, title, target) {
		return target
	}
	if steamAppID == "" {
		if id := steamStoreAppID(title); id != "" && steamCDNArt(id, target) {
			return target
		}
	}
	if wikipediaArt(title, target) {
		return target
	}
	_ = os.WriteFile(missPath(home, cacheID), nil, 0644)
	return ""
}

// ── Game sources ──────────────────────────────────────────────────────────────

func steamArt(home, appID, title string, roots []string) string {
	if path := customBoxArt(home, title); path != "" {
		return path
	}
	if path := steamGridPortrait(home, appID); path != "" {
		return path
	}
	if path := libraryCachePortrait(appID, roots); path != "" {
		return path
	}
	if path := fetchArt(home, appID, title, appID); path != "" {
		return path
	}
	if landscape := libraryCacheLandscape(appID, roots); landscape != "" {
		target := filepath.Join(artCacheDir(home), appID+".jpg")
		if padToVertical(landscape, target) == nil {
			return target
		}
	}
	return ""
}

func steamGames(home string) []game {
	roots := existingSteamRoots(home)
	seen := map[string]bool{}
	var games []game
	for _, root := range roots {
		manifests, _ := filepath.Glob(filepath.Join(root, "steamapps/appmanifest_*.acf"))
		for _, manifest := range manifests {
			data, err := os.ReadFile(manifest)
			if err != nil {
				continue
			}
			idMatch, nameMatch := manifestAppID.FindSubmatch(data), manifestName.FindSubmatch(data)
			if idMatch == nil || nameMatch == nil {
				continue
			}
			id, name := string(idMatch[1]), string(nameMatch[1])
			if seen[id] || supportTitle.MatchString(name) {
				continue
			}
			seen[id] = true
			games = append(games, game{name: name, label: name, icon: steamArt(home, id, name, roots), source: "Steam", kind: "game", command: []string{"steam", "steam://rungameid/" + id}})
		}
	}
	return games
}

func readCString(data []byte, offset *int) string {
	start := *offset
	for *offset < len(data) && data[*offset] != 0 {
		*offset++
	}
	value := string(data[start:*offset])
	if *offset < len(data) {
		*offset++
	}
	return value
}

func parseBinaryVDFObject(data []byte, offset *int) map[string]vdfValue {
	result := map[string]vdfValue{}
	for *offset < len(data) {
		valueType := data[*offset]
		*offset++
		if valueType == 8 {
			break
		}
		key := readCString(data, offset)
		switch valueType {
		case 0:
			result[key] = vdfValue{children: parseBinaryVDFObject(data, offset)}
		case 1:
			result[key] = vdfValue{text: readCString(data, offset)}
		case 2:
			if *offset+4 > len(data) {
				return result
			}
			result[key] = vdfValue{number: binary.LittleEndian.Uint32(data[*offset : *offset+4])}
			*offset += 4
		default:
			return result
		}
	}
	return result
}

func steamShortcutID(appName, exe string, appID uint32) string {
	if appID == 0 {
		appID = crc32.ChecksumIEEE([]byte(appName+exe)) | 0x80000000
	}
	return fmt.Sprintf("%d", appID)
}

func shortcutArt(home, id, title string) string {
	if path := customBoxArt(home, title); path != "" {
		return path
	}
	if path := steamGridPortrait(home, id); path != "" {
		return path
	}
	return fetchArt(home, id, title, "")
}

func steamShortcutGames(home string) []game {
	files, _ := filepath.Glob(filepath.Join(home, ".local/share/Steam/userdata/*/config/shortcuts.vdf"))
	legacy, _ := filepath.Glob(filepath.Join(home, ".steam/steam/userdata/*/config/shortcuts.vdf"))
	files = append(files, legacy...)
	seen := map[string]bool{}
	var games []game
	for _, file := range files {
		data, err := os.ReadFile(file)
		if err != nil {
			continue
		}
		offset := 0
		root := parseBinaryVDFObject(data, &offset)
		shortcuts := root["shortcuts"].children
		for _, value := range shortcuts {
			shortcut := value.children
			appName := strings.TrimSpace(shortcut["AppName"].text)
			if appName == "" {
				appName = strings.TrimSpace(shortcut["appname"].text)
			}
			exe := strings.TrimSpace(shortcut["Exe"].text)
			if exe == "" {
				exe = strings.TrimSpace(shortcut["exe"].text)
			}
			if appName == "" || utilities[strings.ToLower(appName)] {
				continue
			}
			var appID uint32
			if val, exists := shortcut["appid"]; exists {
				appID = val.number
			} else if val, exists := shortcut["AppID"]; exists {
				appID = val.number
			}
			id := steamShortcutID(appName, exe, appID)
			if seen[id] {
				continue
			}
			seen[id] = true
			games = append(games, game{name: appName, label: appName, icon: shortcutArt(home, id, appName), source: "Steam Shortcut", kind: "game", command: []string{"steam", "steam://rungameid/" + id}})
		}
	}
	return games
}

func desktopEntry(path string) map[string]string {
	file, err := os.Open(path)
	if err != nil {
		return nil
	}
	defer file.Close()
	entry, inDesktop := map[string]string{}, false
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if strings.HasPrefix(line, "[") {
			inDesktop = line == "[Desktop Entry]"
			continue
		}
		if !inDesktop || line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		if key, value, ok := strings.Cut(line, "="); ok {
			if _, exists := entry[key]; !exists {
				entry[key] = value
			}
		}
	}
	return entry
}

func desktopEntries(home string) map[string]string {
	entries := map[string]string{}
	for _, directory := range []string{"/usr/share/applications", filepath.Join(home, ".local/share/applications")} {
		files, _ := filepath.Glob(filepath.Join(directory, "*.desktop"))
		for _, path := range files {
			entries[filepath.Base(path)] = path
		}
	}
	return entries
}

func desktopLauncher(home, name string) []string {
	for id, path := range desktopEntries(home) {
		entry := desktopEntry(path)
		if entry == nil || !strings.EqualFold(strings.TrimSpace(entry["Name"]), name) {
			continue
		}
		return []string{"gtk-launch", id}
	}
	return nil
}

func installCommand(packageName string) []string {
	if terminal, err := exec.LookPath("ghostty"); err == nil {
		return []string{terminal, "-e", "paru", "-S", "--needed", packageName}
	}
	if terminal, err := exec.LookPath("kitty"); err == nil {
		return []string{terminal, "paru", "-S", "--needed", packageName}
	}
	return nil
}

func utilityEntries(home string) []game {
	entries := []game{{name: "Add Non-Steam Game", label: "Add Non-Steam Game", icon: "", source: "Steam", kind: "utility", command: []string{"steam", "steam://addnonsteamgame"}}}
	if command := desktopLauncher(home, "Heroic Games Launcher"); command != nil {
		entries = append(entries, game{name: "Heroic Games Launcher", label: "Heroic (Epic/GOG)", icon: "", source: "Installers", kind: "utility", command: command})
	} else if path, err := exec.LookPath("heroic"); err == nil {
		entries = append(entries, game{name: "Heroic Games Launcher", label: "Heroic (Epic/GOG)", icon: "", source: "Installers", kind: "utility", command: []string{path}})
	} else if command := installCommand("heroic-games-launcher-bin"); command != nil {
		entries = append(entries, game{name: "Install Heroic Games Launcher", label: "Install Heroic (Epic/GOG)", icon: "", source: "Installers", kind: "utility", command: command})
	}
	return entries
}

type legendaryGame struct {
	AppName string `json:"app_name"`
	Title   string `json:"title"`
}

func heroicArt(home, id, title string) string {
	if path := customBoxArt(home, title); path != "" {
		return path
	}
	if path := fetchArt(home, id, title, ""); path != "" {
		return path
	}
	return firstImage(filepath.Join(home, ".config/heroic/icons", id+".jpg"), filepath.Join(home, ".config/heroic/icons", id+".png"))
}

func heroicGames(home string) []game {
	var games []game
	path := filepath.Join(home, ".config/heroic/legendaryConfig/legendary/installed.json")
	data, err := os.ReadFile(path)
	if err != nil {
		return games
	}
	var installed map[string]legendaryGame
	if err := json.Unmarshal(data, &installed); err != nil {
		return games
	}
	for id, item := range installed {
		title := item.Title
		if title == "" {
			title = item.AppName
		}
		if title == "" {
			title = id
		}
		games = append(games, game{
			name:    title,
			label:   title,
			icon:    heroicArt(home, id, title),
			source:  "Heroic",
			kind:    "game",
			command: []string{"heroic", "heroic://launch/legendary/" + id},
		})
	}
	return games
}

// ── Art helpers ───────────────────────────────────────────────────────────────

// padToVertical letterboxes a landscape image onto a dark 300x450 canvas.
func padToVertical(sourcePath, targetPath string) error {
	file, err := os.Open(sourcePath)
	if err != nil {
		return err
	}
	defer file.Close()
	src, _, err := image.Decode(file)
	if err != nil {
		return err
	}

	srcBounds := src.Bounds()
	srcW := srcBounds.Dx()
	srcH := srcBounds.Dy()
	if srcW == 0 || srcH == 0 {
		return fmt.Errorf("invalid source dimensions")
	}

	dstW, dstH := 300, 450
	dst := image.NewRGBA(image.Rect(0, 0, dstW, dstH))

	bgColor := color.RGBA{24, 24, 28, 255}
	for y := 0; y < dstH; y++ {
		for x := 0; x < dstW; x++ {
			dst.Set(x, y, bgColor)
		}
	}

	scaledH := (dstW * srcH) / srcW
	if scaledH > dstH {
		scaledH = dstH
	}
	if scaledH == 0 {
		scaledH = 1
	}

	yOffset := (dstH - scaledH) / 2

	for y := 0; y < scaledH; y++ {
		for x := 0; x < dstW; x++ {
			srcX := (x * srcW) / dstW
			srcY := (y * srcH) / scaledH
			dst.Set(x, y+yOffset, src.At(srcBounds.Min.X+srcX, srcBounds.Min.Y+srcY))
		}
	}

	outFile, err := os.Create(targetPath)
	if err != nil {
		return err
	}
	defer outFile.Close()

	return jpeg.Encode(outFile, dst, &jpeg.Options{Quality: 85})
}

// ── Commands ──────────────────────────────────────────────────────────────────

// installArt saves user-provided art (file path or URL) into the box-art
// directory under the game's slug so every art lookup finds it first.
func installArt(home, title, source string) {
	directory := boxArtDir(home)
	if err := os.MkdirAll(directory, 0755); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	extension := strings.ToLower(filepath.Ext(strings.SplitN(source, "?", 2)[0]))
	if extension != ".png" && extension != ".jpg" && extension != ".jpeg" && extension != ".webp" {
		extension = ".jpg"
	}
	target := filepath.Join(directory, titleSlug(title)+extension)
	if strings.HasPrefix(source, "http://") || strings.HasPrefix(source, "https://") {
		if err := downloadFile(source, target); err != nil {
			fmt.Fprintln(os.Stderr, "download failed:", err)
			os.Exit(1)
		}
	} else {
		data, err := os.ReadFile(source)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
		if err := os.WriteFile(target, data, 0644); err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
	}
	fmt.Println("installed box art:", target)
}

// clearMisses removes negative-lookup markers so the next listing retries the
// network for games that previously had no art (e.g. after adding an API key).
func clearMisses(home string) {
	misses, _ := filepath.Glob(filepath.Join(artCacheDir(home), "*.miss"))
	for _, miss := range misses {
		_ = os.Remove(miss)
	}
	fmt.Printf("cleared %d cached misses\n", len(misses))
}

func listGames(home string) {
	games := append(append(steamGames(home), steamShortcutGames(home)...), heroicGames(home)...)
	sort.Slice(games, func(i, j int) bool { return strings.ToLower(games[i].name) < strings.ToLower(games[j].name) })
	games = append(games, utilityEntries(home)...)
	counts := map[string]int{}
	for _, item := range games {
		counts[strings.ToLower(item.name)]++
	}
	for index := range games {
		if counts[strings.ToLower(games[index].name)] > 1 {
			games[index].label += " — " + games[index].source
		}
	}
	for _, item := range games {
		fmt.Printf("%s\t%s\t%s\t%s\t%s\n", item.label, item.source, item.icon, item.kind, strings.Join(item.command, " "))
	}
}

func main() {
	home := homeDir()
	if len(os.Args) > 1 {
		switch os.Args[1] {
		case "--list":
			listGames(home)
			return
		case "--refresh":
			clearMisses(home)
			return
		case "--art":
			if len(os.Args) != 4 {
				fmt.Fprintln(os.Stderr, "usage: games --art \"Game Title\" <image-file-or-url>")
				os.Exit(1)
			}
			installArt(home, os.Args[2], os.Args[3])
			return
		default:
			fmt.Fprintln(os.Stderr, "usage: games [--list | --refresh | --art \"Game Title\" <image-file-or-url>]")
			os.Exit(1)
		}
	}
	listGames(home)
}
