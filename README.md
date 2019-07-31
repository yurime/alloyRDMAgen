# alloyRDMAgen
Repository for development

# To build
## rdmaTestgen
gradle jar

May need to set JAVA_HOME to java 8.1 beforehand.

# To run 
## rdmaTestgen
java -cp build/libs/testgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --scope 10 -p 2 ../model/driver_nic_ord_swPutOrRDMAAtomic.als
