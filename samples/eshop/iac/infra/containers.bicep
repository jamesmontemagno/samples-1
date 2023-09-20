import radius as rad

@description('Radius environment ID')
param environment string

@description('Radius application ID')
param application string

@description('SQL administrator password')
@secure()
param adminPassword string

var adminUsername = 'sa'

// Infrastructure -------------------------------------------------

resource rabbitmqContainer 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'rabbitmq-container-eshop-event-bus'
  properties: {
    application: application
    container: {
      image: 'rabbitmq:3.9'
      env: {}
      ports: {
        rabbitmq: {
          containerPort: 5672
        }
      }
    }
  }
}

resource sqlIdentityContainer 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'sql-server-identitydb'
  properties: {
    application: application
    container: {
      image: 'mcr.microsoft.com/mssql/server:2019-latest'
      env: {
        ACCEPT_EULA: 'Y'
        MSSQL_PID: 'Developer'
        MSSQL_SA_PASSWORD: adminPassword
      }
      ports: {
        sql: {
          containerPort: 1433
        }
      }
    }
  }
}

resource sqlCatalogContainer 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'sql-server-catalogdb'
  properties: {
    application: application
    container: {
      image: 'mcr.microsoft.com/mssql/server:2019-latest'
      env: {
        ACCEPT_EULA: 'Y'
        MSSQL_PID: 'Developer'
        MSSQL_SA_PASSWORD: adminPassword
      }
      ports: {
        sql: {
          containerPort: 1433
        }
      }
    }
  }
}

resource sqlOrderingContainer 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'sql-server-orderingdb'
  properties: {
    application: application
    container: {
      image: 'mcr.microsoft.com/mssql/server:2019-latest'
      env: {
        ACCEPT_EULA: 'Y'
        MSSQL_PID: 'Developer'
        MSSQL_SA_PASSWORD: adminPassword
      }
      ports: {
        sql: {
          containerPort: 1433
        }
      }
    }
  }
}

resource sqlWebhooksContainer 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'sql-server-webhooksdb'
  properties: {
    application: application
    container: {
      image: 'mcr.microsoft.com/mssql/server:2019-latest'
      env: {
        ACCEPT_EULA: 'Y'
        MSSQL_PID: 'Developer'
        MSSQL_SA_PASSWORD: adminPassword
      }
      ports: {
        sql: {
          containerPort: 1433
        }
      }
    }
  }
}

resource redisBasketContainer 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'redis-container-basket-data'
  properties: {
    application: application
    container: {
      image: 'redis:6.2'
      env: {}
      ports: {
        redis: {
          containerPort: 6379
        }
      }
    }
  }
}

resource redisKeystoreContainer 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'redis-container-keystore-data'
  properties: {
    application: application
    container: {
      image: 'redis:6.2'
      env: {}
      ports: {
        redis: {
          containerPort: 6379
        }
      }
    }
  }
}

// Portable Resources ---------------------------------------------------------------

resource rabbitmq 'Applications.Messaging/rabbitMQQueues@2023-10-01-preview' = {
  name: 'eshop-event-bus'
  properties: {
    application: application
    environment: environment
    resourceProvisioning: 'manual'
    queue: 'eshop-event-bus'
    host: rabbitmqContainer.name
    port: rabbitmqContainer.properties.container.ports.rabbitmq.port
    username: 'guest'
    secrets: {
      password: 'guest'
    }
  }
}

resource sqlIdentityDb 'Applications.Datastores/sqlDatabases@2023-10-01-preview' = {
  name: 'identitydb'
  properties: {
    application: application
    environment: environment
    resourceProvisioning: 'manual'
    server: sqlIdentityContainer.name
    database: 'IdentityDb'
    port: sqlIdentityContainer.properties.container.ports.sql.port
    username: adminUsername
    secrets: {
      password: adminPassword
      connectionString: 'Server=tcp:${sqlIdentityContainer.name},${sqlIdentityContainer.properties.container.ports.sql.port};Initial Catalog=IdentityDb;User Id=${adminUsername};Password=${adminPassword};Encrypt=false'
    }
  }
}

