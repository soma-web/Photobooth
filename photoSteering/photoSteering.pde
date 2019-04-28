import processing.video.*;
import java.util.Arrays; 
import java.util.Collections;
import beads.*;


Capture cam;
PImage image;

AudioContext ac;
Glide carrierFreq, modFreqRatio;
color fore = color(255, 102, 204);
color back = color(0,0,0);

int x = 0;
int y = 0;
int imageSize = 50;

int currentX = 10;
int currentY = -10;

boolean left;
boolean right;
boolean up;
boolean down;

boolean triggerPhoto;


int rectWidth = 50;
int rectHeight = 50;

ArrayList<Photo> photoList = new ArrayList<Photo>();
ArrayList<Area> areaList = new ArrayList<Area>();

PGraphics images;
PGraphics squares;
PGraphics triggeredImages;
PGraphics photoCanvas;
PGraphics triggerCanvas;

boolean firstFrame = true;

color currentColor;

void setup(){  
  size(900, 1000);
  images = createGraphics(900, 1000);
  triggeredImages = createGraphics(900, 1000);
  squares = createGraphics(900, 1000);
  photoCanvas = createGraphics(900, 1000);
  triggerCanvas = createGraphics(900, 1000);
  
  frameRate(200);
   
  setupCamera();
  setupAudio();
  
  for(int x = 0; x < width; x += 100){
     for(int y = 0; y < height; y+= 100){
        areaList.add(new Area(x,y,rectWidth, rectHeight)); 
     }
  }
  
  areaList = shuffle(areaList);
  areaList = new ArrayList(areaList.subList(0, 20));

  
  currentColor = color(255,255,255); //<>//
  background(color(255,255, 255));
}

void setupAudio(){ 
  ac = new AudioContext();
  /*
   * This is a copy of Lesson 3 with some mouse control.
   */
   //this time we use the Glide object because it smooths the mouse input.
  carrierFreq = new Glide(ac, 500);
  modFreqRatio = new Glide(ac, 1);
  Function modFreq = new Function(carrierFreq, modFreqRatio) {
    public float calculate() {
      return x[0] * x[1];
    }
  };
  WavePlayer freqModulator = new WavePlayer(ac, modFreq, Buffer.SINE);
  Function carrierMod = new Function(freqModulator, carrierFreq) {
    public float calculate() {
      return x[0] * 400.0 + x[1];    
    }
  };
  WavePlayer wp = new WavePlayer(ac, carrierMod, Buffer.SINE);
  Gain g = new Gain(ac, 1, 0.1);
  g.addInput(wp);
  ac.out.addInput(g);
  ac.start(); 
}


void setupCamera(){
  cam = new Capture(this, 640, 480);
  cam.start();
}

void draw(){
  drawTriggerCanvas();
  checkAreas();
  drawSquares();
  drawPhotoCanvas();
  
  //drawImages();
  drawTriggeredImages();
  
  makeSound(300.0,300.0);
  
  if(firstFrame){
    //images.background(255, 255, 255, 0);
    squares.background(125, 125,0, 0);
    photoCanvas.background(125, 125,0, 0);
    triggerCanvas.background(125, 125,0, 0);
    //triggeredImages.background(255, 255, 255, 0);  
    firstFrame = false;
  }
}

void makeSound(float inputX, float inputY){
  //mouse listening code here
  carrierFreq.setValue((float)inputX / width * 1000 + 50);
  modFreqRatio.setValue((1 - (float)inputY / height) * 10 + 0.1);
}

void drawTriggerCanvas(){
   triggerCanvas.beginDraw();
   for(int i = 0; i < areaList.size(); i++){
     Area a = areaList.get(i);
     triggerCanvas.noStroke();
     drawGradient(triggerCanvas, a.x + 25, a.y + 25, color(16,125,172), color(24,154,211));
     
     //triggerCanvas.fill(color(37, 111, 249));
     //triggerCanvas.ellipse(a.x + 25, a.y + 25, 50, 50);
   }
   triggerCanvas.endDraw();
   image(triggerCanvas, 0, 0);
}

void drawGradient(PGraphics target, float x, float y, color from, color to) {
  int radius = 25;
  float h = random(0, 360);
  color current = to;
  for (int r = radius; r > 0; --r) {
    target.fill(current);
    target.ellipse(x, y, r, r);
    h = (h + 1) % 360;
    current = lerpColor(from, to, float(r)/float(radius));
  }
}

void checkAreas(){
  Area area = null;
   for(int i = 0; i < areaList.size(); i++){
      Area a = areaList.get(i);
      if(a.contains(currentX + rectWidth/2, currentY + rectHeight/2)){
        area = a;
        break;
      }
   }
   
   if(area != null){
     areaList.remove(area);
     Photo img = new Photo( cam,  area.x,  area.y,  currentColor);
     photoList.add(img);
   }
}

void drawPhotoCanvas()                                    
{
  photoCanvas.beginDraw();
  if(keyCode == TAB){
    print("triggerered");
      Photo img = new Photo( cam,  currentX,  currentY,  color(110, 85, 240));
      photoList.add(img);
  }
  
    for(int i = 0; i < photoList.size(); i++){
     Photo img = photoList.get(i); //<>//
     img.drawImage(photoCanvas);
  }
  photoCanvas.endDraw();
  image(photoCanvas, 0, 0);
}


