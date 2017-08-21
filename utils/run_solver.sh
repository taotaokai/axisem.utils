#!/bin/bash

wkdir=$(pwd)

sem_dir=${1:?[arg]need axisem build dir for bin/axisem}
config_dir=${2:?[arg]need config dir for inparam_mesh|basic|... }
mesh_dir=${3:?[arg]need mesh dir for meshdb.dat*, }
syn_dir=${4:?[arg]need run dir for solver}

if [ -d "$syn_dir" ]
then
  echo "[WARN] syn dir already exists, delete"
  rm -rf $syn_dir
fi
mkdir -p $syn_dir

sem_dir=$(readlink -f $sem_dir)
config_dir=$(readlink -f $config_dir)
mesh_dir=$(readlink -f $mesh_dir)
syn_dir=$(readlink -f $syn_dir)

#------ link mesh
meshname=$(grep MESHNAME $config_dir/inparam_basic | awk '{print $2}')
ln -s $mesh_dir $syn_dir/Mesh

#set bgmodel = `grep ^BACKGROUND_MODEL $meshdir/inparam_mesh | awk '{print $2}'`
#if ( $bgmodel == 'external' ) then
#    cp Mesh/external_model.bm .
#endif

#------ copy source/receiver/inparam* files
cp $config_dir/CMTSOLUTION $syn_dir
cp $config_dir/inparam_source $syn_dir

# identify receiver input file
rec_file_type=$(grep "^RECFILE_TYPE" $config_dir/inparam_basic |awk '{print $2}')
#echo "Receiver file type:" $rec_file_type
if [ x$rec_file_type == xcolatlon ]
then
  recfile=$config_dir/receivers.dat
elif [ x$rec_file_type == xstations ]
then
  recfile=$config_dir/STATIONS
fi
cp $recfile $syn_dir

#cp $config_dir/mesh_params.h .
#cp $homedir/runinfo .
#if ( $rec_file_type != 'none' ) then
#  cp $homedir/$recfile . 
#endif

cp $config_dir/inparam_basic     $syn_dir
cp $config_dir/inparam_advanced  $syn_dir
cp $config_dir/inparam_hetero    $syn_dir

data_dir=$(grep "^DATA_DIR" $config_dir/inparam_advanced  |awk '{print $2}'| sed 's/\"//g')
info_dir=$(grep "^INFO_DIR" $config_dir/inparam_advanced  |awk '{print $2}'| sed 's/\"//g')
mkdir -p $syn_dir/$data_dir $syn_dir/$info_dir

#------ make slurm job file
nproc_theta=$(grep "^NTHETA_SLICES" $mesh_dir/inparam_mesh | awk '{print $2}')
nproc_radial=$(grep "^NRADIAL_SLICES" $mesh_dir/inparam_mesh | awk '{print $2}')
nproc_tot=$(echo $nproc_theta $nproc_radial | awk '{print $1*$2}')
cat <<EOF > $syn_dir/syn.job
#!/bin/bash
#SBATCH -J syn
#SBATCH -o $syn_dir/syn.job.o%j
#SBATCH -n $nproc_tot
#SBATCH -t 05:00:00

cd $syn_dir
mpirun -n $nproc_tot $sem_dir/bin/axisem

EOF
