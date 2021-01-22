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
