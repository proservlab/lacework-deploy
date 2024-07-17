########################################
# INSTANCE SUMMARY - DEFAULT AND APP
########################################

locals {
    instances = flatten([
            [for instance in azurerm_linux_virtual_machine.instances : {
                id         = instance.id
                name       = instance.name
                public_ip  = instance.public_ip_address
                admin_user = instance.admin_username
                ssh_key_path = local.ssh_key_path
                role       = lookup(instance.tags,"role","default")
                public     = lookup(instance.tags,"public","false")
                tags       = instance.tags
                dynu_dns_name = var.enable_dynu_dns == true ? "${instance.name}.${var.dynu_dns_domain}" : null
            }],
            [for instance in azurerm_linux_virtual_machine.instances-app : {
                id         = instance.id
                name       = instance.name
                public_ip  = instance.public_ip_address
                admin_user = instance.admin_username
                ssh_key_path = local.ssh_key_path
                role       = lookup(instance.tags,"role","app")
                public     = lookup(instance.tags,"public","false")
                tags       = instance.tags
                dynu_dns_name = var.enable_dynu_dns == true ? "${instance.name}.${var.dynu_dns_domain}" : null
            }]
    ])

    public_compute_instances = var.enable_dynu_dns == true ? [ for compute in local.instances: compute if compute.public == "true" ] : []
    public_instances = [ for compute in local.instances: compute.public_ip if compute.role == "default" && compute.public == "true" ]
    public_app_instances = [ for compute in local.instances: compute.public_ip if compute.role == "app" && compute.public == "true" ]
    private_instances = [ for compute in local.instances: compute.public_ip if compute.role == "default" && compute.public == "false" ]
    private_app_instances = [ for compute in local.instances: compute.public_ip if compute.role == "app" && compute.public == "false" ]
}