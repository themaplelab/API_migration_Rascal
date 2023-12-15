#!/usr/bin/python3

import sys, os
import logging 
from datetime import datetime
currentDateAndTime = datetime.now()
import glob

def main():
    # path to the directory with thread usages
    # D:/Alberta/Thesis/forked_openliberty/open-liberty/dev/com.ibm.ws.channelfw/src
    # D:/Alberta/Thesis/forked_openliberty/open-liberty/dev/io.openliberty.org.jboss.resteasy.mprestclient/src
    root_dir = 'D:/Alberta/Thesis/forked_openliberty/open-liberty/dev/'


    current_time = datetime.now()
  
    time_stamp = current_time.timestamp()
    print("startedTimestamp:-", time_stamp)
    listOfFiles = []
    for filename in glob.iglob(root_dir + '**/**', recursive=True):
        try:
            if filename in listOfFiles:
                break
            listOfFiles.append(filename)
            if os.path.isdir(filename) and ("_fat" not in filename) and ("/test/" not in filename) and os.path.basename(filename) == "src":
                print(filename)
                input_dir = filename

                logging.info("Executing the migrations")

                os.system(f"java -Xmx4G -Xss1G -jar rascal-shell-stable.jar lang::java::transformations::junit::MainProgram -path {input_dir}")

                logging.info("Formatting the source code")
                logging.info("done")
        except FileNotFoundError:
            continue
    current_time1 = datetime.now()
  
    time_stamp1 = current_time1.timestamp()
    print("endedTimestamp:-", time_stamp1)
    c = time_stamp1-time_stamp 
    print('Difference: ', c)
    
    minutes = (current_time1 - current_time).total_seconds() / 60
    print('Total difference in minutes: ', minutes)
    
if __name__ == "__main__":
    main()


    
