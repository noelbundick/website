param siteName string = 'noelbundick'
param branch string = 'main'
param domain string = 'www.noelbundick.com'
param appLocation string = 'site'
param appArtifactLocation string = 'public'
param repositoryUrl string = 'https://github.com/noelbundick/website'
param repositoryToken string {
  secure: true
}

resource site 'Microsoft.Web/staticSites@2020-06-01' = {
  name: siteName
  location: resourceGroup().location
  sku: {
    name: 'Free'
    tier: 'Free'
  }
  properties: {
    repositoryUrl: repositoryUrl
    repositoryToken: repositoryToken
    branch: branch
    customDomains: [
      domain
    ]
    buildProperties: {
      appLocation: appLocation
      appArtifactLocation: appArtifactLocation
    }
  }
}

resource tags 'Microsoft.Resources/tags@2020-06-01' = {
  name: 'default'
  properties: {
    tags: {
      'site': site.id
    }
  }
}

