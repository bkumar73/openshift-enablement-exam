# Rook

## deploy ceph VMs

```shell
export cluster_uuid=$(oc get clusterversions.config.openshift.io version -o jsonpath='{.spec.clusterID}{"\n"}')
export infra_id=$(oc get infrastructures.config.openshift.io cluster -o jsonpath='{.status.infrastructureName}{"\n"}')
export region=$(oc get machines -n openshift-machine-api | grep -m 1 master | awk '{print $4}')
export azs=$(oc get machines -n openshift-machine-api | grep master | awk '{print $5}')
export ami=$(oc get machineset -n openshift-machine-api -o jsonpath='{.items[0].spec.template.spec.providerSpec.value.ami.id}')
for az in $azs; do
  az=$az envsubst < rook-machines.yaml | oc apply -f - -n openshift-machine-api
done
```

to delete the machines:

```shell
for az in $azs; do
  az=$az envsubst < rook-machines.yaml | oc delete -f - -n openshift-machine-api
done
```

## deploy storage operator

```shell
oc adm new-project openshift-storage
oc label namespace openshift-storage openshift.io/cluster-monitoring="true"
oc apply -f operator.yaml
```

## deploy OCS cluster

you can do it via WebUI.

cluster will be created in nodes with this label `cluster.ocs.openshift.io/openshift-storage=""`

```shell
oc apply -f ocs_cluster.yaml
```


debug ceph

```shell
curl -s https://raw.githubusercontent.com/rook/rook/release-1.1/cluster/examples/kubernetes/ceph/toolbox.yaml | sed 's/namespace: rook-ceph/namespace: openshift-storage/g'| oc apply -f -
TOOLS_POD=$(oc get pods -n openshift-storage -l app=rook-ceph-tools -o name)
oc rsh -n openshift-storage $TOOLS_POD
```

test storage

test block and file storage
`oc apply -f ./statefulset-ocs-test.yaml -n openshift-storage`
wait for completion

then to clean-up 
`oc delete -f ./statefulset-ocs-test.yaml -n openshift-storage`



## To enable vault encryption

assume you have vault installed and the kubernetes auth method configured

```shell
./vault-config.sh
export VAULT_ADDR=https://vault.apps.control-cluster-raffa.demo.red-chesterfield.com
export VAULT_TOKEN=$(oc get secret vault-init -n vault -o jsonpath="{.data.root_token}" | base64 -d )
envsubst < ocs-cluster-vault.yaml | oc apply -f - -n openshift-storage
envsubst < vault-encryption-token-secret.yaml | oc apply -f - -n openshift-storage
oc apply -f vault-encryption-configmap.yaml -n openshift-storage
oc apply -f vault-encryption-rbac.yaml -n openshift-storage
oc apply -f vault-encryption-storage-class.yaml
```