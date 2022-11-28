package com.railway_management;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.net.Socket;
import java.util.Scanner;
import java.util.concurrent.TimeUnit;
//import java.security.SecureRandom;

class sendQuery implements Runnable 
{   /**********************/
     int sockPort = 7008 ;
    /*********************/
    sendQuery()
    {
     // Red args if any
    }   
    @Override
    public void run()
    {
        try 
        {
            while(client.files.size() > 0) {
              //Creating a client socket to send query requests
              Socket socketConnection = new Socket("localhost", sockPort) ;
              //SecureRandom rand = new SecureRandom();
              
              // Files for input queries and responses
              String fileName = client.files.get((int) Math.random() * client.files.size());
              client.files.remove(fileName);
              //client.files.remove("pool-1-thread-1_input.txt");
              try
                {
                    Thread.sleep(2000);
                }
                catch(InterruptedException ex)
                {
                    Thread.currentThread().interrupt();
                }
              fileName = fileName.substring(0, fileName.length() - 10);
              String inputfile = "C:\\Users\\janme\\Music\\railway_management\\Input\\" + fileName + "_input.txt" ;
              String outputfile = "C:\\Users\\janme\\Music\\railway_management\\Output\\" + fileName + "_output.txt" ;

              //-----Initialising the Input & ouput file-streams and buffers-------
              OutputStreamWriter outputStream = new OutputStreamWriter(socketConnection
                                                                      .getOutputStream());
              BufferedWriter bufferedOutput = new BufferedWriter(outputStream);
              InputStreamReader inputStream = new InputStreamReader(socketConnection
                                                                    .getInputStream());
              BufferedReader bufferedInput = new BufferedReader(inputStream);
              PrintWriter printWriter = new PrintWriter(bufferedOutput,true);
              File queries = new File(inputfile); 
              File output = new File(outputfile); 
              FileWriter filewriter = new FileWriter(output);
              Scanner queryScanner = new Scanner(queries);
              String query = "";
              //--------------------------------------------------------------------

              // Read input queries and write to the output stream
              while(queryScanner.hasNextLine())
              {
                  query = queryScanner.nextLine();
                  printWriter.println(query);
              }

              System.out.println("Query sent from " + fileName);

              // Get query responses from the input end of the socket of client
              String result;
              while( (result = bufferedInput.readLine()) != null)
              {
                  filewriter.write(result + "\n");
              }    
              // close the buffers and socket
              filewriter.close();
              queryScanner.close();
              printWriter.close();
              socketConnection.close();
            }
        } 
        catch (IOException e1)
        {
            e1.printStackTrace();
        }   
    }
}