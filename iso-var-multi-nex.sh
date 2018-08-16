#!/bin/bash
### The directory RAD_sky should contain 4 programs: iso-var-multi-nex.sh; iso-var-single-nex.sh; phy2fasta.pl; and fasta2nexus.pl
### The purpose of this script is to create multiple nexus files (one for each locus) with only those loci with at least some minimum number
### of specified SNPs so that the file can be read using beauti and used for skyline plots and other coalescent based analyses

### Usage: ./var.sh [min SNPs]
### min SNPs is an integer set to the minimum number of SNPs desired in the output file
### WARNING! Before running the program, copy or move the RAD_sky directory into the outfiles directory that results from PYRAD
### --OR-- a directory that contains the desired .phy & .loci files

# setup a temporary directory for executions
mkdir temp
cp $0 temp
cp ../*.loci temp
cp ../*.phy temp
cd temp

# use these programs written by Steve Mussmann to create the appropriate .nexus file
# making a nexus file in this way formats it specifically for the purposes of loading it into
# beauti, and it does so better than the already created .nex file in the outfiles directory from PYRAD
../phy2fasta.pl -p *.phy -o output.fasta
../fasta2nexus.pl -f output.fasta -o output.nex

# count the number of loci with at least the specified amount of SNPs ($1 from command line)
loci=`cat *.loci | sed -n -r "/\/\/(\s*\*+\s*){"$1",}/p" |  wc -l`
echo "We have found  $loci total loci with at least $1 SNPs"

# make a list with the loci numbers
cat *.loci | sed -n -r "/\/\/(\s*\*+\s*){"$1",}/p" | awk 'BEGIN{ FS="|"} {print $2}' > list

# determine how many bases occur in each loci !!!this assumes all loci have the same number!!!
bases=`head -1 *.loci | awk 'FS="  " {print $2}' | awk 'BEGIN{FS=""} {print NF}'`

# modify the output.nex file so that it is ready to be read by beauti

while read list; do
	start=$((($list * $bases) - ($bases - 1)))
	stop=$(($list * $bases))
	cat output.nex | awk 'BEGIN{FS=""} {if (NF < 100) {print $0 >> "'''$list'''.output.nex"}
	 else {print substr($0,1,16)substr($0,'''$start''','''$bases''') >> "'''$list'''.output.nex"}}'
	sed -i -e 's/?/N/g' $list.output.nex
	sed -i -e "s/NCHAR=[0-9]*;/NCHAR="$bases"/" $list.output.nex
done < list


# mv the output file to the RAD_sky directory and remove the temporary directory
mkdir output.nexus
cp *.output.nex output.nexus
mv output.nexus ..
cd ..
rm -r temp

echo "output files stored in RAD_sky/output.nexus"
echo "file is ready for beauti"
echo "good luck"
