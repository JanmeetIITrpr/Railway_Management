package com.railway_management;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileReader;
import java.io.FileWriter;
import java.sql.*;

// check_train check_seat_availibility generate_pnr assign_berth
// pnr, train_num, journey date, names, seat, berth type
public class TicketBooking 
{
    public static void main( String[] args )
    {
        try {
            BufferedReader reader = new BufferedReader(new FileReader("bookings.txt"));
            BufferedWriter writer = new BufferedWriter(new FileWriter("output.txt"));
            String output_string = "";

            Class.forName("java.sql.DriverManager");
            Connection con = (Connection)DriverManager.getConnection("jdbc:mysql://localhost:3307/railway_management", "root", "");

            for(String line; !(line = reader.readLine()).contains("#"); ) {
                String[] lineComponents = line.split(" ");
                int numberOfPassengers = Integer.parseInt(lineComponents[0]);
                String[] passengers = new String[lineComponents.length - 4];
                int trainNumber = Integer.parseInt(lineComponents[lineComponents.length - 3]);
                String date = lineComponents[lineComponents.length - 2];
                String coachType = lineComponents[lineComponents.length - 1];

                for(int i = 1; i < lineComponents.length - 3; i++) {
                    if(!lineComponents[i].contains(",")) passengers[i - 1] = lineComponents[i];
                    else passengers[i - 1] = lineComponents[i].substring(0, lineComponents[i].length() - 1);
                }


                try{
                    Statement statement = (Statement)con.createStatement();
                    String query = "call generate_pnr()";
                    ResultSet rs = statement.executeQuery(query);
                    String pnr = null;
                    while(rs.next()){
                        pnr = rs.getString("pnr");
                    }

                    query = "insert into tickets(pnr, booked_date, num_passenger, journey_date, train_num, coach_type) values('"+pnr+"', curdate(), '"+numberOfPassengers+"', '"+date+"', '"+trainNumber+"', '"+coachType+"');";
                    statement.executeUpdate(query);

                    for(String passenger : passengers) {
                        query = "call assign_berth('"+trainNumber+"', '"+date+"', '"+coachType+"', '"+passenger+"', '"+pnr+"')";
                        statement.executeUpdate(query);
                    }

                    query = "select pnr, train_num, journey_date from tickets where pnr = '"+pnr+"'";
                    rs = statement.executeQuery(query);
                    while(rs.next()){
                        output_string += rs.getString("pnr")+" "+rs.getInt("train_num")+" "+rs.getString("journey_date")+": ";
                    }

                    query = "select name, seat_num, berth_type from passenger where pnr='"+pnr+"'";
                    rs = statement.executeQuery(query);
                    while(rs.next()){
                        output_string += rs.getString("name")+" "+rs.getString("seat_num")+" "+rs.getString("berth_type")+", ";
                    }
                } catch (Exception e){
                    output_string += e.getMessage();
                } finally {
                    writer.append(output_string+"\n");
                    output_string = "";
                }
            }
            reader.close();
            writer.close();

        } catch (Exception e) {
            System.out.println(e);
        }
    }
}
