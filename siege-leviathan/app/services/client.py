
import httpx
from app.core.config import settings
from app.core.MTLSContextManager import MTLSContextManager


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
