import loadWASM from "./app.js";

// iterate localStorage
function doo_load_files() {
	for (var i = 0; i < localStorage.length; i++) {

	  // set iteration key name
	  var key = localStorage.key(i);

	  // use key name to retrieve the corresponding value
	  var value = localStorage.getItem(key);

	  // console.log the iteration key and value
	  console.log('Key: ' + key + ', Value: ' + value);  
	  
	  //write_file('home/web_user/meee/foldd/test.v', value)
	  if (key.endsWith('.ttf')) {
		continue;
	  }
	  
	  var kkey = key.replace('//', '/');
	 var is_file = mui.module.FS.analyzePath(kkey).exists
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
    	mui.module.FS.mkdir(dd)
    } catch (exx) {}
  }
 
  try {
   mui.module.FS.mkdir(dirr)
   } catch (exx) {}
   mui.module.FS.writeFile(a, b)
  
}

function save_folder(pa) {
  var is_file = mui.module.FS.isFile(mui.module.FS.stat(pa).mode)
  console.log('saving: ' + pa + ' (' + is_file + ')')
 	if (!is_file) {
    var last = pa.substring(pa.lastIndexOf("/") + 1, pa.length);
    if (last.length <= 2 && last.includes('.')) {
      return;
    }
    var lss = mui.module.FS.readdir(pa)
    for (var i = 0; i < lss.length; i++) {
     save_folder(pa + '/' + lss[i]) 
    }
  } else {
    var con =  mui.module.FS.readFile(pa,  { encoding: 'utf8' });
    console.log(con)
    localStorage.setItem(pa, con);
  }
}

window.mui = {
    module: null,
    latest_file: null,
    task_result: "0",
    open_file_dialog: async () => {
        let input = document.createElement("input");
        input.type = "file";
        await new Promise((promise_resolve, promise_reject) => {
            input.addEventListener("change", async e => {
                mui.latest_file = e.target.files[0];
                let array_buffer = await mui.latest_file.arrayBuffer();
                mui.module.FS.writeFile(mui.latest_file.name, new Uint8Array(array_buffer));
                promise_resolve();
            });
            input.click();
        });
        mui.task_result = "1";
        return mui.latest_file.name;
    },
    save_file_dialog: async () => {
        mui.latest_file = {name: prompt("File Name of that will be saved")};
        try {
            mui.module.FS.unlink(mui.latest_file.name);
        } catch (error) {}
        mui.task_result = "1";
        mui.watch_file_until_action();
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
        let the_file_name = mui.latest_file.name;
        let watcher = setInterval(() => {
            if(mui.module.FS.analyzePath(the_file_name).exists){
                clearInterval(watcher);
                mui.download_file(the_file_name, mui.module.FS.readFile(the_file_name));
                mui.module.FS.unlink(the_file_name);
            }
        }, 500);
    },
    set trigger(val){
        if (val == "openfiledialog"){
            mui.open_file_dialog();
        } else if (val == "savefiledialog"){
            mui.save_file_dialog();
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
		}
    }
};

(async () => {
    mui.module = await loadWASM();
})();