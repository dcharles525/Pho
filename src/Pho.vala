using Soup;
using Gtk;
using Json;
using WebKit;
using Gee;

//valac --pkg gtk+-3.0 --pkg libsoup-2.4 --pkg json-glib-1.0 --pkg webkit2gtk-4.0 --pkg glib-2.0 Pho.vala Thread.vala

public class Pho{

  public ArrayList<Thread> threadList = new ArrayList<Thread>();
  public ArrayList<Posts> postList = new ArrayList<Posts>();
  public Gtk.Window window = new Gtk.Window();
  public Gtk.Notebook notebook = new Gtk.Notebook();
  public Gtk.Spinner spinner = new Gtk.Spinner();
  public signal void initSignal();
  public signal void getThreadsSignal();
  public string boardGlobal = "g";
  public Gtk.ComboBoxText comboBox = new Gtk.ComboBoxText ();

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
    Gtk.Box box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
    box.set_spacing(15);
    Gtk.ScrolledWindow scrolled = new Gtk.ScrolledWindow (null, null);

    for (int i = 0; i < this.threadList.size; i++){

      var allTags = new Regex("<(.|\n)*?>", RegexCompileFlags.CASELESS);
      var sub = allTags.replace(this.threadList.get(i).getSubject(), -1, 0, "");

      var threadSubjectLabel = new Gtk.Label(sub);
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

      var threadNumber = this.threadList.get(i).getThreadNumber();

      Gtk.Button openThreadButton = new Gtk.Button.with_label("Open Thread");
      openThreadButton.clicked.connect (() => {
        this.spinner.active = true;
        this.getPosts(threadNumber);
      });

      Gdk.RGBA rgba = Gdk.RGBA ();
		  rgba.parse ("#393f42");

      var webview = new WebKit.WebView();
      webview.set_background_color(rgba);
      webview.load_uri("https://i.4cdn.org/".concat(this.boardGlobal,"/",this.threadList.get(i).getFilename().to_string(),
      this.threadList.get(i).getExtension().to_string()));

      Gtk.ScrolledWindow scrolledImage = new Gtk.ScrolledWindow(null, null);
      scrolledImage.set_min_content_height(200);
      scrolledImage.add(webview);

      box.pack_start(scrolledImage, false, false, 0);
      box.pack_start(threadDateLabel, false, false, 0);
      box.pack_start(threadSubjectLabel, false, false, 0);
      box.pack_start(openThreadButton, false, false, 0);
      box.pack_start(new Gtk.Separator(Gtk.Orientation.HORIZONTAL), false, false, 0);

    }

