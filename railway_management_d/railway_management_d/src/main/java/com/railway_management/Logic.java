package com.railway_management;

import java.io.File;

public class Logic {
    public static int calcNumberOfThreads() {
        int fileCount = new File("C:\\Users\\Lenovo\\Downloads\\final_locking_railway_management\\railway_management\\Input\\").list().length;
        int threadCount = ((int)Math.sqrt(1 + (4 * fileCount)) - 1)/2;
        return threadCount;
    }

    public static void main(String[] args) {
      System.out.println(Runtime.getRuntime().availableProcessors());
    }
}
