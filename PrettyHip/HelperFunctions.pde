public class HelperFunctions {

  public HelperFunctions(){}

  public String today() {
    int[] vals = {year(), month(), day(), hour(), minute(), second()};
    String day = "";
    for (int v : vals) {
      day += String.valueOf(v); 
    }
    return day;
  }
  
  // save sets save mode. video is sequence in imgs folder.
  public void save(String mode, String extra) {
    mode = mode.toLowerCase();
    if(mode == "img") {
      String filename = "screen-##-" + extra + "-" + this.today() + ".png";
      saveFrame(filename);
    } else if (mode == "video") {
      String filename = "imgs/" + extra + "-" + nf(frameCount,4) + ".tga"; //nf pads 0s
      saveFrame(filename);
    }
  }
  
  //overload if you do not want to pass an empty extra everytime  
  public void save(String mode) {
    save(mode, "");
  }
}
