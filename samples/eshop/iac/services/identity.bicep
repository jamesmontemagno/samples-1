import radius as rad

// PARAMETERS ---------------------------------------------------------

@description('Radius application ID')
param application string

@description('Optional App Insights Key')
param APPLICATION_INSIGHTS_KEY string

@description('Use dev spaces')
@allowed([
  'True'
  'False'
])
param ENABLEDEVSPACES string

@description('Container image tag to use for eshop images')
param TAG string

@description('Name of the Gateway')
param gatewayName string

@description('Name of the Basket Container')
param basketHttpName string

@description('Name of the Ordering Container')
param orderingHttpName string

@description('Name of the WebShoppingAgg Container')
param webshoppingaggHttpName string

@description('Name of the Webhooks Container')
param webhooksHttpName string

@description('Name of the WebhooksClient Container')
param webhooksclientHttpName string

@description('Name of the WebMVC Container')
param webmvcHttpName string

@description('Name of the Identity SQL Database portable resource')
param sqlIdentityDbName string

@description('Name of the Keystore Redis portable resource')
param redisKeystoreName string

// CONTAINERS -------------------------------------------------------------------

// Based on https://github.com/dotnet-architecture/eShopOnContainers/tree/dev/deploy/k8s/helm/identity-api
resource identity 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'identity-api'
  properties: {
    application: application
    container: {
      image: 'ghcr.io/radius-project/samples/eshop/identity.api:${TAG}'
      env: {
        PATH_BASE: '/identity-api'
        ASPNETCORE_ENVIRONMENT: 'Development'
        ASPNETCORE_URLS: 'http://0.0.0.0:80'
        OrchestratorType: 'K8S'
        IsClusterEnv: 'True'
        DPConnectionString: redisKeystore.connectionString()
        ApplicationInsights__InstrumentationKey: APPLICATION_INSIGHTS_KEY
        XamarinCallback: ''
        EnableDevspaces: ENABLEDEVSPACES
        ConnectionString: sqlIdentityDb.connectionString()
        MvcClient: '${gateway.properties.url}/${webmvcHttp.name}'
        SpaClient: gateway.properties.url
        BasketApiClient: '${gateway.properties.url}/${basketHttp.name}'
        OrderingApiClient: '${gateway.properties.url}/${orderingHttp.name}'
        WebShoppingAggClient: '${gateway.properties.url}/${webshoppingaggHttp.name}'
        WebhooksApiClient: '${gateway.properties.url}/${webhooksHttp.name}'
        WebhooksWebClient: '${gateway.properties.url}/${webhooksclientHttp.name}'
      }
      ports: {
        http: {
          containerPort: 80
          port: 5105
        }
      }
    }
    connections: {
      redis: {
        source: redisKeystore.id
        disableDefaultEnvVars: true
      }
      sql: {
        source: sqlIdentityDb.id
        disableDefaultEnvVars: true
      }
      webmvc: {
        source: webmvcHttp.id
        disableDefaultEnvVars: true
      }
      basket: {
        source: basketHttp.id
        disableDefaultEnvVars: true
      }
      ordering: {
        source: orderingHttp.id
        disableDefaultEnvVars: true
      }
      webshoppingagg: {
        source: webshoppingaggHttp.id
        disableDefaultEnvVars: true
      }
      webhooks: {
        source: webhooksHttp.id
        disableDefaultEnvVars: true
      }
      webhoolsclient: {
        source: webhooksclientHttp.id
        disableDefaultEnvVars: true
      }
    }
  }
}

// NETWORKING ------------------------------------------------------

resource gateway 'Applications.Core/gateways@2023-10-01-preview' existing = {
  name: gatewayName
}

resource basketHttp 'Applications.Core/containers@2022-03-15-privatepreview' existing = {
  name: basketHttpName
}

resource orderingHttp 'Applications.Core/containers@2022-03-15-privatepreview' existing = {
  name: orderingHttpName
}

resource webshoppingaggHttp 'Applications.Core/containers@2022-03-15-privatepreview' existing = {
  name: webshoppingaggHttpName
}

resource webhooksHttp 'Applications.Core/containers@2022-03-15-privatepreview' existing =  {
  name: webhooksHttpName
}

resource webhooksclientHttp 'Applications.Core/containers@2022-03-15-privatepreview' existing = {
  name: webhooksclientHttpName
}

resource webmvcHttp 'Applications.Core/containers@2022-03-15-privatepreview' existing = {
  name: webmvcHttpName
}

// PORTABLE RESOURCES -----------------------------------------------------------

resource sqlIdentityDb 'Applications.Datastores/sqlDatabases@2023-10-01-preview' existing = {
  name: sqlIdentityDbName
}

resource redisKeystore 'Applications.Datastores/redisCaches@2023-10-01-preview' existing = {
  name: redisKeystoreName
}


// Output
@description('Name of the Identity container')
output container string = identity.name
