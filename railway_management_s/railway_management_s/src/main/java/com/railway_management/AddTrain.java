package com.railway_management;

import java.io.BufferedReader;
import java.io.FileReader;
import java.sql.*;
import java.util.Arrays;

public class AddTrain {
    public static void main(String[] args) {
        try{
            BufferedReader bufferedReader = new BufferedReader(new FileReader("/home/course1/railway_management/railway_management_s/railway_management_s/TestCases/TestCases/input/Trainschedule_underflow_throughput.txt"));

            Class.forName("java.sql.DriverManager");
            Connection con = (Connection)DriverManager.getConnection("jdbc:mysql://localhost:3306/railway_management", "root", "");

            for(String line; !(line = bufferedReader.readLine()).contains("#"); ){
                String[] lineComponents = line.split(" ");
                
                Statement stmt = (Statement)con.createStatement();
                String query = "insert into train(train_num, num_ac, num_sl, journey_date) values('"+ lineComponents[0] +"', '"+ lineComponents[2] +"', '"+ lineComponents[3] +"', '"+ lineComponents[1] +"')";
                stmt.executeUpdate(query);
            }
            bufferedReader.close();
        } catch(Exception e){
            System.out.println(e);
        }
    }
}
