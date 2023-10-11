#!/usr/bin/python3

import sys, os, getopt
import logging 
# import git
from datetime import datetime
# import pomMigration
import pathlib
currentDateAndTime = datetime.now()
import glob


usage = 'migrate.py -i <input_dir> '
branch = 'junit5-migration'


def main(argv):
    cwd = os.getcwd()
    # path to the directory with thread usages
    # D:/Alberta/Thesis/forked_openliberty/open-liberty/dev/com.ibm.ws.channelfw/src
    # D:/Alberta/Thesis/forked_openliberty/open-liberty/dev/io.openliberty.org.jboss.resteasy.mprestclient/src
    root_dir = 'D:/Alberta/Thesis/forked_openliberty/open-liberty/dev/'

    for filename in glob.iglob(root_dir + '**/**', recursive=True):
        try:
            if os.path.isdir(filename) and ("_fat" not in filename) and os.path.basename(filename) == "src":
                print(filename)
                input_dir = filename
                max_files = '0'

                logging.info("Executing the migrations")
                currentTime = currentDateAndTime.strftime("%y%m%d%H%M%S")

                os.system(f"java -Xmx4G -Xss1G -jar rascal-shell-stable.jar lang::java::transformations::junit::MainProgram -path {input_dir}")

                logging.info("Formatting the source code")

                
                logging.info("done")
        except FileNotFoundError:
            continue
    # input_dir = 'D:/Alberta/Thesis/forked_openliberty/open-liberty/dev/com.ibm.ws.install/src'
    # max_files = '0'

    # logging.info("Executing the migrations")
    # currentTime = currentDateAndTime.strftime("%y%m%d%H%M%S")

    # os.system(f"java -Xmx4G -Xss1G -jar rascal-shell-stable.jar lang::java::transformations::junit::MainProgram -path {input_dir}")
if __name__ == "__main__":
    main(sys.argv[1:])


    
