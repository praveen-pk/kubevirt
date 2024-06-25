#!/usr/bin/bash -x

kind create cluster --name como --config ../kind_cluster.yaml
export RELEASE=$(curl https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)

export prefix="kubevirt"
export tag="al3-qemu"

# load devel images in kind cluster
for comp in virt-launcher virt-controller virt-handler virt-api virt-operator; do
    kind load docker-image $prefix/$comp:$tag --name como
done

 kubectl apply -f ./kubevirt-operator.yaml
 kubectl apply -f ./kubevirt-cr.yaml

# Apply the shasum after creating kubevirt-operator
VIRT_API_SHASUM=$(docker inspect kubevirt/virt-api:${tag} | jq -r '.[0]|.Id' | cut -f 2 -d :)
VIRT_CONTROLLER_SHASUM=$(docker inspect kubevirt/virt-controller:${tag} | jq -r '.[0]|.Id' | cut -f 2 -d :)
VIRT_LAUNCHER_SHASUM=$(docker inspect kubevirt/virt-launcher:${tag} | jq -r '.[0]|.Id' | cut -f 2 -d :)
VIRT_HANDLER_SHASUM=$(docker inspect kubevirt/virt-handler:${tag} | jq -r '.[0]|.Id' | cut -f 2 -d :)

kubectl set env deployment -n kubevirt virt-operator \
    VIRT_HANDLER_SHASUM=$VIRT_HANDLER_SHASUM \
    VIRT_LAUNCHER_SHASUM=$VIRT_LAUNCHER_SHASUM \
    VIRT_CONTROLLER_SHASUM=$VIRT_CONTROLLER_SHASUM \
    VIRT_API_SHASUM=$VIRT_API_SHASUM

 kubectl -n kubevirt wait kv kubevirt --for condition=Available

exit 0

# Load guest images
kind load docker-image quay.io/kubevirt/cirros-container-disk-demo:latest --name como

kubectl apply -k https://github.com/kubevirt/common-instancetypes.git/VirtualMachineInstancetypes

kubectl apply -f https://kubevirt.io/labs/manifests/vm.yaml

