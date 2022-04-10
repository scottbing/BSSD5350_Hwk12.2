PShader pretty;

void setup() {
 size(640, 360, P2D); 
 noStroke();

 pretty = loadShader("pretty.glsl"); 
 pretty.set("iResolution", float(width), float(height));
 pretty.set("time", millis() / 500.0);

}

void draw() {
 shader(pretty);
 rect(0.0, 0.0, width, height);
 pretty.set("time", millis() / 500.0);
}
