resource "aws_sns_topic" "ebs_cleanup_notifications" {
    display_name = "available_ebs_volumes"
    name = "ebs_volumes_cleanup_notifications"
    policy = <<POLICY
    {
    "Version": "2008-10-17",
    "Statement": [
        {
            "sid": "__default_statement_ID",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Action": [
                "SNS:GetTopicAttributes",
                "SNS:SetTopicAttributes",
                "SNS:AddPermission",
                "SNS:RemovePermission",
                "SNS:DeleteTopic",
                "SNS:Subscribe",
                "SNS:ListSubscriptionsByTopic",
                "SNS:Publish",
                "SNS:Receive",
                "SNS:ListTopics",
                "SNS:GetSubscriptionAttributes",
                "SNS:ListSubscriptions"  
            ],
            "Resouce": "arn:aws:sns:us-east-1:364056614695:ebs_cleanup_notifications",
            "Condition": {
              "StringEquals": {
                "AWS:SourceOwner": "364056614695"
              }
           
            }
        }

        
    ]
}
POLICY
}


resource "aws_sns_topic_subscription" "ebs_volumes_cleanup_notifications_subscriber" {
    topic_arn = aws_sns_topic.ebs_cleanup_notifications.arn
    protocol = "email"
    endpoint = "mabellebonlo@gmail.com"
  
}
/*
resource "aws_sns_topic_subscription" "ebs_volumes_cleanup_notifications_lambda" {
    topic_arn = aws_sns_topic.ebs_cleanup_notifications.arn
    protocol = "lambda"
    endpoint = aws_lambda_function.ebs_cleanup_lambda.arn
  
}
*/


# iam role for lambda
resource "aws_iam_role" "ebs_cleanup_role" {
    name = "ebs_cleanup"

    assume_role_policy = jsonencode({
        "Version": "2012-10-17",
        "Statement" = [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service": "lambda.amazonaws.com"
                },
                "Action" : "sts:AssumeRole"
            }
        ]

    })
  
}

resource "aws_iam_policy" "ebs_cleanup_lambda_policy" {
    name = "ebs-volume-cleanup-policy"
    path = "/"
    description = "aws iam policy to manage aws lambda role"
    policy = jsonencode({
        "Version": "2012-10-17",
        "Statement" = [
            {
                "Action": [
                    "ec2:DeleteTags",
                    "ec2:CreateTags",
                    "ec2:DeleteVolume",
                    "ec2:DescribeVolumeStatus",
                    "ec2:DescribeVolumes",
                    "ec2:DescribeVolumeAttribute",
                    "sns:GetTopicAttributes",
                    "sns:Publish",
                    "sns:ListTopics",
                    "sns:GetSubscriptionAttributes",
                    "sns:ListSubscriptions"
                ],
                "Resource": "*",
                "Effect": "Allow"
            }
        ]
    })
  
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
    role = aws_iam_role.ebs_cleanup_role.name
    policy_arn = aws_iam_policy.ebs_cleanup_lambda_policy.arn
  
}

data "archive_file" "zip_volume_cleanup_code" {
    type = "zip"
    source_file = "${path.module}/functions/unused_ebs_volumes.py"
    output_path = "${path.module}/functions/unused_ebs_volumes.zip"
}

resource "aws_lambda_function" "ebs_volumes_cleanup_lambda" {
    filename = data.archive_file.zip_volume_cleanup_code.output_path
    source_code_hash = data.archive_file.zip_volume_cleanup_code.output_base64sha256
    function_name = "list_delete_available_ebs_volumes"
    role = aws_iam_role.ebs_cleanup_role.arn
    handler = "ebs_volumes_cleanup.lambda_handler"
    runtime = "python3.11"
    depends_on = [ aws_iam_role_policy_attachment.lambda_policy_attachment ]
    environment {
      variables = {
        sns_topic_arn = aws_sns_topic.ebs_cleanup_notifications.arn
      }
    }

}
#lambda trigger through cloudwatch event bridge

resource "aws_cloudwatch_event_rule" "ebs_scheduled_event_list" {
    name = "ebs_cleanup_schedule_list"
    description = "Schedule to run the cleanup list function "
    schedule_expression = "cron(0/10 * ? * 2#4 *)"
  
}

resource "aws_cloudwatch_event_target" "ebs_scheduled_lambda" {
    rule = aws_cloudwatch_event_rule.ebs_scheduled_event_list.name
    target_id = "ebs_cleanup_lambda"
    input = "{\"action\":\"list\"}"
    arn = aws_lambda_function.ebs_volumes_cleanup_lambda.arn
  
}

resource "aws_cloudwatch_event_rule" "ebs_scheduled_event_delete" {
    name = "ebs_cleanup_schedule_delete"
    description = "Schedule to run the cleanup delete function "
    schedule_expression = "cron(0/15 * ? * 2#4 *)"
  
}

resource "aws_cloudwatch_event_target" "ebs_scheduled_lambda_delete" {
    rule = aws_cloudwatch_event_rule.ebs_scheduled_event_delete.name
    target_id = "ebs_cleanup_lambda_delete"
    input = "{\"action\":\"delete\"}"
    arn = aws_lambda_function.ebs_volumes_cleanup_lambda.arn
  
}

resource "aws_lambda_permission" "allow_eventbridge_to_invoke_lambda" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.ebs_volumes_cleanup_lambda.function_name
    principal = "event.amazonaws.com"
  
}