data "azurerm_platform_image" "ubuntu_focal" {
    location  = var.region
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
}

data "azurerm_platform_image" "debian_11" {
    location  = var.region
    publisher = "Debian"
    offer     = "debian-11"
    sku       = "11"
}

data "azurerm_platform_image" "centos8" {
    location  = var.region
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "8_5-gen2"
}

data "azurerm_platform_image" "windowsserver_2019" {
    location  = var.region
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
}

data "azurerm_platform_image" "windowsserver_2022" {
    location  = var.region
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
}


data "azurerm_platform_image" "rocky_linux_8" {
    location  = var.region
    publisher = "erockyenterprisesoftwarefoundationinc1653071250513"
    offer     = "rockylinux"
    sku       = "free"
    version   = "8.7.20230215"
}