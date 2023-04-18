// Define the virtual network
resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: 'myVnet'
  location: 'japaneast'
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
  }
}

// Define the first subnet
resource subnet1 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  parent: vnet
  name: 'mySubnet1'
  properties: {
    addressPrefix: '10.0.1.0/24'
  }
}

// Define the second subnet
resource subnet2 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  parent: vnet
  name: 'mySubnet2'
  properties: {
    addressPrefix: '10.0.2.0/24'
  }
}

