#!/usr/bin/env bash
# butchered version of https://github.com/MSMFG/tru-strap

main() {
pathmunge /usr/local/bin
parse_args "$@"
install_yum_deps
install_ruby
install_gem_deps
inject_ssh_key
clone_git_repo
symlink_puppet_dir
fetch_puppet_modules
run_puppet

}


usagemessage="Error, USAGE: $(basename "${0}") \n \
  --role|-r \n \
  --environment|-e \n \
  --repouser|-u \n \
  --reponame|-n \n \
  [--repoprivkeyfile|-k] \n \
  [--repobranch|-b] \n \
  [--help|-h] \n \
  [--version|-v]"

puppetdir="/etc/puppetlabs/puppet"

function log_error() {
    echo "###############------Fatal error!------###############"
    caller
    printf "%s\n" "${1}"
    exit 1
}

# from centos /etc/profile
pathmunge() {
    case ":${PATH}:" in
        *:"$1":*)
            ;;
        *)
            if [ "$2" = "after" ] ; then
                PATH=$PATH:$1
            else
                PATH=$1:$PATH
            fi
    esac
}

# Parse the commmand line arguments
parse_args() {
  while [[ -n "${1}" ]] ; do
    case "${1}" in
      --help|-h)
        echo -e ${usagemessage}
        exit
        ;;
      --version|-v)
        print_version "${PROGNAME}" "${VERSION}"
        exit
        ;;
      --role|-r)
        set_facter init_role "${2}"
        shift
        ;;
      --environment|-e)
        set_facter init_env "${2}"
        shift
        ;;
      --repouser|-u)
        set_facter init_repouser "${2}"
        shift
        ;;
      --reponame|-n)
        set_facter init_reponame "${2}"
        shift
        ;;
       --repoprivkeyfile|-k)
        set_facter init_repoprivkeyfile "${2}"
        shift
        ;;
      --repobranch|-b)
        set_facter init_repobranch "${2}"
        shift
        ;;
      --debug)
        shift
        ;;
      *)
        echo "Unknown argument: ${1}"
        echo -e "${usagemessage}"
        exit 1
        ;;
    esac
    shift
  done

  # Define required parameters.
  if [[ -z "${FACTER_init_role}" || \
        -z "${FACTER_init_env}"  || \
        -z "${FACTER_init_repouser}" || \
        -z "${FACTER_init_reponame}"  ]]; then
    echo -e "${usagemessage}"
    exit 1
  fi

  # Set some defaults if they aren't given on the command line.
  [[ -z "${FACTER_init_repobranch}" ]] && set_facter init_repobranch master
  [[ -z "${FACTER_init_repodir}" ]] && set_facter init_repodir /opt/"${FACTER_init_reponame}"
}


# Install yum packages if they're not already installed
yum_install() {
  for i in "$@"
  do
    if ! rpm -q ${i} > /dev/null 2>&1; then
      local RESULT=''
      RESULT=$(yum install -y ${i} 2>&1)
      if [[ $? != 0 ]]; then
        log_error "Failed to install yum package: ${i}\nyum returned:\n${RESULT}"
      else
        echo "Installed yum package: ${i}"
      fi
    fi
  done
}

# Install Ruby gems if they're not already installed
gem_install() {
  local RESULT=''
  for i in "$@"
  do
    if [[ ${i} =~ ^.*:.*$ ]];then
      MODULE=$(echo ${i} | cut -d ':' -f 1)
      VERSION=$(echo ${i} | cut -d ':' -f 2)
      if ! gem list -i --local ${MODULE} --version ${VERSION} > /dev/null 2>&1; then
        echo "Installing ${i}"
        RESULT=$(gem install ${i} --no-ri --no-rdoc)
        if [[ $? != 0 ]]; then
          log_error "Failed to install gem: ${i}\ngem returned:\n${RESULT}"
        fi
      fi
    else
      if ! gem list -i --local ${i} > /dev/null 2>&1; then
        echo "Installing ${i}"
        RESULT=$(gem install ${i} --no-ri --no-rdoc)
        if [[ $? != 0 ]]; then
          log_error "Failed to install gem: ${i}\ngem returned:\n${RESULT}"
        fi
      fi
    fi
  done
}

# Install the yum dependencies
install_yum_deps() {
  echo "Installing required yum packages"
  yum_install augeas-devel ncurses-devel gcc gcc-c++ curl git
}

print_version() {
  echo "${1}" "${2}"
}

