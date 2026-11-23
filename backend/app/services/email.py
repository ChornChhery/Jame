import smtplib
import ssl
from email.message import EmailMessage

from app.config import Settings


class EmailDeliveryError(Exception):
    pass


class EmailService:
    def __init__(self, settings: Settings):
        self.settings = settings

    def check_delivery_ready(self) -> None:
        try:
            with smtplib.SMTP(
                self.settings.smtp_host,
                self.settings.smtp_port,
                timeout=3,
            ) as smtp:
                smtp.ehlo()
                if self.settings.smtp_use_tls:
                    smtp.starttls(context=ssl.create_default_context())
                    smtp.ehlo()
                self._authenticate(smtp)
        except (OSError, smtplib.SMTPException) as error:
            raise EmailDeliveryError("Email delivery is unavailable.") from error

    def send_recovery_code(self, recipient: str, code: str) -> None:
        message = EmailMessage()
        message["Subject"] = "Your Jame password recovery code"
        message["From"] = self.settings.smtp_from
        message["To"] = recipient
        message.set_content(
            f"Your Jame password recovery code is {code}. "
            "It expires in 15 minutes. If you did not request this, ignore this email."
        )

        try:
            with smtplib.SMTP(
                self.settings.smtp_host,
                self.settings.smtp_port,
                timeout=3,
            ) as smtp:
                smtp.ehlo()
                if self.settings.smtp_use_tls:
                    smtp.starttls(context=ssl.create_default_context())
                    smtp.ehlo()
                self._authenticate(smtp)
                smtp.send_message(message)
        except (OSError, smtplib.SMTPException) as error:
            raise EmailDeliveryError("Email delivery is unavailable.") from error

    def _authenticate(self, smtp: smtplib.SMTP) -> None:
        if self.settings.smtp_username:
            smtp.login(
                self.settings.smtp_username,
                self.settings.smtp_password.get_secret_value()
                if self.settings.smtp_password
                else "",
            )
