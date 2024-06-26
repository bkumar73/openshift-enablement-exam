set -o nounset
set -o errexit

function create_openshift()
{
  mkdir -p ./cluster$CLUSTER_ID
  export pull_secret=$(cat ./pullsecret.json)
  envsubst < ./config/config-acm/install-config-raffa$CLUSTER_ID.yaml > ./cluster$CLUSTER_ID/install-config.yaml
  #~/Downloads/openshift-install-linux-4.4.0-0.nightly-2020-02-17-103442/openshift-install create cluster --dir ./cluster$CLUSTER_ID --log-level debug
  openshift-install create cluster --dir ./cluster$CLUSTER_ID --log-level debug
  export KUBECONFIG=/home/rspazzol/git/openshift-enablement-exam/4.0/cluster${CLUSTER_ID}/auth/kubeconfig
  # create route 
  oc create route reencrypt apiserver --service kubernetes --port https -n default
  # add simple user
  htpasswd -c -B -b ./cluster$CLUSTER_ID/auth/htpasswd raffa raffa
  oc create secret generic htpass-secret --from-file=htpasswd=./cluster$CLUSTER_ID/auth/htpasswd -n openshift-config
  oc apply -f ../misc4.0/htpasswd/oauth.yaml -n openshift-config
  oc adm policy add-cluster-role-to-user cluster-admin raffa
}

#download_installer
#configure_aws_credentials
#CLUSTER_ID=1-acm create_openshift 
CLUSTER_ID=2-acm create_openshift 