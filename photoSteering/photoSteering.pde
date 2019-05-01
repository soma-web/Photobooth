import processing.video.*;
import java.util.Arrays; 
import java.util.Collections;
import beads.*;
import processing.serial.*;

import java.io.FileInputStream;
import java.io.IOException;

import javax.print.Doc;
import javax.print.DocFlavor;
import javax.print.DocPrintJob;
import javax.print.PrintException;
import javax.print.PrintService;
import javax.print.PrintServiceLookup;
import javax.print.SimpleDoc;
import javax.print.attribute.HashPrintRequestAttributeSet;
import javax.print.attribute.PrintRequestAttributeSet;
import javax.print.attribute.standard.Copies;

//
//CONFIGS
//
//defines weather a serial Joystick is attached
boolean serialInput = false;
//defines the serial port on which the serial joystick is attached
int serialPortNumber = 7;

//Photo values
public static int imageWidth = 100;
public static int imageHeight = 100;

//Joystick Porperties
SensorInput sensorInput = new SensorInput();
float steeringSensitivity = 0.0005;
int yOffset;
int xOffset;
int yDead = 2000;
int xDead = 2000;

//END CONFIGS


private Capture cam;
private AudioInterface audioInterface;

AudioContext ac;
Glide carrierFreq, modFreqRatio;
color fore = color(255, 102, 204);
color back = color(0,0,0);

int x = 0;
int y = 0;  

float currentX = 10;
float currentY = -10;

boolean left;
boolean right;
boolean up;
boolean down;

boolean triggerPhoto;

//Player rect
int rectWidth = 50;
int rectHeight = 50;
int playerObject = 1;

ArrayList<Photo> photoList = new ArrayList<Photo>();
ArrayList<Area> areaList = new ArrayList<Area>();

//Different graphic layers we are drawing the objects on

PGraphics squares;
PGraphics photoCanvas;
PGraphics triggerCanvas;
PGraphics logoCanvas;

boolean firstFrame = true;
color currentColor;

//Serial port poroperties
Serial mySerial;
boolean serailInitiliazied = false;

//timer for phtotTicks
int millisSinceLastPicture = 0;
int lastTick = 0;
int currentPhotoX = -1;
int currentPhotoY = 0;
boolean completeRound = false;

//Logo
PImage logoPixelWerkstatt;

   
void setup(){  
  size(1500, 1000);
  
  currentX = width/2 - rectWidth/2;
  currentY = height/2 - rectHeight/2; //<>//
 //<>// //<>//
  squares = createGraphics(width, height);
  photoCanvas = createGraphics(width, height);
  triggerCanvas = createGraphics(width, height);
  logoCanvas =  createGraphics(width, height);
  
  frameRate(200);
   
  setupCamera();
  audioInterface = new AudioInterface();
  //removed cause we do not want any trigger
  generateTrigger(); //<>//
   //<>// //<>//
  currentColor = color(255,255,255); //<>// //<>//
  background(color(255,255, 255));
  
  if(serialInput)
  {
     printArray(Serial.list());
     mySerial = new Serial(this, Serial.list()[serialPortNumber], 38400);
     mySerial.bufferUntil(10);
  }
  
  logoPixelWerkstatt = loadImage("images/pixel_logo.png");
}

void generateTrigger()
{
    for(int x = 0; x < width; x += 100){
     for(int y = 0; y < height; y+= 100){       
        areaList.add(new Area(x,y,rectWidth, rectHeight)); 
     }
  }
  
  areaList = shuffle(areaList);
  areaList = new ArrayList(areaList.subList(0, 20));
}

void setupCamera(){
  cam = new Capture(this, 640, 480);
  cam.start();
}

void draw(){
  if(millis() < 2000) return;
  
  checkAreas();
  if(serialInput) 
  {
     drawSquares(sensorInput.x, sensorInput.y, steeringSensitivity, xDead, yDead, xOffset, yOffset);
     audioInterface.makeSound(sensorInput.x / 10,sensorInput.y / 10);
  }else{
     drawSquares(xInput(), yInput(), 1,0,0,0,0); 
     audioInterface.makeSound(xInput() / 10, yInput() / 10);
  }
 
  drawPhotoCanvas();
  drawLogo();
  drawTriggerCanvas();
  if(firstFrame){
    squares.background(125, 125,0, 0);
    photoCanvas.background(125, 125,0, 0);
    triggerCanvas.background(125, 125,0, 0);
    logoCanvas.background(125, 125,0, 0);
    firstFrame = false;
  }
  
  photoTick();

}

void drawLogo()
{
  logoCanvas.beginDraw();
  logoCanvas.image(logoPixelWerkstatt, width - imageWidth, height - imageHeight, imageWidth, imageHeight);
  logoCanvas.endDraw();
  image(logoCanvas, 0, 0);
}

//the clock for the pixtures taken around the frame
void photoTick(){
  int delta =  millis() - lastTick;
  
  millisSinceLastPicture += delta;
  
  if(millisSinceLastPicture > 1000){
     pictureTick(); 
     millisSinceLastPicture = 0;
  }
  lastTick = millis();
}

//takes a photo every tick and places is around the frame
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
       if(currentPhotoY == 0) completeRound = true;
   }
   
   if(currentPhotoX == 0 && currentPhotoY == 0 && !completeRound) return;
   int x = imageWidth * currentPhotoX + 25;
   int y = imageHeight * currentPhotoY + 25;
   //println("PhotoTick:"+ "max ("+ maxX + "," + maxY + ") " + currentPhotoX +"/" + currentPhotoY + " = "+ x + " " + y );
   Photo p = new Photo(cam, x, y, currentColor);
   photoList.add(p);
   
    if(currentPhotoX == 0 && currentPhotoY == 0 && completeRound) 
    {
      OnPhotoSeriesFinished();  
    }
}

