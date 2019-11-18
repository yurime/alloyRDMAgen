#!/bin/bash -l

#fdupes -dN generated_ir/
#cp model/stability_check.als generated_ir/
DIR=$1
FILES=$1/*.ir
EXECUTABLE="java -cp irToRDMA/build/classes/main/:irToRDMA/lib/antlr4-runtime-4.5.jar:irToRDMA/lib/alloy4.2.jar Main"

for f in $FILES
do
  echo "Processing $f"
  echo "JAVA_HOME=/usr/java/jdk1.8.0_211 $EXECUTABLE $f 2>&1 | tee $f.out&"
  JAVA_HOME=/usr/java/jdk1.8.0_211 $EXECUTABLE $f 2>&1 | tee $f.out&
done

wait $(jobs -p)
echo "finished $ME $1"