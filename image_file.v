module main

import stbi
import gx

pub fn read(path string) ?stbi.Image {
	return stbi.load(path)
}

pub fn write(img stbi.Image, path string) {
	stbi.stbi_write_png(path, img.width, img.height, 4, img.data, img.width * 4) or { panic(err) }
}

// Get RGB value from image loaded with STBI
pub fn get_pixel(x int, y int, mut this stbi.Image) gx.Color {
	image := this
	unsafe {
		data := &byte(image.data)
		p := data + (4 * (y * image.width + x))
		r := p[0]
		g := p[1]
		b := p[2]
		a := p[3]
		return gx.Color{r, g, b, a}
	}
}

// Get RGB value from image loaded with STBI
fn set_pixel(image stbi.Image, x int, y int, color gx.Color) bool {
	if x < 0 || x >= image.width {
		return false
	}

	if y < 0 || y >= image.height {
		return false
	}

	unsafe {
		data := &byte(image.data)
		p := data + (4 * (y * image.width + x))
		p[0] = color.r
		p[1] = color.g
		p[2] = color.b
		p[3] = color.a
		return true
	}
}
