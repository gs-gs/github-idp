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
            "GITHUBOIDC_OIDC_CLIENT_ID" : _context.DefaultEnvironment["GITHUB_CLIENT_ID"],
            "GITHUBOIDC_OIDC_CLIENT_SECRET" : _context.DefaultEnvironment["GITHUB_CLIENT_SECRET"],
            "GITHUBOIDC_OIDC_SCOPES" : "openid read:user user:email read:org",
            "GITHUBOIDC_OIDC_ATTRIBUTES_HTTP_METHOD" : "GET",
            "GITHUBOIDC_OIDC_ISSUER" : apiUrl,
            "GITHUBOIDC_OIDC_AUTHORIZE_URL" : formatRelativePath(apiUrl, "authorize"),
            "GITHUBOIDC_OIDC_TOKEN_URL" : formatRelativePath(apiUrl, "token"),
            "GITHUBOIDC_OIDC_ATTRIBUTES_URL" : formatRelativePath(apiUrl, "userinfo"),
            "GITHUBOIDC_OIDC_JWKS_URL" : formatRelativePath(apiUrl, ".well-known/jwks.json" )
        }
    /]

[/#macro]
