export OCP_VERSION="4.16.30"
VARIABLE_NAME=$(curl -s https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$OCP_VERSION/release.txt | grep -m1 'rhel-coreos' | awk -F ' ' '{print $2}')
podman build -t ethtool-6.2-1.el9.x86_64:${OCP_VERSION} --no-cache --build-arg rhel_coreos_release=${VARIABLE_NAME} .
podman tag localhost/ethtool-6.2-1.el9.x86_64:${OCP_VERSION} quay.io/jclaret/lab/ethtool-6.2-1.el9.x86_64:${OCP_VERSION}
podman push quay.io/jclaret/lab/ethtool-6.2-1.el9.x86_64:${OCP_VERSION}
skopeo copy docker://quay.io/jclaret/lab/ethtool-6.2-1.el9.x86_64:${OCP_VERSION} docker://registry.offline.lab:5000/lab/ethtool-6.2-1.el9.x86_64:${OCP_VERSION}
