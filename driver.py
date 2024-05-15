#!/usr/bin/python3

import os
import logging 
from datetime import datetime
currentDateAndTime = datetime.now()
import glob


def main():
    cwd = os.getcwd()
    root_dir = 'D:/Alberta/Thesis/codebases/forked_tomcat/tomcat/'
    current_time = datetime.now()
    time_stamp = current_time.timestamp()
    print("startedTimestamp:-", time_stamp)
    listOfFiles = []
    #make recursive parameter False for tomcat
    #and removed base name is src and  ("/test/" not in filename) for tomcat, undertow, wildfly
    #we considered test folders in tomcat, undertow, wildfly, but not in Open Liberty; 
    #it does not matter for our experiments any how
    for filename in glob.iglob(root_dir + '**/**', recursive=True):
        try:
            if filename in listOfFiles:
                break
            listOfFiles.append(filename)
            if os.path.isdir(filename) and ("_fat" not in filename) and os.path.basename(filename) == "src":
                print(filename)
                input_dir = filename

                logging.info("Executing the migrations")

                os.system(f"java -Xmx4G -Xss1G -jar rascal-shell-stable.jar lang::java::transformations::MainProgram -path {input_dir}")

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

    ## formatting code
    os.chdir(root_dir)
    os.system(f"git config --global --add safe.directory '*' ")
    print("formatting code")

    os.system(f"git diff -U0 HEAD | python3 {cwd}/google-java-format-diff.py -p1 -i -a --google-java-format-jar {cwd}/google-java-format-1.17.0-all-deps.jar")

if __name__ == "__main__":
    main()


    
