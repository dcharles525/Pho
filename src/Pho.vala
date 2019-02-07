using Soup;
using Gtk;
using Json;
using WebKit;
using Gee;
using Gst;

//valac --pkg gtk+-3.0 --pkg libsoup-2.4 --pkg json-glib-1.0 --pkg webkit2gtk-4.0 --pkg gee-0.8 --pkg gstreamer-1.0 --pkg clutter-gst-3.0 --pkg clutter-gtk-1.0 --pkg granite Pho.vala Thread.vala Posts.vala Replies.vala VideoPlayer.vala

public class Pho : Gtk.Application{

  public ArrayList<Thread> threadList = new ArrayList<Thread>();
  public ArrayList<Posts> postList = new ArrayList<Posts>();
  public ArrayList<Replies> repliesList = new ArrayList<Replies>();
  public Gtk.Window window = new Gtk.Window();
  public Gtk.Notebook notebook = new Gtk.Notebook();
  public Gtk.Spinner spinner = new Gtk.Spinner();
  public Gtk.SearchEntry searchEntry = new Gtk.SearchEntry ();
  public Gtk.Revealer revealerGlobal = new Gtk.Revealer ();
  public signal void initSignal();
  public signal void getThreadsSignal();
  public string boardGlobal = "g";
  public Gtk.ComboBoxText comboBox = new Gtk.ComboBoxText ();
  public Gtk.CssProvider provider = new Gtk.CssProvider();
  public Gtk.Box threadBox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
  public bool refreshPostsGlobal = false;
  public Granite.Widgets.Toast toast = new Granite.Widgets.Toast ("");
  public string CODE_STYLE = """
    .green-text{
      color: #b5bd68;
    }

    .blue-text{
      color: #81a2be;
    }

    .white-text{
      color: #fff;
    }

    .padding{
      padding: 5px;
    }

    .button-color{
      background-image: linear-gradient( #1c9cc4, #1c8dc4);
    }
  """;

  public void getThreads(){

    this.threadList.clear ();

    for (int i = 1; i < 10; i++){

      MainLoop loop = new MainLoop ();

      var session = new Soup.Session ();
      var message = new Soup.Message ("GET", "https://a.4cdn.org/".concat(this.boardGlobal,"/",i.to_string(),".json"));

      session.queue_message (message, (sess, message) => {

        try {

          var parser = new Json.Parser ();
          parser.load_from_data((string) message.response_body.flatten().data, -1);
          var root_object = parser.get_root ().get_object ();
          var threads = root_object.get_array_member("threads");

          //::Loop through each board and get the elements.
          foreach (var thread in threads.get_elements()) {

            if (!thread.is_null()) {

              var posts = thread.get_object().get_array_member("posts");
              var post = posts.get_element(0);

              if (!post.is_null()) {

                var post_object = post.get_object();
                string sub = post_object.has_member("sub") ? post_object.get_string_member("sub") : "";
                string com = post_object.has_member("com") ? post_object.get_string_member("com") : "";
                int64 filename = post_object.has_member("tim") ? post_object.get_int_member("tim") : 0;
                string ext = post_object.has_member("ext") ? post_object.get_string_member("ext") : "";
                int64 threadno = post_object.has_member("no") ? post_object.get_int_member("no") : 0;
                string date = post_object.has_member("now") ? post_object.get_string_member("now") : "";
                int64 replies = post_object.has_member("replies") ? post_object.get_int_member("replies") : 0;
                int64 images = post_object.has_member("images") ? post_object.get_int_member("images") : 0;

                if (threadno.to_string() != "51971506"){

                  if (sub == "") {

                    sub = com;

                  }

                  Thread tempThread = new Thread();
                  tempThread.setSubject(sub);
                  tempThread.setComment(com);
                  tempThread.setFilename(filename);
                  tempThread.setExtension(ext);
                  tempThread.setThreadNumber(threadno);
                  tempThread.setDate(date);
                  tempThread.setReplies(replies);
                  tempThread.setImages(images);

                  this.threadList.add(tempThread);

                }

              }else{

                this.toast.title = _("Couldn't show a thread for some network reason...");
                this.toast.send_notification ();

              }

            }

          }

        }catch(Error e){

          stderr.printf (_("Something is wrong in getThreads"));

        }

        loop.quit();

      });

      loop.run();

    }

    this.getThreadsSignal();

  }

