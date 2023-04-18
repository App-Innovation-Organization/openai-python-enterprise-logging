// Define the parameter for location
param location string

// Virtual Network that serves as the gateway
resource vnetgateway 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: 'vnet-gateway'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
  }
}

// Subnet that serves as the gateway
resource snetgateway 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  parent: vnetgateway
  name: 'snet-gateway'
  properties: {
    addressPrefix: '10.0.1.0/24'
  }
}

// Virtual Network for workload
resource vnetapp 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: 'vnet-app'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
  }
}

// Subnet for API Management
resource snetapi 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  parent: vnetapp
  name: 'snet-api'
  properties: {
    addressPrefix: '10.1.1.0/24'
  }
}

// Subnet for Private Links
resource snetendpoints 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  parent: vnetapp
  name: 'snet-endpoints'
  properties: {
    addressPrefix: '10.1.2.0/24'
  }
}
