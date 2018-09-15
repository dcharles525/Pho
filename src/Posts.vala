public class Posts{

  string comment;
  string extension;
  string date;
  int64 filename;
  int64 postNumber;

  public Posts(){



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

  public int64 getPostNumber(){

    return this.postNumber;

  }

  public void setPostNumber(int64 postNumber){

    this.postNumber = postNumber;

  }

}
