// Define the parameter for location
param location string
param email string
param publisherName string
param suffix string
param openAiLocation string
param customSubDomainName string
param openai_model_deployments array = []

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
    networkSecurityGroup: {
      id: nsg.id
    }
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

// Create for Network Security Group
resource nsg 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: 'nsg-api'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-3443-Inbound'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3443'
        }
      }
      {
        name: 'Allow-3443-Outbound'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Outbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3443'
        }
      }
    ]
  }
}

// Application Gateway Public IP
resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name: 'pip-gateway-openai'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

// Craete Application Gateway, subenet name "snet-gateway"
resource appgateway 'Microsoft.Network/applicationGateways@2021-08-01' = {
  name: 'gateway-openai'
  location: location
  properties: {
    sku: {
      // 後で選択できるように変更する
      name: 'Standard_v2'
      tier: 'Standard_v2'
      capacity: 2
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            //id: snetgateway.id
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'vnet-gateway', 'snet-gateway')
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          // 後で、パブリックIPを固定する
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            //id: snetgateway.id
            id: publicIPAddress.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'http'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendPool'
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpSettings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: 30
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        properties: {
          frontendIPConfiguration: {
            //id: appgateway.properties.frontendIPConfigurations[0].id
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', 'gateway-openai', 'appGatewayFrontendIP')
          }
          frontendPort: {
            //id: appgateway.properties.frontendPorts[1].id
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', 'gateway-openai', 'http')
          }
        }
      }
    ]
    //ルールはあとで書く
    requestRoutingRules: [
      {
        name: 'rule1'
        properties: {
          ruleType: 'Basic'
          priority: 10
          httpListener: {
            //id: appgateway.properties.httpListeners[0].id
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', 'gateway-openai', 'appGatewayHttpListener')
          }
          backendAddressPool: {
            //id: appgateway.properties.backendAddressPools[0].id
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', 'gateway-openai', 'appGatewayBackendPool')
          }
          backendHttpSettings: {
            //id: appgateway.properties.backendHttpSettingsCollection[0].id
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', 'gateway-openai', 'appGatewayBackendHttpSettings')
          }
        }
      }
    ]
  }
}

// Create API Management
resource apim 'Microsoft.ApiManagement/service@2020-06-01-preview' = {
  name: 'apim-openai-${suffix}'
  location: location
  sku: {
    name: 'Developer'
    capacity: 1
  }
  properties: {
    publisherEmail: email
    publisherName: publisherName
    virtualNetworkType: 'External'
    virtualNetworkConfiguration: {
      vnetid: vnetapp.id
      subnetResourceId: snetapi.id
    }
  }
}

// OpenAI Account + Model
module openAi 'modules/cognitiveservices.bicep' = {
  name: 'my-openai-account'
  scope: resourceGroup()
  params: {
    name: 'openai'
    openaiLocation: openAiLocation
    sku: {
      name: 'S0'
    }
    customSubDomainName: customSubDomainName
    deployments: openai_model_deployments
  }
}
