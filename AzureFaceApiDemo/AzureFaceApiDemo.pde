/*  Azure Cognitive FaceAPI Demo. 
    Take a webcam picture with the spacebar and analyse it with the FaceAPI. 
    
    Uses the HTTPClient binaries (in the code folder):
    https://hc.apache.org/downloads.cgi
    
    More documentation:
    https://www.kasperkamperman.com/blog/using-azure-cognitive-services-with-processing
    
    Make sure you get the API subscription key and fill it in in the
    FaceAnalysis code (subscriptionKey). 
    
    kasperkamperman.com - 30-01-2018
*/

import processing.video.*;

Capture cam;

PImage webcamFrame;
PImage webcamPicture;
PGraphics faceDataOverlay;

String onScreenText;
PFont SourceCodePro;

// camera in the setup in combination with other code, sometimes gives a
// Waited for 5000s error: "java.lang.RuntimeException: Waited 5000ms for: <"...
// so we will do init in the draw loop
boolean cameraInitDone = false;

// Face API – free: Up to 20 transactions per minute (so interval 3000ms)
// Face API - standard: Up to 10 transactions per second (so interval 100ms)
int minimalAzureRequestInterval = 3000; 

boolean isAzureRequestRunning = false;
int lastAzureRequestTime = 0; 

String azureFaceAPIData;

FaceAnalysis azureFaceAnalysis;

public void setup() {
  size(1280,720,P2D);
  
  SourceCodePro = createFont("SourceCodePro-Regular.ttf",12);
  textFont(SourceCodePro);
  
  onScreenText = "Press space to take a picture and sent to Azure.";
}

void draw() {
  
  background(0);
 
  if(!cameraInitDone) {
    fill(255);
    onScreenText = "Waiting for the camera to initialize...";
    initCamera();
  }
  else {
    if (cam.available() == true) {
      cam.read();
      // store the frame in PImage webcamFrame
      // we can't acces the cam outside of the draw-loop
      webcamFrame = cam.get();
      
      //doFaceAnalysis();  
    }
    
    // keep the aspectratio correct based on the displayed width
    float aspectRatio = cam.height/(float)cam.width;
    int imageWidth = width/2;
    
    image(webcamFrame,0,0,imageWidth,aspectRatio*imageWidth);
    if(webcamPicture!=null) {
      image(webcamPicture,imageWidth,0,imageWidth,aspectRatio*imageWidth);
      image(faceDataOverlay,640,0,640,aspectRatio*640);
    }
    
  }
  
  text(onScreenText,20,380,width-40,height-20);
  
  if(azureFaceAnalysis!=null) {
    if(azureFaceAnalysis.isDataAvailable()) {
      parseAzureFaceAPIResponse(azureFaceAnalysis.getDataString());
      onScreenText = azureFaceAnalysis.getDataString();
      isAzureRequestRunning = false;
    }
  }
 
}

void keyPressed() {
  // space-bar
  if(keyCode == 32) {
    startFaceAnalysis();  
  }
}

void startFaceAnalysis() {
  
  if(isAzureRequestRunning == false) {
    if((millis() - minimalAzureRequestInterval) > lastAzureRequestTime) {
      webcamPicture = webcamFrame.get();
      onScreenText = "The request is sent to Azure.";
      isAzureRequestRunning = true;
      
      azureFaceAnalysis = new FaceAnalysis(webcamPicture);
    }
    else {
      onScreenText = "The request is sent to fast based on transactions per minute (free version every 3 seconds)";  
    }
  }
  else {
    onScreenText = "Previous data is still requested.";
  }
          
}

