# -*- coding: utf-8 -*-
"""
Created on Sat Sep 10 12:23:30 2022

@author: keato
"""

# send automated emails
import smtplib, ssl

# port = 465  # For SSL
gmailkey = "leejohnson1933"
# password = gmailkey

# # Create a secure SSL context
# context = ssl.create_default_context()

# with smtplib.SMTP_SSL("smtp.gmail.com", port, context=context) as server:
#     server.login("ljleadingindicators@gmail.com", password)
#     # TODO: Send email here
    

# sender_email = "ljleadingindicators@gmail.com"
# receiver_email = "keatonmarkey@gmail.com"
# message = """\
# Subject: Hi there

# This message is sent from Python."""


import yagmail

receiver = "keatonmarkey@gmail.com"
body = "Hello there from Yagmail"
filename = "document.pdf"

yag = yagmail.SMTP("ljleadingindicators@gmail.com", gmailkey)
yag.send(
    to=receiver,
    subject="Yagmail test with attachment",
    contents=body
)

# need google app password??