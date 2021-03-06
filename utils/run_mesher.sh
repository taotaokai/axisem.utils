#!/bin/bash

wkdir=$(pwd)

sem_dir=${1:?[arg]need axisem build dir for bin/axisem}
config_dir=${2:?[arg]need config dir for inparam_mesh, ...}
mesh_dir=${3:?[arg]need mesh dir for output}

if [ -d "$mesh_dir" ]
then
  echo "[WARN] mesh dir already exists, delete"
  rm -rf $mesh_dir
fi
mkdir -p $mesh_dir
mkdir $mesh_dir/Diags

sem_dir=$(readlink -f $sem_dir)
config_dir=$(readlink -f $config_dir)
mesh_dir=$(readlink -f $mesh_dir)

cp $config_dir/inparam_mesh $mesh_dir

bgmodel=$(grep "^BACKGROUND_MODEL" $config_dir/inparam_mesh | awk '{print $2}')
if [ x$bgmodel == xexternal ]
then
  fnam_extmodel=$(grep "^EXT_MODEL" $config_dir/inparam_mesh | awk '{print $2}')
  cp $config_dir/$fnam_extmodel $mesh_dir
fi

cat <<EOF > $mesh_dir/mesh.job
#!/bin/bash
#SBATCH -J mesh
#SBATCH -o $mesh_dir/mesh.job.o%j
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -p normal
#SBATCH -t 00:59:00

cd $mesh_dir
#mpirun -n 1 $sem_dir/bin/xmesh
ibrun $sem_dir/bin/xmesh

EOF
