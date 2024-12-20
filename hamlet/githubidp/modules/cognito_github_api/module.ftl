[#ftl]

[@addModule
    name="cognito_github_api"
    description="Creates an API to support Github as a Cognito Federated identity provider"
    provider=GITHUB_IDP_PROVIDER
    properties=[
        {
            "Names" : "id",
            "Description" : "A unique id for this instance of the api",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "instance",
            "Description" : "The instance id of the components",
            "Types" : STRING_TYPE,
            "Default" : "default"
        },
        {
            "Names" : "tier",
            "Description" : "The tier the components will belong to",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "githubOrgs",
            "Description" : "The name of the github org(s) users must be a member of",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "githubTeams",
            "Description" : "A list of teams within the githubOrg that the user must be a member of",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Default" : [],
            "Mandatory" : false
        },
        {
            "Names" : "githubClientId",
            "Description" : "The Github client Id used by the API",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "githubClientSecret",
            "Description" : "The Github client secret used by the API",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "oauthScopes",
            "Description" : "The oauth scopes to request from Github - Leave empty for the code function default",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Default" : []
        },
        {
            "Names" : "cognitoLink",
            "Description" : "A link to the congito userpool which will use this API or set congitoRedirectUri",
            "AttributeSet" : LINK_ATTRIBUTESET_TYPE
        },
        {
            "Names" : "cognitoRedirectUri",
            "Description" : "The IDP response url for the cognito userpool that will use this API",
            "Types" : STRING_TYPE,
            "Default" : ""
        },
        {
            "Names" : "githubApiUrl",
            "Description" : "The Github API Url",
            "Types" : STRING_TYPE,
            "Default" : "https://api.github.com"
        },
        {
            "Names" : "githubLoginUrl",
            "Description" : "The login url endpoint for Github",
            "Types" : STRING_TYPE,
            "Default" : "https://github.com"
        },
        {
            "Names" : "cogntioDeploymentProfileSuffix",
            "Description" : "The suffix ( added to the id ) for the deployment profile which configures the userpool",
            "Types" : STRING_TYPE,
            "Default" : "_githubprovider"
        }
    ]
/]


[#macro githubidp_module_cognito_github_api
        id
        tier
        instance
        githubOrgs
        githubTeams
        githubClientId
        githubClientSecret
        oauthScopes
        cognitoLink
        cognitoRedirectUri
        githubApiUrl
        githubLoginUrl
        cogntioDeploymentProfileSuffix
]

    [#local product = getActiveLayer(PRODUCT_LAYER_TYPE) ]
    [#local environment = getActiveLayer(ENVIRONMENT_LAYER_TYPE)]
    [#local segment = getActiveLayer(SEGMENT_LAYER_TYPE)]

    [#local rawInstance = instance ]
    [#local instance = (instance == "default")?then("", instance)]

    [#local namespace = formatName(product["Name"], environment["Name"], segment["Name"])]

    [#local apiId = formatName(id, "apigateway") ]
    [#local apiDeploymentUnit = formatName(id, "apigateway") ]
    [#local apiDefinition = formatId(tier,id)]
    [#local apiSettingsNamespace = formatName(namespace, tier, apiId, instance)]

    [#local lambdaId = formatName(id, "lambda") ]
    [#local lambdaDeploymentUnit = formatName(id, "lambda")]
    [#local lambdaSettingsNamespace = formatName(namespace, lambdaDeploymentUnit)]

    [#local imageId = formatName(id, "image")]
    [#local imageDeploymentUnit = formatName(id, "image")]

    [#local githubClientSettings = formatName(id, "githubclient" )]
    [#local githubClientSettingsNamespace = formatName(namespace, githubClientSettings)]

    [#-- API Definition for API Gateway --]
    [@loadModule
        definitions={
            apiDefinition : {
                "openapi": "3.0.0",
                "components": {
                    "schemas": {},
                    "securitySchemes": {}
                },
                "info": {
                    "title": "Cognito Github Api",
                    "description": "API for Cogntio Quicksight and Github integration",
                    "version": "1.0.0"
                },
                "paths": {
                    "/authorize": {
                        "get": {
                            "responses": {
                            "200": {
                                "description": "authorize response"
                            }
                            }
                        }
                    },
                    "/.well-known/jwks.json": {
                        "get": {
                            "responses": {
                                "200": {
                                    "description": "jwks endpoint"
                                }
                            }
                        }
                    },
                    "/token": {
                        "post": {
                            "responses": {
                            "200": {
                                "description": "auth token"
                            }
                            }
                        }
                    },
                    "/userinfo": {
                        "get": {
                            "responses": {
                            "200": {
                                "description": "user info"
                            }
                            }
                        }
                    }
                }
            }
        }
    /]

    [#-- API Configuration to map Specification to Lambda Resources --]
    [@loadModule
        settingSets=[
            {
                "Type" : "Settings",
                "Scope" : "Products",
                "Namespace" : apiSettingsNamespace,
                "Settings" : {
                    "apigw": {
                        "Internal": true,
                        "Value": {
                            "Type" : "lambda",
                            "Proxy" : false,
                            "OptionsSecurity" : "disabled",
                            "Validation" : "all",
                            "Patterns" : [
                                {
                                    "Path" : "/authorize",
                                    "Verb" : "get",
                                    "Variable" : "AUTHORIZE_AUTHORIZE_LAMBDA"
                                },
                                {
                                    "Path" : "/.well-known/jwks.json",
                                    "Verb" : "get",
                                    "Variable" : "JWKS_JWKS_LAMBDA"
                                },
                                {
                                    "Path" : "/token",
                                    "Verb" : "post",
                                    "Variable" : "TOKEN_TOKEN_LAMBDA"
                                },
                                {
                                    "Path" : "/userinfo",
                                    "Verb" : "get",
                                    "Variable" : "USERINFO_USERINFO_LAMBDA"
                                }
                            ]
                        }
                    }
                }
            }
        ]
    /]

    [#-- Solution Configuration --]
    [@loadModule
        blueprint={
            "Tiers" : {
                tier : {
                    "Components" : {
                        apiId : {
                            "apigateway" : {
                                "deployment:Unit" : apiDeploymentUnit,
                                "IPAddressGroups" : [ "_global" ],
                                "Instances" : {
                                    rawInstance : {}
                                },
                                "Image" : {
                                    "Source" : "none"
                                },
                                "Links" : {
                                    "authorize" : {
                                        "Tier" : tier,
                                        "Component" : lambdaId,
                                        "instance" : instance,
                                        "Version" : "",
                                        "Function" : "authorize"
                                    },
                                    "jwks" : {
                                        "Tier" : tier,
                                        "Component" : lambdaId,
                                        "instance" : instance,
                                        "Version" : "",
                                        "Function" : "jwks"
                                    },
                                    "token" : {
                                        "Tier" : tier,
                                        "Component" : lambdaId,
                                        "instance" : instance,
                                        "Version" : "",
                                        "Function" : "token"
                                    },
                                    "userinfo" : {
                                        "Tier" : tier,
                                        "Component" : lambdaId,
                                        "instance" : instance,
                                        "Version" : "",
                                        "Function" : "userinfo"
                                    }
                                }
                            }
                        },
                        imageId : {
                            "Type": "image",
                            "deployment:Unit": imageDeploymentUnit,
                            "Instances" : {
                                rawInstance : {}
                            },
                            "Format": "lambda"
                        },
                        lambdaId : {
                            "Type": "lambda",
                            "deployment:Unit" : lambdaDeploymentUnit,
                            "Instances" : {
                                rawInstance : {}
                            },
                            "Memory": 256,
                            "RunTime": "nodejs20.x",
                            "Timeout": 29,
                            "VPCAccess": false,
                            "PredefineLogGroup" : true,
                            "Extensions" : [ "_github_oidc_lambda" ],
                            "Image" : {
                                "Source" : "link",
                                "Link" : {
                                    "Tier" : tier,
                                    "Component" : imageId,
                                    "Instance": rawInstance,
                                    "Version" : ""
                                }
                            },
                            "Settings": {
                                "GITHUB_ORG" : {
                                    "Value": githubOrgs?join(",")
                                },
                                "GITHUB_CLIENT_ID" : {
                                    "Value": githubClientId
                                },
                                "GITHUB_CLIENT_SECRET" : {
                                    "Value": githubClientSecret
                                },
                                "COGNITO_REDIRECT_URI": {
                                    "Value": cognitoRedirectUri
                                },
                                "GITHUB_API_URL" : {
                                    "Value": githubApiUrl
                                },
                                "GITHUB_LOGIN_URL" : {
                                    "Value": githubLoginUrl
                                },
                                "GITHUB_CLIENT_ID" : {
                                    "Value": githubClientId
                                },
                                "GITHUB_CLIENT_SECRET" : {
                                    "Value": githubClientSecret
                                }
                            } +
                            attributeIfContent(
                                "GITHUB_TEAMS",
                                githubTeams,
                                {
                                    "Value": githubTeams?join(",")
                                }
                            ) +
                            attributeIfContent(
                                "GITHUB_SCOPES",
                                oauthScopes,
                                {
                                    "Value": oauthScopes?join(" ")
                                }
                            ),
                            "Links" : {
                                "api" : {
                                    "Tier" : tier,
                                    "Component" : apiId,
                                    "Instance" : instance,
                                    "Version" : "",
                                    "Direction" : "inbound"
                                }
                            } +
                            (cognitoLink.Tier!"")?has_content?then(
                                {
                                    "userpool" : cognitoLink
                                },
                                {}
                            ),
                            "Functions" : {
                                "authorize" : {
                                    "Handler" : "src/connectors/lambda/authorize.handler"
                                },
                                "jwks" : {
                                    "Handler" : "src/connectors/lambda/jwks.handler"
                                },
                                "token" : {
                                    "Handler" : "src/connectors/lambda/token.handler"
                                },
                                "userinfo" : {
                                    "Handler" : "src/connectors/lambda/userinfo.handler"
                                }
                            }
                        }
                    }
                }
            },
            "DeploymentProfiles" : {
                id + cogntioDeploymentProfileSuffix : {
                    "Modes" : {
                        "*" : {
                            "userpoolauthprovider" : {
                                "Engine" : "OIDC",
                                "Extensions" : [ "_github_idp_cognito_provider" ],
                                "SettingsPrefix" : "GITHUBOIDC",
                                "AttributeMappings" : {
                                    "website" : {
                                        "UserPoolAttribute" : "website",
                                        "ProviderAttribute" : "website"
                                    },
                                    "email_verified" : {
                                        "UserPoolAttribute" : "email_verified",
                                        "ProviderAttribute" : "email_verified"
                                    },
                                    "updated_at" : {
                                        "UserPoolAttribute" : "updated_at",
                                        "ProviderAttribute" : "updated_at"
                                    },
                                    "profile" : {
                                        "UserPoolAttribute" : "profile",
                                        "ProviderAttribute" : "profile"
                                    },
                                    "name" : {
                                        "UserPoolAttribute" : "name",
                                        "ProviderAttribute" : "name"
                                    },
                                    "email" : {
                                        "UserPoolAttribute" : "email",
                                        "ProviderAttribute" : "email"
                                    },
                                    "picture" : {
                                        "UserPoolAttribute" : "picture",
                                        "ProviderAttribute" : "picture"
                                    },
                                    "sub" : {
                                        "UserPoolAttribute" : "username",
                                        "ProviderAttribute" : "sub"
                                    }
                                },
                                "Links" : {
                                    "github_api" : {
                                        "Tier" : tier,
                                        "Component" : apiId,
                                        "Instance" : instance,
                                        "Version" : ""
                                    }
                                },
                                "Settings" : {
                                    "GITHUB_CLIENT_ID" : {
                                        "Value": githubClientId
                                    },
                                    "GITHUB_CLIENT_SECRET" : {
                                        "Value": githubClientSecret
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    /]

[/#macro]
