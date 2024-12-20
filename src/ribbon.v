module main

// import gg
import gx
import iui as ui

fn (mut app App) make_ribbon() {
	mut box1 := ui.Panel.new(layout: ui.BoxLayout.new(ori: 1, hgap: 0))

	mut color_box := app.make_color_box()

	box1.add_child(make_c_btn(0))
	box1.add_child(make_c_btn(10))

	// Eye Dropper
	img_picker_file := $embed_file('assets/rgb-picker.png')
	mut btn := app.ribbon_icon_btn(img_picker_file.to_bytes())

	app.ribbon.height = 74

	box1.set_x(5)
	color_box.set_x(11)
	btn.set_x(5)
	btn.border_radius = 2

	btn.y = 0
	btn.height = app.ribbon.height - 10

	app.ribbon.add_child(box1)
	app.ribbon.add_child(color_box)
	app.ribbon.add_child(btn)

	img_file := $embed_file('assets/hsv.png')
	data := img_file.to_bytes()

	mut gg := app.win.gg
	gg_im := gg.create_image_from_byte_array(data) or { panic(err) }

	mut cim := 0
	cim = gg.cache_image(gg_im)
	app.win.id_map['HSL'] = &cim

	mut sp := ui.Panel.new(layout: ui.FlowLayout.new(hgap: 1, vgap: 1))
	sp.subscribe_event('draw', app.shape_box_draw)
	sp.set_bounds(5, 0, 50, app.ribbon.height - 10)

	for i, label in shape_labels {
		mut sbtn := ui.Button.new(
			text: shape_uicons[i]
		)
		sbtn.extra = label
		sbtn.subscribe_event('mouse_up', app.shape_btn_click)
		sbtn.set_bounds(0, 0, 23, 20)
		sbtn.font_size = 12
		sbtn.font = 1
		sbtn.border_radius = -1
		sbtn.set_area_filled_state(false, .normal)
		sp.add_child(sbtn)
	}

	app.ribbon.add_child(sp)
}

fn (mut app App) shape_btn_click(e &ui.MouseEvent) {
	mut tar := e.target
	if mut tar is ui.Button {
		app.set_tool_by_name(tar.extra)
	}
}

fn draw_box_border(com &ui.Component, g &ui.GraphicsContext, mw int) {
	g.draw_rounded_rect(com.x, com.y, com.width - mw, com.height, 4, g.theme.button_border_normal,
		g.theme.textbox_background)
}

fn (mut app App) make_color_box() &ui.Panel {
	mut color_box := ui.Panel.new(
		layout: ui.GridLayout.new(rows: 2, vgap: 3, hgap: 3)
	)

	colors := [gx.rgb(0, 0, 0), gx.rgb(127, 127, 127), gx.rgb(136, 0, 21),
		gx.rgb(237, 28, 36), gx.rgb(255, 127, 39), gx.rgb(255, 242, 0),
		gx.rgb(34, 177, 76), gx.rgb(0, 162, 232), gx.rgb(63, 72, 204),
		gx.rgb(163, 73, 164), gx.rgb(255, 255, 255), gx.rgb(195, 195, 195),
		gx.rgb(185, 122, 87), gx.rgb(255, 174, 201), gx.rgb(255, 200, 15),
		gx.rgb(239, 228, 176), gx.rgb(180, 230, 30), gx.rgb(153, 217, 235),
		gx.rgb(112, 146, 190), gx.rgba(0, 0, 0, 0)]

	// gx.rgba(200, 190, 230, 0)

	size := 24

	for color in colors {
		mut btn := ui.Button.new(text: ' ')
		btn.set_background(color)
		btn.border_radius = 32
		btn.subscribe_event('mouse_up', fn [mut app, color] (mut e ui.MouseEvent) {
			mut btn := e.target
			if mut btn is ui.Button {
				btn_color := btn.override_bg_color
				if btn_color != color {
					// WASM does not support Closures
					// dump('Debug: Problem with Wasm closure')
					app.set_color(btn_color)
					return
				}
			}

			app.set_color(color)
		})
		color_box.add_child(btn)
	}

	color_box.subscribe_event('draw', fn [mut color_box] (mut e ui.DrawEvent) {
		w := e.target.parent.width
		if w < 385 {
			aa := w - 95
			color_box.width = aa
		} else if color_box.width < 300 {
			color_box.width = (24 + 6) * 10
		}

		draw_box_border(e.target, e.ctx, 6)
	})

	color_box.set_background(gx.rgba(0, 0, 0, 1))
	color_box.set_bounds(0, 0, (size + 6) * 10, 64)
	return color_box
}

fn make_c_btn(count int) &ui.Button {
	txt := if count == 0 { '' } else { ' ' }
	mut current_btn := ui.Button.new(text: txt)
	current_btn.set_bounds(0, 0, 26, 26)
	current_btn.border_radius = 16
	current_btn.subscribe_event('draw', current_color_btn_draw)
	return current_btn
}

fn (mut app App) ribbon_icon_btn(data []u8) &ui.Button {
	mut gg := app.win.gg
	gg_im := gg.create_image_from_byte_array(data) or { panic(err) }
	cim := gg.cache_image(gg_im)
	mut btn := ui.Button.new(icon: cim)
	btn.set_bounds(0, 14, 32, 36)
	btn.icon_width = 32
	btn.icon_height = 32

	btn.subscribe_event('mouse_up', fn [mut app] (mut e ui.MouseEvent) {
		mut win := e.ctx.win

		if isnil(app.cp) {
			app.cp = ColorPicker.new()

			app.cp.subscribe_event('color_picked', fn [mut app] (cp &ColorPicker) {
				app.set_color(cp.color)
			})
		}

		mut modal := app.cp.open_color_picker(app.get_color())
		win.add_child(modal)
	})
	return btn
}

fn current_color_btn_draw(mut e ui.DrawEvent) {
	mut com := e.target
	mut win := e.ctx.win
	if mut com is ui.Button {
		mut app := win.get[&App]('app')
		bg := if com.text == '' { app.color } else { app.color_2 }
		com.set_background(bg)
		sele := (com.text == ' ' && app.sele_color) || (com.text == '' && !app.sele_color)
		if sele {
			o := 3
			ry := com.ry
			width := com.width + (o * 2)
			heigh := com.height + (o * 2)
			e.ctx.gg.draw_rounded_rect_filled(com.rx - o, ry - o, width, heigh, 16, e.ctx.theme.button_bg_hover)
			e.ctx.gg.draw_rounded_rect_empty(com.rx - o, ry - o, width, heigh, 16, e.ctx.theme.accent_fill)
		} else if com.is_mouse_rele {
			app.sele_color = !app.sele_color
		}
	}
}

// fn ribbon_draw_fn(mut win ui.Window, mut com ui.Component) {
fn ribbon_draw_fn(mut e ui.DrawEvent) {
	color := e.ctx.theme.textbox_background
	e.ctx.gg.draw_rect_filled(e.target.x, e.target.y - 1, e.target.width, e.target.height + 1,
		color)

	hid := e.target.width < 400
	if e.target.children.len < 3 {
		return
	}
	mut child := e.target.children[3]
	if mut child is ui.Panel {
		child.hidden = hid
	}
}

fn (mut app App) shape_box_draw(mut e ui.DrawEvent) {
	draw_box_border(e.target, e.ctx, 0)
}
