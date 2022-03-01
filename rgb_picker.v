module main

import iui as ui
import gg
import gx
import math { clamp }

fn show_rgb_picker(mut win ui.Window) {
	mut modal := ui.modal(win, 'RGB Picker')
	modal.set_id(mut win, 'rgb_modal')

	// Create sliders with extra value padding.
	mut r_slider := ui.slider(win, 0, 259, .hor)
	mut g_slider := ui.slider(win, 0, 259, .hor)
	mut b_slider := ui.slider(win, 0, 259, .hor)
	mut a_slider := ui.slider(win, 0, 270, .hor)
	a_slider.cur = 270

	r_slider.set_id(mut win, 'r_slider')
	g_slider.set_id(mut win, 'g_slider')
	b_slider.set_id(mut win, 'b_slider')
	a_slider.set_id(mut win, 'a_slider')

	r_slider.set_bounds(10, 10, modal.in_width - 20, 20)
	g_slider.set_bounds(10, 40, modal.in_width - 20, 20)
	b_slider.set_bounds(10, 70, modal.in_width - 20, 20)
	a_slider.set_bounds(10, 99, modal.in_width - 20, 20)

	mut lbl := ui.label(win, 'RGB(A) Color Picker.\n\nrgba(0, 0, 0)')
	lbl.set_id(mut win, 'rgb_lbl')
	lbl.set_pos(10, 130)
	lbl.pack()

	modal.after_draw_event_fn = fn (mut win ui.Window, com &ui.Component) {
		mut this := &ui.Label(win.get_from_id('rgb_lbl'))
		mut r_slider := &ui.Slider(win.get_from_id('r_slider'))
		mut g_slider := &ui.Slider(win.get_from_id('g_slider'))
		mut b_slider := &ui.Slider(win.get_from_id('b_slider'))
		mut a_slider := &ui.Slider(win.get_from_id('a_slider'))

		cr := byte(clamp(r_slider.cur - 2, 0, 255))
		cg := byte(clamp(g_slider.cur - 2, 0, 255))
		cb := byte(clamp(b_slider.cur - 2, 0, 255))
		ca := byte(clamp(a_slider.cur - 2, 0, 255))

		this.text = this.text.split('rgba(')[0] + 'rgba(' + cr.str() + ', ' + cg.str() + ', ' +
			cb.str() + ', ' + ca.str() + ')'

		win.gg.draw_rect_filled(this.rx + this.width + 16, this.ry + this.height, 150,
			20, gx.rgba(cr, cg, cb, ca))
	}

	modal.add_child(r_slider)
	modal.add_child(g_slider)
	modal.add_child(b_slider)
	modal.add_child(a_slider)
	modal.add_child(lbl)

	modal.needs_init = false

	mut cann := ui.button(win, 'Cancel')
	cann.set_bounds((modal.xs + modal.in_width) - 250, 260, 100, 25)
	cann.set_click(fn (mut win ui.Window, btn ui.Button) {
		win.components = win.components.filter(mut it !is ui.Modal)
	})
	modal.add_child(cann)

	mut save := ui.button(win, 'Save')
	save.set_bounds((modal.xs + modal.in_width) - 125, 260, 100, 25)
	save.set_click(fn (mut win ui.Window, btn ui.Button) {
		mut canvas := &KA(win.id_map['pixels'])

		mut r_slider := &ui.Slider(win.get_from_id('r_slider'))
		mut g_slider := &ui.Slider(win.get_from_id('g_slider'))
		mut b_slider := &ui.Slider(win.get_from_id('b_slider'))
		mut a_slider := &ui.Slider(win.get_from_id('a_slider'))

		cr := byte(clamp(r_slider.cur - 2, 0, 255))
		cg := byte(clamp(g_slider.cur - 2, 0, 255))
		cb := byte(clamp(b_slider.cur - 2, 0, 255))
		ca := byte(clamp(a_slider.cur - 2, 0, 255))

		canvas.color = gx.rgba(cr, cg, cb, ca)

		win.components = win.components.filter(mut it !is ui.Modal)
	})
	modal.add_child(save)

	win.add_child(modal)
}
