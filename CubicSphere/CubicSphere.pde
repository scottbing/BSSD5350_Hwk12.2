PShader sphere;

void setup() {
 size(640, 360, P2D); 
 noStroke();

 sphere = loadShader("sphere.glsl"); 
 sphere.set("iResolution", float(width), float(height));
 sphere.set("time", millis() / 500.0);

}

void draw() {
 shader(sphere);
 rect(0.0, 0.0, width, height);
}
