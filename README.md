When terraform creates basic infrastructure need create "root" application

Need to add for each resource to manage it through helm
  annotations:
    meta.helm.sh/release-name: RELEASE_NAME
    meta.helm.sh/release-namespace: ACTUALL_NAMESPACE
  labels:
    app.kubernetes.io/managed-by: Helm