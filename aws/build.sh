
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
usage: $SCRIPTNAME [-h] --env=ENV --action=ACTION [--target=TARGET]
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
    -a=*|--action=*)
        ACTION="${i#*=}"
        shift # past argument=value
        ;;
    -e=*|--env=*)
        ENV="${i#*=}"
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
if [ -z ${ENV} ]; then
		errmsg "Required option not set: --env"
		help
fi

if [ -z ${ACTION} ]; then
		errmsg "Required option not set: --action"
		help
elif [ ${ACTION} != "destroy" ] && [ ${ACTION} != "apply" ] && [ ${ACTION} != "refresh" ]; then
    errmsg "Invalid action: --action should be on of apply, refresh or destroy"
    help
fi

if [ -z ${TARGET} ]; then
  TARGET_ARG=""
else
  TARGET_ARG="--target=${TARGET}"
fi

echo "ENV           = ${ENV}"
echo "ACTION        = ${ACTION}"
echo "TARGET        = ${TARGET}"

# ensure formatting
terraform fmt

# set workspace
terraform workspace select ${ENV} || terraform workspace new ${ENV}

# update modules as required
terraform get -update=true

# ensure backend is initialized
terraform init -backend-config=env_vars/backend-${ENV}.tfvars

# check for destroy
if [ "destroy" = "${ACTION}" ]; then 
terraform ${ACTION} -var-file=env_vars/${ENV}.tfvars ${TARGET_ARG}
elif [ "apply" = "${ACTION}" ]; then
# else plan, show and apply
terraform plan -var-file=env_vars/${ENV}.tfvars -out ${ENV}.tfplan ${TARGET_ARG}
terraform show -no-color ${ENV}.tfplan
terraform ${ACTION} ${ENV}.tfplan
rm -f ${ENV}.tfplan
elif [ "refresh" = "${ACTION}" ]; then
terraform ${ACTION} -var-file=env_vars/${ENV}.tfvars
else
errmsg "Unknown action."
help
fi
