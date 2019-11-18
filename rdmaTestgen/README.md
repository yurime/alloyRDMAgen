
Getting Started
===============

preset JAVA_HOME to a java8 src 
`java -cp build/libs/rdmaTestgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --limit 40 --scope 4  -p 2  -w1 lw -w2 lw ../model/test_consistency_rule1.als 2>&1 | tee out_r1_1.out& `
`java -cp build/libs/testgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --scope 10 -p 2 ../alloy/driver_IR.als`

