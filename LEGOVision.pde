import processing.video.*;
import blobDetection.*;

import teilchen.*;   
import teilchen.behavior.*; 
import teilchen.constraint.*; 
import teilchen.cubicle.*; 
import teilchen.force.*; 
import teilchen.integration.*; 
import teilchen.util.*; 

import processing.sound.*;

//Physics variables
Physics mPhysics;
LineDeflector2D lDeflector;
LineDeflector2D rDeflector;
ShortLivedParticle ball;
ArrayList<LineDeflector2D> mTemporaryDeflectors = new ArrayList();
Gravity myGravity;

//Sound variables
SoundFile fireball;
SoundFile lost;
SoundFile lostLife;
SoundFile won;
boolean gameLostSound = false;


//Game variables
int lives;
boolean gameLost = false;
boolean gameWon = false;
boolean showSplash = true;

//Cam variables
Capture cam;
BlobDetection theBlobDetection;
PImage img;
boolean newFrame=false;

//UI Variables
PImage heart;
PImage arrow;
PImage fireBall;
PImage monster;
PImage cloud1;
PImage cloud2;
int wind;
int cloudx1 = 400;
int cloudx2 = width-200;

//Splash screen UI
PImage splashBG; 
PImage blackLego;


// ==================================================
// setup()
// ==================================================
void setup()
{
  lives = 3;
  //size(1080, 720);
  fullScreen(); 

  //Select Camera
  String[] cameras = Capture.list();
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(i, cameras[i]);
    }
  }
  cam = new Capture(this, cameras[0]);
  cam.start();

  //Blob detection variables
  img = new PImage(80, 60); 
  theBlobDetection = new BlobDetection(img.width, img.height);
  theBlobDetection.setPosDiscrimination(true);
  theBlobDetection.setThreshold(0.2f);

  //Particle System
  mPhysics = new Physics();

  myGravity = new Gravity();
  myGravity.force().x = random(-30,30);
  myGravity.force().y = 50;
  mPhysics.add(myGravity);
  ViscousDrag myViscousDrag = new ViscousDrag();
  myViscousDrag.coefficient = 0.1f;
  mPhysics.add(myViscousDrag);

  //Wind
  wind = (int)myGravity.force().x;
  
  //Wall deflectors
  lDeflector = new LineDeflector2D();
  rDeflector = new LineDeflector2D();

  lDeflector.a().set(0, 0);
  lDeflector.b().set(0, height);
  rDeflector.a().set(width, 0);
  rDeflector.b().set(width, height);

  mPhysics.add(lDeflector);
  mPhysics.add(rDeflector);
  
  //UI Elements
  heart = loadImage("heart.png");
  arrow = loadImage("arrow.png");
  fireBall = loadImage("ball.png");
  monster = loadImage("monster.png");
  cloud1 = loadImage("cloud.png");
  cloud2 = loadImage("cloud.png");
  splashBG = loadImage("splash-bg.jpg");
  blackLego = loadImage("BlackLego.jpg");
  
  //Sound Files
  fireball = new SoundFile(this, "smb_fireball.wav");
  lost = new SoundFile(this, "smb_gameover.wav");
  lostLife = new SoundFile(this, "smb_bump.wav");
  won = new SoundFile(this, "smb_stage_clear.wav");
  
}


// ==================================================
// captureEvent()
// ==================================================
void captureEvent(Capture cam)
{
  cam.read();
  newFrame = true;
}

