package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

var slugUnsafe = regexp.MustCompile(`[^a-z0-9]+`)

func boxArtDir(home string) string {
	return filepath.Join(home, ".config/quickshell-games/box-art")
}

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

func titleSlug(title string) string {
	slug := strings.Trim(slugUnsafe.ReplaceAllString(strings.ToLower(title), "-"), "-")
	if slug == "" {
		return strings.ToLower(title)
	}
	return slug
}

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

func shortcutArt(home, id, title string) string {
	if path := customBoxArt(home, title); path != "" {
		return path
	}
	if path := steamGridPortrait(home, id); path != "" {
		return path
	}
	return fetchArt(home, id, title, "")
}

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

func clearMisses(home string) {
	misses, _ := filepath.Glob(filepath.Join(artCacheDir(home), "*.miss"))
	for _, miss := range misses {
		_ = os.Remove(miss)
	}
	fmt.Printf("cleared %d cached misses\n", len(misses))
}
