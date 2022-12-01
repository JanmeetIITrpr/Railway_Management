package com.railway_management;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

public class invokeWorkers implements Runnable
{
    /*************************/
    int firstLevelThreads;
     int secondLevelThreads = 8;
    /**************************/
    public invokeWorkers(int firstLevelThreads)            // Constructor to get arguments from the main thread
    {
        this.firstLevelThreads = firstLevelThreads;
       // Send args from main thread
    }

    ExecutorService executorService = Executors.newFixedThreadPool(secondLevelThreads) ;
    
    public void run()
    {
        for(int i=0; i < secondLevelThreads ; i++)
        {
            Runnable runnableTask = new sendQuery(firstLevelThreads, i+1)  ;    //  Pass arg, if any to constructor sendQuery(arg)
            executorService.submit(runnableTask) ;
        }

        // sendQuery s = new sendQuery();      // Send queries from current thread
        // s.run();

        // Stop further requests to executor service
        executorService.shutdown()  ;
        try
        {
            // Wait for 8 sec and then exit the executor service
            if (!executorService.awaitTermination(11, TimeUnit.SECONDS))
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
    