// ==================================================
// draw()
// ==================================================
void draw() {
   
  //CHECK LIVES
  checkLives(); 
  
  //SPLASH SCREEN
  if(showSplash){
    imageMode(CORNER);
    image(splashBG,0,0,width,height);
    imageMode(CENTER);
    image(blackLego, width/2,height/2+100,400,200);
    fill(random(150,255));
    textSize(50);
    textAlign(CENTER);
    text("START GAME", width/2, height/2+100);
    textSize(18);
    fill(255);
    text("Press any key", width/2, height/2+140);
    imageMode(CORNER);
      
    if(keyPressed){
      showSplash = false;
    }
    
  }
  
  //GAME WON
  else if(gameWon){
    background(#008e40);
    fill(255);
    textSize(50);
    textAlign(CENTER);
    text("Congrats! You won!",width/2,height/2);
    textSize(25);
    text("Press any key to restart",width/2,height/2+60);
    
          
      for (int i = 0; i < mPhysics.particles().size(); i++) {
        Particle mParticle = mPhysics.particles(i);
        mPhysics.remove(mParticle);
      } 
      
    if(keyPressed) {
      won.stop();
      gameWon=false;
      gameLost=false;
      lives = 3;
  }
}
  
  //GAME LOST
  else if(gameLost){
    background(0);
    fill(255);
    textSize(50);
    textAlign(CENTER);
    text("You lost!",width/2,height/2);
    textSize(25);
    text("Press any key to restart",width/2,height/2+60);
    
     //Play Sound
    if (gameLostSound){
      lost.play();
    }
      gameLostSound=false;
      
    
    for (int i = 0; i < mPhysics.particles().size(); i++) {
      Particle mParticle = mPhysics.particles(i);
      mPhysics.remove(mParticle);
      println(mPhysics.particles().size());
    }
    
    if (keyPressed) {
      lost.stop();
      gameLost=false;
      gameWon=false;
      lives = 3;
    }
  }
  
  //GAME
  else{ 
  
  background(250);
  
  //UI Elements
  showLives();
  showMonsters();
  showArrow();
  showWind();
  showClouds();
  
  //Show camera
  //image(cam,0,0,width,height);
  img.copy(cam, 0, 0, cam.width, cam.height, 0, 0, img.width, img.height);
  theBlobDetection.computeBlobs(img.pixels);
  drawEdges();

  //Physics calculation
  final float mDeltaTime = 1.0f / frameRate;
  mPhysics.step(mDeltaTime);

  //Create ball
  for (int i = 0; i < mPhysics.particles().size(); i++) {
    
    Particle mParticle = mPhysics.particles(i);
    //fill(0);
    //ellipse(mParticle.position().x, mParticle.position().y, mParticle.radius() * 2, mParticle.radius() * 2);
    
    pushMatrix();
    translate(mParticle.position().x, mParticle.position().y);
    rotate(radians(-mParticle.velocity().x*30));
    translate(-mParticle.radius(), -mParticle.radius());
    image(fireBall,0,0, mParticle.radius() * 2, mParticle.radius() * 2);
    popMatrix();
    
    if(mParticle.position().y > height){
      
      if(mParticle.position().x > width/2-250 && mParticle.position().x < width/2-160)
        { gameWon = true; 
          won.play(); 
        }
      
      else if(mParticle.position().x > width/2+250 && mParticle.position().x < width/2+340)
        { gameWon = true; 
          won.play();
        }
      
      else 
        { 
          lives--; 
           myGravity.force().x = random(-30,30); 
           wind = (int)myGravity.force().x;
           lostLife.play();
        }
      
      mPhysics.remove(mParticle); //Remove ball once it exits screen
    }  
  }
  
   //Game lost sound
   if(lives<=0){
    gameLostSound=true;
  }

  //Clear deflectors
  clearEdges();
  mPhysics.removeTags();
  }
}

// ==================================================
// DETECT BLOBS
// ==================================================
void drawEdges()
{
 
  Blob b;
  for (int n=0; n<theBlobDetection.getBlobNb(); n++)
  {
    b=theBlobDetection.getBlob(n);
    if (b!=null)
    {  
      strokeWeight(1);
      stroke(255, 0, 0);
      
      //Map blocks to screen
      float xm = map(b.xMin, 0.1, 0.9, 0, width);
      float ym = map(b.yMin, 0.1, 0.9, 80, height-200);
      float bw = map(b.w, 0, 1, 0, width);
      float bh = map(b.h, 0, 1, 0, height);

      //Create deflectors
      makeBlock( xm, ym, bw, bh);
      //println(xm, ym, b.xMin, b.yMin, b.w);
    }
  }
}

// ==================================================
// Clear Edges
// ==================================================
void clearEdges() {
  for (LineDeflector2D d : mTemporaryDeflectors) {
    mPhysics.forces().remove(d);
  }
}

// ==================================================
// Make Deflectors
// ==================================================
void makeBlock(float p, float q, float w, float h) {
  
  LineDeflector2D aDeflector;
  LineDeflector2D bDeflector;
  LineDeflector2D cDeflector;
  LineDeflector2D dDeflector;
  
  if (w>20 && h>20) {
    stroke(0);
    strokeWeight(2);
    fill(0);
    
    //Draw block
    rect(p,q,w,h);
    //image(block,p,q,w,h);
    
    //Deflector A
    aDeflector = new LineDeflector2D();
    aDeflector.a().set(p, q);
    aDeflector.b().set(p+w, q);
    aDeflector.coefficientofrestitution(1);
    mPhysics.add(aDeflector);

    //Deflector B
    bDeflector = new LineDeflector2D();
    bDeflector.a().set(p+w, q);
    bDeflector.b().set(p+w, q+h);
    bDeflector.coefficientofrestitution(1);
    mPhysics.add(bDeflector);

    //Deflector C
    cDeflector = new LineDeflector2D();
    cDeflector.a().set(p+w, q+h);
    cDeflector.b().set(p, q+h);
    cDeflector.coefficientofrestitution(1);
    mPhysics.add(cDeflector);

    //Deflector D
    dDeflector = new LineDeflector2D();
    dDeflector.a().set(p, q+h);
    dDeflector.b().set(p, q);
    dDeflector.coefficientofrestitution(1);
    mPhysics.add(dDeflector);

    //Add deflectors temporarily
    mTemporaryDeflectors.add(aDeflector);
    mTemporaryDeflectors.add(bDeflector);
    mTemporaryDeflectors.add(cDeflector);
    mTemporaryDeflectors.add(dDeflector);

    //Draw deflectors
    aDeflector.draw(g); 
    bDeflector.draw(g);
    cDeflector.draw(g);
    dDeflector.draw(g);
  }
}


// ==================================================
// Create Ball on mouse click
// ==================================================
void mouseClicked() {
  fireball.play();
  ball = new ShortLivedParticle();
  ball.position().set(width/2, 8);
  ball.velocity().set(mouseX-width/2, 5);
  ball.setMaxAge(1000);
  ball.radius(20);
  mPhysics.add(ball);
  clearEdges();
}

// ==================================================
// Check Lives
// ==================================================
void checkLives(){
  if(lives<=0){
    gameLost = true;
  }
}

// ==================================================
// Show Lives
// ==================================================
void showLives() {
  int posx = width-200;
  int posy = 40;
  for(int i=0;i<lives;i++){
    image(heart,posx+i*50,posy,40,40);
  }
}


// ==================================================
// Show Wind
// ==================================================
void showWind() {
 fill(0);
 textMode(CORNER);
 String wnd = "Wind: " + wind + "mph";
 textSize(18);
 text(wnd,width-145,120);
}

// ==================================================
// Show Monsters
// ==================================================
void showMonsters(){
  //rect(width/2-200,height-50,100,50);
  //rect(width/2+200,height-50,100,50);
  image(monster,width/2-250,height-90,90,90);
  image(monster,width/2+250,height-90,90,90);
}

// ==================================================
// Show Arrow
// ==================================================
void showArrow(){
  pushMatrix();
  translate(width/2,20);
  float mx = map(mouseX,300,width-300,-180,0);
  rotate(radians(-mx));
  translate(-25,-25);
  image(arrow,0,0,50,50);
  popMatrix();
}


// ==================================================
// Show Clouds
// ==================================================
void showClouds(){
  if(cloudx1 < 0) 
    cloudx1 = width;
    
  if(cloudx2 < 0) 
    cloudx2 = width;
    
  if(cloudx1 > width) 
    cloudx1 = 0;
    
  if(cloudx2 > width) 
    cloudx2 = 0;
    
  image(cloud1,cloudx1,height/3,90,70);
  image(cloud2,cloudx2,height*2/3,90,70);
  
  if(wind == 0) 
  { cloudx1 += 0; 
    cloudx2 +=0;}
    
  else if(wind < 4 && wind > 0)
  { cloudx1 += 1; 
    cloudx2 += 1;  }
    
  else if(wind < 0 && wind > -4)
  { cloudx1 -= 1; 
    cloudx2 -= 1;  }
  
  else{
    cloudx1 += wind/3;
    cloudx2 += wind/3;
  }
}
