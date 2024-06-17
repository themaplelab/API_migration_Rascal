mkdir /home/data/experiments/scripts/Data/wildfly/$1
i=1
while [ $i -ne 21 ];
do
        echo $i
        for PORT in 2 1 
        do
                if [ $PORT -eq 1 ]
		then
			cd /home/data/repositories/wildfly/build/target/wildfly-31.0.0.Beta1-SNAPSHOT/bin 
		else
		        cd /home/data/repositories/transformedWildfl/wildfly/build/target/wildfly-31.0.0.Beta1-SNAPSHOT/bin
		fi	
		killall -9 java
        	export JAVA_TOOL_OPTIONS=--enable-preview
		#export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
		ulimit -n 65535        
		taskset -c 0,1,2,3,32,33,34,35,4,5,6,7,36,37,38,39 ./standalone.sh -Djboss.http.port=1234 > /home/data/experiments/scripts/Data/wildfly/$1/server_logs-$i-$PORT.txt 2>&1 &
		sleep 30s
		cd /home/data/experiments/scripts
		j=1
		
		process_id=$(ps aux | grep 1234 | grep 'java'  | head -1 | awk '{ printf $2 }')
                echo $process_id
		
		wrk_pid=$(ps aux | grep $PORT | grep wrk | head -1 | awk '{ printf $2 }')
                kill -9 $wrk_pid

		ps aux | grep wrk | grep -v grep | awk '{print $2}' | xargs -r kill -9

		#process_id=$(ps aux | grep $PORT | grep 'java'  | head -1 | awk '{ printf $2 }')
                #echo $process_id

		while [ $j -ne 3 ];
		do
			if [ $j -eq 2 ]
			then
				echo "Real load starting ..."
                                cd /home/data/repositories
                                ./nmon_X86_Ubuntu23_16p -f -F /home/data/experiments/scripts/Data/wildfly/$1/$i-$PORT.nmon -s 1 -c 1800 -t &
                                jstack $process_id > /home/data/experiments/scripts/Data/wildfly/$1/thread_dump-$i-$PORT.txt &
                                cd /home/data/experiments/scripts	
                        	taskset -c 16,17,24 ./wrk -t22000 -c25000 -d180s --timeout 180s http://localhost:1234/hello > /home/data/experiments/scripts/Data/wildfly/$1/output-$i-$PORT-1.txt &
				pid1=$!				
				taskset -c 18,19,25 ./wrk -t22000 -c25000 -d180s --timeout 180s http://localhost:1234/hello > /home/data/experiments/scripts/Data/wildfly/$1/output-$i-$PORT-2.txt &
				pid2=$!
				taskset -c 48,49,26 ./wrk -t22000 -c25000 -d180s --timeout 180s http://localhost:1234/hello > /home/data/experiments/scripts/Data/wildfly/$1/output-$i-$PORT-3.txt &
				pid3=$!
				taskset -c 50,51,27 ./wrk -t22000 -c25000 -d180s --timeout 180s http://localhost:1234/hello > /home/data/experiments/scripts/Data/wildfly/$1/output-$i-$PORT-4.txt &
				pid4=$!
				taskset -c 20,21,56 ./wrk -t22000 -c25000 -d180s --timeout 180s http://localhost:1234/hello > /home/data/experiments/scripts/Data/wildfly/$1/output-$i-$PORT-5.txt &
                                pid5=$!
                                taskset -c 22,23,57 ./wrk -t22000 -c25000 -d180s --timeout 180s http://localhost:1234/hello > /home/data/experiments/scripts/Data/wildfly/$1/output-$i-$PORT-6.txt &
                                pid6=$!
                                taskset -c 52,53,58 ./wrk -t22000 -c25000 -d180s --timeout 180s http://localhost:1234/hello > /home/data/experiments/scripts/Data/wildfly/$1/output-$i-$PORT-7.txt &
                                pid7=$!
                                taskset -c 54,55,59 ./wrk -t22000 -c25000 -d180s --timeout 180s http://localhost:1234/hello > /home/data/experiments/scripts/Data/wildfly/$1/output-$i-$PORT-8.txt &
                                pid8=$!
				taskset -c 28,29,30 ./wrk -t22000 -c25000 -d180s --timeout 180s http://localhost:1234/hello > /home/data/experiments/scripts/Data/wildfly/$1/output-$i-$PORT-9.txt &
                                pid9=$!
				taskset -c 31,60,61 ./wrk -t22000 -c25000 -d180s --timeout 180s http://localhost:1234/hello > /home/data/experiments/scripts/Data/wildfly/$1/output-$i-$PORT-10.txt &
                                pid10=$!
				#taskset -c 12,13,62 ./wrk -t24000 -c25000 -d180s --timeout 180s http://localhost:1234/hello > /home/data/experiments/scripts/Data/wildfly/$1/output-$i-$PORT-11.txt &
                                #pid11=$!
				#taskset -c 14,15,63 ./wrk -t24000 -c25000 -d180s --timeout 180s http://localhost:1234/hello > /home/data/experiments/scripts/Data/wildfly/$1/output-$i-$PORT-12.txt &
                                #pid12=$!
				wait $pid1 $pid2 $pid3 $pid4 $pid5 $pid6 $pid7 $pid8 $pid9 $pid10 
				nmon_pid=$(ps aux | grep $PORT | grep 'nmon' | head -1 | awk '{ printf $2 }')
                                kill -9 $nmon_pid
				#wrk_pid=$(ps aux | grep 1234 | grep wrk | head -1 | awk '{ printf $2 }')
                                #kill -9 $wrk_pid
				ps aux | grep wrk | grep -v grep | awk '{print $2}' | xargs -r kill -9
			else
				cd /home/data/repositories
                                ./nmon_X86_Ubuntu23_16p -f -F /home/data/experiments/scripts/Data/wildfly/$1/$i-$PORT-warmup.nmon -s 1 -c 1800 -t &

                                cd /home/data/experiments/scripts
				taskset -c 16,17,24 ./wrk -t1000 -c1000 -d300s --timeout 300s http://localhost:1234/hello > /home/data/experiments/scripts/Data/wildfly/$1/warmup-$i-$PORT-1.txt &
				pid1=$!
                                taskset -c 18,19,25 ./wrk -t1000 -c1000 -d300s --timeout 300s http://localhost:1234/hello > /home/data/experiments/scripts/Data/wildfly/$1/warmup-$i-$PORT-2.txt &
				pid2=$!
				taskset -c 48,49,26 ./wrk -t1000 -c1000 -d300s --timeout 300s http://localhost:1234/hello > /home/data/experiments/scripts/Data/wildfly/$1/warmup-$i-$PORT-3.txt &
				pid3=$!
				taskset -c 50,51,27 ./wrk -t1000 -c1000 -d300s --timeout 300s http://localhost:1234/hello > /home/data/experiments/scripts/Data/wildfly/$1/warmup-$i-$PORT-4.txt &
				pid4=$!
				taskset -c 20,21,56 ./wrk -t1000 -c1000 -d300s --timeout 300s http://localhost:1234/hello > /home/data/experiments/scripts/Data/wildfly/$1/warmup-$i-$PORT-5.txt &
                                pid5=$!
                                taskset -c 22,23,57 ./wrk -t1000 -c1000 -d300s --timeout 300s http://localhost:1234/hello > /home/data/experiments/scripts/Data/wildfly/$1/warmup-$i-$PORT-6.txt &
                                pid6=$!
                                taskset -c 52,53,58 ./wrk -t1000 -c1000 -d300s --timeout 300s http://localhost:1234/hello > /home/data/experiments/scripts/Data/wildfly/$1/warmup-$i-$PORT-7.txt &
                                pid7=$!
                                taskset -c 54,55,59 ./wrk -t1000 -c1000 -d300s --timeout 300s http://localhost:1234/hello > /home/data/experiments/scripts/Data/wildfly/$1/warmup-$i-$PORT-8.txt &
                                pid8=$!
				taskset -c 28,29,30 ./wrk -t1000 -c1000 -d300s --timeout 300s http://localhost:1234/hello > /home/data/experiments/scripts/Data/wildfly/$1/warmup-$i-$PORT-9.txt &
                                pid9=$!
                                taskset -c 31,60,61 ./wrk -t1000 -c1000 -d300s --timeout 300s http://localhost:1234/hello > /home/data/experiments/scripts/Data/wildfly/$1/warmup-$i-$PORT-10.txt &
                                pid10=$!
				#taskset -c 12,13,62 ./wrk -t15000 -c15000 -d300s --timeout 300s http://localhost:1234/hello > /home/data/experiments/scripts/Data/wildfly/$1/warmup-$i-$PORT-11.txt &
                                #pid11=$!
				#taskset -c 14,15,63 ./wrk -t15000 -c15000 -d300s --timeout 300s http://localhost:1234/hello > /home/data/experiments/scripts/Data/wildfly/$1/warmup-$i-$PORT-12.txt &
                                #pid12=$!
				wait $pid1 $pid2 $pid3 $pid4 $pid5 $pid6 $pid7 $pid8 $pid9 $pid10 
				echo "Ending warmups ..."
                                nmon_pid=$(ps aux | grep $PORT | grep 'nmon' | head -1 | awk '{ printf $2 }')
                                kill -9 $nmon_pid
				ps aux | grep wrk | grep -v grep | awk '{print $2}' | xargs -r kill -9
                                #wrk_pid=$(ps aux | grep 1234 | grep wrk | head -1 | awk '{ printf $2 }')
                                #kill -9 $wrk_pid 
				#sleep 30s
                        	
			fi
			j=$(($j+1))
		done
		nmon_pid=$(ps aux | grep $PORT | grep 'nmon' | head -1 | awk '{ printf $2 }')
                kill -9 $nmon_pid
	 	ps aux | grep wrk | grep -v grep | awk '{print $2}' | xargs -r kill -9
		mv /home/data/experiments/scripts/Data/wildfly/gc_logs.log /home/data/experiments/scripts/Data/wildfly/$1/gc-$i-$PORT.log
		if [ $PORT -eq 1 ]
                then
			#rm /home/data/repositories/wildfly/build/target/wildfly-31.0.0.Beta1-SNAPSHOT/standalone/deployments/*.war.deployed
			#rm -rf /home/data/repositories/wildfly/build/target/wildfly-31.0.0.Beta1-SNAPSHOT/standalone/tmp/*

                        cd /home/data/repositories/wildfly/build/target/wildfly-31.0.0.Beta1-SNAPSHOT/bin
                else
			#rm /home/data/repositories/transformedWildfl/wildfly/build/target/wildfly-31.0.0.Beta1-SNAPSHOT/standalone/deployments/*.war.deployed
			#rm -rf /home/data/repositories/transformedWildfl/wildfly/build/target/wildfly-31.0.0.Beta1-SNAPSHOT/standalone/tmp/*
                        cd /home/data/repositories/transformedWildfl/wildfly/build/target/wildfly-31.0.0.Beta1-SNAPSHOT/bin
                fi
		./jboss-cli.sh -c --commands=":shutdown"
		sleep 30s
		#killall -9 java
		rm /home/data/repositories/wildfly/build/target/wildfly-31.0.0.Beta1-SNAPSHOT/standalone/deployments/*.war.deployed
		rm /home/data/repositories/transformedWildfl/wildfly/build/target/wildfly-31.0.0.Beta1-SNAPSHOT/standalone/deployments/*.war.deployed
		kill $(lsof -t -i:1234)
	done
	i=$(($i+1))
done
python3 /home/data/experiments/scripts/wildfly_wrk_parser.py $1
#python /home/data/experiments/scripts/wrk2_parser.py $1
