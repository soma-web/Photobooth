import processing.video.*;

Capture cam;
PImage image;

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

boolean firstFrame = true;

color currentColor;

void setup(){  
  size(900, 1000);
  images = createGraphics(900, 1000);
  triggeredImages = createGraphics(900, 1000);
  squares = createGraphics(900, 1000);
  photoCanvas = createGraphics(900, 1000);
  
  frameRate(200);
   
  setupCamera();
  for(int x = 0; x < width; x += rectWidth){
     for(int y = 0; y < height; y+= rectHeight){
        areaList.add(new Area(x,y,rectWidth, rectHeight)); 
     }
  }

  
  currentColor = color(255,255,255); //<>//
  background(color(255,255, 255));
}



void setupCamera(){
  cam = new Capture(this, 640, 480);
  cam.start();
}

void draw(){

  checkAreas();
  drawSquares();
  drawPhotoCanvas();
  
  //drawImages();
  //drawTriggeredImages();
  
  if(firstFrame){
    //images.background(255, 255, 255, 0);
    squares.background(125, 125,0, 0);
    photoCanvas.background(125, 125,0, 0);
    //triggeredImages.background(255, 255, 255, 0);  
    firstFrame = false;
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
      Photo img = new Photo( cam,  currentX,  currentY,  color(125,125,125));
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

/*
void keyPressed(){
   if( keyCode == UP){
      saveFrame("shots/safe_" +millis()+".png");
   }
}
*/


float z;
color shiftColor(color c){
  float r = (c >> 16) & 0xFF;  // Faster way of getting red(argb)
  float g = (c >> 8) & 0xFF;   // Faster way of getting green(argb)
  float b = c & 0xFF;          // Faster way of getting blue(argb)
   if( z > 1) z = 0; 
  float t = noise(float(currentX)/float(width),float(currentY)/float(height), z) * 256;
  print( t + "\n");
  z += 0.06;
  return color(t,255,255);
 
}

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

  if(b<minValue){b=minValue;}
  
  return color(r,g,b);
}


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

void saveComposition(){
   saveFrame("shots/safe_" +millis()+".png");
}

void savePath(){
  squares.save("shots/safe_squares.png");
}

void savePhotos(){
    photoCanvas.save("shots/safe_photos.png");

}

int yInput(){
   int yInput = 0;
   if(up) yInput += -1;
   if(down) yInput += 1;
   return yInput;
}

int xInput(){
 int xInput = 0;
 if(left) xInput += -1;
 if(right) xInput += 1;
 return xInput;
}

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
    if((y >= this.y) && (y <= maxY) && (x >= this.x) && (x <= maxX)){
      conatins = true;
    }
    /*
    if((x >= this.x) && (x <= maxX))
      conatins = true;
    
    if((y >= this.y) && (y <= maxY))
      conatins = true;
      */
    return conatins;
  }
}

public class Photo{
   int x;
   int y;
   PGraphics photo;
   color tintColor;
   
   int imageWidth = 50;
   int imageHeight = 50;
   
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
       targetGraphic.image(photo, this.x, this.y);
       //targetGraphic.rect(10,10,250,250);
   }
   
}
