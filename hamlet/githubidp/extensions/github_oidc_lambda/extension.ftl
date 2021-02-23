[#ftl]

[@addExtension
    id="github_oidc_lambda"
    aliases=[
        "_github_oidc_lambda"
    ]
    description=[
        "Confgures the API gateway lambda function environment variables"
    ]
    supportedTypes=[
        LAMBDA_FUNCTION_COMPONENT_TYPE,
        LAMBDA_COMPONENT_TYPE
    ]
/]

[#macro shared_extension_github_oidc_lambda_deployment_setup occurrence ]

    [@DefaultLinkVariables enabled=false /]
    [@DefaultCoreVariables enabled=false /]
    [@DefaultEnvironmentVariables enabled=false /]
    [@DefaultBaselineVariables enabled=false /]

    [@Settings
        [
            "GITHUB_ORG",
            "GITHUB_CLIENT_ID",
            "GITHUB_CLIENT_SECRET",
            "GITHUB_API_URL",
            "GITHUB_LOGIN_URL",
            "GITHUB_TEAMS"
        ]
    /]

    [#if _context.Links["userpool"]?has_content ]
        [#local cognitoRedirectUri = formatRelativePath(_context.DefaultEnvironment["USERPOOL_UI_BASE_URL"], "oauth2/idpresponse") ]
    [#else]
        [#local cognitoRedirectUri = (_context.DefaultEnvironment["COGNITO_REDIRECT_URI"])!"" ]
    [/#if]

    [@Settings
        {
            "COGNITO_REDIRECT_URI" : cognitoRedirectUri
        }
    /]


[/#macro]
