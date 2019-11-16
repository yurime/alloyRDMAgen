



java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 20 --scope 4  -p 2  -w1 lw -w2 lw ../model/test_consistency_rule1.als
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 20 --scope 4  -p 2  -w1 lw -w2 u ../model/test_consistency_rule1.als
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 20 --scope 4  -p 2  -w1 u -w2 lw ../model/test_consistency_rule1.als
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 20 --scope 4  -p 2  -w1 u -w2 u ../model/test_consistency_rule1.als
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 20 --scope 4  -p 2  -w1 lw -w2 nrwpq ../model/test_consistency_rule1.als
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 20 --scope 4  -p 2  -w1 u -w2 nrwpq ../model/test_consistency_rule1.als
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 20 --scope 8  -p 2  -w1 u -w2 nwp ../model/test_consistency_rule1.als
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 20 --scope 8  -p 2  -w1 lw -w2 nwp ../model/test_consistency_rule1.als
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 20 --scope 10  -p 2  -w1 nrwpq -w2 u ../model/test_consistency_rule1.als
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 20 --scope 10  -p 2  -w1 nwp -w2 u ../model/test_consistency_rule1.als
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 20 --scope 10  -p 2  -w1 nwp -w2 lw ../model/test_consistency_rule1.als&
java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 20 --scope 10  -p 2  -w1 nrwpq -w2 lw ../model/test_consistency_rule1.als

