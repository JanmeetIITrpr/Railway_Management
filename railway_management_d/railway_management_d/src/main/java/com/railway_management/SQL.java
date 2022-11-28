package com.railway_management;

import java.sql.*;

public class SQL
{
    static Connection con = null;
    static String connectionUrl = "jdbc:mysql://localhost:3307/railway_management";
    static String connectionUser = "root";
    static String connectionPassword = "";
    
    public SQL(){}
    
    public static Connection getConnection () {
    
      if (con != null) {
        return con;
      }
      try{
    
      Class.forName("com.mysql.jdbc.Driver");
      con = DriverManager.getConnection(connectionUrl, connectionUser, connectionPassword);
      return con; 
     }
      catch(Exception e){
        e.printStackTrace();
    }
    
    return null;
    }
}