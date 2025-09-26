import pandas as pd
import argparse
import joblib

parser = argparse.ArgumentParser()
parser.add_argument("--input", required=True)
parser.add_argument("--model", required=True)
parser.add_argument("--output", required=True)
args = parser.parse_args()

def parse_vcf(vcf_path):
    records = []
    with open(vcf_path) as f:
        for line in f:
            if line.startswith("#"):
                continue
            fields = line.strip().split("\t")
            info = {kv.split("=")[0]: kv.split("=")[1] for kv in fields[7].split(";") if "=" in kv}
            records.append(info)
    return pd.DataFrame(records)

df = parse_vcf(args.input)
model = joblib.load(args.model)
features = df.select_dtypes(include="number")
preds = model.predict(features)
filtered_df = df[preds == 1]

with open(args.output, "w") as out:
    with open(args.input) as original:
        for line in original:
            if line.startswith("#"):
                out.write(line)
    for i in filtered_df.index:
        out.write(df.iloc[i].to_csv(sep="\t", header=False, index=False))