  public void displayThreads(){

    this.notebook.remove_page(0);
    var webview = new WebKit.WebView();
    this.toast = new Granite.Widgets.Toast ("");

    this.threadBox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
    threadBox.set_spacing(10);
    threadBox.get_style_context().add_class("padding");
    threadBox.pack_start(this.toast);

    this.searchEntry = new Gtk.SearchEntry ();
    this.searchEntry.set_placeholder_text(_("Enter search text..."));
    this.searchEntry.activate.connect (() => {

      this.search(this.searchEntry.get_text());

    });

    this.revealerGlobal.add(this.searchEntry);

    threadBox.pack_start(this.revealerGlobal,false, false, 0);
    Gtk.ScrolledWindow scrolled = new Gtk.ScrolledWindow (null, null);

    string[] filters = {""};
    bool fileExists = false;

    try{

      if (FileUtils.test ("filter.txt", FileTest.IS_REGULAR)){

        string read;
        FileUtils.get_contents ("filter.txt", out read);
        filters = read.split (",");
        fileExists = true;

      }

    }catch(Error e){

      stderr.printf (_("Something went wrong with the settings file"));

    }

    for (int i = 0; i < this.threadList.size; i++){

      var sub = this.threadList.get(i).getSubject();
      sub = sub.replace ("<br>", "\n");

      try {

        var allTags = new Regex("<(.|)*?>", RegexCompileFlags.CASELESS);
        sub = allTags.replace(sub, -1, 0, "");

      }catch(RegexError e){

        print (_("Error report this on github!: %s\n"), e.message);

      }

      bool filterBool = false;

      if (fileExists){

        foreach (unowned string str in filters) {

          if (sub.down().contains(str.down())){

            filterBool = true;

          }

        }

      }

      if (!filterBool){

        var threadRepliesImagesLabel = new Gtk.Label("R: ".concat(this.threadList.get(i).getReplies().to_string()," | I: ",this.threadList.get(i).getImages().to_string()));

        var threadSubjectLabel = new Gtk.Label(sub);
        threadSubjectLabel.set_selectable(true);
        threadSubjectLabel.set_use_markup(true);
        threadSubjectLabel.set_line_wrap(true);
        threadSubjectLabel.set_line_wrap_mode(Pango.WrapMode.WORD_CHAR);
        threadSubjectLabel.set_max_width_chars(75);
        threadSubjectLabel.xalign = 0;

        var threadDateLabel = new Gtk.Label(this.threadList.get(i).getDate()
        .concat(" - ",this.threadList.get(i).getThreadNumber().to_string()));
        threadDateLabel.set_use_markup(true);
        threadDateLabel.set_line_wrap(true);
        threadDateLabel.set_line_wrap_mode(Pango.WrapMode.WORD_CHAR);
        threadDateLabel.set_max_width_chars(75);
        threadDateLabel.xalign = 0;
        threadDateLabel.get_style_context().add_class("blue-text");

        var threadNumber = this.threadList.get(i).getThreadNumber();

        Gtk.Button openThreadButton = new Gtk.Button.with_label(_("Open Thread"));
        openThreadButton.clicked.connect (() => {
          this.spinner.active = true;
          this.getPosts(threadNumber);
        });
        openThreadButton.get_style_context().add_class("button-color");

        Gdk.RGBA rgba = Gdk.RGBA ();
	      rgba.parse ("#393f42");

        if (this.threadList.get(i).getFilename() != 0 &&
        this.threadList.get(i).getExtension().to_string() != ".webm"){

          webview.close();
          webview = new WebKit.WebView();
          var webviewSettings = new WebKit.Settings();
          webviewSettings.set_media_playback_requires_user_gesture(true);
          webview.set_settings(webviewSettings);
          webview.set_background_color(rgba);
          webview.load_uri("https://i.4cdn.org/".concat(this.boardGlobal,"/",this.threadList.get(i).getFilename().to_string(),
          this.threadList.get(i).getExtension().to_string()));

          Gtk.ScrolledWindow scrolledImage = new Gtk.ScrolledWindow(null, null);
          scrolledImage.set_min_content_height(200);
          scrolledImage.add(webview);
          threadBox.pack_start(scrolledImage, false, false, 0);

        }

        if (this.threadList.get(i).getExtension().to_string() == ".webm"){

          var player = new VideoPlayer();
          player.setUrl("https://i.4cdn.org/".concat(this.boardGlobal,"/",this.threadList.get(i).getFilename().to_string(),
          this.threadList.get(i).getExtension().to_string()));
          var clutterBox = player.buildPlayer();

          var playButton = new Button.from_icon_name ("media-playback-start", Gtk.IconSize.BUTTON);
          playButton.clicked.connect (() => {
            player.playFile();
          });

          var stopButton = new Button.from_icon_name ("media-playback-stop", Gtk.IconSize.BUTTON);
          stopButton.clicked.connect (() => {
            player.stopFile();
          });

          var bb = new ButtonBox (Orientation.HORIZONTAL);
          bb.add (playButton);
          bb.add (stopButton);

          clutterBox.set_size_request(150,200);
          var vbox = new Box (Gtk.Orientation.VERTICAL, 0);
          vbox.pack_start (clutterBox);

          threadBox.pack_start (vbox, true, true, 0);
          threadBox.pack_start (bb,  false, false, 0);

        }

        threadBox.pack_start(threadDateLabel, false, false, 0);
        threadBox.pack_start(threadSubjectLabel, false, false, 0);
        threadBox.pack_start(threadRepliesImagesLabel, false, false, 0);
        threadBox.pack_start(openThreadButton, false, false, 0);
        threadBox.pack_start(new Gtk.Separator(Gtk.Orientation.HORIZONTAL), false, false, 0);

      }

    }

    scrolled.set_min_content_width(200);
    scrolled.set_min_content_height(400);
    scrolled.add(threadBox);

    Gtk.Label title = new Gtk.Label ("Board");
    this.notebook.get_style_context().add_class("padding");
    this.notebook.insert_page (scrolled, title,0);
    this.spinner.active = false;
    this.notebook.set_current_page(0);

  }

