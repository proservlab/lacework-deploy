resource "lacework_query" "eks-1-1-0-4-1-4" {
    query_id = "TF_CUSTOM_EKS_CLUSTER_ROLE_CREATE_POD"
    query    = <<-EOT
    {
      source {
          LW_CFG_K8S_CLUSTER_CLUSTERROLEBINDING
      }
      filter {
          -- Where the role in the binding has permission to create pods
          RESOURCE_CONFIG:roleRef.name in {
              source {
                  LW_CFG_K8S_CLUSTER_CLUSTERROLE clusterrole,
                  array_to_rows(clusterrole.RESOURCE_CONFIG:rules) as (rule),
                  array_to_rows(rule:resources) as (resource),
                  array_to_rows(rule:verbs) as (verb)
              }
              filter {
                  -- Cluster Roles that have permission to create pods
                  (resource = 'pods' or resource = '*') and (verb = 'create' or verb = '*')
              }
              return distinct {
                  clusterrole.RESOURCE_CONFIG:metadata.name as NAME
              }
          }
          -- AND where the cluster role binding is not one that comes with an EKS cluster as standard
          and RESOURCE_CONFIG:metadata.name not in (
              'aws-node',
              'cluster-admin',
              'cluster-lacework-agent-rb',
              'ebs-csi-attacher-binding',
              'ebs-csi-node-getter-binding',
              'ebs-csi-provisioner-binding',
              'ebs-csi-resizer-binding',
              'ebs-csi-snapshotter-binding',
              'eks:addon-manager',
              'eks:addon-cluster-admin',
              'eks:certificate-controller',
              'eks:certificate-controller-approver',
              'eks:certificate-controller-signer',
              'eks:cloud-controller-manager',
              'eks:cloud-provider-extraction-migration',
              'eks:cluster-event-watcher',
              'eks:fargate-manager',
              'eks:fargate-scheduler',
              'eks:k8s-metrics',
              'eks:kube-proxy',
              'eks:kube-proxy-fargate',
              'eks:kube-proxy-windows',
              'eks:node-bootstrapper',
              'eks:node-manager',
              'eks:nodewatcher',
              'eks:pod-identity-mutating-webhook',
              'eks:podsecuritypolicy:authenticated',
              'eks:tagging-controller',
              'system:basic-user',
              'system:controller:attachdetach-controller',
              'system:controller:certificate-controller',
              'system:controller:clusterrole-aggregation-controller',
              'system:controller:cronjob-controller',
              'system:controller:daemon-set-controller',
              'system:controller:deployment-controller',
              'system:controller:disruption-controller',
              'system:controller:endpoint-controller',
              'system:controller:endpointslice-controller',
              'system:controller:endpointslicemirroring-controller',
              'system:controller:ephemeral-volume-controller',
              'system:controller:expand-controller',
              'system:controller:generic-garbage-collector',
              'system:controller:horizontal-pod-autoscaler',
              'system:controller:job-controller',
              'system:controller:namespace-controller',
              'system:controller:node-controller',
              'system:controller:persistent-volume-binder',
              'system:controller:pod-garbage-collector',
              'system:controller:pv-protection-controller',
              'system:controller:pvc-protection-controller',
              'system:controller:replicaset-controller',
              'system:controller:replication-controller',
              'system:controller:resourcequota-controller',
              'system:controller:root-ca-cert-publisher',
              'system:controller:route-controller',
              'system:controller:service-account-controller',
              'system:controller:service-controller',
              'system:controller:statefulset-controller',
              'system:controller:ttl-after-finished-controller',
              'system:controller:ttl-controller',
              'system:coredns',
              'system:discovery',
              'system:kube-controller-manager',
              'system:kube-dns',
              'system:kube-scheduler',
              'system:monitoring',
              'system:node',
              'system:node-proxier',
              'system:public-info-viewer',
              'system:service-account-issuer-discovery',
              'system:volume-scheduler',
              'vpc-resource-controller-rolebinding'
          )
      }
      return distinct {
          CLUSTER_ID,
          CLUSTER_TYPE,
          RESOURCE_ID,
          URN as RESOURCE_KEY,
          RESOURCE_TYPE,
          'ClusterRoleBindingWithCreatePodPermission' as COMPLIANCE_FAILURE_REASON
      }
    }
    EOT
}

resource "lacework_policy" "eks-1-1-0-4-1-4" {
  title       = "Minimize access to create pods in ClusterRoles"
  description = "The ability to create pods in a namespace can provide a number of opportunities for privilege escalation, such as assigning privileged service accounts to these pods or mounting hostPaths with access to sensitive data (unless Pod Security Policies are implemented to restrict this access)."
  remediation = "Where possible, remove create access to pod objects in the cluster."
  query_id    = lacework_query.eks-1-1-0-4-1-4.id
  severity    = "High"
  type        = "Violation"
  evaluation  = "Hourly"
  # tags        = ["domain:AWS", "custom"]
  enabled     = true

  alerting {
    enabled = true
    profile = "LW_CFG_K8S_CLUSTER_DEFAULT_PROFILE.Violation"
  }
}

