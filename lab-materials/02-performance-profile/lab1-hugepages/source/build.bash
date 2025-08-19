IMG=quay.io/jclaret/lab/hugepages-web:latest
podman build -t $IMG .
podman push $IMG
skopeo copy docker://quay.io/jclaret/lab/hugepages-web:latest docker://registry.offline.lab:5000/lab/hugepages-web:latest
---
oc apply -f hugepages-web.yaml
oc -n hugepages-web rollout status deploy/hugepages-web
oc -n hugepages-web get route hugepages-web -o jsonpath='{.spec.host}{"\n"}'
