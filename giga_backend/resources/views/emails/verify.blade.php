<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f4f4; margin: 0; padding: 40px 20px; }
        .container { max-width: 500px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #1E88E5 0%, #1565C0 100%); padding: 30px; text-align: center; }
        .header h1 { color: #ffffff; margin: 0; font-size: 28px; letter-spacing: 2px; }
        .content { padding: 40px 30px; text-align: center; }
        .code { display: inline-block; background: #f0f7ff; color: #1E88E5; font-size: 36px; font-weight: bold; letter-spacing: 8px; padding: 20px 40px; border-radius: 12px; margin: 20px 0; border: 2px dashed #1E88E5; }
        .message { color: #666; font-size: 16px; line-height: 1.6; }
        .footer { background: #f9f9f9; padding: 20px; text-align: center; color: #999; font-size: 12px; }
        .highlight { color: #1E88E5; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>GIGA</h1>
        </div>
        <div class="content">
            <p class="message">Hi <span class="highlight">{{ $name }}</span>,</p>
            <p class="message">Welcome to GIGA! Use the verification code below to confirm your email address:</p>
            <div class="code">{{ $code }}</div>
            <p class="message">This code will expire in <strong>15 minutes</strong>.</p>
            <p class="message" style="margin-top: 30px; color: #999;">If you didn't create a GIGA account, please ignore this email.</p>
        </div>
        <div class="footer">
            &copy; {{ date('Y') }} GIGA LOGISTICS. All rights reserved.
        </div>
    </div>
</body>
</html>