  public void getPosts(int64 threadNumber){

    if (checkThread(threadNumber)){

      this.spinner.active = true;
      this.postList.clear ();
      this.repliesList.clear ();

      MainLoop loop = new MainLoop ();
      var session = new Soup.Session ();
      var message = new Soup.Message ("GET", "https://a.4cdn.org/".concat(this.boardGlobal,"/thread/",threadNumber.to_string(),".json"));

      session.queue_message (message, (sess, message) => {

        try {

          var parser = new Json.Parser ();
          parser.load_from_data((string) message.response_body.flatten().data, -1);
          var root_object = parser.get_root().get_object ();
          var posts = root_object.get_array_member("posts");

          foreach (var post in posts.get_elements()) {

            var post_object = post.get_object();
            string com = post_object.has_member("com") ? post_object.get_string_member("com") : "";
            int64 filename = post_object.has_member("tim") ? post_object.get_int_member("tim") : 0;
            int64 postNumber = post_object.has_member("no") ? post_object.get_int_member("no") : 0;
            string ext = post_object.has_member("ext") ? post_object.get_string_member("ext") : "";
            string date = post_object.has_member("now") ? post_object.get_string_member("now") : "";

            Posts tempPost = new Posts();
            tempPost.setComment(com);
            tempPost.setFilename(filename);
            tempPost.setExtension(ext);
            tempPost.setPostNumber(postNumber);
            tempPost.setDate(date);

            com = com.replace ("<br>", "\n");
            var allTags = new Regex("<[^>]*>", RegexCompileFlags.CASELESS);
            com = allTags.replace(com, -1, 0, "");
            var commentArray = com.split("\n");

            if (commentArray[0] != null){

              Regex regexImpliesDouble = new Regex ("&gt;&gt;");

              if (regexImpliesDouble.match (commentArray[0])){

                string threadNumberTemp = commentArray[0].substring (8, commentArray[0].length - 8);

                Replies tempReply = new Replies();
                tempReply.setOriginalPostNumber(int64.parse(threadNumberTemp));
                tempReply.setComment(com);

                this.repliesList.add(tempReply);

              }

            }



            this.postList.add(tempPost);

          }

        }catch(Error e){

          stderr.printf (_("Something is wrong in getPosts"));

        }

        loop.quit();

      });

      loop.run();
      this.dispayPosts(threadNumber);

    }

  }