# Set custom facter facts
set_facter() {
  local key=${1}
  #Note: The name of the evironment variable is not the same as the facter fact.
  local export_key=FACTER_${key}
  local value=${2}
  export ${export_key}="${value}"
  if [[ ! -d /etc/facter ]]; then
    mkdir -p /etc/facter/facts.d || log_error "Failed to create /etc/facter/facts.d"
  fi
  if ! echo "${key}=${value}" > /etc/facter/facts.d/"${key}".txt; then
    log_error "Failed to create /etc/facter/facts.d/${key}.txt"
  fi
  chmod -R 600 /etc/facter || log_error "Failed to set permissions on /etc/facter"
  cat /etc/facter/facts.d/"${key}".txt || log_error "Failed to create ${key}.txt"
}


install_ruby() {
  yum_install ruby ruby-devel
}

# Install the gem dependencies
install_gem_deps() {
  echo "Installing puppet and related gems"
  gem_install puppet hiera facter ruby-augeas hiera-eyaml ruby-shadow
}

# Inject the SSH key to allow git cloning
inject_ssh_key() {
  # Set Git login params
  if [[ ! -d /root/.ssh ]]; then
    mkdir /root/.ssh || log_error "Failed to create /root/.ssh"
    chmod 600 /root/.ssh || log_error "Failed to change permissions on /root/.ssh"
  fi
  echo "StrictHostKeyChecking=no" > /root/.ssh/config ||log_error "Failed to set ssh config"
  if [[ -n "${FACTER_init_repoprivkeyfile}" ]]; then
    echo "Injecting private ssh key"
    GITHUB_PRI_KEY=$(cat "${FACTER_init_repoprivkeyfile}")
    echo "${GITHUB_PRI_KEY}" > /root/.ssh/id_rsa || log_error "Failed to set ssh private key"
  fi
  chmod -R 600 /root/.ssh || log_error "Failed to set permissions on /root/.ssh"
}

# Clone the git repo
clone_git_repo() {
  echo "Cloning ${FACTER_init_repouser}/${FACTER_init_reponame} repo"
  rm -rf "${FACTER_init_repodir}"
  # test for repoprivkeyfile
  if [[ -n "${FACTER_init_repoprivkeyfile}" ]]; then
    clone_git_ssh_repo
  else
    clone_git_http_repo
  fi
}

# Clone the git repo
clone_git_ssh_repo() {
  # Clone private repo.
  # Exit if the clone fails
  if ! git clone -b "${FACTER_init_repobranch}" git@github.com:"${FACTER_init_repouser}"/"${FACTER_init_reponame}".git "${FACTER_init_repodir}";
  then
    log_error "Failed to clone git@github.com:${FACTER_init_repouser}/${FACTER_init_reponame}.git"
  fi
}

# Clone public repo
clone_git_http_repo() {
  if ! git clone -b "${FACTER_init_repobranch}" https://github.com/"${FACTER_init_repouser}"/"${FACTER_init_reponame}".git "${FACTER_init_repodir}";
  then
    log_error "Failed to clone https://github.com/${FACTER_init_repouser}/${FACTER_init_reponame}.git"
  fi
}
# Symlink the cloned git repo to the usual location for Puppet to run
symlink_puppet_dir() {
  # get puppet version - also happens to create /etc/puppetlabs
  local PUPPETVER=$(echo $(puppet --version) | cut -d '.' -f 1)
  local RESULT=''
  # Link $puppetdir to our private repo.
  PUPPET_DIR="${FACTER_init_repodir}/puppet"
  if [ -e ${puppetdir} ]; then
    RESULT=$(rm -rf ${puppetdir});
    if [[ $? != 0 ]]; then
      log_error "Failed to remove ${puppetdir}\nrm returned:\n${RESULT}"
    fi
  fi

  RESULT=$(ln -s "${PUPPET_DIR}" ${puppetdir})
  if [[ $? != 0 ]]; then
    log_error "Failed to create symlink from ${PUPPET_DIR}\nln returned:\n${RESULT}"
  fi

  if [ -e /etc/hiera.yaml ]; then
    RESULT=$(rm -f /etc/hiera.yaml)
    if [[ $? != 0 ]]; then
      log_error "Failed to remove /etc/hiera.yaml\nrm returned:\n${RESULT}"
    fi
  fi

  RESULT=$(ln -s ${puppetdir}/hiera.yaml /etc/hiera.yaml)
  if [[ $? != 0 ]]; then
    log_error "Failed to create symlink from /etc/hiera.yaml\nln returned:\n${RESULT}"
  fi

  # if puppet ver = 4, link to modules
  if [[ "${PUPPETVER}" == "4" ]]; then
    local codedir="/etc/puppetlabs/code"
    if [ -e ${codedir} ]; then
      RESULT=$(rm -rf ${codedir});
      if [[ $? != 0 ]]; then
        log_error "Failed to remove ${codedir}\nrm returned:\n${RESULT}"
      fi
    fi

    RESULT=$(ln -s "${PUPPET_DIR}" ${codedir})
    if [[ $? != 0 ]]; then
      log_error "Failed to create symlink from ${PUPPET_DIR}\nln returned:\n${RESULT}"
    fi
  fi
}

