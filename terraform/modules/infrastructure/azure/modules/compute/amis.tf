data "azurerm_platform_image" "ubuntu_focal" {
    location  = var.region
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
}

data "azurerm_platform_image" "debian_11" {
    location  = var.region
    publisher = "Debian"
    offer     = "debian-11"
    sku       = "11"
    version   = "latest"
}

data "azurerm_platform_image" "centos8" {
    location  = var.region
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "8_5-gen2"
    version   = "latest"
}

data "azurerm_platform_image" "windowsserver_2019" {
    location  = var.region
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
}

data "azurerm_platform_image" "rocky_linux_8" {
    location = var.region
    publisher = "erockyenterprisesoftwarefoundationinc1653071250513"
    offer     = "rockylinux"
    sku       = "free"
    version   = "8.7.20230215"
}


locals {
    amis = {
        ubuntu_focal = data.azurerm_platform_image.ubuntu_focal
        debian_11 = data.azurerm_platform_image.debian_11
        centos8 = data.azurerm_platform_image.centos8
        rocky_linux_8 = data.azurerm_platform_image.rocky_linux_8
        windowsserver_2019 = data.azurerm_platform_image.windowsserver_2019
    }
}