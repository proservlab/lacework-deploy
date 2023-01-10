
#!/bin/bash

SCRIPTNAME=$(basename $0)
VERSION="0.0.1"

info(){
cat <<EOI
$SCRIPTNAME ($VERSION)

EOI
}

help(){
cat <<EOH
usage: $SCRIPTNAME [-h] [--local-backend] --workspace=WORK --action=ACTION [--target=TARGET]
EOH
		exit 1
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
    -l|--local-backend)
        LOCAL_BACKEND="${i#*=}"
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
    -t=*|--target=*)
        TARGET="${i#*=}"
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
elif [ ${ACTION} != "destroy" ] && [ ${ACTION} != "apply" ] && [ ${ACTION} != "plan" ] && [ ${ACTION} != "refresh" ]; then
    errmsg "Invalid action: --action should be on of plan, apply, refresh or destroy"
    help
fi

if [ -z ${TARGET} ]; then
  TARGET_ARG=""
else
  TARGET_ARG="--target=${TARGET}"
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

echo "ACTION        = ${ACTION}"
echo "TARGET        = ${TARGET}"
echo "VARS          = ${VARS}"

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

# check for destroy
if [ "destroy" = "${ACTION}" ]; then 
terraform ${ACTION} ${BACKEND} ${VARS} ${TARGET_ARG}
elif [ "apply" = "${ACTION}" ]; then
# else plan, show and apply
echo "Running: terraform plan ${BACKEND} ${VARS} -out build.tfplan ${TARGET_ARG}"
terraform plan ${BACKEND} ${VARS} -out build.tfplan ${TARGET_ARG}
echo "Running: terraform show -no-color build.tfplan"
terraform show -no-color build.tfplan
echo "Running: terraform ${ACTION} build.tfplan"
terraform ${ACTION} build.tfplan
rm -f build.tfplan
elif [ "plan" = "${ACTION}" ]; then
# else plan, show
echo "Running: terraform plan ${BACKEND} ${VARS} -out build.tfplan ${TARGET_ARG}"
terraform plan ${BACKEND} ${VARS} -out build.tfplan ${TARGET_ARG}
echo "Running: terraform show -no-color build.tfplan"
terraform show -no-color build.tfplan
rm -f build.tfplan
elif [ "refresh" = "${ACTION}" ]; then
echo "Running: terraform ${ACTION} ${BACKEND} ${VARS}"
terraform ${ACTION} ${BACKEND} ${VARS}
else
errmsg "Unknown action."
help
fi
