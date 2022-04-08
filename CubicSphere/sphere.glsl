// derived from BrunoLevy's RayTracing tutorial - step 1, shadertoy.com/view/wdfXR4
// https://www.shadertoy.com/view/7ds3zB

#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 iResolution;
 
struct Camera {
    vec3 Obs;
    vec3 View;
    vec3 Up;
    vec3 Horiz;
    float H;
    float W;
    float z;
};

struct Ray {
    vec3 Origin;
    vec3 Dir;
};

Camera camera(in vec3 Obs, in vec3 LookAt, in float aperture) {
   Camera C;
   C.Obs = Obs;
   C.View = normalize(LookAt - Obs);
   C.Horiz = normalize(cross(vec3(0.0, 0.0, 1.0), C.View));
   C.Up = cross(C.View, C.Horiz);
   C.W = float(iResolution.x);
   C.H = float(iResolution.y);
   C.z = (C.H/2.0) / tan((aperture * 3.1415 / 180.0) / 2.0);
   return C;
}

Ray launch(in Camera C, in vec2 XY) {
   return Ray(
      C.Obs,
      C.z*C.View+(XY.x-C.W/2.0)*C.Horiz+(XY.y-C.H/2.0)*C.Up 
   );
}

struct Sphere {
   vec3 Center;
   float R;
};

bool intersect_sphere(in Ray R, in Sphere S, out float t, out float t2) {
   vec3 CO = R.Origin - S.Center;
   float a = dot(R.Dir, R.Dir);
   float b = 2.0*dot(R.Dir, CO);
   float c = dot(CO, CO) - S.R*S.R;
   float delta = b*b - 4.0*a*c;
   if(delta < 0.0) {
      return false;
   }
   t = (-b-sqrt(delta)) / (2.0*a);
   t2 = (-b+sqrt(delta)) / (2.0*a);
   return true;
}

bool step_forward(in Ray R, inout float t, inout vec3 roundpoint, out int coord, in float max_t, in float cubeWidth, in float cubesRad){
    vec3 point = R.Origin + t*R.Dir;
    vec3 signDir = sign(R.Dir);
    /// solve for param: point + param*Dir = roundpoint + 0.5*(signDir)*cubeWidth component by component
    vec3 params = (roundpoint - point + 0.5*signDir*cubeWidth)/R.Dir;

    // find out which wall we hit next
    if(params.x < params.y){
        if(params.x < params.z){ coord = 0;}
        else{ coord = 2;}
    }
    else{
        if(params.y < params.z){ coord = 1;}
        else{ coord = 2;}
    }
    
    t += params[coord];
    vec3 move = vec3(0.0,0.0,0.0);
    move[coord] += cubeWidth;
    roundpoint += signDir*move;

    if(length(roundpoint) < cubesRad){ 
        roundpoint -= signDir*move; // take a step back to the cube before we hit the solid cube
        return false; } // we hit a cube 
    if(t > max_t){ coord = 3; 
        return false;
    }  // meaning that we were tangent to the sphere of cubes and didnt hit anything
 
    return true; // keep going
}

float mysmoothstep(in float x){
    float t = clamp(x, 0.0, 1.0);
    t = 1.0 - pow((1.0 - t),1.5); 
    return t * t * (3.0 - 2.0 * t);
}

void main( void ) {
   float time = float(100 + iFrame)/100.0;
   float cubeWidth = 1.0/time;  
   //float cubeWidth = 0.2;
   float sphereRad = 1.0;
   float cubesRad = sphereRad - cubeWidth*0.5*sqrt(3.0); // cube with center within this rad is contained in sphere
 
   vec3 red = vec3(1.0,0.0,0.0);
   vec3 green = vec3(0.0,1.0,0.0);
   vec3 blue = vec3(0.0,0.0,1.0);
   
   float beta = 3.14159 / 4.0 + 0.2; // * time; // * time;
   float s = sin(beta);
   float c = cos(beta); 

   // Initialize the Camera 
   Camera C = camera(
       vec3(2.0*c, 2.0*s, 1.5),
       vec3(0.0, 0.0, 0.0),
       50.0       
   );
 
   Ray R = launch(C, gl_FragCoord);
   Sphere S = Sphere(vec3(0.0, 0.0, 0.0), sphereRad);
   
   gl_FragColor = vec4(0.5, 0.5, 0.5, 1.0);
   
   float t;
   float max_t;
   int coord;
   
   vec3 col = vec3(0.0,0.0,0.0);
   if(intersect_sphere(R,S,t,max_t)) {
      vec3 point = R.Origin + t*R.Dir;
      vec3 roundpoint = round(point/cubeWidth)*cubeWidth;
      
      bool cont = true;
      for(int i = 0; i <= 50; i++) { 
          cont = step_forward(R, t, roundpoint, coord, max_t, cubeWidth, cubesRad);
          if(cont == false){break;}
      }
      if(coord <= 2){ // hit a solid cube
          col[coord] = 1.0;
          
          vec3 point = R.Origin + t*R.Dir;
          vec3 signOctant = -sign(point);
          point -= roundpoint; // now relative to the cube center we just hit
          point *= signOctant; // now moving in the positive direction sends us to potential solid cubes
          point /= cubeWidth; // now in (-0.5,0.5)^2
          
          float brightness = 1.0;
          float d = 0.3; // ambient occlusion darkness amount
          
          vec3 move1 = vec3(0.0,0.0,0.0);
          move1[(coord + 1) % 3] += cubeWidth;
          vec3 neighbour1 = signOctant*roundpoint + move1;
          vec3 move2 = vec3(0.0,0.0,0.0);
          move2[(coord + 2) % 3] += cubeWidth;
          vec3 neighbour2 = signOctant*roundpoint + move2;
          vec3 move3 = move1 + move2;
          vec3 neighbour3 = signOctant*roundpoint + move3;
          bool n1solid = (length(neighbour1) < cubesRad);
          bool n2solid = (length(neighbour2) < cubesRad);
          bool n3solid = (length(neighbour3) < cubesRad);
          
          if(n1solid){
              brightness *= (1.0 - d) + d*mysmoothstep(0.5 - point[(coord + 1) % 3]);
          }
          if(n2solid){
              brightness *= (1.0 - d) + d*mysmoothstep(0.5 - point[(coord + 2) % 3]);
          }
          
          if(n3solid && (!n1solid && !n2solid)){
              float s1 = mysmoothstep(0.5 - point[(coord + 1) % 3]);
              float s2 = mysmoothstep(0.5 - point[(coord + 2) % 3]);
              float foo = 1.0 - (1.0 - s1)*(1.0 - s2);
              brightness *= (1.0 - d) + d*foo;
          }
          
          col *= brightness;          
          gl_FragColor = vec4(col, 1.0);
      }
   }

}
 
 
