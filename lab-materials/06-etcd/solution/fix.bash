oc delete pod break-etcd -n default
oc delete pod -n openshift-etcd etcd-guard-mno1-ctlplane-2
oc delete pod -n openshift-etcd etcd-mno1-ctlplane-2
