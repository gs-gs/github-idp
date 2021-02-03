# GithubIDP Hamlet Plugin

This plugin for hamlet deploys the API Gateway/Lambda model described in this repositories [README.md](../../README.md)

The plugin included a module which creates the following

- an API Gateway including an openapi spec with aligns with the services offered
- A set of Lambda functions which are invoked by the API Gateway and perform the Github OIDC proxying
- A Deployment profile which configures a userpool AuthProvider to use the API as its federation source

## Usage

1. Create a userpool in your solution and configure the pool as required
    :::note
    Github doesn't provide a phone_number attribute so you can not enforce MFA with phone_number on the pool
    :::
2. Create a Github OAuth App which will be used by the Lambda function to authenticate with Github
3. Add the `cognito_github_api` module from this plugin into your solution and configure the module. The client Id and Secret should be the details created in step 2
    for example in your solution.json add the following

    ```json
        {
            "Segment": {
                "Plugins" : {
                    "githubidp" : {
                        "Enabled" : true,
                        "Name" : "githubidp",
                        "Priority" : 200,
                        "Required" : true,
                        "Source" : "git",
                        "Source:git" : {
                            "Url" : "https://github.com/gs-gs/github-idp",
                            "Ref" : "master",
                            "Path" : "hamlet/githubidp"
                        }
                    }
                },
                "Modules" : {
                    "githubauth" : {
                        "Provider" : "githubidp",
                        "Name" : "cognito_github_api",
                        "Parameters" : {
                            "id" : {
                                "Key" : "id",
                                "Value" : "github"
                            },
                            "tier" : {
                                "Key" : "tier",
                                "Value" : "api"
                            },
                            "githubClientId" : {
                                "Key" : "githubClientId",
                                "Value" : "abc1234556"
                            },
                            "githubClientSecret" : {
                                "Key" : "githubClientSecret",
                                "Value" : "098765432345678987654"
                            },
                            "githubOrg" : {
                                "Key" : "githubOrg",
                                "Value" : "hamlet-io"
                            },
                            "githubTeams" : {
                                "Key" : "githubTeams",
                                "Value" : [ "engine-maintainers" ]
                            },
                            "cognitoLink" : {
                                "Key" : "cognitoLink",
                                "Value" : {
                                    "Tier" : "mgmt",
                                    "Component" : "pool",
                                    "Instance" : "",
                                    "Version" : ""
                                }
                            }
                        }
                    }
                }
            }
    ```
    The `cognitoLink` is a link to an existing user pool which will you will need in your solution
    The module also creates a DeploymentProfile which needs to be applied to a new AuthProvider on the Cognito user pool

    solution.json
    ```json
    {
        "Tiers" : {
            "mgmt" : {
                "Components" : {
                    "pool" : {
                        "userpool" : {
                            "Instances" : {
                                "default" : {
                                    "deployment:Unit" : "pool"
                                }
                            },
                            "AuthProviders" : {
                                "github" : {
                                    "Profiles" : {
                                        "Deployment" : [ "githubidp_githubprovider"]
                                    }
                                }
                            },
                            "Clients" : {
                                "myAWesomeApp" : {
                                    "AuthProviders" : [ "github" ]
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    ```
