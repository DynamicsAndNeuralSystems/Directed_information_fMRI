
out_space='fsaverage'
out_den=164
data_dir='/Users/abry4213/data/BigBrain/'
github_dir='/Users/abry4213/github/BigBrainWarp'

# Activate conda environment
source ~/.bashrc
source activate base
conda activate annie_env

for layer in 1 2 3 4 5 6; do
    in_lh=/Users/abry4213/data/BigBrain/spaces/tpl-bigbrain/tpl-bigbrain_hemi-L_desc-layer${layer}_thickness.txt
    in_rh=/Users/abry4213/data/BigBrain/spaces/tpl-bigbrain/tpl-bigbrain_hemi-R_desc-layer${layer}_thickness.txt
    desc=layer${layer}_thickness

    for hemi in L R ; do
        # define input
        if [[ "$hemi" == "L" ]] ; then
            inData=$in_lh
        else
            inData=$in_rh
        fi

        if ! test -f ${data_dir}/spaces/tpl-${out_space}/tpl-${out_space}_hemi-${hemi}_den-164k_desc-${desc}.${gii_type}.gii; then
            echo "Processing layer ${layer} for hemisphere ${hemi}"

            # Convert txt to gii
            gii_type=label
            python $github_dir/scripts/txt2gii.py $inData ${data_dir}/spaces/tpl-bigbrain_hemi-${hemi}_desc-${desc}.${gii_type}.gii ${data_dir}/spaces/tpl-bigbrain/tpl-bigbrain_hemi-${hemi}_desc-aparc.${gii_type}.gii

            # multimodal surface matching
            msmMesh=${data_dir}/xfms/tpl-${out_space}_hemi-${hemi}_den-164k_desc-sphere_rsled_like_bigbrain.reg.surf.gii
            inMesh=${data_dir}/spaces/tpl-${out_space}/tpl-${out_space}_hemi-${hemi}_den-164k_desc-sphere.surf.gii
            wb_command -label-resample ${data_dir}/spaces/tpl-bigbrain_hemi-${hemi}_desc-${desc}.${gii_type}.gii \
                    $msmMesh $inMesh BARYCENTRIC \
                    ${data_dir}/spaces/tpl-${out_space}/tpl-${out_space}_hemi-${hemi}_den-164k_desc-${desc}.${gii_type}.gii
        fi
    done
done