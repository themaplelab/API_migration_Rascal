#!/usr/bin/python3

import os
import logging 
from datetime import datetime
currentDateAndTime = datetime.now()
import glob


def main():
    root_dir = 'D:/Alberta/Thesis/codebases/forked_tomcat/tomcat/'
    current_time = datetime.now()
    time_stamp = current_time.timestamp()
    print("startedTimestamp:-", time_stamp)
    listOfFiles = []
    for filename in glob.iglob(root_dir + '**/**', recursive=False):
        try:
            if filename in listOfFiles:
                break
            listOfFiles.append(filename)
            if os.path.isdir(filename) and ("_fat" not in filename) and ("/test/" not in filename) :
                print(filename)
                input_dir = filename

                logging.info("Executing the migrations")

                os.system(f"java -Xmx4G -Xss1G -jar rascal-shell-stable.jar lang::java::transformations::MainProgram -path {input_dir}")

                logging.info("Formatting the source code")
                logging.info("done")
        except FileNotFoundError:
            continue
    current_time1 = datetime.now()
  
    time_stamp1 = current_time1.timestamp()
    print("endedTimestamp:-", time_stamp1)
    c = current_time1-current_time 
    print('Difference: ', c)
    
    minutes = c.total_seconds() / 60
    print('Total difference in minutes: ', minutes)

if __name__ == "__main__":
    main()


    
