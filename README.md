# kubernetes-botpress

#run bash
kubectl exec -it <container> -- /bin/bash

#list pods on nodes
for pod in $(kubectl get pods | awk '{print $1}' | grep -v '^NAME'); do kubectl describe pods $pod | grep '^Node:'; done

