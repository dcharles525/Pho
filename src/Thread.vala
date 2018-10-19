public class Thread{

  string subject;
  string comment;
  string extension;
  string date;
  int64 filename;
  int64 threadNumber;
  int64 replies;
  int64 images;

  public Thread(){



  }

  public string getSubject(){

    return this.subject;

  }

  public void setSubject(string subject){

    this.subject = subject;

  }

  public string getComment(){

    return this.comment;

  }

  public void setComment(string comment){

    this.comment = comment;

  }

  public string getExtension(){

    return this.extension;

  }

  public void setExtension(string extension){

    this.extension = extension;

  }

  public string getDate(){

    return this.date;

  }

  public void setDate(string date){

    this.date = date;

  }

  public int64 getFilename(){

    return this.filename;

  }

  public void setFilename(int64 filename){

    this.filename = filename;

  }

  public int64 getThreadNumber(){

    return this.threadNumber;

  }

  public void setThreadNumber(int64 threadNumber){

    this.threadNumber = threadNumber;

  }

  public void setReplies(int64 replies){
  
    this.replies = replies;

  }

  public int64 getReplies(){
    
    return this.replies;

  }

  public void setImages(int64 images){
  
    this.images = images;

  }

  public int64 getImages(){
    
    return this.images;

  }

}
