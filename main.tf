provider "azurerm" {
  features {}
  subscription_id = "" # Your Azure Subscription ID
}

# Resource Group
resource "azurerm_resource_group" "linux" {
  name     = "Linux"
  location = "North Europe"

  tags = {
    provisioned_by = "terraform"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "linux-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.linux.location
  resource_group_name = azurerm_resource_group.linux.name

  tags = {
    provisioned_by = "terraform"
  }
}

# Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "linux-subnet"
  resource_group_name  = azurerm_resource_group.linux.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP
resource "azurerm_public_ip" "public_ip" {
  name                = "linux-public-ip"
  location            = azurerm_resource_group.linux.location
  resource_group_name = azurerm_resource_group.linux.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    provisioned_by = "terraform"
  }
}

# Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "linux-nsg"
  location            = azurerm_resource_group.linux.location
  resource_group_name = azurerm_resource_group.linux.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "RDP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    provisioned_by = "terraform"
  }
}

# Network Interface
resource "azurerm_network_interface" "nic" {
  name                = "linux-nic"
  location            = azurerm_resource_group.linux.location
  resource_group_name = azurerm_resource_group.linux.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }

  tags = {
    provisioned_by = "terraform"
  }
}

# NSG Association
resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "linux-vm"
  location              = azurerm_resource_group.linux.location
  resource_group_name   = azurerm_resource_group.linux.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  size                  = "Standard_B1s"

  admin_username                  = "testuser1"
  admin_password                  = ""
  disable_password_authentication = false

  os_disk {
    name                 = "linux-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  tags = {
    provisioned_by = "terraform"
  }
}

# Custom Script Extension to install GUI and configure RDP
resource "azurerm_virtual_machine_extension" "install_gui" {
  name                 = "install-xfce-xrdp"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = <<SETTINGS
{
  "script": "${base64encode(file("install_gui.sh"))}"
}
SETTINGS
}
