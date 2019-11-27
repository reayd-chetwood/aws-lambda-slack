from __future__ import print_function

import boto3
import json
import logging
import os
from datetime import datetime
from base64 import b64decode
from urllib2 import Request, urlopen, URLError, HTTPError

# The base-64 encoded, encrypted key (CiphertextBlob) stored in the kmsEncryptedHookUrl environment variable
ENCRYPTED_HOOK_URL = os.environ['kmsEncryptedHookUrl']
# The Slack channel to send a message to stored in the slackChannel environment variable
SLACK_CHANNEL = os.environ['slackChannel']

HOOK_URL = "https://" + boto3.client('kms').decrypt(CiphertextBlob=b64decode(ENCRYPTED_HOOK_URL))['Plaintext']

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    logger.info("Event: " + str(event))

    message = json.loads(event['Records'][0]['Sns']['Message'])
    logger.info("Message: " + str(message))

    alarm_name = message['AlarmName']
    alarm_description = message['AlarmDescription']
    account_id = message['AWSAccountId']
    new_state = message['NewStateValue']
    reason = message['NewStateReason']
    region = message['Region']
    old_state = message['OldStateValue']
    namespace = message['Trigger']['Namespace']
    fallback = "%s state is now %s: %s" % (alarm_name, new_state, reason)
    environment = os.environ['ENVIRONMENT']

    p = '%Y-%m-%dT%H:%M:%S.%f+0000'
    timestring = message['StateChangeTime']
    epoch = datetime(1970, 1, 1)
    time = (datetime.strptime(timestring, p) - epoch).total_seconds()

    slack_message = {
        'channel': SLACK_CHANNEL,
        'attachments': [
            {
                'fallback': fallback,
                'color': '#a63636',
                'pretext': fallback,
                'author_name': namespace,
                'author_link': 'https://{}.console.aws.amazon.com/cloudwatch/home'.format(region),
                'author_icon': 'http://flickr.com/icons/bobby.jpg',
                'title': alarm_name,
                'title_link': 'https://{}.console.aws.amazon.com/cloudwatch/home'.format(region),
                'text': alarm_description,
                'fields': [
                    {
                        'title': '{}/{}'.format(environment.upper(), region),
                        'value': new_state,
                        'short': 'false'
                    }
                ],
                'image_url': 'http://my-website.com/path/to/image.jpg',
                'thumb_url': 'http://example.com/path/to/thumb.png',
                'footer': 'AWS CloudWatch',
                'footer_icon': 'https://s3-us-west-2.amazonaws.com/slack-files2/avatars/2017-07-13/211653317025_9dff44afaa95cfde3c6f_36.png',
                'ts': time
            }
        ]
    }

    req = Request(HOOK_URL, json.dumps(slack_message))
    try:
        response = urlopen(req)
        response.read()
        logger.info("Message posted to %s", slack_message['channel'])
    except HTTPError as e:
        logger.error("Request failed: %d %s", e.code, e.reason)
    except URLError as e:
        logger.error("Server connection failed: %s", e.reason)
