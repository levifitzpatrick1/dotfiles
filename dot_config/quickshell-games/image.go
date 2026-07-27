package main

import (
	"fmt"
	"image"
	"image/color"
	_ "image/gif"
	"image/jpeg"
	_ "image/png"
	"os"
	"path/filepath"
	"sort"
)

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

	bgColor := color.RGBA{R: 24, G: 24, B: 28, A: 255}
	for y := range dstH {
		for x := range dstW {
			dst.Set(x, y, bgColor)
		}
	}

	scaledH := min((dstW*srcH)/srcW, dstH)
	if scaledH == 0 {
		scaledH = 1
	}

	yOffset := (dstH - scaledH) / 2

	for y := range scaledH {
		for x := range dstW {
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
