module main

import iui as ui
import gx
import math

const hue_deg = 359
const modal_width = 445
const compact_width = 360

@[heap]
struct ColorPicker {
mut:
	bw     int = 256
	btn    &ui.Button
	p      &ui.Panel
	slid   &ui.Slider
	aslid  &ui.Slider
	fields []&ui.TextField
	h      f64
	s      int
	v      f64
	mx     int
	my     int
	color  gx.Color
	events map[string][]fn (voidptr)
}

pub fn (mut cp ColorPicker) call_event() {
	for f in cp.events['color_picked'] {
		f(cp)
	}
}

pub fn (mut cp ColorPicker) default_modal_close_fn(mut e ui.MouseEvent) {
	mut win := e.ctx.win
	cp.call_event()
	win.components = win.components.filter(mut it !is ui.Modal)
}

fn modal_draw(mut e ui.DrawEvent) {
	h := e.target.height
	if h > 1 && h < 700 {
		mut tar := e.target
		if mut tar is ui.Modal {
			tar.top_off = 2
		}
	}

	// Responsive Size
	mut tar := e.target
	if mut tar is ui.Modal {
		wss := e.ctx.gg.window_size()
		ws := wss.width

		if ws < modal_width {
			tar.in_width = compact_width
			tar.in_height = 395
		} else {
			tar.in_width = modal_width
			tar.in_height = 330
		}

		tar.children[0].width = tar.in_width
		tar.children[1].y = tar.in_height - 50
		tar.children[2].y = tar.in_height - 50

		bw := (tar.in_width - 20) / 2
		tar.children[1].width = bw - 20
		tar.children[2].x = bw + 5 // 20
		tar.children[2].width = bw - 5
	}
}

pub fn (mut cp ColorPicker) subscribe_event(val string, f fn (voidptr)) {
	cp.events[val] << f
}

fn ColorPicker.new() &ColorPicker {
	return &ColorPicker{
		p:     unsafe { nil }
		btn:   ui.Button.new()
		slid:  ui.Slider.new(min: 0, max: 100, dir: .vert)
		aslid: ui.Slider.new(min: 0, max: 255, dir: .vert)
	}
}

fn (mut cp ColorPicker) open_color_picker(c ?gx.Color) &ui.Modal {
	mut m := ui.Modal.new(title: '')

	m.subscribe_event('draw', modal_draw)
	m.needs_init = false
	m.in_width = modal_width
	m.in_height = 335
	m.top_off = 20

	mut p := cp.make_picker_panel(m.in_width, m.in_height)
	m.add_child(p)

	// Load Given gx.Color
	if c != none {
		cp.load_rgb(c)
		cp.update_text_fields()
	}

	// close btn
	mut close := m.make_close_btn(false)
	y := 292

	close.subscribe_event('mouse_up', cp.default_modal_close_fn)
	close.set_bounds(20, y, 200, 30)
	close.set_accent_filled(true)

	mut can := m.make_close_btn(true)
	can.text = 'Cancel'
	can.set_bounds(227, y, 200, 30)

	return m
}

fn (mut cp ColorPicker) make_picker_panel(w int, h int) &ui.Panel {
	if !isnil(cp.p) {
		return cp.p
	}

	// Create panel
	mut p := ui.Panel.new()
	p.set_bounds(5, 0, w - 10, h)
	cp.p = p

	mut btn := cp.btn
	mut slid := cp.slid
	mut aslid := cp.aslid

	// set bounds
	btn.set_bounds(0, 0, cp.bw, cp.bw)
	slid.set_bounds(0, 0, 38, 256)
	aslid.set_bounds(0, 0, 30, 256) // old h: 192

	// Add to panel
	p.add_child(btn)
	p.add_child(slid)
	p.add_child(aslid)

	// Add events
	btn.subscribe_event('after_draw', cp.hsl_btn_draw_evnt)
	slid.subscribe_event('after_draw', cp.slid_draw_evnt)
	aslid.subscribe_event('after_draw', cp.aslid_draw_evnt)
	slid.subscribe_event('value_change', cp.slid_value_change)
	aslid.subscribe_event('value_change', cp.aslid_value_change)

	mut fields_panel := cp.make_fields()
	p.add_child(fields_panel)

	return p
}

fn roun(a f64, place int) string {
	return '${a}'.substr_ni(0, place)
}

fn (mut cp ColorPicker) slid_draw_evnt(mut e ui.DrawEvent) {
	mut com := e.target // todo

	for i in 0 .. 51 {
		v := 100 - (i * 2)
		vp := f32(v) / 100
		color := hsv_to_rgb(cp.h, f32(cp.s) / 100, vp)
		y := com.ry + (5 * i)
		e.ctx.gg.draw_rect_filled(com.rx, y, com.width - 1, 5, color)
	}

	if mut com is ui.Slider {
		per := com.cur / com.max
		ts := 12
		wid := (com.height * per) - per * ts
		e.ctx.gg.draw_rounded_rect_filled(com.rx, com.ry + wid, com.width, ts, 32, e.ctx.theme.scroll_bar_color)
		e.ctx.gg.draw_rounded_rect_empty(com.rx, com.ry + wid, com.width, ts, 32, gx.black)
	}
}

