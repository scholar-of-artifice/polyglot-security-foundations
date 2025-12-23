import ssl
import os


class MTLSContextManager:
    """
    Manages the lifecycle of the SSL Context to avoid expensive re-initialization
    on every request, while still supporting certificate rotation.
    """

    def __init__(self, cert_path: str):
        self.cert_path = cert_path
        self.ssl_context = None
        self.last_modified = 0.0

    def get_context(self) -> ssl.SSLContext:
        """
        Returns a cached SSLContext if the file has not been modified.
        Reloads the context if the file timestamp has updated.
        """
        # get the current modification time of the certificate bundle
        try:
            current_mtime = os.path.getmtime(self.cert_path)
        except OSError:
            # if the file is momentarily missing
            if self.ssl_context:
                # try to fallback on the old context
                return self.ssl_context
            raise
        # reload if context is missing or if the file has changed since last load
        if self.ssl_context is None or current_mtime != self.last_modified:
            print(
                f"Certificate changed or not loaded. Loading SSL context from {self.cert_path}..."
            )
            try:
                # create a secure SSL context
                context = ssl.create_default_context(
                    purpose=ssl.Purpose.SERVER_AUTH,
                    cafile=self.cert_path
                )
                # load the client certificate and private key to prove OUR identity
                context.load_cert_chain(
                    certfile=self.cert_path
                    # keyfile is not needed if the private key is in the certfile
                )
                # update state
                self.ssl_context = context
                self.last_modified = current_mtime
                print("SSL context loaded/reloaded successfully.")
            except (ssl.SSLError, ValueError, OSError) as e:
                print(
                    f"Warning: Failed to load new certificate. Potential partial write detected. {e}")
                if self.ssl_context:
                    print("Falling back to existing SSL context.")
                    return self.ssl_context
                else:
                    # there might not be an old context...
                    raise
            return self.ssl_context
