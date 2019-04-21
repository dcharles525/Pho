class DataBase : Object {
  /* Using defaults will search a SQLite database located at current directory called test.db */
  public string provider { set; get; default = "SQLite"; }
  public string constr { set; get; default = "SQLite://DB_DIR=.;DB_NAME=test"; }
  public Gda.Connection cnn;
  
  public void open () throws Error {
          stdout.printf("Opening Database connection…\n");
          this.cnn = Gda.Connection.open_from_string (null, this.constr, null, Gda.ConnectionOptions.NONE);
  }

  /* Create a tables and populate them */
  public void create_tables () 
          throws Error
          requires (this.cnn.is_opened())
  {
          stdout.printf("Creating and populating data…\n");
          this.run_query("CREATE TABLE test (description string, notes string)");
          this.run_query("INSERT INTO test (description, notes) VALUES (\"Test description 1\", \"Some notes\")");
          this.run_query("INSERT INTO test (description, notes) VALUES (\"Test description 2\", \"Some additional notes\")");
          
          this.run_query("CREATE TABLE table1 (city string, notes string)");
          this.run_query("INSERT INTO table1 (city, notes) VALUES (\"Mexico\", \"Some place to live\")");
          this.run_query("INSERT INTO table1 (city, notes) VALUES (\"New York\", \"A new place to live\")");
  }
  
  public int run_query (string query) 
          throws Error
          requires (this.cnn.is_opened())
  {
          stdout.printf("Executing query: [%s]\n", query);
          return this.cnn.execute_non_select_command (query);
  }
}
