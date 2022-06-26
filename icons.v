module main

import iui as ui
import net.http
import os

fn img_from_url(mut win ui.Window, url string, size int) &ui.Image {
	full_url := 'https://img.icons8.com/' + url

	dir := os.resource_abs_path('resources')
	os.mkdir(dir) or {}
	path := os.join_path(dir, os.base(full_url))
	http.download_file(full_url, path) or {}

	img_data := os.read_bytes(path) or { [] }

	mut pen_btn := ui.image_from_byte_array_with_size(mut win, img_data, size, size)
	pen_btn.z_index = 8

	pen_btn.set_bounds(4, 0, size, size)
	return pen_btn
}
