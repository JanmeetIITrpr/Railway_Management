package com.railway_management;

//import java.util.concurrent.executorService;
//import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

public class invokeWorkers implements Runnable
{
    /*************************/
    //  int secondLevelThreads = 3;//Logic.calcNumberOfThreads();
    
    /**************************/
    public invokeWorkers()            // Constructor to get arguments from the main thread
    {
       // Send args from main thread
    }

    //client.executorService client.executorService = Executors.newFixedThreadPool(secondLevelThreads) ;
    
    public void run()
    {
        for(int i=0; i < client.nothreads ; i++)
        {
            Runnable runnableTask = new sendQuery()  ;    //  Pass arg, if any to constructor sendQuery(arg)
            client.executorService.submit(runnableTask) ;
        }

        sendQuery s = new sendQuery();      // Send queries from current thread
        s.run();

        // Stop further requests to executor service
        client.executorService.shutdown()  ;
        try
        {
            // Wait for 8 sec and then exit the executor service
            if (!client.executorService.awaitTermination(8, TimeUnit.SECONDS))
            {
                client.executorService.shutdownNow();
            } 
        } 
        catch (InterruptedException e)
        {
            client.executorService.shutdownNow();
        }
    }
}
    
