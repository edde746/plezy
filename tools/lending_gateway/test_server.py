import unittest
from urllib.parse import parse_qs, urlsplit
from server import Gateway, InvalidRequest, pkce


class GatewayTest(unittest.TestCase):
    def setUp(self):
        self.now = 0
        self.exchanges = []
        def exchange(endpoint, fields):
            self.exchanges.append((endpoint, fields))
            return {'access_token': 'patron-token', 'refresh_token': 'rotated-refresh', 'expires_in': 3600,
                    'scope': 'LIB SRCH META AVAIL PATRONINT DEVICELOGININT website:123'}
        self.gateway = Gateway({'origin': 'https://library.example', 'client_id': 'public-client',
                                'client_secret': 'developer-secret', 'signing_key': 'a'*40,
                                'libraries': [{'id': 'local', 'name': 'Test Library', 'websiteId': '123',
                                               'integration': True, 'circulation': True}]},
                               exchange=exchange, clock=lambda: self.now)
        self.verifier = 'v'*43

    def start(self):
        result = self.gateway.initiate({'library': 'local', 'challenge': pkce(self.verifier)})
        query = parse_qs(urlsplit(result['authorizeUrl']).query)
        callback = urlsplit(query['redirect_url'][0]).path.split('/')
        return result['id'], callback[-1], query

    def test_hosted_login_never_exposes_developer_secret(self):
        identifier, secret, query = self.start()
        self.assertEqual(query['website_id'], ['123'])
        self.assertNotIn('developer-secret', str(query))
        self.assertNotEqual(identifier, secret)
        self.assertEqual(self.exchanges, [])

    def test_poll_requires_pkce_and_can_only_exchange_once(self):
        identifier, secret, _ = self.start()
        self.assertEqual(self.gateway.poll(identifier, {'verifier': self.verifier})[0], 202)
        self.gateway.callback(identifier, secret, {'code': ['c'*64]})
        with self.assertRaises(InvalidRequest) as failure:
            self.gateway.poll(identifier, {'verifier': 'x'*43})
        self.assertEqual(failure.exception.status, 403)
        self.assertEqual(len(self.exchanges), 0)
        status, token = self.gateway.poll(identifier, {'verifier': self.verifier})
        self.assertEqual(status, 200)
        self.assertEqual(token['access_token'], 'patron-token')
        with self.assertRaises(InvalidRequest):
            self.gateway.poll(identifier, {'verifier': self.verifier})
        self.assertEqual(len(self.exchanges), 1)

    def test_callback_secret_expiry_and_replay(self):
        identifier, secret, _ = self.start()
        with self.assertRaises(InvalidRequest):
            self.gateway.callback(identifier, 'wrong', {'code': ['c'*64]})
        self.gateway.callback(identifier, secret, {'code': ['c'*64]})
        with self.assertRaises(InvalidRequest):
            self.gateway.callback(identifier, secret, {'code': ['d'*64]})
        self.now = 601
        with self.assertRaises(InvalidRequest):
            self.gateway.poll(identifier, {'verifier': self.verifier})
        self.assertEqual(self.exchanges, [])

    def test_abandoned_flow_does_not_exchange(self):
        identifier, secret, _ = self.start()
        self.gateway.callback(identifier, secret, {'cancelled': ['1']})
        with self.assertRaises(InvalidRequest):
            self.gateway.poll(identifier, {'verifier': self.verifier})
        self.assertEqual(self.exchanges, [])

    def test_refresh_is_bound_to_issued_token_and_library(self):
        identifier, secret, _ = self.start()
        self.gateway.callback(identifier, secret, {'code': ['c'*64]})
        _, token = self.gateway.poll(identifier, {'verifier': self.verifier})
        with self.assertRaises(InvalidRequest):
            self.gateway.refresh({'library': 'local', 'refresh_token': 'arbitrary', 'refreshProof': token['refreshProof']})
        refreshed = self.gateway.refresh({'library': 'local', 'refresh_token': token['refresh_token'], 'refreshProof': token['refreshProof']})
        self.assertIn('refreshProof', refreshed)
        self.assertEqual(self.exchanges[-1][0], 'refresh')

    def test_wrong_collection_or_environment_is_rejected(self):
        for scopes in ['PATRONINT website:999', 'PATRON website:123', 'DEVICELOGININT website:123']:
            with self.subTest(scopes=scopes), self.assertRaises(InvalidRequest):
                self.gateway._tokens({'access_token': 'token', 'scope': scopes}, 'local')

    def test_bounded_authorizations_and_rate_limit(self):
        for _ in range(120):
            self.gateway.rate_limit('client')
        with self.assertRaises(InvalidRequest):
            self.gateway.rate_limit('client')
        self.now = 61
        self.gateway.rate_limit('client')
        for _ in range(1000):
            self.start()
        with self.assertRaises(InvalidRequest):
            self.start()

    def test_catalogue_does_not_leak_private_configuration(self):
        public = str(self.gateway.public_libraries())
        self.assertNotIn('developer-secret', public)
        self.assertNotIn('signing_key', public)


if __name__ == '__main__':
    unittest.main()