void drawSquares(){
  squares.beginDraw(); 
  
   
  int xInput = xInput();
  
  int yInput = yInput();
  
  currentX += xInput;
  currentX = constrain(currentX, 0, width - rectWidth);
  currentY += yInput;
  currentY = constrain(currentY,0,height - rectHeight);
  currentColor = randomGausColor(currentColor);
  
  squares.stroke(currentColor);
  squares.fill(currentColor);
 // print(strokeColor);
   
  squares.rect(currentX, currentY, rectWidth, rectHeight);
  squares.endDraw();
  
  image(squares, 0, 0);
}

void drawImages(){
  images.beginDraw(); 
  cam.read();

  color tintColor = squares.get(x,y);
  images.tint(tintColor);

  images.image(cam, x,y, imageSize, imageSize);
  x+= imageSize;
  
  if(x >= width){
   x = 0;
   y+= imageSize;
  }
  
  if(y >= height){
     y = 0; 
  }
  images.endDraw();
  image(images, 0, 0);
}

void drawTriggeredImages(){
  triggeredImages.beginDraw();
  
  if(triggerPhoto)
  {
    cam.read();
    print("trigger");
// tintColor = color(125);
    triggeredImages.tint(currentColor);
    
    int currentImageSize = 100;
    
    int x = (currentX + rectWidth/2) - currentImageSize/2;
    int y = (currentY + rectHeight/2) - currentImageSize/2;
    
    
    
    triggeredImages.image(cam, x, y, currentImageSize, currentImageSize);
    triggerPhoto = false;
  }
  
  triggeredImages.endDraw();
  image(triggeredImages, 0, 0);
}

///shfting the color in a naural way around blue to get a nice gradient
color randomGausColor(color c){
  int minValue = 50;
  float r = (c >> 16) & 0xFF;  // Faster way of getting red(argb)
  float g = (c >> 8) & 0xFF;   // Faster way of getting green(argb)
  float b = c & 0xFF;          // Faster way of getting blue(argb)
  
  r +=int(randomGaussian()*5);
  g+=int(randomGaussian()*5);
  b+=int(randomGaussian()*5);

  r+= 300 - 2 * dist(currentX, currentY, width, height);

  if(r>255){r=255;}

  if(r<minValue){r=minValue;}

  if(g>255){g=255;}

  if(g<minValue){g=minValue;}

  if(b>255){b=255;}

  if(b<minValue +50){b=minValue + 50;}
  
  return color(r,g,b);
}

///getting input
void keyReleased() {
  if(keyCode == LEFT)
  {
    left = false;      
  }
  
  if(keyCode == RIGHT)
  {
    right = false;      
  }
  
  if(keyCode == UP)
  {
    up = false;      
  }
  
  if(keyCode == DOWN)
  {
    down = false;      
  }
}


void keyPressed()
{
  if(keyCode == UP)
  {
    up = true;
  }
  
  if(keyCode == DOWN)
  {
    down = true;
  }
  
  if(keyCode == LEFT)
  {
    left = true;
  }
  
  if(keyCode == RIGHT)
  {
     right = true;
  }
  
  if(keyCode == TAB){
    triggerPhoto = true;
  }
  
  if(keyCode == 49){
    saveComposition();
  }
  
  if(keyCode == 50){
    savePath();
  }
  
  if(keyCode == 51){
    savePhotos();
  }
}

int yInput(){
   int yInput = 0;
   if(up) yInput += -5;
   if(down) yInput += 5;
   return yInput;
}

int xInput(){
   int xInput = 0;
   if(left) xInput += -5;
   if(right) xInput += 5;
   return xInput;
}


void saveComposition(){
   saveFrame("shots/safe_" +millis()+".png");
}

void savePath(){
  squares.save("shots/safe_squares.png");
}

void savePhotos(){
    photoCanvas.save("shots/safe_photos.png");

}

ArrayList<Area> shuffle(ArrayList<Area> list){
  Collections.shuffle(list);
  Collections.shuffle(list);
  Collections.shuffle(list);
  return list;
}



///Area is used as a rect with intersectioncheks
public class Area
{
  public int x, y;
  int areaWidth, areaHeight;
  int maxX, maxY;
  
  Area(int x, int y, int areaWidth, int areaHeight){
     this.x = x;
     this.y = y;
     this.areaHeight = areaHeight;
     this.areaWidth = areaWidth;
     this.maxX = x + areaWidth;
     this.maxY = y + areaHeight;
  }
  
  public boolean contains(int x, int y)
  {
    boolean conatins = false;
    if((y >= this.y) && (y <= maxY) && (x >= this.x) && (x <= maxX))
    {
      conatins = true;
    }
    return conatins;
  }
}

public class Photo{
   int x;
   int y;
   PGraphics photo;
   color tintColor;
   
   int imageWidth = 100;
   int imageHeight = 100;
   
   public Photo(Capture cam, int x, int y, color tintColor){
      this.x = x;
      this.y = y;
      this.tintColor = tintColor;
      photo = createGraphics(imageWidth, imageHeight);
      photo.beginDraw();
      
      cam.read();
    
      photo.image(cam,0, 0, imageWidth, imageHeight);
      photo.endDraw();
   }
   
   public void drawImage(PGraphics targetGraphic){
       targetGraphic.tint(tintColor);
       targetGraphic.image(photo, this.x - imageWidth/4, this.y - imageHeight/4);
       //targetGraphic.rect(10,10,250,250);
   }  
}
