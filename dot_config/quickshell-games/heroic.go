package main

import (
	"encoding/json"
	"os"
	"path/filepath"
)

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
