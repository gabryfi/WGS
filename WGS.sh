# Input prep and alignment

zcat /path-to-fastq-pass/fastq_pass/*.fastq.gz > pain_sample.fastq 

# Nanoplot
# conda activate --> bulkNextflw
NanoPlot -t 60 --fastq pain_sample.fastq   --outdir Nanoplot_pain_sample 

# Filtering 
# conda activate --> filtlong
filtlong --min_length 1000 --keep_percent 90 pain_sample.fastq  > pain_sample.filtered.fastq 


# Alignment
# conda activate  --> bulkNextflw

# Keep GCA and GCF files in different directories plis

# GCA ref --> more complete but clunky to use and interpret
minimap2 -t 50 -ax map-ont /home/lab-user/reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna pain_sample.filtered.fastq  > pain_sample_GCA.aln.sam
# RefSeq --> already annotated, use this !!!
minimap2 -t 50 -ax map-ont /home/lab-user/reference/hg38_14_human_refseq/GCF_000001405.40_GRCh38.p14_genomic.fna pain_sample.filtered.fastq  > pain_sample_GCF.aln.sam


# QC after alignment 
# samtools --> bulkNextflw

# GCA
samtools view -S -b pain_sample_GCA.aln.sam > pain_sample_GCA.bam
samtools sort --threads 50 -o pain_sample_GCA.sorted.bam pain_sample_GCA.bam
samtools index pain_sample_GCA.sorted.bam

# GCF
samtools view -S -b pain_sample_GCF.aln.sam > pain_sample_GCF.bam
samtools sort --threads 50 -o pain_sample_GCF.sorted.bam pain_sample_GCF.bam
samtools index pain_sample_GCF.sorted.bam


# Mosdepth --> QC post alig and ribbon prep
# depth sequencing moshdepth
# conda activate mosdepth
mosdepth -t 50 -n --fast-mode --by 10000 GCA_pain.wgs pain_sample_GCA.sorted.bam # GCA
mosdepth -t 50 -n --fast-mode --by 10000 GCF_pain.wgs pain_sample_GCF.sorted.bam # GCF


#### Variant Calling GCA #####
# sniffles2 --> conda activate sniffles
# svim --> conda activate svim_env
# cutesv --> conda activate cutesv
sniffles -t 50 --reference /home/lab-user/reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna -i pain_sample_GCA.sorted.bam -v pain_sample_GCA.sniffles.vcf
svim alignment pain_sample_GCA pain_sample_GCA.sorted.bam /home/lab-user/reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna
CuteSV  --threads 50 pain_sample_GCA.sorted.bam /home/lab-user/reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna --max_cluster_bias_INS 100 --diff_ratio_merging_INS 0.3 --max_cluster_bias_DEL 100 --diff_ratio_merging_DEL 0.3 pain_GCA.cutesv.vcf 

#### Variant Calling GCF #####
# sniffles2 --> conda activate sniffles
# svim --> conda activate svim_env
# cutesv --> conda activate cutesv
sniffles -t 50 --reference /home/lab-user/reference/hg38_14_human_refseq/GCF_000001405.40_GRCh38.p14_genomic.fna -i pain_sample_GCF.sorted.bam -v pain_sample_GCF.sniffles.vcf
svim alignment pain_sample_GCF pain_sample_GCF.sorted.bam /home/lab-user/reference/hg38_14_human_refseq/GCF_000001405.40_GRCh38.p14_genomic.fna
CuteSV  --threads 50 pain_sample_GCF.sorted.bam /home/lab-user/reference/hg38_14_human_refseq/GCF_000001405.40_GRCh38.p14_genomic.fna --max_cluster_bias_INS 100 --diff_ratio_merging_INS 0.3 --max_cluster_bias_DEL 100 --diff_ratio_merging_DEL 0.3 pain_GCF.cutesv.vcf 



#### snpEff variant annotation --> to do only after finding a worth variant call
# E' scritto in java, lo abbiamo installato in tools
java -Xmx8g -jar /tools/snpEff/snpEff.jar GRCh38.99 NOME_FILE_VCF > NOME_FILE.ann.vcf
