package main

import (
	"bufio"
	"bytes"
	"encoding/json"
	"fmt"
	"html"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
)

type theme struct {
	label, icon, source, kind string
}

var libraryPath = regexp.MustCompile(`(?m)^\s*"path"\s+"([^"]+)"`)

var abiToads = map[string]string{
	"3737237256": "Fishing Frogs", "3672173183": "Lily Valley Frog",
	"3647375769": "Skating Frogs", "3613206617": "Star Ride",
	"3582809467": "Cozy Campfire", "3553595416": "Frog Tank",
	"3531878415": "Sledding Game", "3519888361": "Lazy River",
	"3451858260": "Ribbiting River", "3408160555": "Froggy Snow Day",
	"3390306162": "Cozy Winter", "3352342968": "Farming Frogs",
	"3337947824": "Gliding Toad", "3317551372": "Dancing Frogs",
	"3305478571": "Axolotl Ride", "3285324108": "Salamander Rides",
	"3256064096": "Cloud Watching Frogs", "3238117266": "Waterfall Frog (Kicks)",
	"3238082868": "Waterfall Frog", "3219522309": "Frog Picnic",
	"3194061367": "Frog & Mush Adventures (Night)", "3174013136": "Frog & Mush Adventures",
	"3147116018": "Shelf of Curiosities", "3119714017": "Frog on Ice",
	"3021911243": "Gliding Frog (Night)", "3019953428": "Gliding Frog",
	"2985464274": "Marshmallow Mushling",
}

func homeDir() string {
	home, err := os.UserHomeDir()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	return home
}

func imageIn(directory string) string {
	for _, name := range []string{"preview.jpg", "preview.jpeg", "preview.png", "preview.gif", "wallpaper.jpg", "wallpaper.jpeg", "wallpaper.png", "background.jpg"} {
		path := filepath.Join(directory, name)
		if info, err := os.Stat(path); err == nil && !info.IsDir() {
			return path
		}
	}
	for _, pattern := range []string{"*.jpg", "*.jpeg", "*.png", "*.gif"} {
		matches, _ := filepath.Glob(filepath.Join(directory, pattern))
		if len(matches) > 0 {
			sort.Strings(matches)
			return matches[0]
		}
	}
	return ""
}

func staticThemes(home string) []theme {
	root := filepath.Join(home, ".config/themes")
	directories, _ := filepath.Glob(filepath.Join(root, "*"))
	var themes []theme
	for _, directory := range directories {
		info, err := os.Stat(directory)
		if err != nil || !info.IsDir() || filepath.Base(directory) == "current" {
			continue
		}
		image := imageIn(directory)
		if image == "" {
			continue
		}
		name := strings.ReplaceAll(filepath.Base(directory), "-", " ")
		themes = append(themes, theme{label: strings.ToUpper(name[:1]) + name[1:], icon: image, source: image, kind: "Static"})
	}
	return themes
}

func steamRoots(home string) []string {
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

func projectTitle(directory, fallback string) string {
	data, err := os.ReadFile(filepath.Join(directory, "project.json"))
	if err != nil {
		return fallback
	}
	var project map[string]any
	if json.Unmarshal(data, &project) == nil {
		if title, ok := project["title"].(string); ok && strings.TrimSpace(title) != "" {
			return html.UnescapeString(title)
		}
	}
	return fallback
}

func workshopThemes(home string) []theme {
	installed := map[string]string{}
	for _, root := range steamRoots(home) {
		directories, _ := filepath.Glob(filepath.Join(root, "steamapps/workshop/content/431960/*"))
		for _, directory := range directories {
			id := filepath.Base(directory)
			if _, wanted := abiToads[id]; wanted {
				installed[id] = directory
			}
		}
	}
	var themes []theme
	for id, directory := range installed {
		preview := imageIn(directory)
		if preview == "" {
			continue
		}
		name := projectTitle(directory, abiToads[id])
		themes = append(themes, theme{label: "Abi Toads · " + name, icon: preview, source: directory, kind: "Animated"})
	}
	for id, name := range abiToads {
		if _, ok := installed[id]; ok {
			continue
		}
		themes = append(themes, theme{
			label:  "Subscribe · Abi Toads · " + name,
			icon:   "steam",
			source: "steam://url/CommunityFilePage/" + id,
			kind:   "Subscribe",
		})
	}
	return themes
}

func main() {
	home := homeDir()
	themes := staticThemes(home)
	themes = append(themes, workshopThemes(home)...)
	sort.Slice(themes, func(i, j int) bool {
		if themes[i].kind != themes[j].kind {
			return themes[i].kind < themes[j].kind
		}
		return strings.ToLower(themes[i].label) < strings.ToLower(themes[j].label)
	})
	if len(os.Args) > 1 && os.Args[1] == "--list" {
		for _, item := range themes {
			fmt.Printf("%s\t%s\t%s\n", item.label, item.kind, item.source)
		}
		return
	}
	if len(themes) == 0 {
		_ = exec.Command("notify-send", "Theme Selector", "No themes found").Start()
		return
	}
	var menu bytes.Buffer
	writer := bufio.NewWriter(&menu)
	for _, item := range themes {
		fmt.Fprintf(writer, "%s%cicon\x1f%s\n", item.label, byte(0), item.icon)
	}
	_ = writer.Flush()
	command := exec.Command("rofi", "-dmenu", "-i", "-show-icons", "-p", "Select Theme", "-theme", filepath.Join(home, ".config/themes/theme_selector.rasi"))
	command.Stdin = &menu
	selected, err := command.Output()
	if err != nil {
		return
	}
	choice := strings.TrimSpace(string(selected))
	for _, item := range themes {
		if item.label != choice {
			continue
		}
		if item.kind == "Subscribe" {
			_ = exec.Command("steam", item.source).Start()
		} else {
			_ = exec.Command(filepath.Join(home, ".config/themes/set_wallpaper"), item.source).Start()
		}
		return
	}
}
