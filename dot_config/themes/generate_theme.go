package main

import (
	"fmt"
	"image"
	_ "image/gif"
	"image/jpeg"
	_ "image/png"
	"math"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

type rgb struct{ r, g, b int }
type bucket struct{ count, r, g, b int }

func dominantColors(path string, limit int) ([]rgb, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()
	img, _, err := image.Decode(file)
	if err != nil {
		return nil, err
	}
	bounds := img.Bounds()
	step := int(math.Max(1, math.Sqrt(float64(bounds.Dx()*bounds.Dy())/20000)))
	buckets := map[int]*bucket{}
	for y := bounds.Min.Y; y < bounds.Max.Y; y += step {
		for x := bounds.Min.X; x < bounds.Max.X; x += step {
			r16, g16, b16, _ := img.At(x, y).RGBA()
			r, g, b := int(r16>>8), int(g16>>8), int(b16>>8)
			key := (r>>4)<<8 | (g>>4)<<4 | (b >> 4)
			entry := buckets[key]
			if entry == nil {
				entry = &bucket{}
				buckets[key] = entry
			}
			entry.count++
			entry.r += r
			entry.g += g
			entry.b += b
		}
	}
	ordered := make([]*bucket, 0, len(buckets))
	for _, entry := range buckets {
		ordered = append(ordered, entry)
	}
	sort.Slice(ordered, func(i, j int) bool { return ordered[i].count > ordered[j].count })
	if len(ordered) > limit {
		ordered = ordered[:limit]
	}
	colors := make([]rgb, 0, len(ordered))
	for _, entry := range ordered {
		colors = append(colors, rgb{entry.r / entry.count, entry.g / entry.count, entry.b / entry.count})
	}
	return colors, nil
}

func rgbToHSV(color rgb) (float64, float64, float64) {
	r, g, b := float64(color.r)/255, float64(color.g)/255, float64(color.b)/255
	maxValue, minValue := math.Max(r, math.Max(g, b)), math.Min(r, math.Min(g, b))
	delta, hue := maxValue-minValue, 0.0
	if delta != 0 {
		switch maxValue {
		case r:
			hue = math.Mod((g-b)/delta, 6)
		case g:
			hue = (b-r)/delta + 2
		default:
			hue = (r-g)/delta + 4
		}
		hue /= 6
		if hue < 0 {
			hue++
		}
	}
	saturation := 0.0
	if maxValue != 0 {
		saturation = delta / maxValue
	}
	return hue, saturation, maxValue
}

func hsvToRGB(h, s, v float64) rgb {
	c := v * s
	x := c * (1 - math.Abs(math.Mod(h*6, 2)-1))
	m := v - c
	var r, g, b float64
	switch sector := int(h * 6); sector {
	case 0:
		r, g, b = c, x, 0
	case 1:
		r, g, b = x, c, 0
	case 2:
		r, g, b = 0, c, x
	case 3:
		r, g, b = 0, x, c
	case 4:
		r, g, b = x, 0, c
	default:
		r, g, b = c, 0, x
	}
	return rgb{int((r + m) * 255), int((g + m) * 255), int((b + m) * 255)}
}

func hex(color rgb) string { return fmt.Sprintf("#%02x%02x%02x", color.r, color.g, color.b) }

func write(path, contents string) error { return os.WriteFile(path, []byte(contents), 0o644) }

func writeJPEG(source, target string) error {
	in, err := os.Open(source)
	if err != nil {
		return err
	}
	defer in.Close()
	img, _, err := image.Decode(in)
	if err != nil {
		return err
	}
	out, err := os.Create(target)
	if err != nil {
		return err
	}
	encodeErr := jpeg.Encode(out, img, &jpeg.Options{Quality: 92})
	closeErr := out.Close()
	if encodeErr != nil {
		return encodeErr
	}
	return closeErr
}

func hueDistance(a, b float64) float64 {
	distance := math.Abs(a - b)
	return math.Min(distance, 1-distance)
}

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "Usage: generate_theme <path_to_wallpaper>")
		os.Exit(1)
	}
	wallpaper, err := filepath.Abs(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	colors, err := dominantColors(wallpaper, 64)
	if err != nil || len(colors) == 0 {
		fmt.Fprintf(os.Stderr, "Error reading image: %v\n", err)
		os.Exit(1)
	}
	best, bestScore := colors[0], -1.0
	for index, color := range colors {
		if index == 16 {
			break
		}
		_, saturation, value := rgbToHSV(color)
		if score := saturation * value; score > bestScore {
			best, bestScore = color, score
		}
	}
	hue, _, _ := rgbToHSV(best)
	
	// Generate beautiful, soft pastel accents (high value, moderate saturation)
	primary := hsvToRGB(hue, 0.40, 0.90)
	
	secondaryHue := math.Mod(hue+.5, 1)
	secondaryScore := -1.0
	for _, color := range colors {
		candidateHue, candidateSaturation, candidateValue := rgbToHSV(color)
		distance := hueDistance(hue, candidateHue)
		if distance < .08 {
			continue
		}
		score := candidateSaturation * candidateValue * (.35 + distance)
		if score > secondaryScore {
			secondaryHue = candidateHue
			secondaryScore = score
		}
	}
	secondary := hsvToRGB(secondaryHue, 0.35, 0.88)

	// Completely neutral, flat, premium slate-gray dark theme colors
	// This reduces noise by ensuring background surfaces and text don't shift hue
	background := rgb{18, 18, 22}        // #121216
	backgroundAlt := rgb{24, 24, 28}     // #18181c
	backgroundSoft := rgb{30, 30, 36}    // #1e1e24
	backgroundHover := rgb{40, 40, 48}   // #282830
	surfaceHigh := rgb{50, 50, 60}       // #32323c
	text := rgb{235, 235, 240}          // #ebebf0
	subtext := rgb{160, 160, 170}        // #a0a0aa

	home, _ := os.UserHomeDir()
	target := filepath.Join(home, ".config/themes/current")
	if err := os.MkdirAll(target, 0o755); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	if err := writeJPEG(wallpaper, filepath.Join(target, "background.jpg")); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	files := map[string]string{
		"colors.conf": fmt.Sprintf(`$primary = rgba(%sff)
$secondary = rgba(%sff)
$on_primary = rgba(%sff)
$background = rgba(%sb8)
$surface = rgba(%sad)
$surface_high = rgba(%sdd)
$text = rgba(%sff)
$subtext = rgba(%sff)
$border = rgba(%s40)
$glow = rgba(%s00)
$warning = rgba(fab387ff)
$critical = rgba(f38ba8ff)
$font_family = Comfortaa
$font_family_bold = Comfortaa Bold
`, strings.TrimPrefix(hex(primary), "#"), strings.TrimPrefix(hex(secondary), "#"), strings.TrimPrefix(hex(background), "#"), strings.TrimPrefix(hex(background), "#"), strings.TrimPrefix(hex(backgroundSoft), "#"), strings.TrimPrefix(hex(surfaceHigh), "#"), strings.TrimPrefix(hex(text), "#"), strings.TrimPrefix(hex(subtext), "#"), strings.TrimPrefix(hex(primary), "#"), strings.TrimPrefix(hex(primary), "#")),
		"colors.css": fmt.Sprintf(`@define-color primary %s;
@define-color secondary %s;
@define-color on_primary %s;
@define-color primary_soft rgba(%d, %d, %d, 0.16);
@define-color background rgba(%d, %d, %d, 0.85);
@define-color surface rgba(%d, %d, %d, 0.74);
@define-color surface_high rgba(%d, %d, %d, 0.88);
@define-color text %s;
@define-color subtext %s;
@define-color border rgba(%d, %d, %d, 0.20);
@define-color glow rgba(%d, %d, %d, 0.0);
@define-color warning #fab387;
@define-color critical #f38ba8;
`, hex(primary), hex(secondary), hex(background), primary.r, primary.g, primary.b, background.r, background.g, background.b, backgroundSoft.r, backgroundSoft.g, backgroundSoft.b, surfaceHigh.r, surfaceHigh.g, surfaceHigh.b, hex(text), hex(subtext), primary.r, primary.g, primary.b, primary.r, primary.g, primary.b),
		"colors.rasi": fmt.Sprintf(`* {
    background: rgba(%d, %d, %d, 0.65);
    background-alt: rgba(%d, %d, %d, 0.75);
    background-soft: rgba(%d, %d, %d, 0.85);
    background-hover: rgba(%d, %d, %d, 0.90);
    foreground: %sff;
    foreground-muted: %sff;
    selected: %sff;
    accent: %sff;
    edge: rgba(%d, %d, %d, 0.15);
    active: %sff;
    urgent: #f38ba8ff;
}
`, background.r, background.g, background.b, backgroundAlt.r, backgroundAlt.g, backgroundAlt.b, backgroundSoft.r, backgroundSoft.g, backgroundSoft.b, backgroundHover.r, backgroundHover.g, backgroundHover.b, hex(text), hex(subtext), hex(primary), hex(secondary), primary.r, primary.g, primary.b, hex(primary)),
		"colors.lua": fmt.Sprintf(`return {
    primary = "rgba(%sff)",
    secondary = "rgba(%sff)",
    glow = "rgba(%s00)",
    background = "rgba(%sb8)",
    surface = "rgba(%sad)",
    text = "rgba(%sff)",
    subtext = "rgba(%sff)",
    border = "rgba(%s28)",
    border_inactive = "rgba(%s0a)",
}
`, strings.TrimPrefix(hex(primary), "#"), strings.TrimPrefix(hex(secondary), "#"), strings.TrimPrefix(hex(primary), "#"), strings.TrimPrefix(hex(background), "#"), strings.TrimPrefix(hex(backgroundSoft), "#"), strings.TrimPrefix(hex(text), "#"), strings.TrimPrefix(hex(subtext), "#"), strings.TrimPrefix(hex(primary), "#"), strings.TrimPrefix(hex(backgroundSoft), "#")),
		"ghostty.conf": fmt.Sprintf(`background = %s
foreground = %s
cursor-color = %s
cursor-text = %s
selection-background = %s
selection-foreground = %s
palette = 0=%s
palette = 1=#f38ba8
palette = 2=#a6e3a1
palette = 3=#f9e2af
palette = 4=%s
palette = 5=#cba6f7
palette = 6=#94e2d5
palette = 7=%s
palette = 8=%s
palette = 9=#eba0ac
palette = 10=#b4f1b0
palette = 11=#fce6b8
palette = 12=%s
palette = 13=#d8b7ff
palette = 14=#a5f0e3
palette = 15=#ffffff
`, hex(background), hex(text), hex(primary), hex(background), hex(primary), hex(background), hex(background), hex(primary), hex(text), hex(subtext), hex(primary)),
	}
	for name, contents := range files {
		if err := write(filepath.Join(target, name), contents); err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
	}
	fmt.Println("Theme generated successfully!")
}
