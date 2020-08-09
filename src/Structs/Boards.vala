using Json;

public class Boards {

  public struct Board {
    public string board_abbrv;
    public string title;
    public bool ws_board; 
    public int per_page;
    public int pages;
    public int max_filesize;
    public int max_webm_filesize;
    public int max_comment_chars;
    public int max_webm_duration;
    public string meta_description;
    public int bump_limit;
    public int image_limit;
    public bool spoilers;
    public int custom_spoilers;
    public bool is_archived;
    public bool troll_flags;
    public bool country_flags;
    public bool user_ids; 
    public bool oekaki;
    public bool sjis_tags;
    public bool code_tags;
    public bool text_only;
    public bool forced_anon;
    public bool webm_audio;
    public bool required_subject;
    public int min_image_width; 
    public int min_image_height;
  }

  GLib.Array<Board?> boards = new GLib.Array<Board?> ();

  public GLib.Array<Board?> populate_boards () {
  
    Network network = new Network ();
    var root_object = network.make_get_call ("https://a.4cdn.org/boards.json");
    var boards = root_object.get_array_member ("boards");
  
    foreach (var board in boards.get_elements ()) {
    
      if (!board.is_null ()) {
        
        var board_object = board.get_object ();
        var temp = board_object.has_member("board") ? board_object.get_string_member("board") : "";
        stdout.printf ("%s", temp);

      } else {
      
        stderr.printf ("A board was null, most likely do to bad call");

      }
    
    }

    return this.boards;

  }

}
