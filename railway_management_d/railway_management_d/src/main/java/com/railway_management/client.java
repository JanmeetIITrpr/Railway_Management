package com.railway_management;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.concurrent.ExecutorService ;
import java.util.concurrent.Executors   ;
import java.util.concurrent.TimeUnit;
import java.io.File;
import java.io.IOException  ;

public class client
{
    static int nothreads= Runtime.getRuntime().availableProcessors();
    static ExecutorService executorService = Executors.newFixedThreadPool(nothreads);
    public static ArrayList<String> files = new ArrayList<String>(new File("C:\\Users\\janme\\Music\\railway_management\\Input\\").list().length);
    public static void main(String args[])throws IOException
    {
        /**************************/
        // int firstLevelThreads = 3;//Logic.calcNumberOfThreads();   // Indicate no of users 
        /**************************/
        // Creating a thread pool
        //ExecutorService executorService = Executors.newFixedThreadPool(firstLevelThreads);
        files.addAll(Arrays.asList(new File("C:\\Users\\janme\\Music\\railway_management\\Input\\").list()));
        
        for(int i = 0; i < nothreads; i++)
        {
            Runnable runnableTask = new invokeWorkers();    //  Pass arg, if any to constructor sendQuery(arg)
            executorService.submit(runnableTask) ;
        }

        //executorService.shutdown();
        try
        {    // Wait for 8 sec and then exit the executor service
            if (!executorService.awaitTermination(8, TimeUnit.SECONDS))
            {
                executorService.shutdownNow();
            } 
        } 
        catch (InterruptedException e)
        {
            executorService.shutdownNow();
        }
    }
}