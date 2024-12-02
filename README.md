When terraform creates basic infrastructure need create "root" application, and run it using "kubectl apply -f root-app.yaml
All "kind: Application" must situated in the same namespace that root application


Problems to solve:
  1. Cleaning storage efs and general if user is deleted.
  2. Create domain name for each user, create A record in Route53 by terraform. Run terraform with this script.
  3. Creating folder with user themes by script in EFS storage  

Commands:
  kubectl port-forward service/argocd-server -n argocd 8080:443
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d