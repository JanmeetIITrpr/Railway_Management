package com.railway_management;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.io.IOException;
import java.net.ServerSocket;
import java.sql.*;
import java.net.Socket;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import javax.jms.TransactionRolledBackException;

class QueryRunner implements Runnable
{
    //  Declare socket for client access
    protected Socket socketConnection;

    public QueryRunner(Socket clientSocket)
    {
        this.socketConnection =  clientSocket;
    }

    public static String bookingsys( String line,Connection con)
    {
        String output_string = "";


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
            con.setTransactionIsolation(8);
            Statement statement = (Statement)con.createStatement();
            String query = "call generate_pnr()";
            ResultSet rs = statement.executeQuery(query);
            String pnr = null;
            while(rs.next()){
                pnr = rs.getString("pnr");
            }

            query = "insert into tickets(pnr, booked_date, num_passenger, journey_date, train_num, coach_type) values('"+pnr+"', curdate(), '"+numberOfPassengers+"', '"+date+"', '"+trainNumber+"', '"+coachType+"');";
            statement.executeUpdate(query);

            //con.setTransactionIsolation(4);
            for(String passenger : passengers) {
                query = "call assign_berth('"+trainNumber+"', '"+date+"', '"+coachType+"', '"+passenger+"', '"+pnr+"')";
                statement.executeUpdate(query);
            }

            con.setAutoCommit(false);
            //con.setTransactionIsolation(8);

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
            con.commit();
            return output_string;

        } catch (Exception e){
            if(e instanceof TransactionRolledBackException) {
                try{
                    System.out.println("x:Rolling back...");
                    con.rollback();
                }
                catch (Exception E){
                        System.err.println(E.getMessage());
                }
            }
            output_string += e.getMessage();
            return output_string;
        }
    }

    public void run()
    {
      try
        {
            //  Reading data from client
            InputStreamReader inputStream = new InputStreamReader(socketConnection
                                                                  .getInputStream()) ;
            BufferedReader bufferedInput = new BufferedReader(inputStream) ;
            OutputStreamWriter outputStream = new OutputStreamWriter(socketConnection
                                                                     .getOutputStream()) ;
            BufferedWriter bufferedOutput = new BufferedWriter(outputStream) ;
            PrintWriter printWriter = new PrintWriter(bufferedOutput, true) ;
            String clientCommand = "" ;
            String responseQuery = "" ;
            //Read client query from the socket endpoint
            clientCommand = bufferedInput.readLine(); 
            while( ! clientCommand.equals("#"))
            {
                
                // System.out.println("Recieved data <" + clientCommand + "> from client : " 
                //                     + socketConnection.getRemoteSocketAddress().toString());

                /*******************************************
                //          Your DB code goes here
                ********************************************/
                
                Connection con=SQL.getConnection();
                // Dummy response send to client
                responseQuery = bookingsys(clientCommand,con);     
                //  Sending data back to the client
                printWriter.println(responseQuery);
                // Read next client query
                clientCommand = bufferedInput.readLine(); 
            }
            inputStream.close();
            bufferedInput.close();
            outputStream.close();
            bufferedOutput.close();
            printWriter.close();
            socketConnection.close();
        }
        catch(IOException e)
        {
            return;
        }
    }
}



/**
 * Main Class to controll the program flow
 */
public class ServiceModule 
{
    // Server listens to port
    static int serverPort = 7008;
    // Max no of parallel requests the server can process
    static int numServerCores = 50 ;         
    //------------ Main----------------------
    public static void main(String[] args) throws IOException 
    {    
        // Creating a thread pool
        ExecutorService executorService = Executors.newFixedThreadPool(numServerCores);
        
        try (//Creating a server socket to listen for clients
        ServerSocket serverSocket = new ServerSocket(serverPort)) {
            Socket socketConnection = null;
            
            // Always-ON server
            while(true)
            {
                System.out.println("Listening port : " + serverPort 
                                    + "\nWaiting for clients...");
                socketConnection = serverSocket.accept();   // Accept a connection from a client
                System.out.println("Accepted client :" 
                                    + socketConnection.getRemoteSocketAddress().toString() 
                                    + "\n");
                //  Create a runnable task
                Runnable runnableTask = new QueryRunner(socketConnection);
                //  Submit task for execution   
                executorService.submit(runnableTask);   
            }
        }
    }
}