  public void dispayPosts(int64 threadNumber){

    Gtk.Box box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
    box.set_spacing(10);
    bool isReplies = false;

    for (int i = 0; i < this.postList.size; i++){

      var com = this.postList.get(i).getComment();
      var commentBox = new Box (Gtk.Orientation.VERTICAL, 0);

      if (com != null){

        com = com.replace ("<br>", "\n");

        try {

          var allTags = new Regex("<[^>]*>", RegexCompileFlags.CASELESS);
          com = allTags.replace(com, -1, 0, "");

        }catch(RegexError e){

          print (_("Error report this on github!: %s\n"), e.message);

        }

        var commentArray = com.split("\n");

        for (int f = 0; f < commentArray.length; f++){

          var commentLabel = new Gtk.Label(commentArray[f]);
          commentLabel.set_selectable(true);
          commentLabel.set_max_width_chars(80);
          commentLabel.set_use_markup (true);
          commentLabel.set_line_wrap (true);
          commentLabel.set_line_wrap_mode(Pango.WrapMode.WORD_CHAR);
          commentLabel.set_justify(Gtk.Justification.LEFT);
          commentLabel.xalign = 0;

          try {

            Regex regexImpliesDouble = new Regex ("&gt;&gt;");

            if (regexImpliesDouble.match (commentArray[f])){

              commentLabel.get_style_context().add_class("green-text");

            }

            Regex regexImpliesSingle = new Regex ("&gt;");

            if (regexImpliesSingle.match (commentArray[f])){

              commentLabel.get_style_context().add_class("green-text");

            }

          }catch(RegexError e){

            print (_("Error report this on github!: %s\n"), e.message);

          }

          commentBox.pack_start (commentLabel, false, false, 0);

        }

      }

      var threadDateLabel = new Gtk.Label(this.postList.get(i).getDate()
      .concat(" - ",this.postList.get(i).getPostNumber().to_string()));
      threadDateLabel.set_use_markup (true);
      threadDateLabel.set_line_wrap (true);
      threadDateLabel.set_line_wrap_mode(Pango.WrapMode.WORD_CHAR);
      threadDateLabel.set_max_width_chars(75);
      threadDateLabel.xalign = 0;
      threadDateLabel.get_style_context().add_class("blue-text");

      if (this.postList.get(i).getFilename() != 0 &&
      this.postList.get(i).getExtension() != ".webm"){

        var webview = new WebKit.WebView();
        var webviewSettings = new WebKit.Settings();
        webviewSettings.set_media_playback_requires_user_gesture(true);
        webview.set_settings(webviewSettings);
        Gdk.RGBA rgba = Gdk.RGBA ();
  		  rgba.parse ("#393f42");
        webview.set_background_color(rgba);
        webview.load_uri("https://i.4cdn.org/".concat(this.boardGlobal,"/",this.postList.get(i).getFilename().to_string(),this.postList.get(i).getExtension()));

        Gtk.ScrolledWindow scrolledImage = new Gtk.ScrolledWindow (null, null);
        scrolledImage.set_min_content_height(200);
        scrolledImage.add(webview);

        box.pack_start(scrolledImage, false, false, 0);

      }

      if (this.postList.get(i).getExtension() == ".webm" ){

        var player = new VideoPlayer();
        player.setUrl("https://i.4cdn.org/".concat(this.boardGlobal,"/",this.postList.get(i).getFilename().to_string(),
        this.postList.get(i).getExtension()));
        var clutterBox = player.buildPlayer();

        var playButton = new Button.from_icon_name ("media-playback-start", Gtk.IconSize.BUTTON);
        playButton.clicked.connect (() => {
          player.playFile();
        });

        var stopButton = new Button.from_icon_name ("media-playback-stop", Gtk.IconSize.BUTTON);
        stopButton.clicked.connect (() => {
          player.stopFile();
        });

        var bb = new ButtonBox (Orientation.HORIZONTAL);
        bb.add (playButton);
        bb.add (stopButton);

        clutterBox.set_size_request(150,200);
        var vbox = new Box (Gtk.Orientation.VERTICAL, 0);
        vbox.pack_start (clutterBox);

        box.pack_start (vbox, true, true, 0);
        box.pack_start (bb,  false, false, 0);

      }

      box.pack_start (threadDateLabel, false, false, 0);
      box.pack_start (commentBox, false, false, 0);

      var revealer = new Gtk.Revealer();
      Gtk.Box tempBox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
      tempBox.set_spacing(10);

      for (int g = 0; g < this.repliesList.size; g++){

        if (this.repliesList.get(g).getOriginalPostNumber() == this.postList.get(i).getPostNumber()){

          var replyLabel = new Gtk.Label(this.repliesList.get(g).getComment());
          replyLabel.set_use_markup (true);
          replyLabel.set_line_wrap (true);
          replyLabel.set_line_wrap_mode(Pango.WrapMode.WORD_CHAR);
          replyLabel.set_max_width_chars(75);
          replyLabel.xalign = 0;

          var hseparator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

          tempBox.pack_start(hseparator);
          tempBox.pack_start(replyLabel);

          isReplies = true;

        }

      }

      if (isReplies){

        revealer.add(tempBox);
        box.pack_start(revealer);

        var getCommentsButton = new Gtk.Button.with_label ("Show/Hide Replies");
        getCommentsButton.get_style_context().add_class("button-color");
        box.pack_start (getCommentsButton);

        getCommentsButton.clicked.connect (() => {

          if (revealer.get_reveal_child()){

            revealer.set_reveal_child(false);

          }else{

            revealer.set_reveal_child(true);

          }

        });

      }

      isReplies = false;

      //box.pack_start(revealer, false, false, 0);
      var hseparator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
      box.pack_start(hseparator, false, false, 0);

    }

    Gtk.ScrolledWindow scrolled = new Gtk.ScrolledWindow (null, null);
    scrolled.set_min_content_width(300);
    scrolled.set_min_content_height(500);
    scrolled.add(box);

    Gtk.Label title = new Gtk.Label (threadNumber.to_string());

    if (this.refreshPostsGlobal){

      int tempPage = this.notebook.get_current_page();
      this.notebook.insert_page (scrolled, title, this.notebook.get_current_page());
      this.notebook.remove_page(this.notebook.get_current_page());
      this.notebook.show_all();
      this.notebook.set_current_page(tempPage);
      this.refreshPostsGlobal = false;

    }else{

      this.notebook.append_page (scrolled, title);

    }


    this.notebook.show_all();
    this.spinner.active = false;

  }

