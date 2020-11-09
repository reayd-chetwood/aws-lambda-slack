# Lambda Slack

Lambda function to send AWS CloudWatch messages to a Slack Channel. Could be modified to send other messages or alerts.

Please note that this pipeline model requires a lambda function called "PipelineUpstream" to copy artifacts to upstream
pipelines in test and prod environments. See this AWS article https://aws.amazon.com/blogs/devops/using-aws-codepipeline-to-perform-multi-region-deployments/


## How to Deploy
Check the Makefile for how to create the Lambda function and update it, but essentually you run the command:
```
  make create
```

## How to Run
there is a CloudWatch cron job that runs the script at midnight every day. Or you could run a test against it with an event.json

## Creating the Encryption URL
Run the command:
```
  $ aws kms encrypt --key-id alias/<KMS key name> --plaintext "<SLACK_HOOK_URL>"
```
Note the slack hook url should not contain the protocol prefix "https://", e.g. hooks.slack.com/services/ZZZZZZZZ/XXXXXXXX...
