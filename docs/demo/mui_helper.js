import loadWASM from "./app.js";

// iterate localStorage
function doo_load_files() {
	for (var i = 0; i < localStorage.length; i++) {

	  // set iteration key name
	  var key = localStorage.key(i);

	  // use key name to retrieve the corresponding value
	  var value = localStorage.getItem(key);

	  //write_file('home/web_user/meee/foldd/test.v', value)
	  if (key.endsWith('.ttf')) {
		continue;
	  }
	  
	  var kkey = key.replace('//', '/');
	 var is_file = iui.module.FS.analyzePath(kkey).exists
	 console.log(kkey + ': exists? ' + is_file)
	  
	  write_file(kkey, value);

	}
}

function write_file(a, b) {
  	console.log(a)
  var dirr = a.substring(0, a.lastIndexOf('/'));
  
  var dd = "";
  var spl = dirr.split('/');
  for (var i = 0; i < spl.length; i++) {
    var da = spl[i];
    dd += da + '/';
    try {
    	iui.module.FS.mkdir(dd)
    } catch (exx) {}
  }
 
  try {
   iui.module.FS.mkdir(dirr)
   } catch (exx) {}
   iui.module.FS.writeFile(a, b)
  
}

function save_folder(pa) {
  var is_file = iui.module.FS.isFile(iui.module.FS.stat(pa).mode)
  console.log('saving: ' + pa + ' (' + is_file + ')')
 	if (!is_file) {
    var last = pa.substring(pa.lastIndexOf("/") + 1, pa.length);
    if (last.length <= 2 && last.includes('.')) {
      return;
    }
    var lss = iui.module.FS.readdir(pa)
    for (var i = 0; i < lss.length; i++) {
     save_folder(pa + '/' + lss[i]) 
    }
  } else {
    var con =  iui.module.FS.readFile(pa,  { encoding: 'utf8' });
    console.log(con)
    localStorage.setItem(pa, con);
  }
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
                let array_buffer = await iui.latest_file.arrayBuffer();
                iui.module.FS.writeFile(iui.latest_file.name, new Uint8Array(array_buffer));
                promise_resolve();
            });
            input.click();
        });
        iui.task_result = "1";
        return iui.latest_file.name;
    },
    save_file_dialog: async () => {
        iui.latest_file = {name: prompt("File Name of that will be saved")};
        try {
            iui.module.FS.unlink(iui.latest_file.name);
        } catch (error) {}
        iui.task_result = "1";
        iui.watch_file_until_action();
    },
    download_file: (filename, uia) => {
        let blob = new Blob([uia], {
            type: "application/octet-stream"
        });
        let url = window.URL.createObjectURL(blob);
        let downloader = document.createElement("a");
        //document.body.append(downloader);
        downloader.href = url;
        downloader.download = filename;
        downloader.click();
        downloader.remove();
        setTimeout(() => {
            window.URL.revokeObjectURL(url);
        }, 1000);
    },
    watch_file_until_action: async () => {
        let the_file_name = iui.latest_file.name;
        let watcher = setInterval(() => {
            if(iui.module.FS.analyzePath(the_file_name).exists){
                clearInterval(watcher);
                iui.download_file(the_file_name, iui.module.FS.readFile(the_file_name));
                iui.module.FS.unlink(the_file_name);
            }
        }, 500);
    },
    set trigger(val){
        if (val == "openfiledialog"){
            return iui.open_file_dialog();
        } else if (val == "savefiledialog"){
            iui.save_file_dialog();
        } else if (val == "keyboard-hide"){
            document.getElementById("canvas").focus();
            navigator.virtualKeyboard.hide();
        } else if (val == "keyboard-show"){
            document.getElementById("canvas").focus();
            navigator.virtualKeyboard.show();
        } else if (val == "lloadfiles") {
            doo_load_files();
        } else if (val == "savefiles") {
			save_folder('/home/')
		} else if (val.indexOf("savefile=") != -1) {
			var the_file_name = val.split("savefile=")[1];
			iui.download_file(the_file_name, iui.module.FS.readFile(the_file_name));
		}
    }
};

(async () => {
    iui.module = await loadWASM();
})();