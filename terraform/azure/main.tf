terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.6.0"
    }
  }
}

provider "azurerm" {
  features {}
  # make sure ARM_SUBSCRIPTION_ID is set, then `az login --scope https://graph.microsoft.com/.default`
}

resource "azurerm_resource_group" "resource_group1" {
  name     = "resource_group1"
  location = "West US 3"
}

resource "azurerm_virtual_network" "virtual_network1" {
  name                = "virtual_network1"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.resource_group1.location
  resource_group_name = azurerm_resource_group.resource_group1.name
}

resource "azurerm_subnet" "subnet1" {
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.resource_group1.name
  virtual_network_name = azurerm_virtual_network.virtual_network1.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_public_ip" "public_ip1" {
  name                = "public_ip1"
  resource_group_name = azurerm_resource_group.resource_group1.name
  location            = azurerm_resource_group.resource_group1.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "network_interface1" {
  name                = "network_interface1"
  resource_group_name = azurerm_resource_group.resource_group1.name
  location            = azurerm_resource_group.resource_group1.location

  ip_configuration {
    name                          = "ip_configuration1"
    primary                       = true
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    private_ip_address_version    = "IPv4"
    public_ip_address_id          = azurerm_public_ip.public_ip1.id
  }
}

resource "azurerm_network_security_group" "network_security_group1" {
  name                = "network_security_group1"
  location = azurerm_resource_group.resource_group1.location
  resource_group_name = azurerm_resource_group.resource_group1.name
  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "network_interface_security_group_association1" {
  network_interface_id      = azurerm_network_interface.network_interface1.id
  network_security_group_id = azurerm_network_security_group.network_security_group1.id
}

resource "azurerm_linux_virtual_machine" "virtual_machine1" {
  name                = "virtual_machine1"
  resource_group_name = azurerm_resource_group.resource_group1.name
  location            = azurerm_resource_group.resource_group1.location
  size                = "Standard_A4_v2" # 4 vCPU, 8 GiB memory
  admin_username      = "debian"
  network_interface_ids = [
    azurerm_network_interface.network_interface1.id,
  ]

  admin_ssh_key {
    username   = "debian"
    public_key = file("~/.ssh/id_ed25519.pub")
  }

  source_image_reference {
    publisher = "Debian"
    offer     = "debian-12"
    sku       = "12-gen2"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}

output "instance_username" {
  value = "debian"
}

output "instance_ipv4" {
  value = azurerm_public_ip.public_ip1.ip_address
}
