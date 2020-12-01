const { GITHUB_ORG } = require('../config');
const logger = require('./logger');
const openid = require('../openid');

module.exports = respond => ({
  authorize: (client_id, scope, state, response_type) => {
    const authorizeUrl = openid.getAuthorizeUrl(
      client_id,
      scope,
      state,
      response_type
    );
    logger.info('Redirecting to authorizeUrl');
    logger.debug('Authorize Url is: %s', authorizeUrl, {});
    respond.redirect(authorizeUrl);
  },
  userinfo: tokenPromise => {
    tokenPromise
      .then(async token => ({
          token,
          userInfo: await openid.getUserInfo(token)
        })
      )
      .then(({userInfo, token}) => {
        logger.info('Resolved user infos:', userInfo, {});
        if (GITHUB_ORG) {
          openid
            .getMembershipConfirmation(token, GITHUB_ORG, userInfo.preferred_username)
            .then(() => {
              logger.info('Successfully confirmed user membership in organisation');
              respond.success(userInfo);
            })
            .catch(error => {
              logger.error('Failed to confirm user membership: %s', error.message || error);
              respond.error(error);
            })
        } else {
          respond.success(userInfo);
        }
      })
      .catch(error => {
        logger.error(
          'Failed to provide user info: %s',
          error.message || error,
          {}
        );
        respond.error(error);
      });
  },
  token: (code, state, host) => {
    if (code) {
      openid
        .getTokens(code, state, host)
        .then(tokens => {
          logger.debug(
            'Token for (%s, %s, %s) provided',
            code,
            state,
            host,
            {}
          );
          logger.debug('Received tokens:', tokens);
          respond.success(tokens);
        })
        .catch(error => {
          logger.error(
            'Token for (%s, %s, %s) failed: %s',
            code,
            state,
            host,
            error.message || error,
            {}
          );
          respond.error(error);
        });
    } else {
      const error = new Error('No code supplied');
      logger.error(
        'Token for (%s, %s, %s) failed: %s',
        code,
        state,
        host,
        error.message || error,
        {}
      );
      respond.error(error);
    }
  },
  jwks: () => {
    const jwks = openid.getJwks();
    logger.info('Providing access to JWKS: %j', jwks, {});
    respond.success(jwks);
  },
  openIdConfiguration: host => {
    const config = openid.getConfigFor(host);
    logger.info('Providing configuration for %s: %j', host, config, {});
    respond.success(config);
  }
});
