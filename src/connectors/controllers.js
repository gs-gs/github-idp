const { GITHUB_ORG, GITHUB_TEAMS } = require('../config');
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
            .then(async () => {
              logger.info('Success: user is a member of %s', GITHUB_ORG);
              if (GITHUB_TEAMS) {
                logger.info('Test: user must have membership in one of %s', GITHUB_TEAMS.split(','));
                const username = userInfo.preferred_username;
                const teams = GITHUB_TEAMS.split(',').map((team) => team.trim());

                // We'll use a loop even though eslint suggests not using awaits in loops.
                // This will limit unnecessary API calls to GitHub and mean we have to worry less
                // about rate limiting. It also means we can stop after we find the first group
                // membership.
                for (let i = 0; i < teams.length; i += 1) {
                  try {
                    // eslint-disable-next-line no-await-in-loop
                    const confirmation = await openid.confirmTeamMembership(token, GITHUB_ORG, teams[i], username);
                    if (confirmation) {
                      logger.info('Success: %s has membership in %s (%s)', username, teams[i], GITHUB_ORG);
                      respond.success(userInfo);
                      return;
                    }
                  } catch (error) {
                    logger.info('User has no membership in %s', teams[i]);
                  }
                }
                respond.error('User does not have membership in at least one of the required teams.');

              } else {
                respond.success(userInfo);
              }
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
