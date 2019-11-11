# alloyRDMAgen
Repository for development

# To build
## rdmaTestgen
gradle jar

May need to set JAVA_HOME to java 8.1 beforehand.

# To run 
## sequence
- rdmaTestgen to generate alloy tests
- the test may have duplicates, run: `fdupes -dN output`
- generate all possible outputs 
- generate ir
- run on rdma

## rdmaTestgen generate ir
`java -cp build/libs/testgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --scope 10 -p 2 ../model/driver_nic_ord_swPutOrRDMAAtomic.als`

## irToRDMA generate all possible outputs
## irToRDMA 
TODO: augment the line below

    `cp ../irToRDMA/benchmarks/stability_check.als output`
    `java -cp ../irToRDMA/build/classes/main/:../irToRDMA/build/libs/antlr4-runtime-4.5.jar:lib/alloy4.2.jar Main output/driver_IR000001.ir`
    `find output -name '*.als' -delete`

# To develop