void parseAzureFaceAPIResponse(String azureFaceAPIData) {
  
    // we don't parse all the data
    // check the reference on other data that is available
    // https://westus.dev.cognitive.microsoft.com/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236
  
    JSONArray jsonArray = parseJSONArray(azureFaceAPIData);
    
    faceDataOverlay.beginDraw();
    faceDataOverlay.clear();
    
    for (int i=0; i < jsonArray.size(); i++) {
      JSONObject faceObject = jsonArray.getJSONObject(i);
      
      JSONObject faceRectangle  = faceObject.getJSONObject("faceRectangle");
      JSONObject faceLandmarks  = faceObject.getJSONObject("faceLandmarks");
      JSONObject faceAttributes = faceObject.getJSONObject("faceAttributes");
      
      int rectX = faceRectangle.getInt("left");   
      int rectY = faceRectangle.getInt("top");    
      int rectW = faceRectangle.getInt("width");  
      int rectH = faceRectangle.getInt("height"); 
      
      float puppilLeftX = faceLandmarks.getJSONObject("pupilLeft").getFloat("x");
      float puppilLeftY = faceLandmarks.getJSONObject("pupilLeft").getFloat("y");
      float puppilRightX = faceLandmarks.getJSONObject("pupilRight").getFloat("x");
      float puppilRightY = faceLandmarks.getJSONObject("pupilRight").getFloat("y");
      
      float age = faceAttributes.getFloat("age");
      String gender = faceAttributes.getString("gender");
      
      String faceInfo = "age: " + str(age) + "\n" + gender;
      JSONObject emotion = faceAttributes.getJSONObject("emotion");
      
      String [] emotions = { "anger", "contempt", "disgust", "happiness", "neutral", "sadness", "surprise" };
      
      float highestEmotionPercentage = 0.0;
      String highestEmotionString = "";
      
      for(int j = 0; j<emotions.length; j++) {
       float thisEmotionPercentage = emotion.getFloat(emotions[j]);
       
       if(thisEmotionPercentage > highestEmotionPercentage) {
        highestEmotionPercentage = thisEmotionPercentage; 
        highestEmotionString = emotions[j];
       }
      }
      
      String faceEmotion = highestEmotionString + "("+str(highestEmotionPercentage)+")";
      
      faceDataOverlay.stroke(0,255,0);
      faceDataOverlay.strokeWeight(4);
      
      //faceDataOverlay.noFill();
      faceDataOverlay.fill(255,128);
      
      faceDataOverlay.rect(rectX,rectY,rectW,rectH);
      
      faceDataOverlay.fill(255,0,0);
      faceDataOverlay.noStroke();
      faceDataOverlay.ellipse(puppilLeftX,puppilLeftY,8,8);
      faceDataOverlay.ellipse(puppilRightX,puppilRightY,8,8);
      
      faceDataOverlay.fill(0,255,0);
      faceDataOverlay.stroke(0);
      faceDataOverlay.textSize(32);
      faceDataOverlay.textAlign(LEFT, BOTTOM);
      
      faceDataOverlay.text(faceInfo,rectX+5,rectY,rectW,rectH-5);
      //faceDataOverlay.text(faceInfo,rectX,rectY+rectH);
       
      if(rectY<((faceDataOverlay.height-rectH)/2)) { 
        // face on upperhalf of picture
        faceDataOverlay.textAlign(LEFT, TOP);
        faceDataOverlay.text(faceEmotion,rectX,rectY+rectH+10);
      } 
      else {
        faceDataOverlay.textAlign(LEFT, BOTTOM);
        faceDataOverlay.text(faceEmotion,rectX,rectY);
      }
      
    }
    
    faceDataOverlay.endDraw();
  
}

void initCamera() { 
  
  // make sure the draw runs one time to display the "waiting" text
  if(frameCount<2) return;
  
   String[] cameras = Capture.list();

   if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
   } 
   else {
    println("Available cameras:");
    printArray(cameras);

    // The camera can be initialized directly using an element
    // from the array returned by list():
    cam = new Capture(this, cameras[0]);
    
    // Start capturing the images from the camera
    cam.start();
    
    while(cam.available() != true) {
      delay(1);//println("waiting for camera");
    }
    
    // read once to get correct width, height
    cam.read();
    
    // create the overlay PGraphics here
    // so it's exactly the size of the camera
    faceDataOverlay = createGraphics(cam.width,cam.height);
    faceDataOverlay.beginDraw();
    faceDataOverlay.clear();
    faceDataOverlay.endDraw();  
    
    cameraInitDone = true;
  }
   
}