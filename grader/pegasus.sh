#!/bin/bash

roc_multi()
{
    family="$1"

    root=`pwd`
    base="${root}/malware/${family}/output/"

    python roc_multi.py "${base}/combined_roc_func_data.npz" \
                        "${base}/combined_capa_func_data.npz" \
                        "${base}/combined_dr_plus_capa_func_data.npz" \
                        "DeepReflect" \
                        "CAPA" \
                        "DeepReflect+CAPA" \
                        "Pegasus" \
                        "${base}/combined_roc.png"
}

combine ()
{
    family="$1"

    root=`pwd`
    base="${root}/malware/${family}/output/"

    python combine.py "${base}/idd_roc_func_data.npz" \
                      "${base}/mod_CmdExec_roc_func_data.npz" \
                      "${base}/mod_DomainReplication_roc_func_data.npz" \
                      "${base}/mod_LogonPasswords_roc_func_data.npz" \
                      "${base}/mod_NetworkConnectivity_roc_func_data.npz" \
                      "${base}/rse_roc_func_data.npz" \
                      "${base}/combined_roc_func_data.npz"

    python combine.py "${base}/idd_capa_func_data.npz" \
                      "${base}/mod_CmdExec_capa_func_data.npz" \
                      "${base}/mod_DomainReplication_capa_func_data.npz" \
                      "${base}/mod_LogonPasswords_capa_func_data.npz" \
                      "${base}/mod_NetworkConnectivity_capa_func_data.npz" \
                      "${base}/rse_capa_func_data.npz" \
                      "${base}/combined_capa_func_data.npz"

    python combine.py "${base}/idd_dr_plus_capa_func_data.npz" \
                      "${base}/mod_CmdExec_dr_plus_capa_func_data.npz" \
                      "${base}/mod_DomainReplication_dr_plus_capa_func_data.npz" \
                      "${base}/mod_LogonPasswords_dr_plus_capa_func_data.npz" \
                      "${base}/mod_NetworkConnectivity_dr_plus_capa_func_data.npz" \
                      "${base}/rse_dr_plus_capa_func_data.npz" \
                      "${base}/combined_dr_plus_capa_func_data.npz"
}

dr ()
{
    family="$1"
    name="$2"

    root=`pwd`
    root_input="${root}/malware/${family}/"
    binary="${root_input}/${name}"

    root_output="${root_input}/output"
    mkdir -p "${root_output}"

    base="${root_output}/${name: 0:-4}"
    bndb="${base}.bndb"
    raw="${base}_raw.txt"

    feature="${base}_feature.npy"
    feature_path="${base}_feature_path.txt"
    echo "${feature}" > "${feature_path}"

    function="${base}_function.txt"
    mse="${base}_mse"
    annotation="${root_input}/${name: 0:-4}_annotation.txt"
    roc_name="${base}_roc"
    roc_out="${base}_roc_stdout_stderr.txt"

    cd ../extract/

    # Extract features
    python binja.py --exe "${binary}" --output "${bndb}"
    python extract_raw.py binja --bndb "${bndb}" --output "${raw}"
    python extract_features.py --raw "${raw}" --output "${feature}"

    # Extract function information
    python extract_function.py --bndb "${bndb}" --output "${function}"

    cd ../autoencoder/

    # Extract MSE values
    python mse.py --feature "${feature_path}" \
                  --model "dr.h5" \
                  --normalize "normalize.npy" \
                  --output "${mse}"

    cd "${root}"

    # Graph ROC curve
    python roc.py --mse "${mse}/output/${name: 0:-4}_feature.npy" \
                  --feature "${feature}" \
                  --bndb-func "${function}" \
                  --annotation "${annotation}" \
                  --roc "${roc_name}" &> "${roc_out}"
}

capa ()
{
    family="$1"
    name="$2"

    root=`pwd`
    root_input="${root}/malware/${family}/"
    binary="${root_input}/${name}"

    root_output="${root_input}/output"

    base="${root_output}/${name: 0:-4}"
    bndb="${base}.bndb"
    raw="${base}_raw.txt"

    feature="${base}_feature.npy"
    feature_path="${base}_feature_path.txt"

    function="${base}_function.txt"
    mse="${base}_mse"
    annotation="${root_input}/${name: 0:-4}_annotation.txt"
    roc_name="${base}_roc"
    roc_out="${base}_roc_stdout_stderr.txt"

    echo "${base}/${name: 0:-4}_roc_func_data.npz"

    cd capa/
    python output_data.py "${family}/${name: 0:-4}.json" "${base}_roc_func_data.npz" \
                            "${base}_capa_func_data.npz"
    cd ../
}

dr_capa()
{
    family="$1"
    name="$2"

    root=`pwd`
    root_input="${root}/malware/${family}/"
    binary="${root_input}/${name}"

    root_output="${root_input}/output"

    base="${root_output}/${name: 0:-4}"
    bndb="${base}.bndb"
    raw="${base}_raw.txt"

    feature="${base}_feature.npy"
    feature_path="${base}_feature_path.txt"

    function="${base}_function.txt"
    mse="${base}_mse"
    annotation="${root_input}/${name: 0:-4}_annotation.txt"
    roc_name="${base}_roc"
    roc_out="${base}_roc_stdout_stderr.txt"

    echo "${base}/${name: 0:-4}_roc_func_data.npz"

    cd capa/
    python dr_plus_capa.py "${family}/${name: 0:-4}.json" "${base}_roc_func_data.npz" \
                            "${base}_dr_plus_capa_func_data.npz"
    cd ../
}

family="pegasus"

name="idd.x32"
dr "${family}" "${name}"
capa "${family}" "${name}"
dr_capa "${family}" "${name}"

name="mod_CmdExec.x32"
dr "${family}" "${name}"
capa "${family}" "${name}"
dr_capa "${family}" "${name}"

name="mod_DomainReplication.x32"
dr "${family}" "${name}"
capa "${family}" "${name}"
dr_capa "${family}" "${name}"

name="mod_LogonPasswords.x32"
dr "${family}" "${name}"
capa "${family}" "${name}"
dr_capa "${family}" "${name}"

name="mod_NetworkConnectivity.x32"
dr "${family}" "${name}"
capa "${family}" "${name}"
dr_capa "${family}" "${name}"

name="rse.x32"
dr "${family}" "${name}"
capa "${family}" "${name}"
dr_capa "${family}" "${name}"

# Combine ROC data
combine "${family}"

# Graph ROC data
roc_multi "${family}"
