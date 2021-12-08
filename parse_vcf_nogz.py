import re
import sys
import gzip
import pandas as pd
from tqdm import tqdm

sys.version_info
# sys.version_info(major=3, minor=6, micro=5, releaselevel='final', serial=0)

def get_vcf_names(vcf_path):
    with open(vcf_path, "rt") as ifile:
          for line in ifile:
            if line.startswith("#CHROM"):
                  vcf_names = [x for x in line.split('\t')]
                  break
    ifile.close()
    return vcf_names

def get_ann_field_structure(vcf_path):
    with open(vcf_path, "rt") as ifile:
        for line in ifile:
            if line.startswith("##INFO=<ID=ANN"):
                ann_field_names = re.findall(r"'(.*?)'", line, re.DOTALL)
                ann_field_names = ''.join(ann_field_names).split(" | ")
                break
    ifile.close()
    return ann_field_names

def get_info_field_structure(vcf_path):
    with open(vcf_path, "rt") as ifile:
        info_field_names = []
        for line in ifile:
            if line.startswith("##INFO=<ID="):
                info_field_names.append(''.join(re.findall(r"##INFO=<ID=(.*?),", line, re.DOTALL)))
            elif line.startswith("##contig"):
                break
    ifile.close()
    return info_field_names

def parse_info_field(vcf_path):
    vcf_names = get_vcf_names(vcf_path)
    vcf = pd.read_csv(vcf_path, comment='#', delim_whitespace=True, header=None, names=vcf_names)
    
    vcf_info = vcf['INFO'].str.split(pat=';', n=- 1, expand=False)
    vcf_info_names = get_info_field_structure(vcf_path)
    
    vcf_info_df = pd.DataFrame(columns = vcf_info_names)
    # for i in tqdm(range(1000)):
    # Only reads first 1k lines from vcf files since function is not yet optimized for time
    for i in tqdm(range(len(vcf_info.index))):
        split = [i.split('=', 1) for i in vcf_info[i]]
        names = [item[0] for item in split]
        vcf_info_df = vcf_info_df.append(
            pd.DataFrame([[item[1] for item in split]], columns = [item[0] for item in split]),
            ignore_index=True, sort=True)
    
    return vcf_info_df

def parse_info_ann_field(vcf_path, vcf_info):
    df = vcf_info['ANN'].str.split(',',expand=True)
    ann_names = get_ann_field_structure(vcf_path)
    results = list()
    for i in tqdm(range(len(df.index))):
        try:
            variant_df = df.iloc[i].dropna().str.split('\\|',expand=True)
            variant_df.columns = ann_names
            results.append(variant_df)
        except:
            results.append(pd.DataFrame(columns = ann_names))
    
    return results
  
  
# Example usage
vcfFilePath = '/path/to/vcf/patient.vcf'

# Limited to 1k rows for testing!
vcf_df = pd.read_csv(vcfFilePath, nrows=1000, comment='#', delim_whitespace=True, header=None, names=get_vcf_names(vcfFilePath))
vcf_info_df = parse_info_field(vcfFilePath)
vcf_info_ann_list = parse_info_ann_field(vcfFilePath, vcf_info_df)
