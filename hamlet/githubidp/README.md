# GithubIDP Hamlet Plugin

This plugin for hamlet deploys the API Gateway/Lambda model described in this repositories [README.md](../../README.md)

The plugin includes the module `cognito_github_api` which creates the following:

- an API Gateway including an openapi spec which aligns with the services offered
- A set of Lambda functions which are invoked by the API Gateway and perform the Github OIDC proxying
- A Deployment profile which configures a userpool AuthProvider to use the API as its federation source

## Usage

1. Create a userpool in your solution and configure the pool as required
    :::note
    Github doesn't provide a phone_number attribute so you can not enforce MFA with phone_number on the pool
    :::
2. Create a Github OAuth App which will be used by the Lambda function to authenticate with Github
    1. Set an Application name the relates to your user pool or product
    2. The home page URL can be anything but usually points to your products public page
    3. Provide a description about your product
    4. The Authorization callback Url is based on the the cognito userpool hosted UI. To get the callback Url run the following
        1. In your cmdb run the following hamlet query

        ```
        hamlet query describe occurrence --tier-id <your pools tier id> --component-id <your pools component id> attributes
        ```

        2. The callback Url will be `<UI_BASE_URL>/oauth2/idpresponse` where UI_BASE_URL is listed in the attributes from step one
    4. Once you have created the pool you will need to generate a client secret which can be done on the details page once the initial app has been setup
    5. Note down the Client Id and the Generated client secret, you will need these for the module configuration
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
                            "Ref" : "v0.0.3",
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
                                "Value" : "<Github OAuth App Client Id>"
                            },
                            "githubClientSecret" : {
                                "Key" : "githubClientSecret",
                                "Value" : "<Github OAuth App Client Secret>"
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
                                "myAwesomeApp" : {
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

    This creates the github federated provider and enables github auth for applications which use the `myAwesomeApp` userpool client

4. This lambda function is built with a private key which is generated during the build process and is used to sign JWT's.
    To reduce the risk of keys being used by multiple people we do not provide artefacts for this module and the lambda needs to be built and provided to the hamlet registry.

    A sample [Jenkinsfile](../pipelines/Jenkinsfile-example) has been included which can be copied into your CMDB and added as a pipeline in your jenkins instance

    You will need to add the following properties to your pipelines properties file

    ```
    APPLICATION_UNITS=<MODULE_ID>-lambda

    # Code Properties
    <PRODUCT>_<MODULE_ID>_LAMBDA_CODE_REPO=github-idp
    ```

    Where:
      - `<MODULE_ID>` is the id parameter value in the module
      - `<PRODUCT>` is the Id of your product in upper case
