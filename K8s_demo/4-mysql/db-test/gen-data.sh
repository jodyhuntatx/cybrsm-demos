#!/bin/bash
NUM_TYPES=3
NUM_OWNERS=1000
NUM_PETS=200
OUTFILE=test_data.sql

rm -f $OUTFILE
echo "USE petclinic;" >> $OUTFILE
echo >> $OUTFILE

echo "INSERT INTO types (name)" >> $OUTFILE
echo "VALUES" >> $OUTFILE
for i in $(seq 1 $NUM_TYPES); do
  echo  "(\"Type$i\")," >> $OUTFILE
done
echo ";" >> $OUTFILE
echo >> $OUTFILE

echo "INSERT INTO owners (first_name, last_name, address, city, telephone)" >> $OUTFILE
echo "VALUES" >> $OUTFILE
for i in $(seq 1 $NUM_OWNERS); do
  echo "(\"Firstname$i\", \"Lastname$i\", \"Address$i\", \"City$i\", \"Phone$i\")," >> $OUTFILE
done
echo ";" >> $OUTFILE
echo >> $OUTFILE

echo "INSERT INTO pets (name, birth_date, type_id, owner_id)" >> $OUTFILE
echo "VALUES" >> $OUTFILE
for i in $(seq 1 $NUM_PETS); do
  type_mod=$(($(($i % $NUM_TYPES))+1))
  owner_mod=$(($(($i % $NUM_OWNERS))+1))
  echo  "(\"Name$i\", \"2015-09-25\", \"$type_mod\", \"$owner_mod\")," >> $OUTFILE
done
echo ";" >> $OUTFILE