run_librarian() {
  gem_install activesupport:4.2.6 librarian-puppet
  echo -n "Running librarian-puppet"
  local RESULT=''
  RESULT=$(librarian-puppet install --verbose)
  if [[ $? != 0 ]]; then
    log_error "librarian-puppet failed.\nThe full output was:\n${RESULT}"
  fi
  librarian-puppet show
}

# Fetch the Puppet modules via the moduleshttpcache or librarian-puppet
fetch_puppet_modules() {
  ENV_BASE_PUPPETFILE="${FACTER_init_env}/Puppetfile.base"
  ENV_ROLE_PUPPETFILE="${FACTER_init_env}/Puppetfile.${FACTER_init_role}"
  BASE_PUPPETFILE=Puppetfile.base
  ROLE_PUPPETFILE=Puppetfile."${FACTER_init_role}"
  if [[ -f "${puppetdir}/Puppetfiles/${ENV_BASE_PUPPETFILE}" ]]; then
    BASE_PUPPETFILE="${ENV_BASE_PUPPETFILE}"
  fi
  if [[ -f "${puppetdir}/Puppetfiles/${ENV_ROLE_PUPPETFILE}" ]]; then
    ROLE_PUPPETFILE="${ENV_ROLE_PUPPETFILE}"
  fi
  PUPPETFILE=${puppetdir}/Puppetfile
  rm -f "${PUPPETFILE}" ; cat ${puppetdir}/Puppetfiles/"${BASE_PUPPETFILE}" ${puppetdir}/Puppetfiles/"${ROLE_PUPPETFILE}" > "${PUPPETFILE}"


  PUPPETFILE_MD5SUM=$(md5sum "${PUPPETFILE}" | cut -d " " -f 1)
  if [[ ! -z $PASSWD ]]; then
    MODULE_ARCH=${FACTER_init_role}."${PUPPETFILE_MD5SUM}".tar.gz.aes
  else
    MODULE_ARCH=${FACTER_init_role}."${PUPPETFILE_MD5SUM}".tar.gz
  fi

  cd "${PUPPET_DIR}" || log_error "Failed to cd to ${PUPPET_DIR}"

  run_librarian
}

# Execute the Puppet run
run_puppet() {
  export LC_ALL=en_GB.utf8
  echo ""
  echo "Running puppet apply"
  puppet apply ${puppetdir}/manifests/site.pp --detailed-exitcodes

  PUPPET_EXIT=$?

  case $PUPPET_EXIT in
    0 )
      echo "Puppet run succeeded with no failures."
      ;;
    1 )
      log_error "Puppet run failed."
      ;;
    2 )
      echo "Puppet run succeeded, and some resources were changed."
      ;;
    4 )
      log_error "Puppet run succeeded, but some resources failed."
      ;;
    6 )
      log_error "Puppet run succeeded, and included both changes and failures."
      ;;
    * )
      log_error "Puppet run returned unexpected exit code."
      ;;
  esac

  #Find the newest puppet log
  local PUPPET_LOG=''
  PUPPET_LOG=$(find /var/lib/puppet/reports -type f -exec ls -ltr {} + | tail -n 1 | awk '{print $9}')
  PERFORMANCE_DATA=( $(grep evaluation_time "${PUPPET_LOG}" | awk '{print $2}' | sort -n | tail -10 ) )
  echo "===============-Top 10 slowest Puppet resources-==============="
  for i in ${PERFORMANCE_DATA[*]}; do
    echo -n "${i}s - "
    echo "$(grep -B 3 "$i" /var/lib/puppet/reports/*/*.yaml | head -1 | awk '{print $2 $3}' )"
  done | tac
  echo "===============-Top 10 slowest Puppet resources-==============="
}

main "$@"