fn (mut cp ColorPicker) aslid_draw_evnt(mut e ui.DrawEvent) {
	mut win := e.ctx.win
	mut com := e.target

	cpc := cp.color
	lenth := 16
	space := 16

	aa := gx.rgb(150, 150, 150)
	bb := gx.rgb(255, 255, 255)

	mut cc := false
	for i in 0 .. lenth {
		val := 255 - (i * space)
		color := gx.rgba(cpc.r, cpc.g, cpc.b, u8(val))
		y := com.ry + space * i

		ca := if cc { aa } else { bb }
		cb := if cc { bb } else { aa }
		fw := com.width / 2

		win.gg.draw_rect_filled(com.rx, y, fw, space, ca)
		win.gg.draw_rect_filled(com.rx + fw, y, fw - 1, space, cb)
		win.gg.draw_rect_filled(com.rx, y, com.width - 1, space, color)
		cc = !cc
	}

	if mut com is ui.Slider {
		com.thumb_wid = 1
		mut per := com.cur / com.max
		ts := 12
		wid := (com.height * per) - per * ts
		win.gg.draw_rounded_rect_filled(com.rx, com.ry + wid, com.width, ts, 8, win.theme.scroll_bar_color)
		win.gg.draw_rounded_rect_empty(com.rx, com.ry + wid, com.width - 1, ts, 8, gx.black)
	}
}

fn (mut cp ColorPicker) aslid_value_change(mut e ui.FloatValueChangeEvent) {
	cur := 255 - u8(e.target.cur)
	cp.fields[3].text = '${cur}'
	cp.update_text_fields_if_need()
	cp.update_color()
}

fn (mut cp ColorPicker) slid_value_change(mut e ui.FloatValueChangeEvent) {
	cp.v = 100 - e.target.cur
	cp.update_text_fields_if_need()
	cp.update_color()
}

fn p1_draw_responsive(mut e ui.DrawEvent) {
	mut p1 := e.get_target[ui.Panel]()
	wss := e.ctx.gg.window_size()
	ws := wss.width

	if ws < modal_width {
		if mut p1.layout is ui.BoxLayout {
			p1.layout = ui.GridLayout.new(cols: 4)
		}
		p1.width = compact_width - 20
		p1.height = 32 * 2
	} else {
		if mut p1.layout is ui.GridLayout {
			p1.layout = ui.BoxLayout.new(ori: 1, hgap: 4, vgap: 8)
			p1.width = 0
			p1.height = 0
		}
	}
}

fn (mut cp ColorPicker) make_fields() &ui.Panel {
	mut p1 := ui.Panel.new(layout: ui.BoxLayout.new(ori: 1, hgap: 4, vgap: 8))
	mut l1 := ui.Label.new(text: 'HSV', pack: true, vertical_align: .middle)

	p1.subscribe_event('draw', p1_draw_responsive)
	p1.add_child(l1)

	for val in ['H', 'S', 'V', 'A'] {
		if val == 'A' {
			mut lbl := ui.Label.new(text: 'Alpha', pack: true, vertical_align: .middle)
			p1.add_child(lbl)
		}

		mut f := ui.numeric_field(255)
		f.subscribe_event('draw', numfield_draw_evnt)
		f.subscribe_event('text_change', cp.hsv_num_box_change_evnt)
		p1.add_child(f)
		cp.fields << f
	}

	for val in ['RGB'] {
		mut f := ui.TextField.new(text: '255, 255, 255,')
		f.subscribe_event('draw', numfield_draw_evnt)
		f.numeric = true

		mut lbl := ui.Label.new(text: val, pack: true, vertical_align: .middle)
		f.subscribe_event('text_change', cp.rgb_num_box_change_evnt)

		p1.add_child(lbl)
		p1.add_child(f)
		cp.fields << f
	}

	return p1
}

fn numfield_draw_evnt(mut e ui.DrawEvent) {
	if e.target.text.contains(',') {
		e.target.width = e.ctx.text_width('255, 255, 255') + 10
		return
	}

	if e.target.parent.width > 150 {
		// Let GridLayout do size
		return
	}

	e.target.width = e.target.parent.width - 5 // e.ctx.text_width('255,255')
}

fn (mut cp ColorPicker) rgb_num_box_change_evnt(mut e ui.TextChangeEvent) {
	colors := cp.fields[4].text.replace(' ', '').split(',')

	if colors.len < 3 {
		mut nt := []string{}
		for col in colors {
			nt << col
		}
		for nt.len < 3 {
			nt << '0'
		}
		cp.fields[4].text = nt.join(', ')

		return
	}

	r := colors[0].u8()
	g := colors[1].u8()
	b := colors[2].u8()

	if colors.len > 3 {
		cp.fields[4].text = '0, 0, 0'
	}

	a := cp.fields[3].text.u8()
	cp.load_rgb(gx.rgba(r, g, b, a))
}

