import ssl
import httpx
from app.core.config import settings


async def send_secret_message(message: str) -> dict:
    """
    Creates a secure mTLS context and sends a message to the target service.
    """
    # create a secure SSL context
    ssl_context = ssl.create_default_context(
        purpose=ssl.Purpose.SERVER_AUTH,
        cafile=settings.CERT_BUNDLE
    )
    # load the client certificate and private key to prove OUR identity
    ssl_context.load_cert_chain(
        certfile=settings.CERT_BUNDLE
        # keyfile is not needed if the private key is in the certfile
    )

    print(f"Attempting to contact {settings.TARGET_URL}...")
    try:
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
