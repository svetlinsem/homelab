export OS_USERNAME=<feide-id>
export OS_PROJECT_NAME=<project>
export OS_PASSWORD=<password>
export OS_AUTH_URL=https://api.nrec.no:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_USER_DOMAIN_NAME=dataporten
export OS_PROJECT_DOMAIN_NAME=dataporten
export OS_REGION_NAME=<region>
export OS_INTERFACE=public
export OS_NO_CACHE=1
export TF_VAR_K8S_WORKER_COUNT=19
export TF_VAR_K8S_WORKER_FLAVOR="m1.medium"
export TF_VAR_K8S_IMAGE_NAME="Debian12"
export TF_VAR_K8S_NETWORK_NAME="dualStack"
export TF_VAR_K8S_KEY_PAIR="k8s-nodes"
export TF_VAR_K8S_KEY_PAIR_LOCATION="~/.ssh"
export TF_VAR_K8S_SECURITY_GROUP="SSH and ICMP"
export ANSIBLE_NOCOWS=1