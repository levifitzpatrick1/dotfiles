package main

import (
	"bufio"
	"bytes"
	"encoding/binary"
	"fmt"
	"hash/crc32"
	"image"
	"image/color"
	_ "image/gif"
	"image/jpeg"
	_ "image/png"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
)

type game struct {
	name, label, icon, source string
	command                   []string
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
		"battle.net": true, "faugus": true, "faugus launcher": true,
		"path of building 1 (rusty)": true, "path of building 2 (rusty)": true,
		"piper": true, "protonup-qt": true, "steam": true, "wagoapp": true,
	}
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

func imageWithExtensions(base string) string {
	return firstImage(base+".png", base+".jpg", base+".jpeg", base+".webp")
}

func titleSlug(title string) string {
	slug := strings.Trim(slugUnsafe.ReplaceAllString(strings.ToLower(title), "-"), "-")
	if slug == "" {
		return strings.ToLower(title)
	}
	return slug
}

func customBoxArt(home, title string) string {
	directory := filepath.Join(home, ".config/rofi-games/box-art")
	for _, name := range []string{title, titleSlug(title)} {
		if path := imageWithExtensions(filepath.Join(directory, name)); path != "" {
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
		matches, _ := filepath.Glob(pattern)
		sort.Strings(matches)
		for _, match := range matches {
			if imageFile(match) {
				return match
			}
		}
	}
	return ""
}

func steamGridLandscape(home, appID string) string {
	patterns := []string{
		filepath.Join(home, ".local/share/Steam/userdata/*/config/grid/"+appID+".*"),
		filepath.Join(home, ".steam/steam/userdata/*/config/grid/"+appID+".*"),
	}
	for _, pattern := range patterns {
		matches, _ := filepath.Glob(pattern)
		sort.Strings(matches)
		for _, match := range matches {
			if imageFile(match) {
				return match
			}
		}
	}
	return ""
}

func steamIcon(home, appID, title string, roots []string) string {
	// 1. Check custom vertical/box art first
	if path := customBoxArt(home, title); path != "" {
		return path
	}
	// 2. Check Steam userdata Grid portrait art
	if path := steamGridPortrait(home, appID); path != "" {
		return path
	}
	// 3. Check Steam library cache portrait art (600x900)
	for _, root := range roots {
		cache := filepath.Join(root, "appcache/librarycache", appID)
		if path := firstImage(filepath.Join(cache, "library_600x900.jpg")); path != "" {
			return path
		}
		matches, _ := filepath.Glob(filepath.Join(cache, "*", "library_600x900.jpg"))
		sort.Strings(matches)
		for _, match := range matches {
			if imageFile(match) {
				return match
			}
		}
	}
	// 4. Fallback: Check Steam userdata Grid landscape art
	if path := steamGridLandscape(home, appID); path != "" {
		return path
	}
	// 5. Fallback: Check Steam library cache landscape art/logos
	preferredLandscapes := []string{"library_header.jpg", "header.jpg", "logo.png"}
	for _, root := range roots {
		cache := filepath.Join(root, "appcache/librarycache", appID)
		for _, name := range preferredLandscapes {
			if path := firstImage(filepath.Join(cache, name)); path != "" {
				return path
			}
			matches, _ := filepath.Glob(filepath.Join(cache, "*", name))
			sort.Strings(matches)
			for _, match := range matches {
				if imageFile(match) {
					return match
				}
			}
		}
	}
	return "steam"
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
			games = append(games, game{name: name, label: name, icon: ensureVerticalImage(home, id, steamIcon(home, id, name, roots)), source: "Steam", command: []string{"steam", "steam://rungameid/" + id}})
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

func steamShortcutIcon(shortcut map[string]vdfValue) string {
	for _, key := range []string{"icon", "Icon"} {
		if value := strings.Trim(shortcut[key].text, `"`); value != "" {
			if imageFile(value) {
				return value
			}
		}
	}
	return "steam"
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
			appName, exe := strings.TrimSpace(shortcut["appname"].text), strings.TrimSpace(shortcut["exe"].text)
			if appName == "" || utilities[strings.ToLower(appName)] {
				continue
			}
			id := steamShortcutID(appName, exe, shortcut["appid"].number)
			if seen[id] {
				continue
			}
			seen[id] = true
			icon := customBoxArt(home, appName)
			if icon == "" {
				icon = steamGridPortrait(home, id)
			}
			if icon == "" {
				icon = steamShortcutIcon(shortcut)
			}
			if icon == "" {
				icon = steamGridLandscape(home, id)
			}
			games = append(games, game{name: appName, label: appName, icon: ensureVerticalImage(home, id, icon), source: "Steam Shortcut", command: []string{"steam", "steam://rungameid/" + id}})
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
	entries := []game{{name: "Add Non-Steam Game", label: "Add Non-Steam Game to Steam", icon: "steam", source: "Steam", command: []string{"steam", "steam://addnonsteamgame"}}}
	if command := desktopLauncher(home, "Heroic Games Launcher"); command != nil {
		entries = append(entries, game{name: "Heroic Games Launcher", label: "Open Heroic - Epic/GOG", icon: "heroic", source: "Installers", command: command})
	} else if path, err := exec.LookPath("heroic"); err == nil {
		entries = append(entries, game{name: "Heroic Games Launcher", label: "Open Heroic - Epic/GOG", icon: "heroic", source: "Installers", command: []string{path}})
	} else if command := installCommand("heroic-games-launcher-bin"); command != nil {
		entries = append(entries, game{name: "Install Heroic Games Launcher", label: "Install Heroic - Epic/GOG", icon: "system-software-install", source: "Installers", command: command})
	}
	return entries
}

func notify(message string) {
	if path, err := exec.LookPath("notify-send"); err == nil {
		_ = exec.Command(path, "Game Launcher", message).Start()
	}
}

func main() {
	home := homeDir()
	games := append(steamGames(home), steamShortcutGames(home)...)
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
	if len(os.Args) > 1 && os.Args[1] == "--list" {
		for _, item := range games {
			fmt.Printf("%s\t%s\t%s\t%s\n", item.label, item.source, item.icon, strings.Join(item.command, " "))
		}
		return
	}
	if len(games) == 0 {
		notify("No installed games were found.")
		return
	}
	var menu bytes.Buffer
	for _, item := range games {
		fmt.Fprintf(&menu, "%s%cicon\x1f%s\n", item.label, byte(0), item.icon)
	}
	theme := filepath.Join(home, ".config/rofi/games.rasi")
	command := exec.Command("rofi", "-dmenu", "-i", "-show-icons", "-p", "Games", "-theme", theme)
	command.Stdin = &menu
	selected, err := command.Output()
	if err != nil {
		return
	}
	choice := strings.TrimSpace(string(selected))
	for _, item := range games {
		if item.label == choice {
			_ = exec.Command(item.command[0], item.command[1:]...).Start()
			return
		}
	}
}

func downloadFile(url, filepath string) error {
	resp, err := http.Get(url)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("bad status: %d", resp.StatusCode)
	}
	out, err := os.Create(filepath)
	if err != nil {
		return err
	}
	defer out.Close()
	_, err = io.Copy(out, resp.Body)
	return err
}

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

func ensureVerticalImage(home, appID, localPath string) string {
	if localPath == "" || localPath == "steam" {
		return localPath
	}
	
	cacheDir := filepath.Join(home, ".cache/rofi-games/vertical")
	_ = os.MkdirAll(cacheDir, 0755)
	targetPath := filepath.Join(cacheDir, appID+".jpg")
	
	if _, err := os.Stat(targetPath); err == nil {
		return targetPath
	}
	
	if imageFile(localPath) {
		file, err := os.Open(localPath)
		if err == nil {
			imgCfg, _, err := image.DecodeConfig(file)
			file.Close()
			if err == nil && imgCfg.Width > 0 && imgCfg.Width < imgCfg.Height {
				return localPath
			}
		}
	}
	
	isNumeric := true
	for _, c := range appID {
		if c < '0' || c > '9' {
			isNumeric = false
			break
		}
	}
	if isNumeric {
		cdnURL := fmt.Sprintf("https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/%s/library_600x900.jpg", appID)
		if err := downloadFile(cdnURL, targetPath); err == nil {
			return targetPath
		}
		cdnURL2 := fmt.Sprintf("https://steamcdn-a.akamaihd.net/steam/apps/%s/library_600x900.jpg", appID)
		if err := downloadFile(cdnURL2, targetPath); err == nil {
			return targetPath
		}
	}
	
	if imageFile(localPath) {
		if err := padToVertical(localPath, targetPath); err == nil {
			return targetPath
		}
	}
	
	return localPath
}
