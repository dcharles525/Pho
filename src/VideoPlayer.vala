public class VideoPlayer{

  public GtkClutter.Embed clutter;
  public Clutter.Actor video_actor;
  public Clutter.Stage stage;
  public ClutterGst.Playback playback;
  string url; 

  public GtkClutter.Embed buildPlayer () {

    playback = new ClutterGst.Playback ();
    clutter = new GtkClutter.Embed ();
    stage = (Clutter.Stage)clutter.get_stage ();
    stage.background_color = {0, 0, 0, 0};

    video_actor = new Clutter.Actor ();
    #if VALA_0_34
      var aspect_ratio = new ClutterGst.Aspectratio ();
    #else
      var aspect_ratio = ClutterGst.Aspectratio.@new ();
    #endif
    ((ClutterGst.Aspectratio) aspect_ratio).paint_borders = false;
    ((ClutterGst.Content) aspect_ratio).player = playback;
    video_actor.content = aspect_ratio;

    video_actor.add_constraint (new Clutter.BindConstraint (stage, Clutter.BindCoordinate.WIDTH, 0));
    video_actor.add_constraint (new Clutter.BindConstraint (stage, Clutter.BindCoordinate.HEIGHT, 0));
    
    stage.add_child (video_actor);

    return clutter;

  }

  public void playFile () {

    playback.uri = this.url;
    playback.playing = true;

  }

  public void stopFile(){

    playback.playing = false;  

  }

  public void setUrl (string url){

    this.url = url;  

  }

}
