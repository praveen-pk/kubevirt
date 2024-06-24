#!/bin/bash
prefix=kubevirt
tag=devel

for comp in virt-launcher virt-controller virt-handler virt-api virt-operator; do
    kind load docker-image $prefix/$comp:$tag
done
