
#!/bin/bash

SCRIPTNAME=$(basename $0)
VERSION="1.0.0"

info(){
cat <<EOI
$SCRIPTNAME ($VERSION)

EOI
}

help(){
cat <<EOH
usage: $SCRIPTNAME [-h] --workspace=WORK --action=ACTION
EOH
    exit 1
}

infomsg(){
echo "INFO: ${1}"
}
warnmsg(){
echo "WARN: ${1}"
}
errmsg(){
echo "ERROR: ${1}"
}

for i in "$@"; do
  case $i in
    -h|--help)
        HELP="${i#*=}"
        shift # past argument=value
        help
        ;;
    -a=*|--action=*)
        ACTION="${i#*=}"
        shift # past argument=value
        ;;
    -w=*|--workspace=*)
        WORK="${i#*=}"
        shift # past argument=value
        ;;
    *)
      # unknown option
      ;;
  esac
done

# check for required
if [ -z ${WORK} ]; then
    errmsg "Required option not set: --workspace"
    help
fi

if [ -z ${ACTION} ]; then
    errmsg "Required option not set: --action"
    help
elif [ "${ACTION}" != "destroy" ] && [ "${ACTION}" != "apply" ] && [ "${ACTION}" != "plan" ] && [ "${ACTION}" != "refresh" ]; then
    errmsg "Invalid action: --action should be one of plan, apply, refresh or destroy"
    help
fi

# use variables.tfvars if it exists
if [ -f "env_vars/variables.tfvars" ]; then
  VARS="-var-file=env_vars/variables.tfvars"
else
  VARS=""
fi

# look for work space variables
if [ -f "env_vars/variables-${WORK}.tfvars" ]; then
  VARS="${VARS} -var-file=env_vars/variables-${WORK}.tfvars"
else
  VARS="${VARS}"
fi

# force local back-end
LOCAL_BACKEND="true"

echo "ACTION            = ${ACTION}"
echo "LOCAL_BACKEND     = ${LOCAL_BACKEND}"
echo "VARS              = ${VARS}"

# ensure formatting
terraform fmt

# set workspace
terraform workspace select ${WORK} || terraform workspace new ${WORK}

# update modules as required
terraform get -update=true

# ensure backend is initialized
if [ -z ${LOCAL_BACKEND} ]; then
terraform init -backend-config=env_vars/init.tfvars
BACKEND="-var-file=env_vars/backend.tfvars"
else
terraform init
BACKEND=""
fi;

check_tf_apply(){
    if [ ${1} -eq 0 ]; then
        warnmsg "No changes, not applying"
    elif [ ${1} -eq 1 ]; then
        errmsg "Terraform plan failed"
        exit 1
    elif [ ${1} -eq 2 ]; then
        if [ "apply" = "${2}" ]; then
            infomsg "Changes required, applying"
            terraform show ${PLANFILE}
            terraform apply ${3}
        else
            warnmsg "Plan only, not applying"
        fi
    fi
}

# set plan file
PLANFILE="build.tfplan"

if [ "plan" = "${ACTION}" ]; then
    echo "Running: terraform plan ${DESTROY} ${BACKEND} ${VARS} -out ${PLANFILE} -detailed-exitcode"
    terraform plan ${BACKEND} ${VARS} -out ${PLANFILE} -detailed-exitcode
    ERR=$?
    terraform show ${PLANFILE}
elif [ "apply" = "${ACTION}" ]; then        
    echo "Running: terraform plan ${DESTROY} ${BACKEND} ${VARS} -out ${PLANFILE} -detailed-exitcode"
    terraform plan ${BACKEND} ${VARS} -out ${PLANFILE} -detailed-exitcode
    ERR=$?
    check_tf_apply ${ERR} apply ${PLANFILE}
elif [ "destroy" = "${ACTION}" ]; then
    echo "Running: terraform plan ${DESTROY} ${BACKEND} ${VARS} -out ${PLANFILE} -detailed-exitcode"
    terraform plan -destroy ${BACKEND} ${VARS} -out ${PLANFILE} -detailed-exitcode
    ERR=$?
    check_tf_apply ${ERR} apply ${PLANFILE}
fi
rm -f ${PLANFILE}

echo "Done."