// Turn mouse down (mx, my) into HSV
fn (mut cp ColorPicker) do_hsv_mouse_down(wmx int, wmy int) {
	cp.mx = math.min(wmx, cp.btn.rx + cp.btn.width)
	cp.my = math.min(wmy, cp.btn.ry + cp.btn.height)
	cp.mx = math.max(cp.btn.rx, cp.mx) - cp.btn.rx
	cp.my = math.max(cp.btn.ry, cp.my) - cp.btn.ry

	w := cp.bw
	cp.h = (f32(cp.mx) / w)
	cp.s = int((f32(w - (cp.my)) / w) * 100)
	cp.v = 100 - cp.slid.cur

	cp.update_color()
	cp.update_text_fields_if_need()
}

fn (mut cp ColorPicker) update_color() {
	color := hsv_to_rgb(cp.h, f32(cp.s) / 100, f32(cp.v) / 100)
	alpha := cp.fields[3].text.u8()
	cp.color = gx.rgba(color.r, color.g, color.b, alpha)
}

fn (mut cp ColorPicker) update_text_fields_if_need() {
	cp.update_text_fields()
}

fn (mut cp ColorPicker) update_text_fields() {
	cp.fields[0].text = '${int(cp.h * hue_deg)}'
	cp.fields[1].text = '${cp.s}'
	cp.fields[2].text = '${int(cp.v)}'
	cp.fields[4].text = '${cp.color.r}, ${cp.color.g}, ${cp.color.b}'
	cp.update_fields_pos()
}

fn (mut cp ColorPicker) hsl_btn_draw_evnt(mut e ui.DrawEvent) {
	mut win := e.ctx.win

	if e.target.is_mouse_down {
		cp.do_hsv_mouse_down(win.mouse_x, win.mouse_y)
	}

	if cp.btn.icon == -1 {
		mut cim := 0
		if 'HSL' in win.id_map {
			hsl := &int(unsafe { win.id_map['HSL'] })
			cim = *hsl
		}
		cp.btn.icon = cim
	}

	x := cp.mx - 7 + e.target.rx
	e.ctx.gg.draw_rounded_rect_empty(x, cp.my - 7 + e.target.ry, 16, 16, 32, gx.white)
	e.ctx.gg.draw_rounded_rect_empty(x - 1, cp.my - 8 + e.target.ry, 16, 16, 32, gx.black)

	ty := cp.btn.ry - 24 - 8 // cp.btn.ry + cp.btn.height + 4

	e.ctx.gg.draw_rect_filled(cp.btn.rx, ty, cp.bw, 24, cp.color)

	br := f32(cp.color.r) * 299
	bg := f32(cp.color.g) * 587
	bb := f32(cp.color.b) * 114
	o := (br + bg + bb) / 1000
	tco := if o > 125 { gx.black } else { gx.white }

	e.ctx.gg.draw_text(cp.btn.rx + 5, ty + 4, '${cp.color.to_css_string()}', gx.TextCfg{
		size:  e.ctx.font_size
		color: tco
	})

	// Draw color
	e.ctx.gg.draw_rect_empty(e.target.rx, e.target.ry, e.target.width, e.target.height,
		gx.black)
	e.ctx.gg.draw_rect_empty(e.target.rx - 1, e.target.ry - 1, e.target.width + 2,
		e.target.height + 2, cp.color)
}

const field_max = [359, 100, 100]

fn (mut cp ColorPicker) hsv_num_box_change_evnt(mut e ui.TextChangeEvent) {
	for i, max in field_max {
		if cp.fields[i].text.int() > max {
			cp.fields[i].text = '${max}'
		}
	}

	h := cp.fields[0].text.int()
	s := cp.fields[1].text.int()
	v := cp.fields[2].text.int()

	cp.load_hsv_int(h, s, v)
	cp.update_hsv_m()
}

fn (mut cp ColorPicker) load_hsv_int(h int, s int, v int) {
	cp.h = f32(h) / hue_deg
	cp.s = s
	cp.v = v

	cp.slid.cur = f32(100 - cp.v)
	cp.aslid.cur = 255 - cp.fields[3].text.u8()

	cp.update_color()
	cp.update_hsv_m()
}

fn (mut cp ColorPicker) load_rgb(color gx.Color) {
	mut h, s, v := rgb_to_hsv(color)

	cp.h = h
	cp.s = int(f32(s) * 100)
	cp.v = 100 * v
	alpha := color.a

	cp.fields[3].text = '${alpha}'
	cp.slid.cur = f32(100 - cp.v)
	cp.aslid.cur = 255 - alpha
	cp.color = gx.rgba(color.r, color.g, color.b, alpha)

	cp.update_hsv_m()
	cp.update_text_fields()
}

fn (mut cp ColorPicker) update_fields_pos() {
	for mut f in cp.fields {
		if f.is_selected {
			continue
		}

		f.carrot_left = f.text.len
	}
}

fn (mut cp ColorPicker) update_hsv_m() {
	w := cp.bw
	cp.mx = int(cp.h * w)
	cp.my = (-(cp.s * w) / 100) + w
}
