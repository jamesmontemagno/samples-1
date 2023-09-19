import radius as rad

// PARAMETERS ---------------------------------------------------------

@description('Radius application ID')
param application string

@description('What container orchestrator to use')
@allowed([
  'K8S'
])
param ORCHESTRATOR_TYPE string

@description('Optional App Insights Key')
param APPLICATION_INSIGHTS_KEY string

@description('Container image tag to use for eshop images')
param TAG string

@description('Name of the Gateway')
param gatewayName string

@description('Name of the Keystore Redis portable resource')
param redisKeystoreName string

// CONTAINER --------------------------------------------------------------------

// Based on https://github.com/dotnet-architecture/eShopOnContainers/tree/dev/deploy/k8s/helm/webspa
resource webspa 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'web-spa'
  properties: {
    application: application
    container: {
      image: 'ghcr.io/radius-project/samples/eshop/webspa:${TAG}'
      env: {
        PATH_BASE: '/'
        ASPNETCORE_ENVIRONMENT: 'Production'
        ASPNETCORE_URLS: 'http://0.0.0.0:80'
        UseCustomizationData: 'False'
        ApplicationInsights__InstrumentationKey: APPLICATION_INSIGHTS_KEY
        OrchestratorType: ORCHESTRATOR_TYPE
        IsClusterEnv: 'True'
        CallBackUrl: '${gateway.properties.url}/'
        DPConnectionString: redisKeystore.connectionString()
        IdentityUrl: '${gateway.properties.url}/identity-api'
        IdentityUrlHC: 'http://identity-api:5105/hc'
        PurchaseUrl: '${gateway.properties.url}/webshoppingapigw'
        SignalrHubUrl: 'http://ordering-signalrhub:5112'
      }
      ports: {
        http: {
          containerPort: 80
          port: 5104
        }
      }
    }
    connections: {
      redis: {
        source: redisKeystore.id
        disableDefaultEnvVars: true
      }
      webshoppingagg: {
        source: 'http://webshoppingagg:5121'
        disableDefaultEnvVars: true
      }
      identity: {
        source: 'http://identity-api:5105'
        disableDefaultEnvVars: true
      }
      webshoppingapigw: {
        source: 'http://webshoppingapigw:5202'
        disableDefaultEnvVars: true
      }
      orderingsignalrhub: {
        source: 'http://ordering-signalrhub:5112'
        disableDefaultEnvVars: true
      }
    }
  }
}

// Based on https://github.com/dotnet-architecture/eShopOnContainers/tree/dev/deploy/k8s/helm/webmvc
resource webmvc 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'webmvc'
  properties: {
    application: application
    container: {
      image: 'ghcr.io/radius-project/samples/eshop/webmvc:${TAG}'
      env: {
        ASPNETCORE_ENVIRONMENT: 'Development'
        ASPNETCORE_URLS: 'http://0.0.0.0:80'
        PATH_BASE: '/webmvc'
        UseCustomizationData: 'False'
        DPConnectionString: redisKeystore.connectionString()
        ApplicationInsights__InstrumentationKey: APPLICATION_INSIGHTS_KEY
        UseLoadTest: 'False'
        OrchestratorType: ORCHESTRATOR_TYPE
        IsClusterEnv: 'True'
        ExternalPurchaseUrl: '${gateway.properties.url}/webshoppingapigw'
        CallBackUrl: '${gateway.properties.url}/webmvc'
        IdentityUrl: '${gateway.properties.url}/identity-api'
        IdentityUrlHC: 'http://identity-api:5105/hc'
        PurchaseUrl: 'http://webshoppingapigw:5202'
        SignalrHubUrl: 'http://ordering-signalrhub:5112'
      }
      ports: {
        http: {
          containerPort: 80
          port: 5100
        }
      }
    }
    connections: {
      redis: {
        source: redisKeystore.id
        disableDefaultEnvVars: true
      }
      webshoppingagg: {
        source: 'http://webshoppingagg:5121'
        disableDefaultEnvVars: true
      }
      identity: {
        source: 'http://identity-api:5105'
        disableDefaultEnvVars: true
      }
      webshoppingapigw: {
        source: 'http://webshoppingapigw:5202'
        disableDefaultEnvVars: true
      }
      orderingsignalrhub: {
        source: 'http://ordering-signalrhub:5112'
        disableDefaultEnvVars: true
      }
    }
  }
}

// NETWORKING ----------------------------------------------

resource gateway 'Applications.Core/gateways@2023-10-01-preview' existing = {
  name: gatewayName
}

// PORTABLE RESOURCES ------------------------------------------------------

resource redisKeystore 'Applications.Datastores/redisCaches@2023-10-01-preview' existing = {
  name: redisKeystoreName
}


// Output
@description('Name of the Web spa container')
output spacontainer string = webspa.name

@description('Name of the Web mvc container')
output mvccontainer string = webmvc.name
