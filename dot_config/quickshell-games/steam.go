package main

import (
	"bufio"
	"encoding/binary"
	"fmt"
	"hash/crc32"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
)

type vdfValue struct {
	text     string
	number   uint32
	children map[string]vdfValue
}

var (
	manifestAppID = regexp.MustCompile(`(?m)^\s*"appid"\s+"(\d+)"`)
	manifestName  = regexp.MustCompile(`(?m)^\s*"name"\s+"([^"]+)"`)
	libraryPath   = regexp.MustCompile(`(?m)^\s*"path"\s+"([^"]+)"`)
	supportTitle  = regexp.MustCompile(`(?i)^(Proton(?: Experimental| Hotfix| \d)|Steam Linux Runtime|Steamworks Common Redistributables)`)
)

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
