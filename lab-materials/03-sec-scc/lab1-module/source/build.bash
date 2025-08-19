IMG=quay.io/jclaret/lab/module-app:latest
podman build -t $IMG .
podman push $IMG
skopeo copy docker://quay.io/jclaret/lab/module-app:latest docker://registry.offline.lab:5000/lab/module-app:latest
---
oc new-project module-app
oc apply -f deployment.yaml
oc -n module-app rollout status deploy/module-app
oc -n module-app get route module-app -o jsonpath='{.spec.host}{"\n"}'

