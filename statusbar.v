module main

import gg
import iui as ui
import gx

fn make_status_bar(mut win ui.Window) {
	mut status_bar := ui.menubar(win, win.theme)
	status_bar.z_index = 10
	status_bar.set_id(mut win, 'status_bar')
	status_bar.draw_event_fn = fn (mut win ui.Window, com &ui.Component) {
		size := gg.window_size()
		mut this := *com
		this.y = size.height - 25
		win.gg.draw_line(this.x, this.y - 1, size.width, this.y, gx.rgb(200, 200, 200))
	}
	win.add_child(status_bar)

	mut zoom_status := ui.menuitem('Zoom: 1')
	zoom_status.draw_event_fn = fn (mut win ui.Window, com &ui.Component) {
		mut this := *com

		if mut this is ui.MenuItem {
			if this.show_items {
				win.extra_map['zoom'] = '1'
			}
			zoom := win.extra_map['zoom'].f32()
			if zoom > 20 {
				win.extra_map['zoom'] = '10'
			}
			this.text = (zoom * 100).str() + '%'
		}
	}

	mut zoom_plus := ui.menuitem('+')
	zoom_plus.draw_event_fn = fn (mut win ui.Window, com &ui.Component) {
		mut this := *com
		if mut this is ui.MenuItem {
			if this.is_mouse_rele {
				win.extra_map['zoom'] = (win.extra_map['zoom'].f32() + .25).str()
				this.is_mouse_rele = false
			}
			this.width = ui.text_width(win, ' ++ ')
		}
	}

	mut zoom_min := ui.menuitem('-')
	zoom_min.draw_event_fn = fn (mut win ui.Window, com &ui.Component) {
		mut this := *com
		if mut this is ui.MenuItem {
			if this.is_mouse_rele {
				win.extra_map['zoom'] = (win.extra_map['zoom'].f32() - .25).str()
				this.is_mouse_rele = false
			}
			this.width = ui.text_width(win, ' -- ')
		}
	}

	status_bar.add_child(zoom_min)
	status_bar.add_child(zoom_status)
	status_bar.add_child(zoom_plus)
}