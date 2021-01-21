[#ftl]

[@addExtension
    id="github_idp_cognito_provider"
    aliases=[
        "_github_idp_cognito_provider"
    ]
    description=[
        "Sets auth provider federation settings to align with Github Auth API"
    ]
    supportedTypes=[
        USERPOOL_AUTHPROVIDER_COMPONENT_TYPE
    ]
/]

[#macro shared_extension_github_idp_cognito_provider_deployment_setup occurrence ]

    [#local authProviderName = ((occurrence.State.Resources["authprovider"].Name)!"")?upper_case ]
    [#local apiUrl = (_context.Links["github_api"].State.Attributes["URL"])!"" ]

    [@Settings
        {
            authProviderName + "_OIDC_CLIENT_ID" : _context.Default["GITHUB_CLIENT_ID"],
            authProviderName + "_OIDC_CLIENT_SECRET" : _context.Default["GITHUB_CLIENT_SECRET"],
            authProviderName + "_OIDC_SCOPES" : "openid read:user user:email",
            authProviderName + "_OIDC_ATTRIBUTES_HTTP_METHOD" : "GET",
            authProviderName + "_OIDC_ISSUER" : apiUrl,
            authProviderName + "_OIDC_AUTHORIZE_URL" : formatRelativePath(apiUrl, "authorize"),
            authProviderName + "_OIDC_TOKEN_URL" : formatRelativePath(apiUrl, "token"),
            authProviderName + "_OIDC_ATTRIBUTES_URL" : formatRelativePath(apiUrl, "userinfo"),
            authProviderName + "_JWKS_URL" : formatRelativePath(apiUrl, ".well-known/jwks.json" )
        }
    /]

[/#macro]
