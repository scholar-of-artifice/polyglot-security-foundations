import ssl
import httpx
import os
from app.core.config import settings


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
        return self.ssl_context


# instantiate the manager globally so it persists across requests
mtls_manager = MTLSContextManager(cert_path=settings.CERT_BUNDLE)


async def send_secret_message(message: str) -> dict:
    """
    Uses the cached mTLS context to send a message to the target service.
    """

    print(f"Attempting to contact {settings.TARGET_URL}...")
    try:
        # retrieve the context
        ssl_context = mtls_manager.get_context()
        # use httpx with the custom SSL context
        async with httpx.AsyncClient(verify=ssl_context) as client:
            response = await client.post(settings.TARGET_URL, content=message)
            # return the conversation log
            return {
                "siege_leviathan_says": message,
                "overwhelming_minotaur_responds": response.text
            }
    except Exception as e:
        return {
            "error": f"Failed to connect to overwhelming-minotaur: {str(e)}"
        }