resource sqlCatalogDb 'Applications.Datastores/sqlDatabases@2023-10-01-preview' = {
  name: 'catalogdb'
  properties: {
    application: application
    environment: environment
    resourceProvisioning: 'manual'
    server: sqlCatalogContainer.name
    database: 'CatalogDb'
    port: sqlCatalogContainer.properties.container.ports.sql.port
    username: adminUsername
    secrets: {
      password: adminPassword
      connectionString: 'Server=tcp:${sqlCatalogContainer.name},${sqlCatalogContainer.properties.container.ports.sql.port};Initial Catalog=CatalogDb;User Id=${adminUsername};Password=${adminPassword};Encrypt=false'
    }
  }
}

resource sqlOrderingDb 'Applications.Datastores/sqlDatabases@2023-10-01-preview' = {
  name: 'orderingdb'
  properties: {
    application: application
    environment: environment
    resourceProvisioning: 'manual'
    server: sqlOrderingContainer.name
    database: 'OrderingDb'
    port: sqlOrderingContainer.properties.container.ports.sql.port
    username: adminUsername
    secrets: {
      password: adminPassword
      connectionString: 'Server=tcp:${sqlOrderingContainer.name},${sqlOrderingContainer.properties.container.ports.sql.port};Initial Catalog=OrderingDb;User Id=${adminUsername};Password=${adminPassword};Encrypt=false'
    }
  }
}

resource sqlWebhooksDb 'Applications.Datastores/sqlDatabases@2023-10-01-preview' = {
  name: 'webhooksdb'
  properties: {
    application: application
    environment: environment
    resourceProvisioning: 'manual'
    server: sqlWebhooksContainer.name
    database: 'WebhooksDb'
    port: sqlWebhooksContainer.properties.container.ports.sql.port
    username: adminUsername
    secrets: {
      password: adminPassword
      connectionString: 'Server=tcp:${sqlWebhooksContainer.name},${sqlWebhooksContainer.properties.container.ports.sql.port};Initial Catalog=WebhooksDb;User Id=${adminUsername};Password=${adminPassword};Encrypt=false'
    }
  }
}

resource redisBasket 'Applications.Datastores/redisCaches@2023-10-01-preview' = {
  name: 'basket-data'
  properties: {
    application: application
    environment: environment
    resourceProvisioning: 'manual'
    host: redisBasketContainer.name
    port: redisBasketContainer.properties.container.ports.redis.port
    secrets: {
      connectionString: '${redisBasketContainer.name}:${redisBasketContainer.properties.container.ports.redis.port},abortConnect=False'
    }
  }
}

resource redisKeystore 'Applications.Datastores/redisCaches@2023-10-01-preview' = {
  name: 'keystore-data'
  properties: {
    application: application
    environment: environment
    resourceProvisioning: 'manual'
    host: redisKeystoreContainer.name
    port:redisKeystoreContainer.properties.container.ports.redis.port
    secrets: {
      connectionString: '${redisKeystoreContainer.name}:${redisKeystoreContainer.properties.container.ports.redis.port},abortConnect=False'
    }
  }
}

// Outputs ------------------------------------

@description('The name of the SQL Identity portable resource')
output sqlIdentityDb string = sqlIdentityDb.name

@description('The name of the SQL Catalog portable resource')
output sqlCatalogDb string = sqlCatalogDb.name

@description('The name of the SQL Ordering portable resource')
output sqlOrderingDb string = sqlOrderingDb.name

@description('The name of the SQL Webhooks portable resource')
output sqlWebhooksDb string = sqlWebhooksDb.name

@description('The name of the Redis Keystore portable resource')
output redisKeystore string = redisKeystore.name

@description('The name of the Redis Basket portable resource')
output redisBasket string = redisBasket.name

@description('The name of the RabbitMQ portable resource')
output rabbitmq string = rabbitmq.name
