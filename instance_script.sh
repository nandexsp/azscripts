#!/bin/bash
user="atrio"
pass="ylosabes"
VERSION="3.5.2"
echo 'export HISTTIMEFORMAT="%d/%m/%y %T "' >>~/.bashrc
source ~/.bashrc
FILE="/root/1st"
if [ -f "${FILE}" ]; then
  sudo touch /root/2nd
  sudo yum -y install munge munge-libs munge-devel rng-tools python3 perl-devel readline-devel pam-devel mariadb-server mariadb-devel perl-Switch
  sudo systemctl enable mariadb
  sudo systemctl start mariadb
  MUNGEUSER=997
  sudo groupadd -g ${MUNGEUSER} munge
  sudo useradd -m -c "MUNGE Uid 'N' Gid Emporium" -d /var/lib/munge -u ${MUNGEUSER} -g munge -s /sbin/nologin munge
  SLURMUSER=992
  sudo groupadd -g ${SLURMUSER} slurm
  sudo useradd -m -c "SLURM workload manager" -d /var/lib/slurm -u ${SLURMUSER} -g slurm -s /bin/bash slurm
  sudo rngd -r /dev/urandom
  sudo /usr/sbin/create-munge-key -r
  sudo dd if=/dev/urandom bs=1 count=1024 >/etc/munge/munge.key
  sudo chown munge: /etc/munge/munge.key
  sudo chmod 400 /etc/munge/munge.key
  sudo chown -R munge: /etc/munge/ /var/log/munge/
  sudo chmod 0700 /etc/munge/ /var/log/munge/
  sudo systemctl enable munge
  sudo systemctl start munge
  cd /opt
  sudo wget https://download.schedmd.com/slurm/slurm-20.02.0.tar.bz2
  sudo tar --bzip -x -f slurm-20.02.0.tar.bz2
  sudo rpmbuild -ta slurm-20.02.0.tar.bz2
  sudo mv /root/rpmbuild /opt
  sudo yum -y --nogpgcheck localinstall /opt/rpmbuild/RPMS/x86_64/*
  sudo mkdir /var/spool/slurmctld
  sudo chown slurm: /var/spool/slurmctld
  sudo chmod 755 /var/spool/slurmctld
  sudo touch /var/log/slurmctld.log
  sudo chown slurm: /var/log/slurmctld.log
  sudo touch /var/log/slurm_jobacct.log /var/log/slurm_jobcomp.log
  sudo chown slurm: /var/log/slurm_jobacct.log /var/log/slurm_jobcomp.log
  cd /opt
  sudo sh /opt/openmpi-install.sh --with-slurm
  sudo mv /home/${user}/openmpi /opt/
  sudo ln -s /opt/openmpi /home/${user}/openmpi
  cd /opt
  sudo yum -y install kernel-headers kernel-devel --disablerepo=updates
  sudo yum -y install gcc
  sudo wget http://developer.download.nvidia.com/compute/cuda/10.2/Prod/local_installers/cuda_10.2.89_440.33.01_linux.run
  vers=$(ls /usr/src/kernels/ | head -n 1)
  sudo sh cuda_10.2.89_440.33.01_linux.run --toolkit --toolkitpath=/opt/cuda10.2 --driver --silent --kernel-source-path=/usr/src/kernels/${vers}/
  sudo rm /opt/cuda_10.2.89_440.33.01_linux.run
  sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  sudo yum -y install docker-ce
  distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
  sudo curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.repo |   sudo tee /etc/yum.repos.d/nvidia-docker.repo
  sudo yum -y install nvidia-docker2
  sudo systemctl enable docker
  sudo systemctl restart docker
  sudo groupadd docker
  sudo usermod -aG docker ${user}
  sudo rm /root/1st -f
  sudo rm /root/2nd -f
  sudo rm /opt/rpmbuild -Rf
  sudo rm /opt/slurm-20.02.0 -Rf
  sudo rm /opt/slurm-20.02.0.tar.bz2 -f
  sudo rm /opt/openmpi-install.sh -f
  sudo chown ${user}:${user} /opt -Rf
  sudo chown ${user}:${user} /home/${user} -Rf
  sudo touch /root/finished
else
  sudo touch /root/1st
  sudo chmod 777 /root/1st
  sudo groupadd ${user}
  sudo useradd -g ${user} -G wheel -m ${user}
  echo -e "${pass}\n${pass}" | sudo passwd ${user}
  sudo systemctl stop firewalld
  sudo systemctl disable firewalld
  sudo yum -y update
  sudo yum -y groupinstall "Development tools"
  sudo yum -y install wget openssl-devel libuuid-devel cryptsetup-devel yum-utils device-mapper-persistent-data lvm2 nfs-utils bind-utils
  sudo sed -i "s/enforcing/disabled/g" /etc/selinux/config
  cd /opt
  echo 'export HISTTIMEFORMAT="%d/%m/%y %T "' >>/home/${user}/.bashrc
  sudo wget https://dl.google.com/go/go1.13.8.linux-amd64.tar.gz -O /tmp/go-latest.tar.gz
  sudo tar -C /usr/local -xzf /tmp/go-latest.tar.gz
  rm /tmp/go-latest.tar.gz -f
  echo 'export PATH=$PATH:/usr/local/go/bin' >>/home/${user}/.bashrc
  echo 'export PATH=$PATH:/usr/local/go/bin' >>/root/.bashrc
  sudo chown ${user}:${user} /opt -Rf
  sudo chown ${user}:${user} /home/${user} -Rf
  wget https://github.com/sylabs/singularity/releases/download/v${VERSION}/singularity-${VERSION}.tar.gz -O /opt/singularity-${VERSION}.tar.gz && tar -C /opt/ -xzvf /opt/singularity-${VERSION}.tar.gz && rm /opt/singularity-${VERSION}.tar.gz -f
  cd /opt/singularity
  sudo ln -s /usr/local/go/bin/* /bin/
  sudo /opt/singularity/mconfig && sudo make -C builddir && sudo make -C builddir install
  sudo ln -s /usr/local/bin/singularity /usr/bin/singularity
  cd /opt
  cat <<EOF >/opt/openmpi-install.sh
#!/bin/bash
#
# Copyright (c) 2017-2019 Atrio, Inc.
#
# All rights reserved.
#
set -ex
# Create a temp dir for download the source codes
temp=\`mktemp -d --suffix=.install_app\`
[[ -n "\${temp}" ]] && [[ -d \${temp} ]] && cd \${temp}
echo "You can check the logs on the folder below (you can rm this folder when done):"
pwd
# Destination path
host_folder=/home/USERNAME/openmpi
mkdir -p \${host_folder}
# Flags for OpenMPI e.g. --with-slurm
ompi_flags=
if [[ -n "\${@}" ]];then
  ompi_flags="\${@}"
fi
echo "ompi_flags=\${ompi_flags}"
# Download and install OpenMPI from versions below:
# NOTE: If this changes it should be changed also at 'openmpi-selection.sh'
for version in "1.6.5" "1.8.4" "1.10.2" "1.10.6" "1.10.7" "2.0.2" "2.0.4" "2.1.1" "2.1.2" "3.0.0" "4.0.0" "4.0.1"; do
# 1.6 is already retired...(installing just in case there is an older container we need to support)
	  # Set the major version and destination folder
  major=\`echo \${version} |cut -d\. -f-2\`
  if [[ -z "\${major}" ]];then exit 1;fi
  echo "Installing Open MPI branch \${major} version \${version}"
  dest="\${host_folder}/openmpi-\${version}"
  [[ -n "\${dest}" ]] && echo "Destination folder: \${dest}"
	# Download and install
  curl -sSL "https://www.open-mpi.org/software/ompi/v\${major}/downloads/openmpi-\${version}.tar.bz2"|tar -xj
  cd openmpi-*
  ./configure --prefix=\${dest} \${ompi_flags} > ../\${version}.configure.txt 2>&1
  make -j 6 > ../\${version}.make.txt 2>&1
  make install > ../\${version}.make_install.txt 2>&1
  cd -
  rm -rf openmpi-*
 # Create the mpivars.sh script in order to make this MPI available on host
  if [[ ! -d \${dest} ]];then exit 1;fi
  mpivars=\${dest}/mpivars.sh
  echo '#!/bin/bash' > \${mpivars}
  echo "export PATH=\${dest}/bin:\$PATH" >> \$mpivars
  echo "export LD_LIBRARY_PATH=\${dest}/lib:\\\$LD_LIBRARY_PATH" >> \${mpivars}
  echo "export LD_RUN_PATH=\${dest}/lib:\\\$LD_RUN_PATH" >> \${mpivars}
  chmod 755 \${mpivars}
done
echo "Success"
EOF
  mkdir /home/${user}/.openmpi
  cat <<EOF >>/home/${user}/.openmpi/mca-params.conf
btl_tcp_if_include=eth0
EOF
  sudo sh -c 'cat >/etc/yum.repos.d/lustre.repo' <<EOF
[lustre-server]
name=CentOS-7 - Lustre
baseurl=https://downloads.hpdd.intel.com/public/lustre/latest-feature-release/el7/server/
gpgcheck=0
[e2fsprogs]
name=CentOS-7 - Ldiskfs
baseurl=https://downloads.hpdd.intel.com/public/e2fsprogs/latest/el7/
gpgcheck=0
[lustre-client]
name=CentOS-7 - Lustre
baseurl=https://downloads.hpdd.intel.com/public/lustre/latest-feature-release/el7/client/
gpgcheck=0
EOF
  sudo yum -y upgrade e2fsprogs
  sudo yum -y install lustre-tests
  sudo sh -c 'cat > /etc/modprobe.d/lnet.conf' <<EOF
options lnet networks=tcp0(eth0)
EOF
  sudo sh -c 'cat > /etc/sysconfig/modules/lustre.modules' <<EOF
#!/bin/sh
/sbin/lsmod | /bin/grep lustre 1>/dev/null 2>&1
if [ ! \$? ] ; then
   /sbin/modprobe lustre >/dev/null 2>&1
fi
EOF
  sudo chmod 744 /etc/sysconfig/modules/lustre.modules
  sudo reboot
fi
