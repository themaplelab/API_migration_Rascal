mkdir /home/hewage/data/experiments/scripts/Data/$1
delay=$2
i=11
while [ $i -ne 21 ];
do
        echo $i
	for PORT in 9092 9093
	do
		#cd /home/hewage/data/repositories
        	#./nmon_X86_Ubuntu23_16p -f -F /home/hewage/data/experiments/scripts/Data/$1/$i-$PORT.nmon -s 15 -c 6000 -t &
		if [ $PORT -eq 9093 ]
		then
        		cd /home/hewage/data/experiments/scenario_latest_original_2024/wlp/bin
		else
			cd /home/hewage/data/experiments/scenario_all_2024_06_07_NEW6/wlp/bin
		fi
		killall -9 java
		#export JAVA_HOME=/usr/lib/jvm/jdk-19.0.2
        	#export JAVA_TOOL_OPTIONS=--enable-preview -XX:BindGCTaskThreadsToCPUs=1,2
		
		export JAVA_TOOL_OPTIONS=--enable-preview
		
		ulimit -n 65535

		taskset -c 2-3 ./server run test  -Xms256m -Xmx2560m -Xlog:gc:/home/hewage/data/experiments/scripts/Data/$1/gc-$i-$PORT.log > /home/hewage/data/experiments/scripts/Data/$1/server_logs-$i-$PORT.txt 2>&1 &
		
		echo "waiting for server..."
		sleep 30s
		
		j=1

		#sleep 10s
		process_id=$(ps aux | grep $PORT | grep 'java'  | head -1 | awk '{ printf $2 }')
		echo $process_id

		wrk_pid=$(ps aux | grep $PORT | grep wrk | head -1 | awk '{ printf $2 }')
                kill -9 $wrk_pid
		
		#./nmon_X86_Ubuntu23_16p -f -F /home/hewage/data/experiments/scripts/Data/$1/$i-$PORT-Full.nmon -s 1 -c 1800 -t &
		while [ $j -ne 3 ];
		do
			if [ $j -eq 2 ]
			then 	
				echo "Real load starting ..."
				process_id=$(ps aux | grep $PORT | grep 'java'  | head -1 | awk '{ printf $2 }')
                		echo $process_id
				cd /home/hewage/data/repositories
				./nmon_X86_Ubuntu23_16p -f -F /home/hewage/data/experiments/scripts/Data/$1/$i-$PORT.nmon -s 1 -c 1800 -t &
				jstack $process_id > /home/hewage/data/experiments/scripts/Data/$1/thread_dump-$i-$PORT.txt &
				#sleep 10s
				cd /home/hewage/data/experiments/scripts
				multiple=$((delay / 50))
				echo $multiple
				threads=$((300 * multiple))
				echo $threads
				taskset -c 17-18 ./wrk -t$threads -c$threads -d180s --timeout 180s http://localhost:$PORT/hello > /home/hewage/data/experiments/scripts/Data/$1/output-$i-$PORT-1.txt 
				nmon_pid=$(ps aux | grep $PORT | grep $i-$PORT.nmon | head -1 | awk '{ printf $2 }')
				kill -9 $nmon_pid
				#kill -9 $dstat_pid
				wrk_pid=$(ps aux | grep $PORT | grep wrk | head -1 | awk '{ printf $2 }')
                                kill -9 $wrk_pid
			else
				cd /home/hewage/data/repositories
				./nmon_X86_Ubuntu23_16p -f -F /home/hewage/data/experiments/scripts/Data/$1/$i-$PORT-warmup.nmon -s 1 -c 1800 -t &
				cd /home/hewage/data/experiments/scripts
				multiple=$((delay / 50))
				threads=$((150 * multiple))
				taskset -c 17-18 ./wrk -t$threads -c$threads -d300s --timeout 300s http://localhost:$PORT/hello > /home/hewage/data/experiments/scripts/Data/$1/warmup-$i-$PORT-1.txt
				echo "Ending warmups ..."
				#sleep 60s
				nmon_pid=$(ps aux | grep $PORT | grep $i-$PORT-warmup.nmon | head -1 | awk '{ printf $2 }')
				kill -9 $nmon_pid
				wrk_pid=$(ps aux | grep $PORT | grep wrk | head -1 | awk '{ printf $2 }')
				kill -9 $wrk_pid
			fi
			j=$(($j+1))
		done
		nmon_pid=$(ps aux | grep $PORT | grep 'nmon' | head -1 | awk '{ printf $2 }')
		kill -9 $nmon_pid
		if [ $PORT -eq 9093 ]
		then
			cd /home/hewage/data/experiments/scenario_latest_original_2024/wlp/bin
		else
		        cd /home/hewage/data/experiments/scenario_all_2024_06_07_NEW6/wlp/bin
		fi
		timeout 2m ./server stop test
        	sleep 30s	
		if [ $PORT -eq 9093 ]
		then 
			cp -r /home/hewage/data/experiments/scenario_latest_original_2024/wlp/usr/servers/test /home/hewage/data/experiments/scenario_latest_original_2024/wlp/usr/servers/test2
			rm -r /home/hewage/data/experiments/scenario_latest_original_2024/wlp/usr/servers/test
			mv /home/hewage/data/experiments/scenario_latest_original_2024/wlp/usr/servers/test2 /home/hewage/data/experiments/scenario_latest_original_2024/wlp/usr/servers/test
			kill $(lsof -t -i:9093)
			kill $(lsof -t -i:9443)
		else
			cp -r /home/hewage/data/experiments/scenario_all_2024_06_07_NEW6/wlp/usr/servers/test /home/hewage/data/experiments/scenario_all_2024_06_07_NEW6/wlp/usr/servers/test2
			rm -r /home/hewage/data/experiments/scenario_all_2024_06_07_NEW6/wlp/usr/servers/test
			mv /home/hewage/data/experiments/scenario_all_2024_06_07_NEW6/wlp/usr/servers/test2 /home/hewage/data/experiments/scenario_all_2024_06_07_NEW6/wlp/usr/servers/test
			kill $(lsof -t -i:9092)
			kill $(lsof -t -i:9442)
		fi
	done
	i=$(($i+1))
done
#python3 /home/hewage/data/experiments/scripts/wrk_parser.py $1
#python /home/hewage/data/experiments/scripts/wrk2_parser.py $1
