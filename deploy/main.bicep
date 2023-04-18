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


// Craete Application Gateway, subenet name "snet-gateway"
resource appgateway 'Microsoft.Network/applicationGateways@2020-11-01' = {
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
            id: snetgateway.id
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
          subnet: {
            id: snetgateway.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'https'
        properties: {
          port: 443
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
        name: 'appGatewayHttpsListener'
        properties: {
          frontendIPConfiguration: {
            //id: appgateway.properties.frontendIPConfigurations[0].id
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', 'gateway-openai', 'appGatewayFrontendIP')
          }
          frontendPort: {
            //id: appgateway.properties.frontendPorts[1].id
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', 'gateway-openai', 'https')
          }
          protocol: 'Https'
          sslCertificate: {
            //id: appgateway.properties.sslCertificates[0].id
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', 'gateway-openai', 'appGatewaySslCertificate')
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
          httpListener: {
            //id: appgateway.properties.httpListeners[0].id
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', 'gateway-openai', 'appGatewayHttpsListener')
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
