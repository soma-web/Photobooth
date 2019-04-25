import processing.serial.*;

Serial mySerial;
boolean serailInitiliazied = false;

float currentX = 10;
float currentY = -10;

float steeringSensitivity = 0.001;

boolean left;
boolean right;
boolean up;
boolean down;



color strokeColor;

int rectWidth = 55;
int rectHeight = 55;

SensorInput sensorInput = new SensorInput();

void setup(){
   size(900, 1000);
   frameRate(200);
   background(color(255,255, 255));
   strokeColor = color(255,255,255);
   
   printArray(Serial.list());
   mySerial = new Serial(this, Serial.list()[1], 38400);
   mySerial.bufferUntil(10);
}

void serialEvent(Serial s){  
  sensorInput = ReadInput(s.readString());
}

void draw()
{  
   if(sensorInput != null)
   {
     DrawPlayer(sensorInput.x, sensorInput.y, steeringSensitivity);  
   }else{
      println("no sensordata"); 
   }
}

float z;
color shiftColor(color c){
  float r = (c >> 16) & 0xFF;  // Faster way of getting red(argb)
  float g = (c >> 8) & 0xFF;   // Faster way of getting green(argb)
  float b = c & 0xFF;          // Faster way of getting blue(argb)
   if( z > 1) z = 0; 
  float t = noise(currentX/float(width),currentY/float(height), z) * 256;
  //print( t + "\n");
  z += 0.06;
  return color(t,255,255);
}

color randomGausColor(color c){
  float r = (c >> 16) & 0xFF;  // Faster way of getting red(argb)
  float g = (c >> 8) & 0xFF;   // Faster way of getting green(argb)
  float b = c & 0xFF;          // Faster way of getting blue(argb)
  
  r +=int(randomGaussian()*5);
  g+=int(randomGaussian()*5);
  b+=int(randomGaussian()*5);

  r+= 300 - 2 * dist(currentX, currentY, width, height);

  if(r>255){r=255;}

  if(r<0){r=0;}

  if(g>255){g=255;}

  if(g<0){g=0;}

  if(b>255){b=255;}

  if(b<0){b=0;}
  
  return color(r,g,b);
}


void DrawPlayer(float inputX, float inputY, float steeringSensitivity){
  float moveX = inputX * steeringSensitivity;
  float moveY = inputY * steeringSensitivity;
  println("Move: " + moveX + ", " + moveY);

  currentX += moveX;
  currentX = constrain(currentX, 0, width - rectWidth);
  currentY += moveY;
  currentY = constrain(currentY,0,height - rectHeight);
  
  strokeColor = randomGausColor(strokeColor);
  stroke(strokeColor);
  fill(strokeColor);
   //print(strokeColor);
  rect(currentX, currentY, rectWidth, rectHeight);
}

SensorInput ReadSensorInput(Serial mySerial){
   SensorInput input = new SensorInput();
   String inBuffer = mySerial.readStringUntil('\n');
   if(inBuffer != null){
       //println(inBuffer);
       
     try{
       JSONObject json = parseJSONObject(inBuffer);
       if(json != null){
         JSONArray accelerometerValues = json.getJSONArray("Accel");
         JSONArray gyroscopeValues = json.getJSONArray("Gyro");
         JSONObject angleValues = json.getJSONObject("Angle");
         JSONArray usedValues = accelerometerValues;
         
         println(usedValues.getInt(0) + ", " + usedValues.getInt(1) + ", " + usedValues.getInt(2)); 
        
             
         input.x = (usedValues.getInt(1));
         input.y = (usedValues.getInt(2));
         input.success = true;
       }
     }catch(RuntimeException e){
      print("errror"); 
     }
   }
   return input;
}

SensorInput ReadInput(String serialInput){
   SensorInput input = new SensorInput();
    if(serialInput != null){
      println(serialInput);
       
     try{
       JSONObject json = parseJSONObject(serialInput);
       if(json != null){
         JSONArray accelerometerValues = json.getJSONArray("Accel");
         JSONArray gyroscopeValues = json.getJSONArray("Gyro");
         JSONObject angleValues = json.getJSONObject("Angle");
         JSONArray usedValues = accelerometerValues;
         
         println(usedValues.getInt(0) + ", " + usedValues.getInt(1) + ", " + usedValues.getInt(2)); 
        
             
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

public class SensorInput{
 public float x;
 public float y;
 public boolean success = false;
 
 public SensorInput(){

 }
 
 public void print(){
    println("x: " + x + ", " + y);
 }
}
