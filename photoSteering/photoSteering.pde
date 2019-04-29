import processing.video.*;
import java.util.Arrays; 
import java.util.Collections;
import beads.*;
import processing.serial.*;

Capture cam;
PImage image;

AudioContext ac;
Glide carrierFreq, modFreqRatio;
color fore = color(255, 102, 204);
color back = color(0,0,0);

int x = 0;
int y = 0;
int imageSize = 50;

float currentX = 10;
float currentY = -10;

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

//Serial port poroperties
Serial mySerial;
boolean serailInitiliazied = false;

//Joystick Porperties
SensorInput sensorInput = new SensorInput();
float steeringSensitivity = 0.0005;
int yOffset;
int xOffset;
int yDead = 2000;
int xDead = 2000;

boolean serialInput = true;

//timer
int millisSinceLastPicture = 0;

//Photo
public static int imageWidth = 100;
public static int imageHeight = 100;
   
void setup(){  
  size(1500, 1000);
  
  currentX = width/2 - rectWidth/2;
  currentY = height/2 - rectHeight/2;
  
  images = createGraphics(width, height);
  triggeredImages = createGraphics(width, height);
  squares = createGraphics(width, height);
  photoCanvas = createGraphics(width, height);
  triggerCanvas = createGraphics(width, height);
  
  frameRate(200);
   
  setupCamera();
  setupAudio();
  //removed cause we do not want any trigger
  /*
  for(int x = 0; x < width; x += 100){
     for(int y = 0; y < height; y+= 100){
        areaList.add(new Area(x,y,rectWidth, rectHeight)); 
     }
  }
  
  areaList = shuffle(areaList);
  areaList = new ArrayList(areaList.subList(0, 20));
*/
  
  currentColor = color(255,255,255); //<>//
  background(color(255,255, 255));
  
  if(serialInput)
  {
     printArray(Serial.list());
     mySerial = new Serial(this, Serial.list()[1], 38400);
     mySerial.bufferUntil(10);
  }
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
  if(millis() < 2000) return;
  drawTriggerCanvas();
  checkAreas();
  drawSquares(sensorInput.x, sensorInput.y, steeringSensitivity);
  drawPhotoCanvas();
  
  //drawImages();
  //drawTriggeredImages();
  
  makeSound(sensorInput.x / 10,sensorInput.y / 10);
  
  if(firstFrame){
    //images.background(255, 255, 255, 0);
    squares.background(125, 125,0, 0);
    photoCanvas.background(125, 125,0, 0);
    triggerCanvas.background(125, 125,0, 0);
    //triggeredImages.background(255, 255, 255, 0);  
    firstFrame = false;
  }
  
  photoTick();
}
int lastTick = 0;
void photoTick(){
  int delta =  millis() - lastTick;
  
  millisSinceLastPicture += delta;
  
  if(millisSinceLastPicture > 1000){
     pictureTick(); 
     millisSinceLastPicture = 0;
  }
  lastTick = millis();
}

int currentPhotoX = -1;
int currentPhotoY = 0;
void pictureTick(){
   int maxX = width / imageWidth - 1;
   int maxY = height / imageHeight - 1;
   
   if(currentPhotoY == 0 && currentPhotoX < maxX){
      currentPhotoX++;      
   }else if(currentPhotoX == maxX && currentPhotoY < maxY){
      currentPhotoY++; 
   }else if(currentPhotoY == maxY && currentPhotoX > 0){
      currentPhotoX--; 
   }else if(currentPhotoX == 0 && currentPhotoY > 0){
       currentPhotoY--;
   }
   
   int x = imageWidth * currentPhotoX + 25;
   int y = imageHeight * currentPhotoY + 25;
   println("PhotoTick:"+ "max ("+ maxX + "," + maxY + ") " + currentPhotoX +"/" + currentPhotoY + " = "+ x + " " + y );
   Photo p = new Photo(cam, x, y, currentColor);
   photoList.add(p);
   
}

void serialEvent(Serial s){  
  sensorInput = ReadInput(s.readString());
}

SensorInput ReadInput(String serialInput){
   SensorInput input = new SensorInput();
    if(serialInput != null){
      //println(serialInput);
       
     try{
       JSONObject json = parseJSONObject(serialInput);
       if(json != null){
         JSONArray accelerometerValues = json.getJSONArray("Accel");
         JSONArray gyroscopeValues = json.getJSONArray("Gyro");
         JSONObject angleValues = json.getJSONObject("Angle");
         JSONArray usedValues = accelerometerValues;
         
         //println(usedValues.getInt(0) + ", " + usedValues.getInt(1) + ", " + usedValues.getInt(2)); 
        
             
         input.x = (usedValues.getInt(1));
         input.y = (usedValues.getInt(2));
         input.success = true;
       }
     }catch(RuntimeException e){
      print("errror"); 
     }
   }else{
    println("no input"); 
   }
   return input;
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
      if(a.contains((int)(currentX + rectWidth/2), (int)(currentY + rectHeight/2))){
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
      Photo img = new Photo( cam,  (int)currentX,  (int)currentY,  color(110, 85, 240));
      photoList.add(img);
  }
  
    for(int i = 0; i < photoList.size(); i++){
     Photo img = photoList.get(i); //<>//
     img.drawImage(photoCanvas);
  }
  photoCanvas.endDraw();
  image(photoCanvas, 0, 0);
}


void drawSquares(float inputX, float inputY, float steeringSensitivity){
  squares.beginDraw(); 

  float moveX = 0;
  float moveY = 0;
  
  float tmpInputX = (inputX + xOffset);
  float tmpInputY = (inputY + yOffset);
  //println(inputY + " " + yOffset + " " + tmpInputY); 
  if(abs(tmpInputX) > xDead){
    moveX = -1 * tmpInputX * steeringSensitivity;
  }
  
  if(abs(tmpInputY) > yDead){
     moveY =  tmpInputY * steeringSensitivity;
  }
  
  currentX += moveX;
  currentX = constrain(currentX, 0, width - rectWidth);
  currentY += moveY;
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
    
    int x = (int)(currentX + rectWidth/2) - currentImageSize/2;
    int y = (int)(currentY + rectHeight/2) - currentImageSize/2;
    
    
    
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
  
  if(keyCode == CONTROL)
  {
    CalibrateJoystick();  
  }
}

void CalibrateJoystick()
{
  println("Calibrating Joystick");
  xOffset = -1 * (int)sensorInput.x;
  yOffset = -1 * (int)sensorInput.y;
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

   public Photo(Capture cam, int x, int y, color tintColor){
      this.x = x;
      this.y = y;
      
     int r = (tintColor >> 16) & 0xFF;
     int g = (tintColor >> 8) & 0xFF;
     int b = tintColor & 0xFF;
      
       r = r < 100 ? (int)random(r, 255) : r;
       g = g < 100 ? (int)random(g, 255) : g;
       b = b < 100 ? (int)random(b, 255) : b;
       
      if (r < 0) r = 0; 
      if (r > 255) r = 255;
      if (g < 0 ) g = 0;
      if (g > 255) g = 255;
      if (b < 0) b = 0;
      if (b > 255) b = 255;
       //println(r + " " + g + " " + b);
      this.tintColor = color(r, g, b);
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

public class SensorInput{
 public float x;
 public float y;
 public boolean success = false;
 
 public SensorInput(){

 }
 
 public void print(){
    //println("x: " + x + ", " + y);
 }
}
