mkdir /home/hewage/data/experiments/scripts/Data/tomcat/$1
i=1
while [ $i -ne 21 ];
do
        echo $i
	for PORT in 8085 8086
        do
		if [ $PORT -eq 8086 ]
		then 
        		cd /home/hewage/data/repositories/tomcat/output/build/bin 
		else 
			cd /home/hewage/data/repositories/transformed-tomcat/output/build/bin
		fi
        	killall -9 java
		export JAVA_TOOL_OPTIONS=--enable-preview
		export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
		ulimit -n 65535
		taskset -c 1,2,3 ./catalina.sh run  -Xms256m -Xmx1080m -Xloggc:/home/hewage/data/experiments/scripts/Data/tomcat/$1/gc-$i-$PORT.log > /home/hewage/data/experiments/scripts/Data/tomcat/$1/server_logs-$i-$PORT.txt 2>&1 &
		sleep 30s
		 echo "waiting for server..."
                sleep 30s

                j=1

                #sleep 10s
                process_id=$(ps aux | grep $PORT | grep 'java'  | head -1 | awk '{ printf $2 }')
                echo $process_id

                wrk_pid=$(ps aux | grep $PORT | grep wrk | head -1 | awk '{ printf $2 }')
                kill -9 $wrk_pid

		cd /home/hewage/data/experiments/scripts
		j=1
		process_id=$(ps aux | grep $PORT | grep 'java'  | head -1 | awk '{ printf $2 }')
                echo $process_id
		while [ $j -ne 3 ];
		do
			if [ $j -eq 2 ]
			then
                               
				echo "Real load starting ..."
                                cd /home/hewage/data/repositories
				./nmon_X86_Ubuntu23_16p -f -F /home/hewage/data/experiments/scripts/Data/tomcat/$1/$i-$PORT.nmon -s 1 -c 1800 -t &
                                jstack $process_id > /home/hewage/data/experiments/scripts/Data/tomcat/$1/thread_dump-$i-$PORT.txt &
				cd /home/hewage/data/experiments/scripts
				taskset -c 16,17,20,21 ./wrk -t30000 -c35000 -d180s --timeout 180s http://localhost:$PORT/java-project/hello > /home/hewage/data/experiments/scripts/Data/tomcat/$1/output-$i-$PORT-1.txt &
				pid1=$!
				taskset -c 18,19,22,23 ./wrk -t30000 -c35000 -d180s --timeout 180s http://localhost:$PORT/java-project/hello > /home/hewage/data/experiments/scripts/Data/tomcat/$1/output-$i-$PORT-2.txt &
				pid2=$!
				taskset -c 48,49,52,53 ./wrk -t30000 -c35000 -d180s --timeout 180s http://localhost:$PORT/java-project/hello > /home/hewage/data/experiments/scripts/Data/tomcat/$1/output-$i-$PORT-3.txt &
				pid3=$!
				taskset -c 50,51,54,55 ./wrk -t30000 -c35000 -d180s --timeout 180s http://localhost:$PORT/java-project/hello > /home/hewage/data/experiments/scripts/Data/tomcat/$1/output-$i-$PORT-4.txt &
				pid4=$!
				#taskset -c 20,21 ./wrk -t16000 -c16000 -d180s --timeout 180s http://localhost:$PORT/java-project/hello > /home/hewage/data/experiments/scripts/Data/tomcat/$1/output-$i-$PORT-5.txt &
                                #pid5=$!
                                #taskset -c 12,13 ./wrk -t16000 -c16000 -d180s --timeout 180s http://localhost:$PORT/java-project/hello > /home/hewage/data/experiments/scripts/Data/tomcat/$1/output-$i-$PORT-6.txt &
                                #pid6=$!
				#taskset -c 52,53 ./wrk -t16000 -c16000 -d180s --timeout 180s http://localhost:$PORT/java-project/hello > /home/hewage/data/experiments/scripts/Data/tomcat/$1/output-$i-$PORT-7.txt &
                                #pid7=$!
                                #taskset -c 44,45 ./wrk -t16000 -c16000 -d180s --timeout 180s http://localhost:$PORT/java-project/hello > /home/hewage/data/experiments/scripts/Data/tomcat/$1/output-$i-$PORT-8.txt &
                                #pid8=$!
				wait $pid1 $pid2 $pid3 $pid4  
				nmon_pid=$(ps aux | grep $PORT | grep $i-$PORT.nmon | head -1 | awk '{ printf $2 }')
                                kill -9 $nmon_pid
                                #kill -9 $dstat_pid
                                wrk_pid=$(ps aux | grep $PORT | grep wrk | head -1 | awk '{ printf $2 }')
                                kill -9 $wrk_pid
			else
				cd /home/hewage/data/repositories
				./nmon_X86_Ubuntu23_16p -f -F /home/hewage/data/experiments/scripts/Data/tomcat/$1/$i-$PORT-warmup.nmon -s 1 -c 1800 -t &
				
				cd /home/hewage/data/experiments/scripts
				taskset -c 16,17,20,21 ./wrk -t1500 -c2000 -d300s --timeout 300s http://localhost:$PORT/java-project/hello > /home/hewage/data/experiments/scripts/Data/tomcat/$1/warmup-$i-$PORT-1.txt &
				pid1=$!
				taskset -c 18,19,22,23 ./wrk -t1500 -c2000 -d300s --timeout 300s http://localhost:$PORT/java-project/hello > /home/hewage/data/experiments/scripts/Data/tomcat/$1/warmup-$i-$PORT-2.txt &
				pid2=$!
				taskset -c 48,49,52,53 ./wrk -t1500 -c2000 -d300s --timeout 300s http://localhost:$PORT/java-project/hello > /home/hewage/data/experiments/scripts/Data/tomcat/$1/warmup-$i-$PORT-3.txt &
                                pid3=$!
				taskset -c 50,51,54,55 ./wrk -t1500 -c2000 -d300s --timeout 300s http://localhost:$PORT/java-project/hello > /home/hewage/data/experiments/scripts/Data/tomcat/$1/warmup-$i-$PORT-4.txt &
                                pid4=$!
				#taskset -c 20,21 ./wrk -t10000 -c10000 -d300s --timeout 300s http://localhost:$PORT/java-project/hello > /home/hewage/data/experiments/scripts/Data/tomcat/$1/warmup-$i-$PORT-5.txt &
                                #pid5=$!
                                #taskset -c 12,13 ./wrk -t10000 -c10000 -d300s --timeout 300s http://localhost:$PORT/java-project/hello > /home/hewage/data/experiments/scripts/Data/tomcat/$1/warmup-$i-$PORT-6.txt &
                                #pid6=$!
                                #taskset -c 52,53 ./wrk -t10000 -c10000 -d300s --timeout 300s http://localhost:$PORT/java-project/hello > /home/hewage/data/experiments/scripts/Data/tomcat/$1/warmup-$i-$PORT-7.txt &
                                #pid7=$!
                                #taskset -c 44,45 ./wrk -t10000 -c10000 -d300s --timeout 300s http://localhost:$PORT/java-project/hello > /home/hewage/data/experiments/scripts/Data/tomcat/$1/warmup-$i-$PORT-8.txt &
                                #pid8=$!
				wait $pid1 $pid2 $pid3 $pid4 
				echo "Ending warmups ..."
				nmon_pid=$(ps aux | grep $PORT | grep $i-$PORT-warmup.nmon | head -1 | awk '{ printf $2 }')
                                kill -9 $nmon_pid
                                #kill -9 $dstat_pid
                                wrk_pid=$(ps aux | grep $PORT | grep wrk | head -1 | awk '{ printf $2 }')
                                kill -9 $wrk_pid
			fi
			j=$(($j+1))
		done
		nmon_pid=$(ps aux | grep $PORT | grep 'nmon' | head -1 | awk '{ printf $2 }')
                kill -9 $nmon_pid
		mv /tmp/gc.log /home/hewage/data/experiments/scripts/Data/tomcat/$1/gc-$i-$PORT.log
		if [ $PORT -eq 8086 ]
                then
                        cd /home/hewage/data/repositories/tomcat/output/build/bin
                else
                        cd /home/hewage/data/repositories/transformed-tomcat/output/build/bin
                fi
        	timeout 2m ./catalina.sh stop
        	sleep 20s
	done
	i=$(($i+1))
done
python3 /home/hewage/data/experiments/scripts/tomcatwrkParser.py $1
#python /home/hewage/data/experiments/scripts/wrk2_parser.py $1
