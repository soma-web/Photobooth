int currentX = 0;
int currentY = 0;

boolean left;
boolean right;
boolean up;
boolean down;

void setup(){
   size(900, 1000);
   frameRate(200);
}

void draw()
{
  int xInput = xInput();
  int yInput = yInput();
  
  currentX += xInput;
  currentY += yInput;
  rect(currentX, currentY, 55, 55);
  
}


void keyReleased() {
  print("released: " + keyCode);
  if(key == LEFT)
  {
    left = false;      
  }
  
  if(key == RIGHT)
  {
    right = false;      
  }
  
  if(key == UP)
  {
    up = false;      
  }
  
  if(key == DOWN)
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
