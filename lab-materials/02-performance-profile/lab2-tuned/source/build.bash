IMG=quay.io/jclaret/lab/conntrack-app:latest
podman build -t $IMG .
podman push $IMG
skopeo copy docker://quay.io/jclaret/lab/conntrack-app:latest docker://registry.offline.lab:5000/lab/conntrack-app:latest
---
oc new-project conntrack-app
oc apply -f deployment.yaml
oc -n conntrack-app rollout status deploy/conntrack-app
oc -n conntrack-app get route conntrack-app -o jsonpath='{.spec.host}{"\n"}'

