```shell

oc create namespace openshift-operators-redhat
oc apply -f operators.yaml
oc new-project istio-system
oc apply -f control_plane.yaml -n istio-system
```

Testing:
```shell
oc new-project bookinfo
#oc -n istio-system patch --type='json' smmr default -p '[{"op": "add", "path": "/spec/members", "value":["'"bookinfo"'"]}]'
oc apply -f servicemember.yaml -n bookinfo
oc apply -n bookinfo -f https://raw.githubusercontent.com/Maistra/bookinfo/maistra-1.1/bookinfo.yaml
oc apply -n bookinfo -f https://raw.githubusercontent.com/Maistra/bookinfo/maistra-1.1/bookinfo-gateway.yaml
export istio_gateway_url=$(oc get route istio-ingressgateway -n istio-system -o jsonpath='{.spec.host}')
curl http://${istio_gateway_url}/productpage
```