  public void getBoards(){

    this.comboBox = new Gtk.ComboBoxText ();

    Soup.Session session = new Soup.Session();
		Soup.Message message = new Soup.Message("GET", "https://a.4cdn.org/boards.json");
		session.send_message (message);

		try {

			var parser = new Json.Parser();
			parser.load_from_data((string) message.response_body.flatten().data, -1);
			var root_object = parser.get_root ().get_object ();
			var boards = root_object.get_array_member("boards");
      int counter = 0;

			foreach (var board in boards.get_elements()) {

				if (!board.is_null()) {

					var board_node = board.get_object();
					string boardLetter= board_node.has_member("board") ? board_node.get_string_member("board") : "";

			    this.comboBox.append(counter.to_string(),boardLetter);

          counter++;

				}

			}

      comboBox.active = 20;

      this.comboBox.changed.connect (() => {
        this.spinner.active = true;
  			string title = this.comboBox.get_active_text ();
        this.boardGlobal = title;
        this.getThreads();
  		});

      Gtk.Button closeThreadButton = new Gtk.Button.from_icon_name ("edit-clear-all-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
      closeThreadButton.clicked.connect (() => {

        int currentPage = notebook.get_current_page();

        if (currentPage != 0){

          notebook.remove_page(currentPage);

        }else{

          currentPage++;
          notebook.remove_page(currentPage);

        }

      });

      Gtk.Image refreshImage = new Gtk.Image.from_icon_name ("view-refresh-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
      Gtk.ToolButton refreshButton = new Gtk.ToolButton (refreshImage, null);
      refreshButton.clicked.connect (() => {

        int currentPage = this.notebook.get_current_page();
        this.spinner.active = true;

        if (currentPage == 0){

          this.getThreads();

        }else{

          var childPage = this.notebook.get_nth_page(currentPage);
          this.refreshPostsGlobal = true;
          this.getPosts(int64.parse(this.notebook.get_tab_label_text(childPage)));

        }

      });

      Gtk.Image settingsImage = new Gtk.Image.from_icon_name ("preferences-system-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
      settingsImage.pixel_size = 16;
      Gtk.ToolButton settingsButton = new Gtk.ToolButton (settingsImage, null);
      settingsButton.clicked.connect (() => {

        Gtk.Label shortCutsLabel = new Gtk.Label (_("Short Cuts: "));
        shortCutsLabel.xalign = 0;

        Gtk.Label ctrlWLabel = new Gtk.Label (_("- CTRL W | Close tab"));
        ctrlWLabel.xalign = 0;

        Gtk.Label ctrlFLabel = new Gtk.Label (_("- CTRL F | Reveal Search"));
        ctrlFLabel.xalign = 0;

        Gtk.Label ctrlQLabel = new Gtk.Label (_("- CTRL Q | Quit App"));
        ctrlQLabel.xalign = 0;

        Gtk.Label filterLabel = new Gtk.Label (_("Filter (comma seperated): "));
        filterLabel.xalign = 0;

        Gtk.Dialog dialog = new Gtk.Dialog ();

        var filterBox = new Gtk.Entry ();
        string filename = "filter.txt";
        string read;

        try {

          if (FileUtils.test (filename, FileTest.IS_REGULAR)){

            FileUtils.get_contents (filename, out read);
            filterBox.set_text(read);

          }else{

            filterBox.set_text("");

          }

        }catch(Error e){

          stderr.printf (_("Something went wrong with the settings file"));

        }

        var saveButton = new Gtk.Button.with_label ("Apply Filter");
        saveButton.get_style_context().add_class("button-color");

        saveButton.clicked.connect (() => {
          try {

            FileUtils.set_contents (filename, filterBox.get_text());

          }catch(Error e){

            stderr.printf (_("Something went wrong writing the settings file"));

          }
          this.toast.title = "Filter was saved";
          this.toast.send_notification ();
          this.spinner.active = true;
          this.getThreads();
        });

        dialog.width_request = 500;
        dialog.get_content_area ().spacing = 7;
        dialog.get_content_area ().border_width = 10;
        dialog.get_content_area ().pack_start (shortCutsLabel);
        dialog.get_content_area ().pack_start (ctrlWLabel);
        dialog.get_content_area ().pack_start (ctrlFLabel);
        dialog.get_content_area ().pack_start (ctrlQLabel);
        dialog.get_content_area ().pack_start (new Gtk.Label (""));
        dialog.get_content_area ().pack_start (filterLabel);
        dialog.get_content_area ().pack_start (filterBox);
        dialog.get_content_area ().pack_start (saveButton);
        dialog.get_widget_for_response (Gtk.ResponseType.OK).can_default = true;
        dialog.set_default_response (Gtk.ResponseType.OK);
        dialog.show_all ();

      });

      if (this.notebook.get_n_pages() == 1){

        this.spinner = new Gtk.Spinner();

        var header = new Gtk.HeaderBar ();
        header.show_close_button = true;
        header.pack_start (refreshButton);
        header.pack_start (closeThreadButton);
        header.pack_end(settingsButton);
        header.pack_end (this.comboBox);
        header.pack_end(this.spinner);
        header.show_all ();

        this.window.set_titlebar(header);

      }

		}catch(Error e) {

      stderr.printf (_("Something is wrong in getBoards"));

    }

  }

  public void search(string search){

    this.spinner.active = true;

    ArrayList<Thread> searchList = new ArrayList<Thread>();

    for (int i = 0; i < this.threadList.size; i++){

      if (this.threadList.get(i).getSubject().down().contains(search.down())){

        searchList.add(this.threadList.get(i));

      }

    }

    this.threadList.clear ();
    this.threadList = searchList;
    this.getThreadsSignal();

  }

  public bool checkThread(int64 threadNumber){

    var pages = this.notebook.get_n_pages();

    for (int i = 0; pages > i; i++){

      var childPage = this.notebook.get_nth_page(i);

      if (threadNumber == int64.parse(this.notebook.get_tab_label_text(childPage))){

        this.spinner.active = false;
        return false;

      }

    }

    return true;

  }

}

int main (string[] args){
  Gtk.init (ref args);
  Gst.init (ref args);
  GtkClutter.init (ref args);
  var err = GtkClutter.init (ref args);
  if (err != Clutter.InitError.SUCCESS) {
      error (_("Could not initalize clutter! ")+err.to_string ());
  }

  Pho pho = new Pho();
  Gtk.Settings.get_default().set("gtk-application-prefer-dark-theme", true);

  try {

    pho.provider.load_from_data (pho.CODE_STYLE, pho.CODE_STYLE.length);
    Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), pho.provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

  } catch (Error e) {

    warning(_("css didn't load %s"),e.message);

  }

  var windowTitle = "Pho";
  pho.window.title = windowTitle;
  pho.window.set_position (Gtk.WindowPosition.CENTER);
  pho.window.destroy.connect (Gtk.main_quit);
  pho.window.set_default_size (375,625);

  bool ctrBool = false;
  bool qBool = false;
  bool wBool = false;
  bool fBool = false;
  bool escBool = false;

  pho.window.key_press_event.connect ((event) => {

    if (event.keyval == Gdk.Key.Control_L){

      ctrBool = true;

    }

    if (event.keyval == Gdk.Key.q){

      qBool = true;

    }

    if (event.keyval == Gdk.Key.w){

      wBool = true;

    }

    if (event.keyval == Gdk.Key.f){

      fBool = true;

    }

    if (event.keyval == Gdk.Key.Escape){

      escBool = true;

    }

    if (ctrBool && qBool){

      Gtk.main_quit();
      ctrBool = false;
      qBool = false;

    }

    if (ctrBool && wBool){

      int currentPage = pho.notebook.get_current_page();

      if (currentPage != 0){

        pho.notebook.remove_page(currentPage);

      }

      ctrBool = false;
      wBool = false;

    }

    if (ctrBool && fBool){

      pho.revealerGlobal.set_reveal_child(true);
      pho.searchEntry.grab_focus();
      ctrBool = false;
      fBool = false;
      pho.spinner.active = false;

    }

    if (escBool){

      pho.revealerGlobal.set_reveal_child(false);
      pho.spinner.active = true;
      escBool = false;
      pho.getThreads();

    }

    return false;

  });

  pho.spinner.active = true;

  Gtk.Image img = new Gtk.Image.from_icon_name ("view-refresh-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
  Gtk.ToolButton refreshButton = new Gtk.ToolButton (img, null);
  refreshButton.clicked.connect (() => {

    int currentPage = pho.notebook.get_current_page();
    pho.spinner.active = true;

    if (currentPage == 0){

      pho.getThreads();

    }else{

      var childPage = pho.notebook.get_nth_page(currentPage);
      pho.refreshPostsGlobal = true;
      pho.getPosts(int64.parse(pho.notebook.get_tab_label_text(childPage)));

    }

  });

  Gtk.Button closeThreadButton = new Gtk.Button.from_icon_name ("edit-clear-all-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
  closeThreadButton.clicked.connect (() => {

    int currentPage = pho.notebook.get_current_page();

    if (currentPage != 0){

      pho.notebook.remove_page(currentPage);

    }else{

      currentPage++;
      pho.notebook.remove_page(currentPage);

    }

  });

  pho.toast = new Granite.Widgets.Toast ("");

  var header = new Gtk.HeaderBar ();
  header.show_close_button = true;
  header.title = windowTitle;
  header.pack_start (refreshButton);
  header.pack_start (closeThreadButton);
  header.pack_end(pho.spinner);
  header.show_all();
  pho.window.set_titlebar(header);
  pho.window.add(pho.notebook);
  pho.window.show_all();

  pho.getThreadsSignal.connect(() => {

    pho.displayThreads();
    pho.notebook.show_all();

  });

  pho.getThreads();
  pho.getBoards();

  Gtk.main();
  return 0;

}
