mkdir /home/hewage/data/experiments/scripts/Data/undertow/$1
i=1
while [ $i -ne 21 ];
do
        echo $i
        for PORT in 1 2
        do
		if [ $PORT -eq 1 ]
                then
			cd /home/hewage/data/repositories/undertow
        		git checkout d24e1f778d74bcb6ab6abb0f1648dbe5ef0ce784
        		mvn clean install -DskipTests
		else
 			cd /home/hewage/data/repositories/undertow
        		git checkout Nipuni_06_november
        		mvn clean install -DskipTests
		fi
		cd /home/hewage/data/repositories/compiled-java-projects/undertow/java-project
        	export JAVA_TOOL_OPTIONS=--enable-preview
		ulimit -n 65535
		#export MAVEN_OPTS="-Xms256m -Xmx1280m"
		
        	taskset -c 0,1,2,3,32,33,34,35,4,5,6,7,36,37,38,39,8,9,10,11,40,41,42,43,28,29  mvn spring-boot:run -Dspring-boot.run.jvmArguments="-Xms256m -Xmx1280m -Xloggc:/home/hewage/data/experiments/scripts/Data/undertow/$1/gc-$i-$PORT.log" > /home/hewage/data/experiments/scripts/Data/undertow/$1/server_logs-$i-$PORT-8098.txt 2>&1 &
		sleep 30s
		cd /home/hewage/data/experiments/scripts
		j=1
		process_id=$(ps aux | grep 'com.demo.nipuni.App'  | head -1 | awk '{ printf $2 }')
        	echo $process_id

        	wrk_pid=$(ps aux | grep $PORT | grep wrk | head -1 | awk '{ printf $2 }')
        	kill -9 $wrk_pid

        	cd /home/hewage/data/experiments/scripts
        
		process_id=$(ps aux | grep 'com.demo.nipuni.App' | head -1 | awk '{ printf $2 }')
		while [ $j -ne 3 ];
		do
			if [ $j -eq 2 ]
			then
				echo "Real load starting ..."
				cd /home/hewage/data/repositories
                        	./nmon_X86_Ubuntu23_16p -f -F /home/hewage/data/experiments/scripts/Data/undertow/$1/$i-$PORT.nmon -s 1 -c 1800 -t &
                        	jstack $process_id > /home/hewage/data/experiments/scripts/Data/undertow/$1/thread_dump-$i-$PORT.txt &
                        	cd /home/hewage/data/experiments/scripts
				#dstat -C 1,2 > /home/hewage/data/experiments/scripts/Data/undertow/$1/cpuInfo-$i.txt &
                        	#dstat_pid=$!
                        	taskset -c 16,17,24,62 ./wrk -t23000 -c25000 -d180s --timeout 180s http://localhost:8098/hello > /home/hewage/data/experiments/scripts/Data/undertow/$1/output-$i-$PORT-8098-1.txt &
                        	pid1=$!
				taskset -c 18,19,25,63 ./wrk -t23000 -c25000 -d180s --timeout 180s http://localhost:8098/hello > /home/hewage/data/experiments/scripts/Data/undertow/$1/output-$i-$PORT-8098-2.txt &
				pid2=$!
				taskset -c 48,49,26,12 ./wrk -t23000 -c25000 -d180s --timeout 180s http://localhost:8098/hello > /home/hewage/data/experiments/scripts/Data/undertow/$1/output-$i-$PORT-8098-3.txt &
                        	pid3=$!
                        	taskset -c 50,51,27,13 ./wrk -t23000 -c25000 -d180s --timeout 180s http://localhost:8098/hello > /home/hewage/data/experiments/scripts/Data/undertow/$1/output-$i-$PORT-8098-4.txt &
                        	pid4=$!
				taskset -c 20,21,56,14 ./wrk -t23000 -c25000 -d180s --timeout 180s http://localhost:8098/hello > /home/hewage/data/experiments/scripts/Data/undertow/$1/output-$i-$PORT-8098-5.txt &
                        	pid5=$!
                        	taskset -c 22,23,57,15 ./wrk -t23000 -c25000 -d180s --timeout 180s http://localhost:8098/hello > /home/hewage/data/experiments/scripts/Data/undertow/$1/output-$i-$PORT-8098-6.txt &
                        	pid6=$!
				taskset -c 52,53,58,44 ./wrk -t23000 -c25000 -d180s --timeout 180s http://localhost:8098/hello > /home/hewage/data/experiments/scripts/Data/undertow/$1/output-$i-$PORT-8098-7.txt &
                        	pid7=$!
                        	taskset -c 54,55,59,45 ./wrk -t23000 -c25000 -d180s --timeout 180s http://localhost:8098/hello > /home/hewage/data/experiments/scripts/Data/undertow/$1/output-$i-$PORT-8098-8.txt &
                        	pid8=$!
				#taskset -c 28,29,30,46 ./wrk -t22000 -c25000 -d180s --timeout 180s http://localhost:8098/hello > /home/hewage/data/experiments/scripts/Data/undertow/$1/output-$i-$PORT-8098-9.txt &
                        	#pid9=$!
				#taskset -c 31,60,61,47 ./wrk -t22000 -c25000 -d180s --timeout 180s http://localhost:8098/hello > /home/hewage/data/experiments/scripts/Data/undertow/$1/output-$i-$PORT-8098-10.txt &
                        	#pid10=$!
				#taskset -c 8,9,10,11 ./wrk -t22000 -c25000 -d180s --timeout 180s http://localhost:8098/hello > /home/hewage/data/experiments/scripts/Data/undertow/$1/output-$i-$PORT-8098-11.txt &
                                #pid11=$!
				#taskset -c 40,41,42,43 ./wrk -t22000 -c25000 -d180s --timeout 180s http://localhost:8098/hello > /home/hewage/data/experiments/scripts/Data/undertow/$1/output-$i-$PORT-8098-12.txt &
                                #pid12=$!
				wait $pid1 $pid2 $pid3 $pid4 $pid5 $pid6 $pid7 $pid8 
				#kill -9 $dstat_pid
				nmon_pid=$(ps aux | grep 'nmon' | head -1 | awk '{ printf $2 }')
                        	kill -9 $nmon_pid
                        	#wrk_pid=$(ps aux | grep 1234 | grep wrk | head -1 | awk '{ printf $2 }')
                        	#kill -9 $wrk_pid
                        	ps aux | grep wrk | grep -v grep | awk '{print $2}' | xargs -r kill -9
			else
				cd /home/hewage/data/repositories
				./nmon_X86_Ubuntu23_16p -f -F /home/hewage/data/experiments/scripts/Data/undertow/$1/warmup-$i-$PORT.nmon -s 1 -c 1800 -t &
				cd /home/hewage/data/experiments/scripts
				taskset -c 16,17,24,62 ./wrk -t1000 -c2000 -d300s --timeout 300s http://localhost:8098/hello > /home/hewage/data/experiments/scripts/Data/undertow/$1/warmup-$i-$PORT-8098-1.txt &
				pid1=$!
				taskset -c 18,19,25,63 ./wrk -t1000 -c2000 -d300s --timeout 300s http://localhost:8098/hello > /home/hewage/data/experiments/scripts/Data/undertow/$1/warmup-$i-$PORT-8098-2.txt &
				pid2=$!
				taskset -c 48,49,26,12 ./wrk -t1000 -c2000 -d300s --timeout 300s http://localhost:8098/hello > /home/hewage/data/experiments/scripts/Data/undertow/$1/warmup-$i-$PORT-8098-3.txt &
                        	pid3=$!
                        	taskset -c 50,51,27,13 ./wrk -t1000 -c2000 -d300s --timeout 300s http://localhost:8098/hello > /home/hewage/data/experiments/scripts/Data/undertow/$1/warmup-$i-$PORT-8098-4.txt &
                        	pid4=$!
				taskset -c 20,21,56,14 ./wrk -t1000 -c2000 -d300s --timeout 300s http://localhost:8098/hello > /home/hewage/data/experiments/scripts/Data/undertow/$1/warmup-$i-$PORT-8098-5.txt &
                        	pid5=$!
                        	taskset -c 22,23,57,15 ./wrk -t1000 -c2000 -d300s --timeout 300s http://localhost:8098/hello > /home/hewage/data/experiments/scripts/Data/undertow/$1/warmup-$i-$PORT-8098-6.txt &
                        	pid6=$!
				taskset -c 52,53,58,44 ./wrk -t1000 -c2000 -d300s --timeout 300s http://localhost:8098/hello > /home/hewage/data/experiments/scripts/Data/undertow/$1/warmup-$i-$PORT-8098-7.txt &
                        	pid7=$!
                        	taskset -c 54,55,59,45 ./wrk -t1000 -c2000 -d300s --timeout 300s http://localhost:8098/hello > /home/hewage/data/experiments/scripts/Data/undertow/$1/warmup-$i-$PORT-8098-8.txt &
                        	pid8=$!
				#taskset -c 28,29,30,46 ./wrk -t1000 -c2000 -d300s --timeout 300s http://localhost:8098/hello > /home/hewage/data/experiments/scripts/Data/undertow/$1/warmup-$i-$PORT-8098-9.txt &
                        	#pid9=$!
                        	#taskset -c 31,60,61,47 ./wrk -t1000 -c2000 -d300s --timeout 300s http://localhost:8098/hello > /home/hewage/data/experiments/scripts/Data/undertow/$1/warmup-$i-$PORT-8098-10.txt &
                        	#pid10=$!
				#taskset -c 8,9,10,11 ./wrk -t1000 -c2000 -d300s --timeout 300s http://localhost:8098/hello > /home/hewage/data/experiments/scripts/Data/undertow/$1/warmup-$i-$PORT-8098-11.txt &
                                #pid11=$!
                                #taskset -c 40,41,42,43 ./wrk -t1000 -c2000 -d300s --timeout 300s http://localhost:8098/hello > /home/hewage/data/experiments/scripts/Data/undertow/$1/warmup-$i-$PORT-8098-12.txt &
                                #pid12=$!
                        	#pid2=$!
				wait $pid1 $pid2 $pid3 $pid4 $pid5 $pid6 $pid7 $pid8 
				echo "Ending warmups ..."
                        	nmon_pid=$(ps aux | grep 'nmon' | head -1 | awk '{ printf $2 }')
                        	kill -9 $nmon_pid                                                                                                                    ps aux | grep wrk | grep -v grep | awk '{print $2}' | xargs -r kill -9
			fi
			j=$(($j+1))
		done
		nmon_pid=$(ps aux | grep 'nmon' | head -1 | awk '{ printf $2 }')
        	kill -9 $nmon_pid
        	ps aux | grep wrk | grep -v grep | awk '{print $2}' | xargs -r kill -9
		#sleep 10s
        	#curl -X POST http://localhost:8092/actuator/shutdown
        	kill -9 $process_id
		#sleep 10s
	done
	i=$(($i+1))
	
done
python3 /home/hewage/data/experiments/scripts/wrk_parser.py $1
#python /home/hewage/data/experiments/scripts/wrk2_parser.py $1
