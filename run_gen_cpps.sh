#!/bin/bash -l

#fdupes -dN generated_ir/
#cp model/stability_check.als generated_ir/
DIR=$1
OUT_DIR=$2
FILES=$DIR/*.ir
EXECUTABLE="java -cp irToRDMA/src/main/resources:irToRDMA/build/classes/main/:irToRDMA/lib/antlr4-runtime-4.5.jar:irToRDMA/lib/alloy4.2.jar ConvertToRDMA"
ME=`basename "$0"`

echo "mkdir output/${OUT_DIR}"
mkdir output/${OUT_DIR}

for f in $FILES
do
  out_d=${f%.ir}
  out=${out_d##*/}
  echo "JAVA_HOME=/usr/java/jdk1.8.0_211 $EXECUTABLE $f ${OUT_DIR}/$out 2>&1 | tee ${out}.cpp_out&"
  JAVA_HOME=/usr/java/jdk1.8.0_211 $EXECUTABLE $f ${OUT_DIR}/$out 2>&1 | tee ${out}.cpp_out &
done

wait $(jobs -p)
echo "finished $ME $1 $2"