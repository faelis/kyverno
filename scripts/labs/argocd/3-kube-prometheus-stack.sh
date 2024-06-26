#!/usr/bin/env bash

set -e

# CREATE KUBE-PROMETHEUS-STACK APP

kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: kube-prometheus-stack
  namespace: argocd
spec:
  destination:
    namespace: monitoring
    server: https://kubernetes.default.svc
  project: default
  source:
    chart: kube-prometheus-stack
    repoURL: https://prometheus-community.github.io/helm-charts
    targetRevision: 41.7.3
    helm:
      values: |
        kubeEtcd:
          service:
            enabled: true
            targetPort: 2381
        defaultRules:
          create: true
        alertmanager:
          alertmanagerSpec:
            routePrefix: /alertmanager
            alertmanagerConfigSelector:
              matchLabels: {}
            alertmanagerConfigNamespaceSelector:
              matchLabels: {}
          ingress:
            enabled: true
            pathType: Prefix
        prometheus:
          prometheusSpec:
            externalUrl: /prometheus
            routePrefix: /prometheus
            ruleSelectorNilUsesHelmValues: false
            serviceMonitorSelectorNilUsesHelmValues: false
            podMonitorSelectorNilUsesHelmValues: false
            probeSelectorNilUsesHelmValues: false
          ingress:
            enabled: true
            pathType: Prefix
        grafana:
          enabled: true
          adminPassword: admin
          sidecar:
            enableUniqueFilenames: true
            dashboards:
              enabled: true
              searchNamespace: ALL
              provider:
                foldersFromFilesStructure: true
            datasources:
              enabled: true
              searchNamespace: ALL
          grafana.ini:
            server:
              root_url: "%(protocol)s://%(domain)s:%(http_port)s/grafana"
              serve_from_sub_path: true
          ingress:
            enabled: true
            path: /grafana
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true
EOF
