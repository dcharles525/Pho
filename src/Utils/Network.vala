using Soup;
using Json;

/*
* Network.vala
*
* Meant to do all network operations and return parsed data only!
*/

public class Network {

  public Json.Object make_get_call (string url) {
    
    var root_object = new Json.Object ();

    var session = new Soup.Session ();
    var message = new Soup.Message (
      "GET",
      url
    );

    session.send_message (message);
    
    try {
    
      var parser = new Json.Parser ();
      parser.load_from_data ( (string) message.response_body.flatten().data, -1);
      root_object = parser.get_root ().get_object ();
      stdout.printf ("%u\n",root_object.get_size());

    } catch (Error e) {
    
      stderr.printf ("Something went wrong resolving json in make_get_call");

    }

    return root_object;
  
  }

}
