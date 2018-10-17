using Soup;
using Gtk;
using Json;
using WebKit;
using Gee;
using Gst;

//valac --pkg gtk+-3.0 --pkg libsoup-2.4 --pkg json-glib-1.0 --pkg webkit2gtk-4.0 --pkg gee-0.8 --pkg gstreamer-1.0 Pho.vala Thread.vala Posts.vala

public class Pho{

  public ArrayList<Thread> threadList = new ArrayList<Thread>();
  public ArrayList<Posts> postList = new ArrayList<Posts>();
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

                  this.threadList.add(tempThread);

                }

              }else{



              }

            }

          }

        }catch(Error e){

        }

        loop.quit();

      });

      loop.run();

    }

    this.getThreadsSignal();

  }

  public void displayThreads(){

    this.notebook.remove_page(0);
    this.threadBox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
    threadBox.set_spacing(10);
    threadBox.get_style_context().add_class("padding");

    this.searchEntry = new Gtk.SearchEntry ();
    this.searchEntry.set_placeholder_text("Enter search text...");
    this.searchEntry.activate.connect (() => {

      this.search(this.searchEntry.get_text());

    });

    this.revealerGlobal.add(this.searchEntry);

    threadBox.pack_start(this.revealerGlobal);
    Gtk.ScrolledWindow scrolled = new Gtk.ScrolledWindow (null, null);

    for (int i = 0; i < this.threadList.size; i++){

      var sub = this.threadList.get(i).getSubject();
      sub = sub.replace ("<br>", "\n");
      var allTags = new Regex("<(.|)*?>", RegexCompileFlags.CASELESS);
      sub = allTags.replace(sub, -1, 0, "");

      var threadSubjectLabel = new Gtk.Label(sub);
      threadSubjectLabel.set_selectable(true);
      threadSubjectLabel.set_use_markup(true);
      threadSubjectLabel.set_line_wrap(true);
      threadSubjectLabel.set_line_wrap_mode(Pango.WrapMode.WORD_CHAR);
      threadSubjectLabel.set_max_width_chars(75);
      threadSubjectLabel.set_alignment(0,0);

      var threadDateLabel = new Gtk.Label(this.threadList.get(i).getDate()
      .concat(" - ",this.threadList.get(i).getThreadNumber().to_string()));
      threadDateLabel.set_use_markup(true);
      threadDateLabel.set_line_wrap(true);
      threadDateLabel.set_line_wrap_mode(Pango.WrapMode.WORD_CHAR);
      threadDateLabel.set_max_width_chars(75);
      threadDateLabel.set_alignment(0,0);
      threadDateLabel.get_style_context().add_class("blue-text");

      var threadNumber = this.threadList.get(i).getThreadNumber();

      Gtk.Button openThreadButton = new Gtk.Button.with_label("Open Thread");
      openThreadButton.clicked.connect (() => {
        this.spinner.active = true;
        this.getPosts(threadNumber);
      });
      openThreadButton.get_style_context().add_class("button-color");

      Gdk.RGBA rgba = Gdk.RGBA ();
		  rgba.parse ("#393f42");

      if (this.threadList.get(i).getFilename() != 0 &&
      this.threadList.get(i).getExtension().to_string() != ".webm"){

        var webview = new WebKit.WebView();
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

        Widget videoArea;

        Element playBin = ElementFactory.make ("playbin", "bin");
        playBin["uri"] = "https://i.4cdn.org/".concat(this.boardGlobal,"/",this.threadList.get(i).getFilename().to_string(),
        this.threadList.get(i).getExtension().to_string());
        var gtkSink = ElementFactory.make ("gtksink", "sink");
        gtkSink.get ("widget", out videoArea);
        playBin["video-sink"] = gtkSink;

        var playButton = new Button.from_icon_name ("media-playback-start", Gtk.IconSize.BUTTON);
        playButton.clicked.connect (() => {
          playBin.set_state(Gst.State.PLAYING);
        });

        var stopButton = new Button.from_icon_name ("media-playback-stop", Gtk.IconSize.BUTTON);
        stopButton.clicked.connect (() => {
          playBin.set_state(Gst.State.READY);
        });

        var bb = new ButtonBox (Orientation.HORIZONTAL);
        bb.add (playButton);
        bb.add (stopButton);
        videoArea.set_size_request(300,200);
        var vbox = new Box (Gtk.Orientation.VERTICAL, 0);
        vbox.pack_start (videoArea);

        threadBox.pack_start(vbox);
        threadBox.pack_start (bb, false);

      }

      threadBox.pack_start(threadDateLabel, false, false, 0);
      threadBox.pack_start(threadSubjectLabel, false, false, 0);
      threadBox.pack_start(openThreadButton, false, false, 0);
      threadBox.pack_start(new Gtk.Separator(Gtk.Orientation.HORIZONTAL), false, false, 0);

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

            this.postList.add(tempPost);

          }



        }catch(Error e){

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

    for (int i = 0; i < this.postList.size; i++){

      var com = this.postList.get(i).getComment();
      com = com.replace ("<br>", "\n");
      var allTags = new Regex("<[^>]*>", RegexCompileFlags.CASELESS);
      com = allTags.replace(com, -1, 0, "");

      var commentArray = com.split("\n");
      var commentBox = new Box (Gtk.Orientation.VERTICAL, 0);

      for (int f = 0; f < commentArray.length; f++){

        var commentLabel = new Gtk.Label(commentArray[f]);
        commentLabel.set_selectable(true);
        commentLabel.set_max_width_chars(80);
        commentLabel.set_use_markup (true);
        commentLabel.set_line_wrap (true);
        commentLabel.set_line_wrap_mode(Pango.WrapMode.WORD_CHAR);
        commentLabel.set_justify(Gtk.Justification.LEFT);
        commentLabel.set_alignment(0,0);

        Regex regexImpliesDouble = new Regex ("&gt;&gt;");

        if (regexImpliesDouble.match (commentArray[f])){

          commentLabel.get_style_context().add_class("green-text");

        }

        Regex regexImpliesSingle = new Regex ("&gt;");

        if (regexImpliesSingle.match (commentArray[f])){

          commentLabel.get_style_context().add_class("green-text");

        }

        commentBox.pack_start (commentLabel, false, false, 0);

      }

      var threadDateLabel = new Gtk.Label(this.postList.get(i).getDate()
      .concat(" - ",this.postList.get(i).getPostNumber().to_string()));
      threadDateLabel.set_use_markup (true);
      threadDateLabel.set_line_wrap (true);
      threadDateLabel.set_line_wrap_mode(Pango.WrapMode.WORD_CHAR);
      threadDateLabel.set_max_width_chars(75);
      threadDateLabel.set_alignment(0,0);
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

      if (this.postList.get(i).getExtension().to_string() == ".webm"){

        Widget videoArea;

        Element playBin = ElementFactory.make ("playbin", "bin");
        playBin["uri"] = "https://i.4cdn.org/".concat(this.boardGlobal,"/",this.postList.get(i).getFilename().to_string(),this.postList.get(i).getExtension());
        var gtkSink = ElementFactory.make ("gtksink", "sink");
        gtkSink.get ("widget", out videoArea);
        playBin["video-sink"] = gtkSink;

        var playButton = new Button.from_icon_name ("media-playback-start", Gtk.IconSize.BUTTON);
        playButton.clicked.connect (() => {
          playBin.set_state(Gst.State.PLAYING);
        });

        var stopButton = new Button.from_icon_name ("media-playback-stop", Gtk.IconSize.BUTTON);
        stopButton.clicked.connect (() => {
          playBin.set_state(Gst.State.READY);
        });

        var bb = new ButtonBox (Orientation.HORIZONTAL);
        bb.add (playButton);
        bb.add (stopButton);
        videoArea.set_size_request(300,200);
        var vbox = new Box (Gtk.Orientation.VERTICAL, 0);
        vbox.pack_start (videoArea);

        box.pack_start(vbox);
        box.pack_start (bb, false);

      }

      box.pack_start (threadDateLabel, false, false, 0);
      box.pack_start (commentBox, false, false, 0);
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
          this.getPosts((int64)this.notebook.get_tab_label_text(childPage).to_int());

        }

      });

      if (this.notebook.get_n_pages() == 1){

        this.spinner = new Gtk.Spinner();;

        var header = new Gtk.HeaderBar ();
        header.show_close_button = true;
        header.pack_start (refreshButton);
        header.pack_start (closeThreadButton);
        header.pack_start(this.searchEntry);
        header.pack_end (this.comboBox);
        header.pack_end(this.spinner);
        header.show_all ();

        this.window.set_titlebar(header);

      }

		}catch {


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

      if (threadNumber == (int64)this.notebook.get_tab_label_text(childPage).to_int()){

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

  Pho pho = new Pho();

  Gtk.Settings.get_default().set("gtk-application-prefer-dark-theme", true);

  try {

    pho.provider.load_from_data (pho.CODE_STYLE, pho.CODE_STYLE.length);
    Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), pho.provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

  } catch (Error e) {

    warning("css didn't load %s",e.message);

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
      pho.getPosts((int64)pho.notebook.get_tab_label_text(childPage).to_int());

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

  var header = new Gtk.HeaderBar ();
  header.show_close_button = true;
  header.title = windowTitle;
  header.pack_start (refreshButton);
  header.pack_start (closeThreadButton);
  header.pack_end(pho.spinner);
  header.show_all();
  pho.window.set_titlebar(header);
  pho.window.show_all();

  pho.getThreadsSignal.connect(() => {

    pho.displayThreads();
    pho.window.add(pho.notebook);
    pho.window.show_all();

  });

  pho.getThreads();
  pho.getBoards();

  Gtk.main();
  return 0;

}
