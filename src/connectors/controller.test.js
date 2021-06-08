jest.mock('../openid');

const controllers = require('./controllers');
const openid = require('../openid');

jest.mock('../config', () => ({
  GITHUB_ORG: 'foo,bar,baz',
  GITHUB_CLIENT_ID: 'GITHUB_CLIENT_ID',
  GITHUB_CLIENT_SECRET: 'GITHUB_CLIENT_SECRET',
  COGNITO_REDIRECT_URI: 'COGNITO_REDIRECT_URI',
  GITHUB_API_URL: 'GITHUB_API_URL',
  GITHUB_LOGIN_URL: 'GITHUB_LOGIN_URL',
  GITHUB_TEAMS: 'foo:alpha,foo:beta,bar:beta,baz:delta,*:theta',
  GITHUB_SCOPES: 'GITHUB_SCOPES'
}));

describe('controllers', () => {
  describe('userinfo', () => {
    beforeEach(() => {
      // Reset all implementations
      jest.resetAllMocks();
    });

    const getMockCallback = () => ({
      error: jest.fn(),
      success: jest.fn(),
    });

    const tokenPromise = Promise.resolve('token');

    it('should error if token cannot resolve', async () => {
      const callback = getMockCallback();
      await controllers(callback).userinfo(Promise.reject(new Error('token did not resolve')));
      expect(callback.error).toHaveBeenCalled();
    });

    it('should error if userinfo cannot resolve', async () => {
      const callback = getMockCallback();
      openid.getUserInfo.mockImplementation(() => Promise.reject(new Error('user info did not resolve')));
      await controllers(callback).userinfo(Promise.resolve('token'));
      expect(callback.error).toHaveBeenCalled();
    });

    it('should error without org membership', async () => {
      openid.getUserInfo.mockImplementation(() => Promise.resolve({
        preferred_username: 'john'
      }));
      openid.confirmTeamMembership.mockImplementation(() => Promise.resolve(true));
      openid.getMembershipConfirmation.mockImplementation(() => Promise.reject(new Error('no org membership')));

      const callback = getMockCallback();
      await controllers(callback).userinfo(tokenPromise);

      expect(callback.error).toHaveBeenCalled();
    });

    it('should error with org membership, but no team membership', async () => {
      openid.getUserInfo.mockImplementation(() => Promise.resolve({
        preferred_username: 'john'
      }));
      openid.getMembershipConfirmation.mockImplementation((_token, org, _userinfo) => new Promise((resolve, reject) => {
        if(org === 'baz') {
          resolve(true);
        }
        reject(new Error('no membership'));
      }));
      openid.confirmTeamMembership.mockImplementation(() => Promise.reject(new Error('no team access')));

      const callback = getMockCallback();
      await controllers(callback).userinfo(tokenPromise)
      expect(openid.getMembershipConfirmation).toHaveBeenCalledWith('token', 'foo', 'john');
      expect(openid.getMembershipConfirmation).toHaveBeenCalledWith('token', 'bar', 'john');
      expect(openid.getMembershipConfirmation).toHaveBeenCalledWith('token', 'baz', 'john');
      expect(callback.error).toHaveBeenCalled();
    });

    it('should work with valid membership', async () => {
      openid.getUserInfo.mockImplementation(() => Promise.resolve({
        preferred_username: 'john'
      }));
      openid.getMembershipConfirmation.mockImplementation(() => Promise.resolve(true));
      openid.confirmTeamMembership.mockImplementation((token, org, team, _user) => new Promise((resolve, reject) => {
        if (org === 'baz' && team === 'delta') {
          resolve(true);
        }
        reject(new Error('no membership'));
      }));

      const callback = getMockCallback();
      await controllers(callback).userinfo(tokenPromise);

      expect(openid.confirmTeamMembership).toHaveBeenCalledWith('token', 'foo', 'alpha', 'john');
      expect(openid.confirmTeamMembership).toHaveBeenCalledWith('token', 'foo', 'beta', 'john');
      expect(openid.confirmTeamMembership).toHaveBeenCalledWith('token', 'bar', 'beta', 'john');
      expect(openid.confirmTeamMembership).toHaveBeenCalledWith('token', 'baz', 'delta', 'john');
      expect(callback.success).toHaveBeenCalled();
    });

    it('should take the first org membership for a wildcard team', async () => {
      openid.getUserInfo.mockImplementation(() => Promise.resolve({
        preferred_username: 'john'
      }));
      openid.getMembershipConfirmation.mockImplementation(() => Promise.resolve(true));
      openid.confirmTeamMembership.mockImplementation((token, org, team, _user) => new Promise((resolve, reject) => {
        if (team === 'theta') {
          resolve(true);
        }
        reject(new Error('no membership'));
      }));

      const callback = getMockCallback();
      await controllers(callback).userinfo(tokenPromise);
      expect(openid.confirmTeamMembership).toHaveBeenLastCalledWith('token', 'foo', 'theta', 'john');
      expect(callback.success).toHaveBeenCalled();
    });
  });
});
