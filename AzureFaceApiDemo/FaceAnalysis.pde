import java.net.URI;
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.StringEntity;
import org.apache.http.entity.ContentType;

import org.apache.http.client.utils.URIBuilder;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.util.EntityUtils;

class FaceAnalysis extends Thread {
  
  // Don't forget to fill in your API key!
  String subscriptionKey = "";
  String uriBase = "https://westcentralus.api.cognitive.microsoft.com/face/v1.0/detect";
  
  HttpClient httpclient = new DefaultHttpClient();
  URIBuilder builder;
  
  PImage image;
  
  String faceAPIData = "";
  boolean isDataAvailable = false;
  
  FaceAnalysis(PImage _image) {
    this.image = _image;
    
    if(subscriptionKey == "") {
      println("Make sure you fill in your API key!");
      return;
    }
    super.start();
  }
  
  boolean isDataAvailable() {
    return isDataAvailable;
  }
  
  String getDataString() {
    return faceAPIData;
  }
  
  void run() {
    try
    {
      URIBuilder builder = new URIBuilder(uriBase);
  
      // Request parameters. All of them are optional.
      builder.setParameter("returnFaceId", "false");
      builder.setParameter("returnFaceLandmarks", "true");
      builder.setParameter("returnFaceAttributes", "age,gender,smile,emotion,glasses,hair,facialHair");
    
      // Prepare the URI for the REST API call.
      URI uri = builder.build();
      HttpPost request = new HttpPost(uri);
  
      // Request headers.
      request.setHeader("Content-Type", "application/octet-stream");
      request.setHeader("Ocp-Apim-Subscription-Key", subscriptionKey);
      
      // we just save it to disk and then upload that file to Azure. 
      // simpler that converting raw info to a jpeg bytestream
      image.save(dataPath("pictureToBeAnalysed.jpg"));
  
      File file = new File(dataPath("pictureToBeAnalysed.jpg"));
      FileEntity reqEntity = new FileEntity(file, ContentType.APPLICATION_OCTET_STREAM);
   
      request.setEntity(reqEntity);
      
      // Execute the REST API call and get the response entity.
      HttpResponse response = httpclient.execute(request);
      
      HttpEntity entity = response.getEntity();
  
      if (entity != null)
      {
          // Format and display the JSON response.
          faceAPIData = EntityUtils.toString(entity).trim();
          isDataAvailable = true;
          
          //println("REST Response:\n"+faceAPIData);
      }
    }
    catch (Exception e)
    {  // Display error message.
       System.out.println(e.getMessage());
    } 
  }
}