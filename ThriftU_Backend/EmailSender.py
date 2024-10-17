import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

class EmailSender:
    def __init__(self, smtp_server, smtp_port, smtp_user, smtp_password):
        self.smtp_server = smtp_server
        self.smtp_port = smtp_port
        self.smtp_user = smtp_user
        self.smtp_password = smtp_password

    def send_verification_email(self, recipient_email, code):
        subject = "Your Verification Code"
        body = f"Your verification code is: {code}"

        msg = MIMEMultipart()
        msg['From'] = self.smtp_user
        msg['To'] = recipient_email
        msg['Subject'] = subject
        msg.attach(MIMEText(body, 'plain'))

        try:
            # Use SSL connection
            server = smtplib.SMTP_SSL(self.smtp_server, self.smtp_port)
            server.login(self.smtp_user, self.smtp_password)

            # Send email
            server.sendmail(self.smtp_user, recipient_email, msg.as_string())

            server.quit()

            print("Email sent successfully")
        except Exception as e:
            print(f"Failed to send email. Error: {str(e)}")



def send_verification_email(recipient_email, verification_code):
    smtp_server = "smtp.163.com"
    smtp_port = 465  # Using port 465 for SSL connection
    smtp_user = "thriftuservice@163.com"
    smtp_password = "xxxxxxxxxxxx"
    email_sender = EmailSender(smtp_server, smtp_port, smtp_user, smtp_password)
    email_sender.send_verification_email(recipient_email, verification_code)



if __name__ == "__main__":

    recipient_email = "realharrison034@gmail.com"
    verification_code = "12345"

    send_verification_email(recipient_email, verification_code)