//called once the frame is absolutely filled
void OnPhotoSeriesFinished(){
  println("finished");
}

//caled every time a serial messages arrives
void serialEvent(Serial s){  
  sensorInput = sensorInput.ReadInput(s.readString());
}

void drawTriggerCanvas(){
   triggerCanvas.beginDraw(); //<>//
   for(int i = 0; i < areaList.size(); i++){ //<>// //<>//
     Area a = areaList.get(i);
     triggerCanvas.noStroke();
     a.draw(triggerCanvas, color(16,125,172), color(24,154,211));
   }
   triggerCanvas.endDraw();
   image(triggerCanvas, 0, 0);
}

//checks weather the player hits a trigger
void checkAreas(){
  Area area = null;
   for(int i = 0; i < areaList.size(); i++){
      Area a = areaList.get(i);
      if(a.contains((int)(currentX + rectWidth), (int)(currentY + rectHeight))){
        area = a;
        break;
      }
   }
   
   if(area != null){
     areaList.remove(area);
     //
     // Photo img = new Photo( cam,  area.x,  area.y,  currentColor);
     // photoList.add(img);
     
     OnTriggerEnter(area);
   }
}

void OnTriggerEnter(Area triggerArea)
{
  println("trigger enter");
    
    int tempObject = this.playerObject;
    while( tempObject == this.playerObject ){
      this.playerObject = (int)random(1,4);
    }    
   
    println("Intensity: " + this.steeringSensitivity);
    
}

//draws the triggered photos
void drawPhotoCanvas()                                    
{ //<>//
  photoCanvas.beginDraw();
  if(keyCode == TAB){
    print("triggerered");
      Photo img = new Photo( cam,  (int)currentX,  (int)currentY,  color(110, 85, 240));
      photoList.add(img);
  }
  
    for(int i = 0; i < photoList.size(); i++){
     Photo img = photoList.get(i); //<>// //<>//
     img.drawImage(photoCanvas);
  }
  photoCanvas.endDraw();
  image(photoCanvas, 0, 0);
}

//draws the player
void drawSquares(float inputX, float inputY, float steeringSensitivity, int xDead, int yDead, int xOffset, int yOffset){
  squares.beginDraw(); 

  float moveX = 0;
  float moveY = 0;
  
  float tmpInputX = (inputX + xOffset);
  float tmpInputY = (inputY + yOffset);
  
  if(abs(tmpInputX) > xDead){
    moveX = -1 * tmpInputX * steeringSensitivity;
  }
  
  if(abs(tmpInputY) > yDead){
     moveY =  tmpInputY * steeringSensitivity;
  }
  //println("Input: (" + inputX + "," + inputY + ") " + " Move: (" + moveX +"," + moveY + ") "); 

  currentX += moveX;
  currentX = constrain(currentX, 0, width - rectWidth);
  currentY += moveY;
  currentY = constrain(currentY,0,height - rectHeight);
  currentColor = randomGausColor(currentColor);
  
  squares.stroke(currentColor);
  squares.fill(currentColor);
  
 
  if ( playerObject == 1 ){
    squares.rect(currentX, currentY, rectWidth, rectHeight);
  }
  
  if ( playerObject == 2 ){ //<>//
    int eWidth = (int)random(rectWidth, rectWidth + 20);
    int eHeight = (int) random(rectHeight, rectHeight + 20);
    squares.ellipse (currentX + eWidth/4 , currentY + eHeight/4, eWidth, eHeight); 
  }
  
  if ( playerObject == 3){
    
    squares.triangle(currentX, currentY, currentX + random(28, 60), currentY - random(5, 45), currentX + random(30, 70), currentY);
  }
    
  squares.endDraw();
  
  image(squares, 0, 0);
}


///shfting the color in a naural way around blue to get a nice gradient
color randomGausColor(color c){
  int minValue = 50;
  float r = (c >> 16) & 0xFF;  // Faster way of getting red(argb)
  float g = (c >> 8) & 0xFF;   // Faster way of getting green(argb)
  float b = c & 0xFF;          // Faster way of getting blue(argb)
   //<>//
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
    println("50 pressed");
    savePath();
  }
  
  if(keyCode == 51){
    println("51 pressed");
    savePhotos();
  }
  
  if(keyCode == 52){
    println("52 pressed");
    String imgPath = saveComposition();
    printComposition(imgPath);
  }
  
  if(keyCode == CONTROL)
  {
    CalibrateJoystick();  
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

void CalibrateJoystick()
{
  println("Calibrating Joystick");
  xOffset = -1 * (int)sensorInput.x;
  yOffset = -1 * (int)sensorInput.y;
}


String saveComposition(){
  String path = "shots/safe_" +millis()+".png";
 
   saveFrame(path);
   return path;
}

void printComposition(String imagePath){
   try {
    println("printing: " + imagePath);
    launch("i_view64 " + imagePath + " /print=\"EPSON5923F9 (ET-2750 Series)\"");
  } 
  catch (Exception e) {
    e.printStackTrace();
    println("error " + e);
  }
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
  
  void draw(PGraphics target, color from, color to) {
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
 
 public SensorInput ReadInput(String serialInput){ 
     //reset all values cause we can not make sure the input is read correctly
     success = false;
     x = 0;
     y = 0;
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
        
             
         x = (usedValues.getInt(1));
         y = (usedValues.getInt(2));
         success = true;
       }
     }catch(RuntimeException e){
      println("errror"); 
     }
   }else{
    println("no input"); 
   }
   return this;
}
 
 public void print(){
    println("x: " + x + ", " + y);
 }
}