    scrolled.set_min_content_width(350);
    scrolled.set_min_content_height(500);
    scrolled.add(box);
    Gtk.Label title = new Gtk.Label ("Board");
    this.notebook.append_page (scrolled, title);
    this.spinner.active = false;

  }

  public void getPosts(int64 threadNumber){

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

        loop.quit();



      }catch(Error e){

      }

    });

    loop.run();
    this.dispayPosts(threadNumber);

  }

  public void dispayPosts(int64 threadNumber){

    Gtk.Box box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
    box.set_spacing(10);

    for (int i = 0; i < this.postList.size; i++){

      var allTags = new Regex("<(.|\n)*?>", RegexCompileFlags.CASELESS);
      var com = allTags.replace(this.postList.get(i).getComment(), -1, 0, "");

      var label = new Gtk.Label(com);
      label.set_max_width_chars(80);
      label.set_use_markup (true);
      label.set_line_wrap (true);
      label.set_line_wrap_mode(Pango.WrapMode.WORD_CHAR);
      label.set_justify(Gtk.Justification.LEFT);
      label.set_alignment(0,0);

      var threadDateLabel = new Gtk.Label(this.postList.get(i).getDate()
      .concat(" - ",this.postList.get(i).getPostNumber().to_string()));
      threadDateLabel.set_use_markup (true);
      threadDateLabel.set_line_wrap (true);
      threadDateLabel.set_line_wrap_mode(Pango.WrapMode.WORD_CHAR);
      threadDateLabel.set_max_width_chars(75);
      threadDateLabel.set_alignment(0,0);

      if (this.postList.get(i).getFilename() != 0){

        var webview = new WebKit.WebView();
        Gdk.RGBA rgba = Gdk.RGBA ();
  		  rgba.parse ("#393f42");
        webview.set_background_color(rgba);
        webview.load_uri("https://i.4cdn.org/".concat(this.boardGlobal,"/",this.postList.get(i).getFilename().to_string(),this.postList.get(i).getExtension()));

        Gtk.ScrolledWindow scrolledImage = new Gtk.ScrolledWindow (null, null);
        scrolledImage.set_min_content_height(200);
        scrolledImage.add(webview);

        box.pack_start(scrolledImage, false, false, 0);

      }

      box.pack_start (threadDateLabel, false, false, 0);
      box.pack_start (label, false, false, 0);
      var hseparator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
      box.pack_start(hseparator, false, false, 0);

    }

    Gtk.ScrolledWindow scrolled = new Gtk.ScrolledWindow (null, null);
    scrolled.set_min_content_width(350);
    scrolled.set_min_content_height(500);
    scrolled.add(box);

    Gtk.Button closeThreadButton = new Gtk.Button.with_label ("Close");
    closeThreadButton.clicked.connect (() => {

      int currentPage = notebook.get_current_page();

      if (currentPage != 0){

        notebook.remove_page(currentPage);

      }else{

        currentPage++;
        notebook.remove_page(currentPage);

      }

      this.getBoards();

    });

    var header = new Gtk.HeaderBar ();
    var windowTitle = "Pho";
    header.title = windowTitle;
    header.show_close_button = true;
    header.pack_start(closeThreadButton);
    header.show_all ();
    this.window.set_titlebar(header);

    Gtk.Label title = new Gtk.Label (threadNumber.to_string().concat(" - ",this.boardGlobal));
    this.notebook.append_page (scrolled, title);
    this.notebook.show_all();
    this.spinner.active = false;

  }

  public void headerCheck(){

    if (notebook.get_n_pages() == 1){

      Gtk.Image refreshImage = new Gtk.Image.from_icon_name ("view-refresh", Gtk.IconSize.SMALL_TOOLBAR);
      Gtk.ToolButton refreshButton = new Gtk.ToolButton (refreshImage, null);
      refreshButton.clicked.connect (() => {
        this.spinner.active = true;
        this.getThreads();
      });

      var header = new Gtk.HeaderBar ();
      var windowTitle = "Pho";
      header.title = windowTitle;
      header.show_close_button = true;
      header.pack_start (refreshButton);
      header.pack_start (this.comboBox);
      header.show_all ();
      this.window.set_titlebar(header);

    }

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

      Gtk.Image refreshImage = new Gtk.Image.from_icon_name ("view-refresh", Gtk.IconSize.SMALL_TOOLBAR);
      Gtk.ToolButton refreshButton = new Gtk.ToolButton (refreshImage, null);
      refreshButton.clicked.connect (() => {
        this.spinner.active = true;
        this.getThreads();
      });

      var header = new Gtk.HeaderBar ();
      var windowTitle = "Pho";
      header.title = windowTitle;
      header.show_close_button = true;
      header.pack_start (refreshButton);
      header.pack_start (this.comboBox);
      header.show_all ();

      this.window.set_titlebar(header);

		}catch {


    }

  }

}

int main (string[] args){
  Gtk.init (ref args);

  Pho pho = new Pho();

  var windowTitle = "Pho";
  pho.window.title = windowTitle;
  pho.window.set_border_width (10);
  pho.window.set_position (Gtk.WindowPosition.CENTER);
  pho.window.destroy.connect (Gtk.main_quit);
  pho.window.set_default_size (550, 800);

  pho.spinner.active = true;

  Gtk.Image img = new Gtk.Image.from_icon_name ("view-refresh", Gtk.IconSize.SMALL_TOOLBAR);
  Gtk.ToolButton refreshButton = new Gtk.ToolButton (img, null);
  refreshButton.clicked.connect (() => {
    pho.spinner.active = true;
    pho.getThreads();
  });

  var header = new Gtk.HeaderBar ();
  header.show_close_button = true;
  header.title = windowTitle;
  header.pack_start (refreshButton);
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
