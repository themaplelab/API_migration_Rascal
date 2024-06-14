i=1
while [ $i -ne 2 ];
do

	cd /home/hewage/data/repositories/compiled-java-projects/undertow/java-project
	git checkout 6361a45412ad39de2efea5ac60168696b90b3a7d
        cd /home/hewage/data/experiments/scripts
       # ./undertowWrkRunnerNewMarch19.sh undertow-2024-03-20-50ms-new-$i 
        sleep 5s


	cd /home/hewage/data/repositories/compiled-java-projects/undertow/java-project
        git checkout 030f4375f8de88d293deb75d9bc04be38d241204
        cd /home/hewage/data/experiments/scripts
   #     ./undertowWrkRunnerNewMarch19.sh undertow-2024-03-20-100ms-$i
        sleep 5s

	cd /home/hewage/data/repositories/compiled-java-projects/undertow/java-project
        git checkout 087dd32f02ba69b8148a6c66db72c7c2786e772b
        cd /home/hewage/data/experiments/scripts
  #      ./undertowWrkRunnerNewMarch19.sh undertow-2024-03-20-200ms-$i
        sleep 5s

	cd /home/hewage/data/repositories/compiled-java-projects/undertow/java-project
        git checkout 7786595aa98cea12c52da703181d4fe2d42f6b0f
        cd /home/hewage/data/experiments/scripts
 #       ./undertowWrkRunnerNewMarch19.sh undertow-2024-03-20-500ms-$i
        sleep 5s

	cd /home/hewage/data/repositories/compiled-java-projects/undertow/java-project
        git checkout 52cd1fcc89abdb1353f93f03653dcdc6b8571ad0
        cd /home/hewage/data/experiments/scripts
        ./undertowWrkRunnerNewMarch19.sh undertow-2024-03-20-1000ms-$i
        sleep 5s

	cd /home/hewage/data/repositories/compiled-java-projects/undertow/java-project
        git checkout e4c389c20da5a68575e3e7cff0325f51bb8710c9
        cd /home/hewage/data/experiments/scripts
        #./undertowWrkRunnerNewMarch19.sh undertow-2024-03-20-1500ms-$i
        sleep 5s

	cd /home/hewage/data/repositories/compiled-java-projects/undertow/java-project
        git checkout ba74b42276ac52d033a4eb202b2aba7655e0887d
        cd /home/hewage/data/experiments/scripts
        #./undertowWrkRunnerNewMarch19.sh undertow-2024-03-20-2000ms-$i
        sleep 5s

	cd /home/hewage/data/repositories/compiled-java-projects/undertow/java-project
        git checkout e18a0efd60d95f3d68b3c72b361130d1f721f967
        cd /home/hewage/data/experiments/scripts
        #./undertowWrkRunnerNewMarch19.sh undertow-2024-03-20-2500ms-$i
        sleep 5s

	cd /home/hewage/data/repositories/compiled-java-projects/undertow/java-project
        git checkout e7cdc145cc43ba54c7def2c2bd082919956aec7f
        cd /home/hewage/data/experiments/scripts
        ./undertowWrkRunnerNewMarch19.sh undertow-2024-03-20-25ms-$i
        sleep 5s

        #sleep 5s


#	cd /home/hewage/data/repositories/undertow
      #  git checkout d24e1f778d74bcb6ab6abb0f1648dbe5ef0ce784
      #  mvn clean install -DskipTests
      #  cd /home/hewage/data/repositories/compiled-java-projects/undertow/java-project
      #  git checkout 70075c6c0b8152b88f697657e16a9dc0932dcd9b
      #  cd /home/hewage/data/experiments/scripts
      #  sleep 5s
      #  ./undertowWrkRunnerNew.sh undertow-2024-02-01-original-2s-10000-$i
      #  sleep 5s
      #  cd /home/hewage/data/repositories/undertow
      #  git checkout Nipuni_06_november
       # mvn clean install -DskipTests
       # cd /home/hewage/data/experiments/scripts
       # sleep 5s
       # ./undertowWrkRunnerNew.sh undertow-2024-02-01-transformed-2s-10000-$i
        #sleep 5s

	#cd /home/hewage/data/repositories/undertow
        #git checkout d24e1f778d74bcb6ab6abb0f1648dbe5ef0ce784
        #mvn clean install -DskipTests
        #cd /home/hewage/data/repositories/compiled-java-projects/undertow/java-project
        #git checkout 7279b1a747cd7b4afe2f199a6e6651645622f46b
        #cd /home/hewage/data/experiments/scripts
        #sleep 5s
        #sh undertowWrkRunnerNew.sh undertow-2024-01-30-test-original-1s-10000-$i
        #sleep 5s
	#cd /home/hewage/data/repositories/undertow
        #git checkout Nipuni_06_november
        #mvn clean install -DskipTests
        #cd /home/hewage/data/experiments/scripts
        #sleep 5s
        #sh  undertowWrkRunnerNew.sh undertow-2024-01-30-test-transformed-1s-10000-$i
        #sleep 5s
	
	echo "delayed application"

	
   
	i=$(($i+1))
done
