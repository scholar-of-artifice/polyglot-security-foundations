from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # these fields match the environment variables names
    # Pydantic will automatically validate that they exist.
    CERT_BUNDLE: str
    TARGET_URL: str


settings = Settings()
