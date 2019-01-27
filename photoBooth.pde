import processing.video.*;

Capture cam;
PImage image;

int x = 0;
int y = 0;
int imageSize = 50;


void setup(){  
  size(900, 1000);
  frameRate(100000);
  setupCamera();
  setupImage();
}

void setupImage(){
  image = loadImage("assets/smiley.jpg");
  image.loadPixels();
}

void setupCamera(){
  cam = new Capture(this, 640, 480);
  cam.start();
}

void draw(){
  cam.read();
 // color tintColor = color(random(0, 255), random(0, 255), random(0, 255));
  int arrayIndex = x + y * image.width;
  color tintColor = image.pixels[arrayIndex];
  tint(tintColor);

  image(cam, x,y, imageSize, imageSize);
  x+= imageSize;
  
  if(x >= width){
   x = 0;
   y+= imageSize;
  }
  
  if(y >= height){
     y = 0; 
  }
}

void keyPressed(){
   if( keyCode == UP){
      saveFrame("shots/safe_" +millis()+".png");
   }
}
