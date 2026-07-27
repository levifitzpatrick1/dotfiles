package main

import (
	"fmt"
	"net/http"
	"os"
	"sort"
	"strings"
	"time"
)

type game struct {
	name, label, icon, source, kind string
	command                         []string
}

const userAgent = "quickshell-games/1.0 (personal game launcher)"

var (
	utilities = map[string]bool{
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
