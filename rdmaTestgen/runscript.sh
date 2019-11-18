#!/bin/bash -l



java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 4  -p 2  -w1 lw -w2 lw ../model/test_consistency_rule1.als 2>&1 | tee out_r1_1.out& 
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 4  -p 2  -w1 lw -w2 u ../model/test_consistency_rule1.als 2>&1 | tee out_r1_2.out&  
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 4  -p 2  -w1 u -w2 lw ../model/test_consistency_rule1.als 2>&1 | tee out_r1_3.out&  
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 4  -p 2  -w1 u -w2 u ../model/test_consistency_rule1.als 2>&1 | tee out_r1_4.out&  
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 8  -p 2  -w1 u -w2 nwp ../model/test_consistency_rule1.als 2>&1 | tee out_r1_5.out&  
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 8  -p 2  -w1 lw -w2 nwp ../model/test_consistency_rule1.als 2>&1 | tee out_r1_6.out&  
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 10  -p 2  -w1 nrwpq -w2 u ../model/test_consistency_rule1.als 2>&1 | tee out_r1_7.out&  
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 10  -p 2  -w1 nrwpq -w2 lw ../model/test_consistency_rule1.als 2>&1 | tee out_r1_8.out&  
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 10  -p 2  -w1 nwp -w2 u ../model/test_consistency_rule1.als 2>&1 | tee out_r1_9.out&  
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 10  -p 2  -w1 nwp -w2 lw ../model/test_consistency_rule1.als  2>&1 | tee out_r1_10.out&  


java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 4  -p 2  -w1 lw -w2 lw ../model/test_consistency_rule3.als 2>&1 | tee out_r3_1.out&  
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 4  -p 2  -w1 lw -w2 u ../model/test_consistency_rule3.als 2>&1 | tee out_r3_2.out&  
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 4  -p 2  -w1 u -w2 lw ../model/test_consistency_rule3.als 2>&1 | tee out_r3_3.out&  
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 4  -p 2  -w1 u -w2 u ../model/test_consistency_rule3.als 2>&1 | tee out_r3_4.out&  
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 8  -p 2  -w1 lw -w2 nwp ../model/test_consistency_rule3.als 2>&1 | tee out_r3_5.out&  
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 8  -p 2  -w1 lw -w2 nwp ../model/test_consistency_rule3.als 2>&1 | tee out_r3_6.out&  
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 10  -p 2  -w1 nwp -w2 lw ../model/test_consistency_rule3.als 2>&1 | tee out_r3_7.out&  
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 10  -p 2  -w1 nwp -w2 u ../model/test_consistency_rule3.als 2>&1 | tee out_r3_8.out&  
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 10  -p 2  -w1 nrwpq -w2 lw ../model/test_consistency_rule3.als 2>&1 | tee out_r3_9.out&  
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 10  -p 2  -w1 nrwpq -w2 u ../model/test_consistency_rule3.als 2>&1 | tee out_r3_10.out&  

java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 10  -p 2  -w1 lw -w2 nwp ../model/test_consistency_rule4.als 2>&1 | tee out_r4_1.out& 
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 12  -p 2  -w1 lw -w2 lw ../model/test_consistency_rule4.als 2>&1 | tee out_r4_3.out&   
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 10  -p 2  -w1 u -w2 nwp ../model/test_consistency_rule4.als 2>&1 | tee out_r4_2.out&  
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 12  -p 2  -w1 lw -w2 u ../model/test_consistency_rule4.als 2>&1 | tee out_r4_4.out&  
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 12  -p 2  -w1 u -w2 lw ../model/test_consistency_rule4.als 2>&1 | tee out_r4_5.out&  
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 12  -p 2  -w1 u -w2 u ../model/test_consistency_rule4.als 2>&1 | tee out_r4_6.out&   
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 12  -p 2  -w1 nwp -w2 lw ../model/test_consistency_rule4.als 2>&1 | tee out_r4_7.out&  
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 12  -p 2  -w1 nwp -w2 u ../model/test_consistency_rule4.als 2>&1 | tee out_r4_8.out&  

java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 6  -p 2  -w1 lw -w2 lw ../model/test_consistency_rule5.als 2>&1 | tee out_r5_1.out&  
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 6  -p 2  -w1 lw -w2 u ../model/test_consistency_rule5.als 2>&1 | tee out_r5_2.out&  
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 6  -p 2  -w1 u -w2 lw ../model/test_consistency_rule5.als 2>&1 | tee out_r5_3.out&  
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 6  -p 2  -w1 u -w2 u ../model/test_consistency_rule5.als 2>&1 | tee out_r5_4.out&  

java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 10  -p 2  ../model/test_consistency_rule6.als 2>&1 | tee out_r6_1.out&  

java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 10  -p 2  ../model/test_consistency_rule7.als 2>&1 | tee out_r7_1.out&  
