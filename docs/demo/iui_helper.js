// (c) 2024 Isaiah.
import loadWASM from "./app.js";

function doo_load_files() {
	setTimeout(function() { 
		for (var i = 0; i < localStorage.length; i++) { var key = localStorage.key(i);
			if (key.endsWith(".ttf")) { continue; }
			write_file(key.replace("//", "/"), localStorage.getItem(key));
		}
	}, 1);
}

function write_file(a, b) {
	setTimeout(function() { 
		var dirr = a.substring(0, a.lastIndexOf("/")); var dd = "";
		var spl = dirr.split("/");
		for (var i = 0; i < spl.length; i++) { var da = spl[i]; dd += da + "/"; try { iui.module.FS.mkdir(dd) } catch (exx) {} }
		try { iui.module.FS.mkdir(dirr) } catch (exx) {}
		iui.module.FS.writeFile(a, b);
	}, 1);
}

function save_folder(pa) {
	setTimeout(function() { save_folder_2(pa); }, 1); // wasm crashes if we load FS too early
}

function save_folder_2(pa) {
	var is_file = iui.module.FS.isFile(iui.module.FS.stat(pa).mode)
	if (!is_file) {
		var last = pa.substring(pa.lastIndexOf("/") + 1, pa.length);
		if (last.length <= 2 && last.includes(".")) { return; }
		var lss = iui.module.FS.readdir(pa); for (var i = 0; i < lss.length; i++) { save_folder_2(pa + "/" + lss[i]); }
	} else { var con = iui.module.FS.readFile(pa, { encoding: "utf8" }); localStorage.setItem(pa, con); }
}

window.iui = {
	module: null,
	latest_file: null,
	task_result: "0",
	open_file_dialog: async () => {
		let input = document.createElement("input");
		input.type = "file";
		await new Promise((promise_resolve, promise_reject) => {
			input.addEventListener("change", async e => {
				iui.latest_file = e.target.files[0];
				let arr_buf = await iui.latest_file.arrayBuffer();
				iui.module.FS.writeFile(iui.latest_file.name, new Uint8Array(arr_buf));
				promise_resolve();
			});
			input.click();
		});
		iui.task_result = "1";
		return iui.latest_file.name;
	},
	save_file_dialog: async () => {
		iui.latest_file = {name: prompt("File Name to save to")};
		try { iui.module.FS.unlink(iui.latest_file.name); } catch (error) {}
		iui.task_result = "1"; iui.watch_file_until_action();
	},
	download_file: (filename, uia) => {
		let blob = new Blob([uia], { type: "application/octet-stream" });
		let url = window.URL.createObjectURL(blob);
		let downloader = document.createElement("a");
		downloader.href = url; downloader.download = filename; downloader.click(); downloader.remove();
		setTimeout(() => { window.URL.revokeObjectURL(url); }, 1000);
	},
	watch_file_until_action: async () => {
		let fi_nam = iui.latest_file.name;
		let watcher = setInterval(() => {
			if(iui.module.FS.analyzePath(fi_nam).exists){ clearInterval(watcher); iui.download_file(fi_nam, iui.module.FS.readFile(fi_nam)); iui.module.FS.unlink(fi_nam); }
		}, 500);
	},
	set trigger(val){
		if (val == "openfiledialog"){ return iui.open_file_dialog(); } else if (val == "savefiledialog"){ iui.save_file_dialog(); }
		else if (val == "keyboard-hide"){ document.getElementById("canvas").focus(); navigator.virtualKeyboard.hide(); }
		else if (val == "keyboard-show"){ document.getElementById("canvas").focus(); navigator.virtualKeyboard.show(); }
		else if (val == "lloadfiles") { doo_load_files(); } else if (val == "savefiles") { save_folder("/home") }
		else if (val.indexOf("savefile=") != -1) { var fi_nam = val.split("savefile=")[1]; iui.download_file(fi_nam, iui.module.FS.readFile(fi_nam)); }
	}
};

(async () => {
	iui.module = await loadWASM();
})();
	