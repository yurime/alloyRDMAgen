# alloyRDMAgen
Repository for development

# To build
## rdmaTestgen
### from commandline
- `gradle jar`
May need to set JAVA_HOME to java 8.1 beforehand.
### eclipse
- Instal the gradel ‘buildship’ from eclipse marketplace
- Add from the folder lib the alloy4.2.jar file to the build
- Add Junit library to build path

# To run 
## sequence
- rdmaTestgen to generate alloy tests
- the test may have duplicates, run: `fdupes -dN output`
- run alloy from irToRDMA to generate all possible outputs 
- irToRDMA to generate ir 
- run on rdma

## rdmaTestgen generate ir
./run_testgen.sh
executes inside generation of each example
`java -cp build/libs/testgen.jar:lib/alloy4.2.jar ch.ethz.srl.Main --scope 10 -p 2 ../model/driver_nic_ord_swPutOrRDMAAtomic.als`

## small maintainance
`cp rdmaTestgen/output/test_consistency_rule*ir generated_ir/`
remove duplicate files
`fdupes -dN generated_ir/`

## alloy from irToRDMA to generate all possible outputs 
./run_gen_all_outpts.sh

## irToRDMA 
TODO: augment the line below

    `cp ../irToRDMA/benchmarks/stability_check.als output`
    `java -cp ../irToRDMA/build/classes/main/:../irToRDMA/build/libs/antlr4-runtime-4.5.jar:lib/alloy4.2.jar Main output/driver_IR000001.ir`
    `find output -name '*.als' -delete`

# To develop
