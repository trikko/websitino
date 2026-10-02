/*
MIT License

Copyright (c) 2025-2026 Andrea Fontana

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

module selfsigned;

version(serverino_enable_https):

import std;
import serverino.openssl_headers;

// The certificate is kept between runs, so the browser asks to accept it only once.
string certificateDir()
{
	version(OSX) return buildPath(environment.get("HOME", tempDir), "Library", "Caches", "websitino");
	else return buildPath(environment.get("XDG_CACHE_HOME", buildPath(environment.get("HOME", tempDir), ".cache")), "websitino");
}

// Returns the paths of a self-signed certificate and its key, creating them if missing or about to expire.
string[2] selfSignedCertificate()
{
	auto dir = certificateDir();
	auto cert = buildPath(dir, "selfsigned.crt");
	auto key = buildPath(dir, "selfsigned.key");

	if (cert.exists && key.exists && Clock.currTime - cert.timeLastModified < 360.days)
		return [cert, key];

	mkdirRecurse(dir);

	// A P-256 key: small, fast, accepted by every browser
	EVP_PKEY* pkey = EVP_PKEY_Q_keygen(null, null, "EC", "P-256".ptr);
	enforce(pkey !is null, "can't generate the private key");
	scope(exit) EVP_PKEY_free(pkey);

	X509* x509 = X509_new();
	enforce(x509 !is null, "can't create the certificate");
	scope(exit) X509_free(x509);

	X509_set_version(x509, X509_VERSION_3);
	ASN1_INTEGER_set(X509_get_serialNumber(x509), cast(int)(Clock.currTime.toUnixTime & 0x7fffffff));
	X509_gmtime_adj(X509_getm_notBefore(x509), 0);
	X509_gmtime_adj(X509_getm_notAfter(x509), 365L * 24 * 60 * 60);
	X509_set_pubkey(x509, pkey);

	X509_NAME* name = X509_get_subject_name(x509);
	X509_NAME_add_entry_by_txt(name, "O", MBSTRING_ASC, cast(const(ubyte)*)"websitino".ptr, -1, -1, 0);
	X509_NAME_add_entry_by_txt(name, "CN", MBSTRING_ASC, cast(const(ubyte)*)"localhost".ptr, -1, -1, 0);
	X509_set_issuer_name(x509, name);

	// Browsers ignore the CN: the names must be in the subject alternative names
	X509V3_CTX ctx;
	X509V3_set_ctx(&ctx, x509, x509, null, null, 0);
	X509_EXTENSION* san = X509V3_EXT_conf_nid(null, &ctx, NID_subject_alt_name, "DNS:localhost,IP:127.0.0.1,IP:::1");
	enforce(san !is null, "can't set the certificate names");
	X509_add_ext(x509, san, -1);
	X509_EXTENSION_free(san);

	enforce(X509_sign(x509, pkey, EVP_sha256()) > 0, "can't sign the certificate");

	// The key is created readable only by the user
	import core.sys.posix.sys.stat : umask;
	auto oldMask = umask(octal!77);
	auto keyBio = BIO_new_file(key.toStringz, "w");
	umask(oldMask);
	enforce(keyBio !is null, "can't write " ~ key);
	PEM_write_bio_PrivateKey(keyBio, pkey, null, null, 0, null, null);
	BIO_free(keyBio);

	auto certBio = BIO_new_file(cert.toStringz, "w");
	enforce(certBio !is null, "can't write " ~ cert);
	PEM_write_bio_X509(certBio, x509);
	BIO_free(certBio);

	return [cert, key];
}
